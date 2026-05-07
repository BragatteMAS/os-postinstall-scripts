#!/usr/bin/env bash
set -o pipefail
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
# Side effects: appends brew stderr to ${BREW_LOG:-/dev/null} for diagnosis.
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

    # Capture stderr to a per-package buffer so we can:
    #   1) classify the failure (manual-install conflict vs network vs cask name)
    #   2) append it to BREW_LOG for postmortem
    #   3) surface a meaningful reason in the failure summary
    local err_buf rc=0
    err_buf=$(HOMEBREW_NO_INSTALL_UPGRADE=1 brew install --cask "$cask" 2>&1 >/dev/null) || rc=$?

    if [[ -n "${BREW_LOG:-}" ]]; then
        {
            echo "=== brew install --cask $cask (rc=$rc) ==="
            [[ -n "$err_buf" ]] && echo "$err_buf"
        } >> "$BREW_LOG" 2>/dev/null
    fi

    if (( rc == 0 )); then
        log_ok "Installed: $cask"
        save_package_state "brew-cask" "$cask" "${PROFILE_NAME:-unknown}"
        return 0
    fi

    # Classify failure for the summary. Each branch also emits a one-line
    # actionable hint so the user knows the exact command to fix it.
    local reason="exit $rc"
    local hint=""
    if grep -qE "conflicts with cask '?[a-zA-Z0-9_@-]+|conflicts with another cask" <<<"$err_buf"; then
        local conflicting
        # Capture only valid cask name chars (alphanumeric, @, -, _) — prevents
        # trailing punctuation like "." or "," from being absorbed.
        conflicting=$(grep -oE "conflicts with cask '?[a-zA-Z0-9_@-]+" <<<"$err_buf" | head -1 | awk '{print $4}' | tr -d "'")
        reason="conflicts with another cask${conflicting:+ ($conflicting)}"
        hint="Fix: brew uninstall --cask ${conflicting:-<other>} && brew install --cask $cask"
    elif grep -qE "It seems there is already an App at|already exists" <<<"$err_buf"; then
        reason="app exists at /Applications (installed manually before brew)"
        hint="Fix: brew install --cask --force $cask  (overwrites the manual install)"
    elif grep -qiE "no available formula|cask .* is unavailable|Cask '.*' is unavailable" <<<"$err_buf"; then
        reason="cask name not found in any tap"
        hint="Fix: brew search $cask  (find the new name; cask may have been renamed)"
    elif grep -qiE "could not be found|404|connection|network|timeout|resolve" <<<"$err_buf"; then
        reason="network error"
        hint="Fix: re-run setup.sh — idempotent, only retries the missing items"
    fi

    log_error "Failed to install: $cask ($reason)"
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

# Determine which cask file to use (two-pass support: developer/full)
pkg_file="brew-cask-developer.txt"
if [[ "${1:-}" == "--full" ]]; then
    pkg_file="brew-cask-full.txt"
fi

# Load packages from data file
if ! load_packages "$pkg_file"; then
    log_error "Failed to load cask packages from data/packages/$pkg_file"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} casks from $pkg_file"

# Install casks
log_info "Installing ${#PACKAGES[@]} Homebrew casks..."

# Per-wave outcome counters — distinguishes newly installed / skipped / failed.
_n_installed=0
_n_skipped=0
_n_failed=0

for cask in "${PACKAGES[@]}"; do
    if _is_cask_installed "$cask"; then
        log_info "[skip] $cask (already installed)"
        _n_skipped=$((_n_skipped + 1))
        continue
    fi
    if _brew_cask_install "$cask"; then
        _n_installed=$((_n_installed + 1))
    else
        _n_failed=$((_n_failed + 1))
        record_failure "$cask"
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
