#!/usr/bin/env bash
#######################################
# Script: brew-cask.sh
# Description: Install Homebrew casks for macOS (data-driven)
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Source core utilities from src/core/
source "${SCRIPT_DIR}/../../../core/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${SCRIPT_DIR}/../../../core/idempotent.sh" || {
    log_error "Failed to load idempotent.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../../core/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../../core/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

#######################################
# Verify Homebrew is available
#######################################

if ! command -v brew &>/dev/null; then
    log_error "Homebrew not found. Run install/homebrew.sh first."
    exit 1
fi

#######################################
# Brew Cask Helper Functions
#######################################

# _is_cask_installed - Check if a cask is already installed
# Note: is_brew_installed() from core checks formulae only; casks need --cask flag
# Args: $1 = cask name
# Returns: 0 if installed, 1 if not
_is_cask_installed() {
    local cask="${1:-}"
    [[ -z "$cask" ]] && return 1
    brew list --cask "$cask" &>/dev/null
}

# _brew_cask_install - Install a single Homebrew cask
# Args: $1 = cask name
# Returns: 0 on success, 1 on failure
_brew_cask_install() {
    local cask="$1"

    # Check if already installed (cask-specific check)
    if _is_cask_installed "$cask"; then
        log_debug "Already installed: $cask"
        return 0
    fi

    # DRY_RUN check before actual install
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install cask: $cask"
        return 0
    fi

    log_info "Installing: $cask"
    if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install --cask "$cask" 2>/dev/null; then
        log_ok "Installed: $cask"
        return 0
    else
        log_error "Failed to install: $cask"
        return 1
    fi
}

#######################################
# Cleanup function
#######################################
cleanup() {
    local exit_code=$?
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed casks: ${FAILED_ITEMS[*]}"
    fi
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# Track failed installations
declare -a FAILED_ITEMS=()

#######################################
# Main
#######################################

log_banner "Homebrew Cask Installer"

# Load packages from data file
if ! load_packages "brew-cask.txt"; then
    log_error "Failed to load cask packages from data/packages/brew-cask.txt"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} casks from brew-cask.txt"

# Install casks
log_info "Installing ${#PACKAGES[@]} Homebrew casks..."

for cask in "${PACKAGES[@]}"; do
    if ! _brew_cask_install "$cask"; then
        record_failure "$cask"
    fi
done

# Summary
show_failure_summary

# Always exit 0 (per Phase 1 decision)
exit 0
