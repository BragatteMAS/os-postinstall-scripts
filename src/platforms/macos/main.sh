#!/usr/bin/env bash
#######################################
# Script: main.sh
# Description: Main orchestrator for macOS post-installation
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME

# MACOS_DIR: the directory where THIS script lives
# Note: We use MACOS_DIR instead of SCRIPT_DIR because packages.sh
# overwrites SCRIPT_DIR with its own location (src/core/).
MACOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly MACOS_DIR

# Source core utilities from src/core/
source "${MACOS_DIR}/../../core/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${MACOS_DIR}/../../core/platform.sh" || {
    log_error "Failed to load platform.sh"
    exit 1
}

source "${MACOS_DIR}/../../core/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

source "${MACOS_DIR}/../../core/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

source "${MACOS_DIR}/../../core/progress.sh" || {
    log_error "Failed to load progress.sh"
    exit 1
}

# Cross-platform installers directory
INSTALL_DIR="${MACOS_DIR}/../../install"

# DATA_DIR is set by packages.sh, but verify it's correct
if [[ -z "${DATA_DIR:-}" || ! -d "${DATA_DIR}" ]]; then
    DATA_DIR="$(cd "${MACOS_DIR}/../../data" 2>/dev/null && pwd -P)"
fi

# Cleanup function
cleanup() {
    local exit_code=$?

    # Aggregate failures from child processes via shared log
    if [[ -n "${FAILURE_LOG:-}" && -f "$FAILURE_LOG" && -s "$FAILURE_LOG" ]]; then
        log_warn "Child process failures detected:"
        while IFS= read -r item; do
            echo "  - $item"
        done < "$FAILURE_LOG"
    fi

    [[ $exit_code -ne 0 ]] && log_info "Exiting ${SCRIPT_NAME} with code $exit_code"
    exit $exit_code
}
trap cleanup EXIT INT TERM

#######################################
# check_bash_upgrade()
# Warn if Bash version < 4.0 and provide upgrade instructions
# Does NOT exit - user may want to install brew first to get newer bash
#######################################
check_bash_upgrade() {
    local major="${BASH_VERSINFO[0]:-0}"

    if [[ "$major" -lt 4 ]]; then
        log_warn "Bash ${BASH_VERSINFO[0]:-?}.${BASH_VERSINFO[1]:-?} detected (version 4.0+ recommended)"
        echo ""
        echo "  Upgrade instructions:"
        echo "    brew install bash"
        echo "    sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'"
        echo "    chsh -s /opt/homebrew/bin/bash"
        echo ""
        log_info "Continuing with current Bash version..."
    fi
}

#######################################
# show_menu()
# Display macOS profile selection menu
# Uses simple read/case (Bash 3.2 compatible, no select builtin)
#######################################
show_menu() {
    echo ""
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${BLUE}         macOS Post-Installation Script                ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo ""
    echo "Select installation profile:"
    echo "  1. Minimal   (essential tools only)"
    echo "  2. Developer (system + dev tools)"
    echo "  3. Full      (everything + AI tools)"
    echo "  0. Exit"
    echo ""
}

#######################################
# install_profile()
# Install packages for a given profile
# Args: $1 = profile name (minimal, developer, full)
# Returns: 0 on success, 1 on error
#
# DRY_RUN design: NOT checked here. Each sub-script
# (homebrew.sh, brew.sh, brew-cask.sh) checks DRY_RUN
# at the point of mutation.
#######################################
install_profile() {
    local profile_name="$1"
    local profile_file="${DATA_DIR}/packages/profiles/${profile_name}.txt"

    # Validate profile exists
    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile not found: $profile_name"
        return 1
    fi

    # Show DRY_RUN banner if active
    show_dry_run_banner

    log_info "Profile: $profile_name"

    # Count platform-relevant steps for progress feedback
    # +1 for Homebrew installation step (always runs first)
    local total_steps
    total_steps=$(count_platform_steps "$profile_file" "macos")
    total_steps=$((total_steps + 1))

    local current_step=0

    # Ensure Homebrew is installed first
    current_step=$((current_step + 1))
    log_info "[Step ${current_step}/${total_steps}] Ensuring Homebrew is installed..."
    bash "${MACOS_DIR}/install/homebrew.sh" || return 1

    # Read profile and dispatch to macOS-relevant installers
    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        # Trim leading whitespace
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"

        # Skip comments and empty lines
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        # Dispatch based on package file type (PLATFORM FILTERING)
        case "$pkg_file" in
            brew.txt)
                current_step=$((current_step + 1))
                log_info "[Step ${current_step}/${total_steps}] Installing brew packages..."
                bash "${MACOS_DIR}/install/brew.sh"
                ;;
            brew-cask.txt)
                current_step=$((current_step + 1))
                log_info "[Step ${current_step}/${total_steps}] Installing brew cask packages..."
                bash "${MACOS_DIR}/install/brew-cask.sh"
                ;;
            ai-tools.txt)
                current_step=$((current_step + 1))
                log_info "[Step ${current_step}/${total_steps}] Installing AI tools..."
                bash "${INSTALL_DIR}/ai-tools.sh"
                ;;
            apt.txt|apt-post.txt)
                # Linux-only - skip silently on macOS
                log_debug "Skipping $pkg_file (Linux only)"
                ;;
            flatpak.txt|flatpak-post.txt|snap.txt|snap-post.txt)
                # Linux-only - skip silently on macOS
                log_debug "Skipping $pkg_file (Linux only)"
                ;;
            cargo.txt)
                # No macOS cargo installer yet - skip
                log_debug "Skipping cargo.txt (no macOS installer)"
                ;;
            npm.txt)
                log_debug "Skipping npm.txt (handled by dev-env)"
                ;;
            winget.txt)
                # Windows-only - skip silently on macOS
                log_debug "Skipping winget.txt (Windows only)"
                ;;
            *)
                log_warn "Unknown package file: $pkg_file"
                ;;
        esac
    done < "$profile_file"
}

#######################################
# Main: Dual-mode operation
# - With $1: unattended mode (called from setup.sh)
# - Without args: interactive menu
#######################################

# Check Bash version and warn if old
check_bash_upgrade

# Check for command-line argument FIRST (unattended mode)
if [[ -n "${1:-}" ]]; then
    log_info "Running in unattended mode with profile: $1"
    install_profile "$1"
    exit $?
fi

# INTERACTIVE MODE: no argument, show menu
while true; do
    show_menu
    read -rp "Enter your choice (0-3): " choice

    case $choice in
        1) install_profile "minimal" ;;
        2) install_profile "developer" ;;
        3) install_profile "full" ;;
        0) log_info "Exiting..."; exit 0 ;;
        *) log_warn "Invalid choice" ;;
    esac

    echo ""
    read -rp "Press Enter to continue..."
done
