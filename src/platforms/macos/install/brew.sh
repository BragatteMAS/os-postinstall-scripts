#!/usr/bin/env bash
set -o pipefail
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

source "${SCRIPT_DIR}/../../../core/state.sh" || {
    log_error "Failed to load state.sh"
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

    # Capture stderr to BREW_LOG so silent failures (network, formula not found,
    # tap missing) can be diagnosed after the run.
    local err_buf rc=0
    err_buf=$(HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "$pkg" 2>&1 >/dev/null) || rc=$?

    if [[ -n "${BREW_LOG:-}" ]]; then
        {
            echo "=== brew install $pkg (rc=$rc) ==="
            [[ -n "$err_buf" ]] && echo "$err_buf"
        } >> "$BREW_LOG" 2>/dev/null
    fi

    if (( rc == 0 )); then
        log_ok "Installed: $pkg"
        save_package_state "brew" "$pkg" "${PROFILE_NAME:-unknown}"
        return 0
    fi

    local reason="exit $rc"
    if grep -qiE "no available formula|formula .* is unavailable" <<<"$err_buf"; then
        reason="formula name not found in any tap"
    elif grep -qiE "404|connection|network|timeout|resolve" <<<"$err_buf"; then
        reason="network error"
    fi

    log_error "Failed to install: $pkg ($reason)"
    return 1
}

#######################################
# Cleanup function
#######################################
# shellcheck disable=SC2329  # invoked via trap
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

# Determine which formula file to use — mirror brew-cask.sh's two-pass dispatch.
# Without this, every wave (base / developer / full) was loading brew.txt and
# the developer/full formulae (mise, jq, gh, postgresql@17, ...) silently
# never installed.
pkg_file="brew.txt"
case "${1:-}" in
    --developer) pkg_file="brew-developer.txt" ;;
    --full)      pkg_file="brew-full.txt" ;;
esac

# Load packages from data file
if ! load_packages "$pkg_file"; then
    log_error "Failed to load brew packages from data/packages/$pkg_file"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} formulae from $pkg_file"

# Install formulae
log_info "Installing ${#PACKAGES[@]} Homebrew formulae..."

# Track per-wave outcome so the summary distinguishes "newly installed",
# "skipped because already present" and "failed".
_n_installed=0
_n_skipped=0
_n_failed=0

for pkg in "${PACKAGES[@]}"; do
    if is_brew_installed "$pkg"; then
        log_info "[skip] $pkg (already installed)"
        _n_skipped=$((_n_skipped + 1))
        continue
    fi
    if _brew_formula_install "$pkg"; then
        _n_installed=$((_n_installed + 1))
    else
        _n_failed=$((_n_failed + 1))
        record_failure "$pkg"
    fi
done

log_info "Summary ($pkg_file): ${_n_installed} installed, ${_n_skipped} skipped, ${_n_failed} failed"

# Summary
show_failure_summary

# Semantic exit code based on failure state
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    exit "${EXIT_PARTIAL_FAILURE:-1}"
else
    exit "${EXIT_SUCCESS:-0}"
fi
