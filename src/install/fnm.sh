#!/usr/bin/env bash
#######################################
# Script: fnm.sh
# Description: Cross-platform fnm (Fast Node Manager) installer with Node LTS and global npm packages
# Author: Bragatte
# Date: 2026-02-06
#
# NOTE (2026-05): mise (in dev-env.sh) is the preferred orchestrator for tool
# versions. fnm is kept here as a reliable fallback for users who don't install
# mise, and to bootstrap Node before mise is available. When mise is present,
# user projects with .nvmrc / .tool-versions are picked up by mise transparently.
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
# Prefers `brew install fnm` for centralized package management.
# Falls back to the official curl installer when brew is unavailable
# (e.g. some Linux runners without Homebrew).
# Idempotent: skips if already installed.
#######################################
install_fnm() {
    # Idempotent check
    if command -v fnm &>/dev/null; then
        log_info "[skip] fnm already installed: $(fnm --version)"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install fnm (brew preferred, curl fallback)"
        return 0
    fi

    # Prefer brew when available — single source of truth for package mgmt.
    if command -v brew &>/dev/null; then
        log_info "Installing fnm via brew..."
        if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install fnm; then
            log_ok "fnm installed: $(fnm --version)"
            return 0
        fi
        log_warn "brew install fnm failed — falling back to curl installer"
    fi

    log_info "Installing fnm via official script..."
    # NOTE: do not insert `--` separator — the fnm installer rejects it as
    # "Unrecognized argument --" and aborts before processing real flags.
    if ! safe_curl_sh "https://fnm.vercel.app/install" --skip-shell; then
        log_error "Failed to install fnm"
        record_failure "fnm"
        return 1
    fi

    # Add fnm to PATH for current session (curl installer drops it here)
    export PATH="$HOME/.local/share/fnm:$PATH"

    if command -v fnm &>/dev/null; then
        eval "$(fnm env)"
    fi

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
# Installs pnpm and bun. Prefers brew (centralized package mgmt) and
# falls back to `npm install -g` only when brew is unavailable.
# Bun ships via a dedicated tap (oven-sh/bun); brew handles the tap
# automatically for the qualified formula name.
#######################################
install_global_npm() {
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install pnpm + bun (brew preferred, npm fallback)"
        return 0
    fi

    local _have_brew=0
    command -v brew &>/dev/null && _have_brew=1

    # --- pnpm ---
    if command -v pnpm &>/dev/null; then
        log_info "[skip] pnpm already installed: $(pnpm --version)"
    elif (( _have_brew )) && HOMEBREW_NO_INSTALL_UPGRADE=1 brew install pnpm; then
        log_ok "pnpm installed via brew: $(pnpm --version 2>/dev/null || echo 'version unknown')"
    elif command -v npm &>/dev/null && npm install -g pnpm; then
        log_ok "pnpm installed via npm: $(pnpm --version 2>/dev/null || echo 'version unknown')"
    else
        log_warn "Failed to install pnpm (brew + npm both unavailable or failed)"
        record_failure "pnpm"
    fi

    # --- bun (formula lives in third-party tap oven-sh/bun) ---
    # Tap explicitly before install: brew's auto-tap can fail silently behind
    # proxies / restricted networks, leaving the install with a generic error.
    if command -v bun &>/dev/null; then
        log_info "[skip] bun already installed: $(bun --version)"
    elif (( _have_brew )); then
        brew tap oven-sh/bun >/dev/null 2>&1 || \
            log_warn "Could not tap oven-sh/bun — brew install may fall back to npm"
        if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install oven-sh/bun/bun; then
            log_ok "bun installed via brew: $(bun --version 2>/dev/null || echo 'version unknown')"
        elif command -v npm &>/dev/null && npm install -g bun; then
            log_ok "bun installed via npm: $(bun --version 2>/dev/null || echo 'version unknown')"
        else
            log_warn "Failed to install bun (brew + npm both failed)"
            record_failure "bun"
        fi
    elif command -v npm &>/dev/null && npm install -g bun; then
        log_ok "bun installed via npm: $(bun --version 2>/dev/null || echo 'version unknown')"
    else
        log_warn "Failed to install bun (brew + npm both unavailable)"
        record_failure "bun"
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
