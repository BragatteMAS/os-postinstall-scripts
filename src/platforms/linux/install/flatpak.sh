#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: flatpak.sh
# Description: Install Flatpak packages for Linux (data-driven)
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
# Flatpak Helper Functions
#######################################

# ensure_flathub_remote - Add Flathub remote if not already configured
# Returns: 0 on success, 1 on failure
ensure_flathub_remote() {
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would add Flathub remote"
        return 0
    fi

    log_info "Ensuring Flathub remote is configured..."
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_ok "Flathub remote ready"
        return 0
    else
        log_warn "Failed to add Flathub remote"
        return 1
    fi
}

# is_flatpak_installed - Check if a Flatpak app is already installed
# Args: $1 = app ID
# Returns: 0 if installed, 1 if not
is_flatpak_installed() {
    local app_id="$1"
    flatpak list --app --columns=application 2>/dev/null | grep -q "^${app_id}$"
}

# flatpak_install - Install a single Flatpak app idempotently with classifier
# Flatpak errors are mostly deterministic (app_id wrong, already installed,
# permission denied) — single attempt + per-failure classifier mirrors the
# brew-cask.sh pattern adopted in v5.4.2. Transient network errors recover
# by re-running setup.sh (idempotent).
# Args: $1 = app ID
# Returns: 0 on success, 1 on failure
flatpak_install() {
    local app_id="$1"

    if is_flatpak_installed "$app_id"; then
        log_debug "Already installed: $app_id"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would flatpak install: $app_id"
        return 0
    fi

    log_info "Installing: $app_id"

    local err_buf rc=0
    err_buf=$(flatpak install flathub "$app_id" -y --noninteractive 2>&1 >/dev/null) || rc=$?

    if (( rc == 0 )); then
        log_ok "Installed: $app_id"
        save_package_state "flatpak" "$app_id" "${PROFILE_NAME:-unknown}"
        return 0
    fi

    local reason="exit $rc"
    local hint=""
    if grep -qiE "Nothing matches|No remote refs found|Couldn't find" <<<"$err_buf"; then
        reason="app_id not found in flathub"
        hint="Fix: flatpak search $app_id  (find correct name; reverse-DNS format)"
    elif grep -qiE "is already installed" <<<"$err_buf"; then
        reason="already installed (state file out of sync)"
        hint="Fix: flatpak list | grep $app_id  (verify); next setup.sh run will reconcile"
    elif grep -qiE "Permission denied|polkit|authentication|not authorized" <<<"$err_buf"; then
        reason="permission denied"
        hint="Fix: re-run with sudo, or use 'flatpak install --user'"
    elif grep -qiE "could not be found|404|connection|network|timeout|resolve" <<<"$err_buf"; then
        reason="network error"
        hint="Fix: re-run setup.sh — idempotent, only retries the missing items"
    fi

    log_error "Failed to install: $app_id ($reason)"
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

log_banner "Flatpak Package Installer"

# Parse --full arg for two-pass install
pkg_file="flatpak-developer.txt"
if [[ "${1:-}" == "--full" || "${1:-}" == "--post" ]]; then
    # --post kept as alias for backwards-compat
    pkg_file="flatpak-full.txt"
fi

# Check if flatpak is available
if ! command -v flatpak &>/dev/null; then
    log_warn "flatpak not found, skipping..."
    exit 0
fi

# Ensure Flathub remote is configured
if ! ensure_flathub_remote; then
    log_warn "Could not configure Flathub remote. Continuing anyway..."
fi

# Load packages from data file
if ! load_packages "$pkg_file"; then
    log_error "Failed to load flatpak packages from data/packages/$pkg_file"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} packages from $pkg_file"

# Install packages
log_info "Installing ${#PACKAGES[@]} Flatpak packages..."

for pkg in "${PACKAGES[@]}"; do
    if ! flatpak_install "$pkg"; then
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
