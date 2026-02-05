#!/usr/bin/env bash
#######################################
# Script: apt.sh
# Description: Install APT packages for Linux (data-driven)
# Author: Bragatte
# Date: 2026-02-05
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
# APT Helper Functions
#######################################

# is_apt_installed - Check if a package is already installed
# Args: $1 = package name
# Returns: 0 if installed, 1 if not
is_apt_installed() {
    local pkg="$1"
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
}

# apt_install - Install a single package via apt
# Args: $1 = package name
# Returns: 0 on success, 1 on failure
apt_install() {
    local pkg="$1"

    if is_apt_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"
    if sudo apt-get install -y "$pkg" 2>/dev/null; then
        log_ok "Installed: $pkg"
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

# safe_apt_update - Update package lists with lock handling
# Returns: 0 on success, 1 on failure
safe_apt_update() {
    # Wait for apt lock to be free
    local wait_count=0
    while sudo fuser /var/lib/dpkg/lock-frontend &>/dev/null 2>&1; do
        if [[ $wait_count -eq 0 ]]; then
            log_info "Waiting for apt lock..."
        fi
        sleep 2
        wait_count=$((wait_count + 1))
        if [[ $wait_count -gt 30 ]]; then
            log_error "Timeout waiting for apt lock"
            return 1
        fi
    done

    sudo apt-get update -y
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

log_banner "APT Package Installer"

# Load packages from data file
if ! load_packages "apt.txt"; then
    log_error "Failed to load apt packages from data/packages/apt.txt"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} packages from apt.txt"

# Update package lists
log_info "Updating package lists..."
if ! safe_apt_update; then
    log_warn "Failed to update package lists. Continuing with installation..."
fi

# Install packages
log_info "Installing ${#PACKAGES[@]} APT packages..."

for pkg in "${PACKAGES[@]}"; do
    if ! apt_install "$pkg"; then
        record_failure "$pkg"
    fi
done

# Final cleanup
log_info "Performing system cleanup..."
sudo apt-get autoclean -y 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true

# Summary
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    log_warn "Completed with ${#FAILED_ITEMS[@]} failures"
else
    log_ok "All packages installed successfully"
fi

# Always exit 0 (per Phase 1 decision)
exit 0
