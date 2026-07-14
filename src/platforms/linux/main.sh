#!/usr/bin/env bash
set -o pipefail
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
# Named LINUX_DIR (not SCRIPT_DIR) to avoid readonly collisions
# when multiple scripts in the source chain declare SCRIPT_DIR.
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

source "${LINUX_DIR}/../../core/progress.sh" || {
    log_error "Failed to load progress.sh"
    exit 1
}

source "${LINUX_DIR}/../../core/wizard.sh" || {
    log_error "Failed to load wizard.sh"
    exit 1
}

# Cross-platform installers directory
INSTALL_DIR="${LINUX_DIR}/../../install"

# DATA_DIR is set by packages.sh, but verify it's correct
if [[ -z "${DATA_DIR:-}" || ! -d "${DATA_DIR}" ]]; then
    DATA_DIR="$(cd "${LINUX_DIR}/../../data" 2>/dev/null && pwd -P)"
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

    # Show DRY_RUN banner if active
    show_dry_run_banner

    log_info "Profile: $profile_name"

    # Count platform-relevant steps for progress feedback
    local total_steps
    total_steps=$(count_platform_steps "$profile_file" "linux")

    # For developer/full: dev-env runs before dispatch loop
    # (Rust CLI tools moved to CSV-driven csv:rust-* dispatch in Onda 5)
    if [[ "$profile_name" != "minimal" ]]; then
        total_steps=$((total_steps + 1))
    fi

    local current_step=0

    # For developer/full: install dev environment FIRST (Node.js + Python for AI tools)
    # NOTE: dev-env.sh is an orchestrator with side effects (mise/fnm/uv installers,
    # interactive prompts). retry_with_backoff is for atomic transient ops — wrapping
    # an orchestrator multiplies failures (each retry re-records the same failed
    # sub-installer). Atomic curl/brew calls inside the orchestrator handle their
    # own retry semantics where it matters.
    if [[ "$profile_name" != "minimal" ]]; then
        current_step=$((current_step + 1))
        show_progress "$current_step" "$total_steps" "Setting up development environment..."
        # full = the user already chose "everything" at the profile menu; the
        # category menus inside dev-env would re-ask what is already decided
        # (and are the only mid-run prompts). NONINTERACTIVE makes them follow
        # the profile intent (install all; SSH-key offer skipped, default was
        # No anyway). developer keeps the menus — partial intent is plausible.
        if [[ "$profile_name" == "full" ]]; then
            if ! NONINTERACTIVE=true bash "${INSTALL_DIR}/dev-env.sh"; then
                record_failure "dev-env"
            fi
        elif ! bash "${INSTALL_DIR}/dev-env.sh"; then
            record_failure "dev-env"
        fi
    fi

    # Read profile and dispatch to Linux-relevant installers.
    # The list rides on FD 3, NOT stdin: children (apt, installers) inherit
    # stdin and can drain it, silently eating the remaining profile lines —
    # the macOS twin of this loop did exactly that on a real install
    # (2026-07-13). Same pattern as csv.sh's install loop.
    while IFS= read -r pkg_file <&3 || [[ -n "$pkg_file" ]]; do
        # Trim leading whitespace
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"

        # Skip comments and empty lines
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        # Dispatch based on package file type (PLATFORM FILTERING)
        case "$pkg_file" in
            apt.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing APT packages..."
                if ! retry_with_backoff bash "${LINUX_DIR}/install/apt.sh"; then
                    record_failure "APT packages"
                fi
                ;;
            apt-developer.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing APT developer packages..."
                if ! retry_with_backoff bash "${LINUX_DIR}/install/apt.sh" --developer; then
                    record_failure "APT developer packages"
                fi
                ;;
            apt-full.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing APT full extras..."
                if ! retry_with_backoff bash "${LINUX_DIR}/install/apt.sh" --full; then
                    record_failure "APT full extras"
                fi
                ;;
            flatpak-developer.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing Flatpak packages..."
                # NOTE: retry_with_backoff dropped here (was wrapping the whole
                # wave). Flatpak failures are mostly deterministic (app_id wrong,
                # already installed, permission). Per-package classifier in
                # flatpak.sh surfaces actionable hints. Mirror v5.4.2 brew-cask.
                if ! bash "${LINUX_DIR}/install/flatpak.sh"; then
                    record_failure "Flatpak packages"
                fi
                ;;
            flatpak-full.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing Flatpak full extras..."
                if ! bash "${LINUX_DIR}/install/flatpak.sh" --full; then
                    record_failure "Flatpak full extras"
                fi
                ;;
            snap-developer.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing Snap packages..."
                # NOTE: retry_with_backoff dropped here. Snap failures are mostly
                # deterministic (snap missing, classic flag missing, already
                # installed). Per-package classifier in snap.sh surfaces hints.
                if ! bash "${LINUX_DIR}/install/snap.sh"; then
                    record_failure "Snap packages"
                fi
                ;;
            snap-full.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing Snap full extras..."
                if ! bash "${LINUX_DIR}/install/snap.sh" --full; then
                    record_failure "Snap full extras"
                fi
                ;;
            # cargo-developer.txt removed in Onda 5 — Rust tools live in data/packages.csv (csv:rust-*)
            npm-developer.txt)
                log_debug "Skipping npm-developer.txt (handled by dev-env)"
                ;;
            ai-tools-full.txt)
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing AI tools..."
                # NOTE: retry_with_backoff dropped here. ai-tools.sh is an
                # orchestrator (multiple sub-installers); wave-level retry
                # multiplied failures (each retry re-records the same failed
                # sub-installer). Same rationale as dev-env.sh:138 which never
                # had retry, and as v5.4.5 dropped retry around snap/flatpak.
                if ! bash "${INSTALL_DIR}/ai-tools.sh"; then
                    record_failure "AI tools"
                fi
                ;;
            brew.txt|brew-developer.txt|brew-full.txt|brew-cask-developer.txt|brew-cask-full.txt|macos-defaults.txt)
                # macOS-only - skip silently on Linux
                log_debug "Skipping $pkg_file (macOS only)"
                ;;
            csv:rust-*)
                _csv_cat="${pkg_file#csv:}"
                current_step=$((current_step + 1))
                show_progress "$current_step" "$total_steps" "Installing CSV category: $_csv_cat..."
                install_csv_category "$_csv_cat" || record_failure "csv:$_csv_cat"
                ;;
            winget.txt)
                # Windows-only - skip silently on Linux
                log_debug "Skipping winget.txt (Windows only)"
                ;;
            *)
                log_warn "Unknown package file: $pkg_file"
                ;;
        esac
    done 3< "$profile_file"

    # Run post-install hooks
    source "${LINUX_DIR}/../../core/hooks.sh" 2>/dev/null || true
    if type run_hooks &>/dev/null; then
        run_hooks "linux"
    fi

    return $_worst_exit
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

# INTERACTIVE MODE: no argument — use the shared wizard menu (same as setup.sh)
if profile=$(select_profile_interactive "linux"); then
    install_profile "$profile"
else
    log_info "Cancelled — no changes made."
    exit 0
fi
