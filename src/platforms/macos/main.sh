#!/usr/bin/env bash
set -o pipefail
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
# Named MACOS_DIR (not SCRIPT_DIR) to avoid readonly collisions
# when multiple scripts in the source chain declare SCRIPT_DIR.
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

source "${MACOS_DIR}/../../core/csv.sh" || {
    log_error "Failed to load csv.sh"
    exit 1
}

# Cross-platform installers directory
INSTALL_DIR="${MACOS_DIR}/../../install"

# DATA_DIR is set by packages.sh, but verify it's correct
if [[ -z "${DATA_DIR:-}" || ! -d "${DATA_DIR}" ]]; then
    DATA_DIR="$(cd "${MACOS_DIR}/../../data" 2>/dev/null && pwd -P)"
fi

# Track worst exit code from child processes
_worst_exit=0

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

    [[ ${_worst_exit:-$exit_code} -ne 0 ]] && log_info "Exiting ${SCRIPT_NAME} with code ${_worst_exit:-$exit_code}"
    exit ${_worst_exit:-$exit_code}
}
trap cleanup EXIT
trap signal_cleanup INT TERM

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
    echo "Select installation profile:"
    echo "  1. Minimal   — essential system packages only"
    echo "  2. Developer — adds dev tools, Rust CLIs, dotfiles"
    echo "  3. Full      — everything + AI tools (Claude, etc)"
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

    # For developer/full: dev-env runs before dispatch loop
    # (Rust CLI tools moved to CSV-driven csv:rust-* dispatch in Onda 5)
    if [[ "$profile_name" != "minimal" ]]; then
        total_steps=$((total_steps + 1))
    fi

    local current_step=0

    # Ensure Homebrew is installed first
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Ensuring Homebrew is installed..."
    bash "${MACOS_DIR}/install/homebrew.sh" || return 1

    # For developer/full: install dev environment FIRST (Node.js + Python for AI tools)
    # NOTE: dev-env.sh is an orchestrator with side effects (mise/fnm/uv installers,
    # interactive prompts). retry_with_backoff is for atomic transient ops — wrapping
    # an orchestrator multiplies failures (each retry re-records the same failed
    # sub-installer). Atomic curl/brew calls inside the orchestrator handle their
    # own retry semantics where it matters.
    if [[ "$profile_name" != "minimal" ]]; then
        current_step=$((current_step + 1))
        show_progress "$current_step" "$total_steps" "Setting up development environment..."
        if ! bash "${INSTALL_DIR}/dev-env.sh"; then
            record_failure "dev-env"
        fi
    fi

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
                show_progress "$current_step" "$total_steps" "Installing brew packages (base)..."
                if ! retry_with_backoff bash "${MACOS_DIR}/install/brew.sh"; then
                    record_failure "brew packages"
                fi
                ;;
            brew-developer.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing brew developer packages..."
                if ! retry_with_backoff bash "${MACOS_DIR}/install/brew.sh" --developer; then
                    record_failure "brew developer packages"
                fi
                ;;
            brew-full.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing brew full extras..."
                if ! retry_with_backoff bash "${MACOS_DIR}/install/brew.sh" --full; then
                    record_failure "brew full extras"
                fi
                ;;
            brew-cask-developer.txt|brew-cask-full.txt)
                # In --groups mode, defer all cask install to a single
                # interactive selector run AFTER the dispatch loop. Skip both
                # brew-cask-* dispatch entries.
                if [[ "${GROUPS_MODE:-}" == "true" ]]; then
                    log_debug "Skipping $pkg_file (deferred to --groups selector)"
                    continue
                fi
                current_step=$((current_step + 1))
                # NOTE: retry_with_backoff dropped here (was wrapping the whole
                # wave). Most cask failures are deterministic (app exists,
                # cask renamed, conflicts) — retrying wastes 50s and produces
                # the same error. Per-package classification + actionable hint
                # in brew-cask.sh tells the user what to do; transient network
                # errors are recovered by re-running setup.sh (idempotent).
                if [[ "$pkg_file" == "brew-cask-developer.txt" ]]; then
                    show_progress "$current_step" "$total_steps" "Installing brew cask packages..."
                    if ! bash "${MACOS_DIR}/install/brew-cask.sh"; then
                        record_failure "brew cask packages"
                    fi
                else
                    show_progress "$current_step" "$total_steps" "Installing brew cask full extras..."
                    if ! bash "${MACOS_DIR}/install/brew-cask.sh" --full; then
                        record_failure "brew cask full extras"
                    fi
                fi
                ;;
            ai-tools-full.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing AI tools..."
                if ! retry_with_backoff bash "${INSTALL_DIR}/ai-tools.sh"; then
                    record_failure "AI tools"
                fi
                ;;
            apt.txt|apt-developer.txt|apt-full.txt)
                # Linux-only - skip silently on macOS
                log_debug "Skipping $pkg_file (Linux only)"
                ;;
            csv:rust-*)
                local _csv_cat="${pkg_file#csv:}"
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing CSV category: $_csv_cat..."
                install_csv_category "$_csv_cat" || record_failure "csv:$_csv_cat"
                ;;
            flatpak-developer.txt|flatpak-full.txt|snap-developer.txt|snap-full.txt)
                # Linux-only - skip silently on macOS
                log_debug "Skipping $pkg_file (Linux only)"
                ;;
            # cargo-developer.txt removed in Onda 5 — Rust tools live in data/packages.csv (csv:rust-*)
            macos-defaults.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Applying macOS system defaults..."
                if ! bash "${MACOS_DIR}/install/defaults.sh"; then
                    record_failure "macOS defaults"
                fi
                ;;
            npm-developer.txt)
                log_debug "Skipping npm-developer.txt (handled by dev-env)"
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

    # ── --groups mode: run interactive cask selector ─────────────────────
    # Defers all brew-cask-* dispatch to a single multi-select prompt over
    # data/packages/groups/*.txt. User picks groups; only chosen groups install.
    if [[ "${GROUPS_MODE:-}" == "true" ]]; then
        source "${MACOS_DIR}/../../core/group-selector.sh"
        local _selected
        _selected=$(select_groups)
        if [[ -n "$_selected" ]]; then
            log_info "Installing selected groups..."
            # shellcheck disable=SC2086 # word-splitting intentional
            install_groups $_selected || record_failure "group install"
        else
            log_info "No groups selected — skipping cask install"
        fi
    fi

    # Run post-install hooks
    source "${MACOS_DIR}/../../core/hooks.sh" 2>/dev/null || true
    if type run_hooks &>/dev/null; then
        run_hooks "macos"
    fi

    return $_worst_exit
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
