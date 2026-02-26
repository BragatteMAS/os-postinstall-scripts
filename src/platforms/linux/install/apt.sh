#!/usr/bin/env bash
set -o pipefail
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

# NOTE: is_apt_installed() comes from core/idempotent.sh (already sourced)
# NOTE: retry_with_backoff() comes from core/errors.sh (already sourced)

# safe_apt_update - Update package lists with lock handling and retry
# Uses DPkg::Lock::Timeout=60 instead of manual fuser loop
# Returns: 0 on success, 1 on failure
safe_apt_update() {
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would run apt update"
        return 0
    fi

    log_info "Updating package lists (with dpkg lock timeout)..."
    retry_with_backoff sudo apt-get update -y -o DPkg::Lock::Timeout=60
}

# apt_hardened_install - Install a single package with retry and lock handling
# Uses DPkg::Lock::Timeout=60, retry_with_backoff, and --force-confold in non-interactive mode
# Args: $1 = package name
# Returns: 0 on success, 1 on failure
apt_hardened_install() {
    local pkg="$1"

    if is_apt_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would apt install: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"

    # Build apt command array
    local apt_cmd=(sudo apt-get install -y -o DPkg::Lock::Timeout=60)

    # Append non-interactive options if set
    if [[ "${NONINTERACTIVE:-}" == "true" ]]; then
        apt_cmd+=("${APT_NONINTERACTIVE_OPTS[@]}")
    fi

    apt_cmd+=("$pkg")

    if retry_with_backoff "${apt_cmd[@]}"; then
        log_ok "Installed: $pkg"
        return 0
    else
        log_warn "Package not found or install failed: $pkg"
        return 1
    fi
}

#######################################
# Cleanup function
#######################################
# shellcheck disable=SC2329  # invoked via trap
cleanup() {
    local exit_code=$?
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed packages: ${FAILED_ITEMS[*]}"
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

log_banner "APT Package Installer"

# Determine which package file to use (two-pass support)
pkg_file="apt.txt"
if [[ "${1:-}" == "--post" ]]; then
    pkg_file="apt-post.txt"
fi

# Non-interactive mode: keep existing config files on package upgrades
if [[ "${NONINTERACTIVE:-}" == "true" ]]; then
    export DEBIAN_FRONTEND=noninteractive
    APT_NONINTERACTIVE_OPTS=(-o Dpkg::Options::="--force-confold")
    log_info "Non-interactive mode: DEBIAN_FRONTEND=noninteractive, --force-confold"
fi

# Load packages from data file
if ! load_packages "$pkg_file"; then
    log_error "Failed to load apt packages from data/packages/$pkg_file"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} packages from $pkg_file"

# Update package lists
if ! safe_apt_update; then
    log_warn "Failed to update package lists. Continuing with installation..."
fi

# Install packages
log_info "Installing ${#PACKAGES[@]} APT packages..."

for pkg in "${PACKAGES[@]}"; do
    if ! apt_hardened_install "$pkg"; then
        record_failure "$pkg"
    fi
done

# No cleanup (setup script, not maintenance tool)

# Summary
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    log_warn "Completed with ${#FAILED_ITEMS[@]} failures"
else
    log_ok "All packages installed successfully"
fi

# Semantic exit code based on failure state
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    exit "${EXIT_PARTIAL_FAILURE:-1}"
else
    exit "${EXIT_SUCCESS:-0}"
fi
