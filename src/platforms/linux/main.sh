#!/usr/bin/env bash
#######################################
# Script: main.sh
# Description: Main orchestrator for Linux post-installation
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME

# LINUX_DIR: the directory where THIS script lives
# Note: We use LINUX_DIR instead of SCRIPT_DIR because packages.sh
# overwrites SCRIPT_DIR with its own location (src/core/).
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly LINUX_DIR

# Source core utilities from src/core/
source "${LINUX_DIR}/../../core/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${LINUX_DIR}/../../core/platform.sh" || {
    log_error "Failed to load platform.sh"
    exit 1
}

source "${LINUX_DIR}/../../core/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

source "${LINUX_DIR}/../../core/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

# Cross-platform installers directory
INSTALL_DIR="${LINUX_DIR}/../../install"

# DATA_DIR is set by packages.sh, but verify it's correct
if [[ -z "${DATA_DIR:-}" || ! -d "${DATA_DIR}" ]]; then
    DATA_DIR="$(cd "${LINUX_DIR}/../../data" 2>/dev/null && pwd -P)"
fi

# Cleanup function
cleanup() {
    local exit_code=$?
    [[ $exit_code -ne 0 ]] && log_info "Exiting ${SCRIPT_NAME} with code $exit_code"
    exit $exit_code
}
trap cleanup EXIT INT TERM

#######################################
# show_menu()
# Display Linux profile selection menu
#######################################
show_menu() {
    echo ""
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${BLUE}         Linux Post-Installation Script                ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo ""
    echo "Select installation profile:"
    echo "  1. Minimal   (essential packages only)"
    echo "  2. Developer (system + dev tools + AI)"
    echo "  3. Full      (everything)"
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
# (apt.sh, flatpak.sh, snap.sh, etc.) checks DRY_RUN
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

    log_info "Profile: $profile_name"

    # For developer/full: install dev tools FIRST (provides Node.js for AI tools)
    if [[ "$profile_name" != "minimal" ]]; then
        log_info "Setting up development environment..."
        bash "${INSTALL_DIR}/dev-env.sh"

        log_info "Installing Rust CLI tools..."
        bash "${INSTALL_DIR}/rust-cli.sh"
    fi

    # Read profile and dispatch to Linux-relevant installers
    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        # Trim leading whitespace
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"

        # Skip comments and empty lines
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        # Dispatch based on package file type (PLATFORM FILTERING)
        case "$pkg_file" in
            apt.txt)
                log_info "Installing APT packages..."
                bash "${LINUX_DIR}/install/apt.sh"
                ;;
            apt-post.txt)
                log_info "Installing APT post-packages..."
                bash "${LINUX_DIR}/install/apt.sh" --post
                ;;
            flatpak.txt)
                log_info "Installing Flatpak packages..."
                bash "${LINUX_DIR}/install/flatpak.sh"
                ;;
            flatpak-post.txt)
                log_info "Installing Flatpak post-packages..."
                bash "${LINUX_DIR}/install/flatpak.sh" --post
                ;;
            snap.txt)
                log_info "Installing Snap packages..."
                bash "${LINUX_DIR}/install/snap.sh"
                ;;
            snap-post.txt)
                log_info "Installing Snap post-packages..."
                bash "${LINUX_DIR}/install/snap.sh" --post
                ;;
            cargo.txt)
                log_info "Installing Cargo packages..."
                bash "${LINUX_DIR}/install/cargo.sh"
                ;;
            npm.txt)
                log_debug "Skipping npm.txt (handled by dev-env)"
                ;;
            ai-tools.txt)
                log_info "Installing AI tools..."
                bash "${INSTALL_DIR}/ai-tools.sh"
                ;;
            brew.txt|brew-cask.txt)
                # macOS-only - skip silently on Linux
                log_debug "Skipping $pkg_file (macOS only)"
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
