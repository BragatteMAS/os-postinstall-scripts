#!/usr/bin/env bash
#######################################
# Script: uv.sh
# Description: Cross-platform uv (Python package/version manager) installer
# Author: Bragatte
# Date: 2026-02-06
#######################################

# Prevent multiple sourcing
[[ -n "${_UV_SOURCED:-}" ]] && return 0
readonly _UV_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

SCRIPT_NAME="uv.sh"
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
fi

#######################################
# Source core utilities
#######################################
# shellcheck source=../core/logging.sh
if [[ -z "${_LOGGING_SOURCED:-}" ]]; then
    source "${SCRIPT_DIR}/../core/logging.sh"
fi
# shellcheck source=../core/errors.sh
if [[ -z "${_ERRORS_SOURCED:-}" ]]; then
    source "${SCRIPT_DIR}/../core/errors.sh"
fi

#######################################
# install_uv()
# Prefers `brew install uv` for centralized package management.
# Falls back to the official curl installer when brew is unavailable
# (e.g. some Linux runners without Homebrew).
# Idempotent: skips if already installed.
#######################################
install_uv() {
    # Idempotent check
    if command -v uv &>/dev/null; then
        log_debug "uv already installed: $(uv --version)"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install uv (brew preferred, curl fallback)"
        return 0
    fi

    # Prefer brew when available — single source of truth for package mgmt.
    if command -v brew &>/dev/null; then
        log_info "Installing uv via brew..."
        if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install uv; then
            log_ok "uv installed: $(uv --version)"
            return 0
        fi
        log_warn "brew install uv failed — falling back to curl installer"
    fi

    log_info "Installing uv via official script..."
    if ! safe_curl_sh "https://astral.sh/uv/install.sh"; then
        log_error "Failed to install uv"
        record_failure "uv"
        return 1
    fi

    # Add to PATH for current session (curl installer drops it here)
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v uv &>/dev/null; then
        log_error "uv installation failed - command not found after install"
        record_failure "uv"
        return 1
    fi

    log_ok "uv installed: $(uv --version)"
    return 0
}

#######################################
# install_python()
# Installs latest stable Python via uv
#######################################
install_python() {
    if ! command -v uv &>/dev/null; then
        log_warn "uv not available - cannot install Python"
        return 1
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install Python via uv"
        return 0
    fi

    log_info "Installing Python via uv..."

    if ! uv python install; then
        log_error "Failed to install Python via uv"
        record_failure "python (uv)"
        return 1
    fi

    log_ok "Python installed via uv"
    return 0
}

#######################################
# Cleanup
#######################################
cleanup() {
    show_failure_summary
}

trap cleanup EXIT INT TERM

#######################################
# Main (when run directly, not sourced)
#######################################
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    log_banner "uv - Python Package Manager"

    install_uv
    install_python

    # Semantic exit code based on failure state
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        exit "${EXIT_PARTIAL_FAILURE:-1}"
    else
        exit "${EXIT_SUCCESS:-0}"
    fi
fi
