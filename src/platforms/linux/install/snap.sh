#!/usr/bin/env bash
#######################################
# Script: snap.sh
# Description: Install Snap packages for Linux (data-driven)
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
# Snap Helper Functions
#######################################

# NOTE: retry_with_backoff() comes from core/errors.sh (already sourced)

# is_snap_installed - Check if a Snap package is already installed
# Args: $1 = package name
# Returns: 0 if installed, 1 if not
is_snap_installed() {
    local pkg="$1"
    # Trailing space prevents partial matches (e.g., "docker" vs "docker-compose")
    snap list 2>/dev/null | grep -q "^${pkg} "
}

# snap_install - Install a single Snap package with retry and idempotency
# Handles classic: prefix for classic confinement packages
# Args: $1 = package entry (may have classic: prefix)
# Returns: 0 on success, 1 on failure
snap_install() {
    local entry="$1"
    local pkg="$entry"
    local classic_flag=""

    # Parse classic: prefix
    if [[ "$entry" == classic:* ]]; then
        pkg="${entry#classic:}"
        classic_flag="--classic"
    fi

    if is_snap_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"

    if retry_with_backoff sudo snap install "$pkg" $classic_flag; then
        if [[ -n "$classic_flag" ]]; then
            log_ok "Installed: $pkg (classic)"
        else
            log_ok "Installed: $pkg"
        fi
        return 0
    else
        log_warn "Package not found or install failed: $pkg"
        return 1
    fi
}

#######################################
# Cleanup function
#######################################
cleanup() {
    local exit_code=$?
    # Show failure summary if any
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed packages: ${FAILED_ITEMS[*]}"
    fi
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Track failed installations
declare -a FAILED_ITEMS=()

#######################################
# Main
#######################################

log_banner "Snap Package Installer"

# Parse --post arg for two-pass install
pkg_file="snap.txt"
if [[ "${1:-}" == "--post" ]]; then
    pkg_file="snap-post.txt"
fi

# Check if snap is available
if ! command -v snap &>/dev/null; then
    log_warn "snap not found, skipping..."
    exit 0
fi

# Load packages from data file
if ! load_packages "$pkg_file"; then
    log_error "Failed to load snap packages from data/packages/$pkg_file"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} packages from $pkg_file"

# Install packages
log_info "Installing ${#PACKAGES[@]} Snap packages..."

for pkg in "${PACKAGES[@]}"; do
    if ! snap_install "$pkg"; then
        record_failure "$pkg"
    fi
done

# Summary
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    log_warn "Completed with ${#FAILED_ITEMS[@]} failures"
else
    log_ok "All packages installed successfully"
fi

# Always exit 0 (per Phase 1 decision)
exit 0
