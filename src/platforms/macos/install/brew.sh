#!/usr/bin/env bash
#######################################
# Script: brew.sh
# Description: Install Homebrew formulae for macOS (data-driven)
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
# Brew Formula Helper Functions
#######################################

# _brew_formula_install - Install a single Homebrew formula
# Uses is_brew_installed() from core/idempotent.sh for idempotency check
# Args: $1 = formula name
# Returns: 0 on success, 1 on failure
_brew_formula_install() {
    local pkg="$1"

    # Check if already installed (uses core/idempotent.sh)
    if is_brew_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    # DRY_RUN check before actual install
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install formula: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"
    if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "$pkg" 2>/dev/null; then
        log_ok "Installed: $pkg"
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

#######################################
# Cleanup function
#######################################
cleanup() {
    local exit_code=$?
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed formulae: ${FAILED_ITEMS[*]}"
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

log_banner "Homebrew Formulae Installer"

# Load packages from data file
if ! load_packages "brew.txt"; then
    log_error "Failed to load brew packages from data/packages/brew.txt"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} formulae from brew.txt"

# Install formulae
log_info "Installing ${#PACKAGES[@]} Homebrew formulae..."

for pkg in "${PACKAGES[@]}"; do
    if ! _brew_formula_install "$pkg"; then
        record_failure "$pkg"
    fi
done

# Summary
show_failure_summary

# Always exit 0 (per Phase 1 decision)
exit 0
