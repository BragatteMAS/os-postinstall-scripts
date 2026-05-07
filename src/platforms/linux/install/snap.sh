#!/usr/bin/env bash
set -o pipefail
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

source "${SCRIPT_DIR}/../../../core/state.sh" || {
    log_error "Failed to load state.sh"
    exit 1
}

#######################################
# Snap Helper Functions
#######################################

# is_snap_installed - Check if a Snap package is already installed
# Args: $1 = package name
# Returns: 0 if installed, 1 if not
is_snap_installed() {
    local pkg="$1"
    snap list "$pkg" &>/dev/null
}

# snap_install - Install a single Snap package idempotently with classifier
# Handles classic: prefix for classic confinement packages.
# Snap errors are mostly deterministic (package missing, classic flag missing,
# already installed) — single attempt + per-failure classifier mirrors the
# brew-cask.sh pattern adopted in v5.4.2. Transient network errors recover
# by re-running setup.sh (idempotent).
# Args: $1 = package entry (may have classic: prefix)
# Returns: 0 on success, 1 on failure
snap_install() {
    local entry="$1"
    local pkg="$entry"
    local classic_flag=""

    if [[ "$entry" == classic:* ]]; then
        pkg="${entry#classic:}"
        classic_flag="--classic"
    fi

    if is_snap_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would snap install: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"

    local err_buf rc=0
    err_buf=$(sudo snap install "$pkg" $classic_flag 2>&1 >/dev/null) || rc=$?

    if (( rc == 0 )); then
        if [[ -n "$classic_flag" ]]; then
            log_ok "Installed: $pkg (classic)"
        else
            log_ok "Installed: $pkg"
        fi
        save_package_state "snap" "$pkg" "${PROFILE_NAME:-unknown}"
        return 0
    fi

    local reason="exit $rc"
    local hint=""
    if grep -qiE "no snap found|not found in the store|cannot find" <<<"$err_buf"; then
        reason="snap not found in store"
        hint="Fix: snap find $pkg  (find correct name; snap may have been renamed)"
    elif grep -qiE "is already installed" <<<"$err_buf"; then
        reason="already installed (state file out of sync)"
        hint="Fix: snap list $pkg  (verify); next setup.sh run will reconcile"
    elif grep -qiE "requires --classic|requires classic confinement" <<<"$err_buf"; then
        reason="package requires --classic confinement"
        hint="Fix: prefix entry with 'classic:' in snap-*.txt (e.g., 'classic:$pkg')"
    elif grep -qiE "could not be found|404|connection|network|timeout|resolve|temporarily unavailable" <<<"$err_buf"; then
        reason="network error"
        hint="Fix: re-run setup.sh — idempotent, only retries the missing items"
    fi

    log_error "Failed to install: $pkg ($reason)"
    [[ -n "$hint" ]] && log_info "  → $hint"
    return 1
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

log_banner "Snap Package Installer"

# Parse --full arg for two-pass install
pkg_file="snap-developer.txt"
if [[ "${1:-}" == "--full" || "${1:-}" == "--post" ]]; then
    # --post kept as alias for backwards-compat
    pkg_file="snap-full.txt"
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

# Semantic exit code based on failure state
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    exit "${EXIT_PARTIAL_FAILURE:-1}"
else
    exit "${EXIT_SUCCESS:-0}"
fi
