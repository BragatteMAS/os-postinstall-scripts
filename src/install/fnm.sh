#!/usr/bin/env bash
#######################################
# Script: fnm.sh
# Description: Cross-platform fnm (Fast Node Manager) installer with Node LTS and global npm packages
# Author: Bragatte
# Date: 2026-02-06
#######################################

# Prevent multiple sourcing
[[ -n "${_FNM_SOURCED:-}" ]] && return 0
readonly _FNM_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

SCRIPT_NAME="fnm.sh"
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
# install_fnm()
# Installs fnm via official curl script
# Idempotent: skips if already installed
#######################################
install_fnm() {
    # Idempotent check
    if command -v fnm &>/dev/null; then
        log_debug "fnm already installed: $(fnm --version)"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install fnm"
        return 0
    fi

    log_info "Installing fnm (Fast Node Manager)..."

    # Install fnm via official script (--skip-shell prevents modifying shell configs)
    if ! safe_curl_sh "https://fnm.vercel.app/install" -- --skip-shell; then
        log_error "Failed to install fnm"
        record_failure "fnm"
        return 1
    fi

    # Add fnm to PATH for current session
    export PATH="$HOME/.local/share/fnm:$PATH"

    # Source fnm env for current session
    if command -v fnm &>/dev/null; then
        eval "$(fnm env)"
    fi

    # Verify installation
    if ! command -v fnm &>/dev/null; then
        log_error "fnm installation failed - command not found after install"
        record_failure "fnm"
        return 1
    fi

    log_ok "fnm installed: $(fnm --version)"
    return 0
}

#######################################
# install_node_lts()
# Installs Node.js LTS via fnm and sets as default
#######################################
install_node_lts() {
    if ! command -v fnm &>/dev/null; then
        log_warn "fnm not available - cannot install Node.js"
        return 1
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install Node LTS via fnm"
        return 0
    fi

    log_info "Installing Node.js LTS via fnm..."

    if ! fnm install --lts; then
        log_error "Failed to install Node.js LTS"
        record_failure "node-lts"
        return 1
    fi

    # Set LTS as default version
    fnm default lts-latest

    # Verify node is available
    if ! command -v node &>/dev/null; then
        log_warn "Node.js installed but not in PATH for current session"
        return 1
    fi

    log_ok "Node.js $(node --version) installed via fnm"
    return 0
}

#######################################
# install_global_npm()
# Installs global npm packages: pnpm, bun
#######################################
install_global_npm() {
    if ! command -v npm &>/dev/null; then
        log_warn "npm not available - cannot install global packages"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would npm install -g: pnpm, bun"
        return 0
    fi

    log_info "Installing global npm packages..."

    # Install pnpm
    if command -v pnpm &>/dev/null; then
        log_debug "pnpm already installed: $(pnpm --version)"
    elif npm install -g pnpm; then
        log_ok "pnpm installed: $(pnpm --version 2>/dev/null || echo 'version unknown')"
    else
        log_warn "Failed to install pnpm globally"
        record_failure "pnpm (global npm)"
    fi

    # Install bun
    if command -v bun &>/dev/null; then
        log_debug "bun already installed: $(bun --version)"
    elif npm install -g bun; then
        log_ok "bun installed: $(bun --version 2>/dev/null || echo 'version unknown')"
    else
        log_warn "Failed to install bun globally"
        record_failure "bun (global npm)"
    fi

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
    log_banner "fnm - Fast Node Manager"

    install_fnm
    install_node_lts
    install_global_npm

    # Semantic exit code based on failure state
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        exit "${EXIT_PARTIAL_FAILURE:-1}"
    else
        exit "${EXIT_SUCCESS:-0}"
    fi
fi
