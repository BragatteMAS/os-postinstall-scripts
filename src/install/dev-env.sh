#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: dev-env.sh
# Description: Development environment orchestrator (fnm + uv + globals + SSH)
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

SCRIPT_NAME="dev-env.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

#######################################
# Source core utilities
#######################################
# shellcheck source=../core/logging.sh
source "${SCRIPT_DIR}/../core/logging.sh"
# shellcheck source=../core/errors.sh
source "${SCRIPT_DIR}/../core/errors.sh"
# shellcheck source=../core/interactive.sh
source "${SCRIPT_DIR}/../core/interactive.sh"

#######################################
# Source sub-installers (functions only, main guard prevents execution)
#######################################
# shellcheck source=fnm.sh
source "${SCRIPT_DIR}/fnm.sh"
# shellcheck source=uv.sh
source "${SCRIPT_DIR}/uv.sh"

#######################################
# setup_ssh_key()
# Offers SSH key generation in interactive mode (default=No)
# Skips entirely in non-interactive mode
#######################################
setup_ssh_key() {
    # Non-interactive mode: skip entirely
    if [[ "${NONINTERACTIVE:-}" == "true" || ! -t 0 ]]; then
        log_debug "Skipping SSH key generation (non-interactive)"
        return 0
    fi

    # Check if key already exists
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        log_debug "SSH key already exists: $HOME/.ssh/id_ed25519"
        return 0
    fi

    echo ""
    read -rp "Generate SSH key for GitHub? [y/N]: " answer

    # Default is No
    case "$answer" in
        [yY]*)
            ;;
        *)
            log_debug "SSH key generation skipped by user"
            return 0
            ;;
    esac

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would generate SSH key"
        return 0
    fi

    log_info "Generating SSH key (ed25519)..."

    # Ensure .ssh directory exists with correct permissions
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if ssh-keygen -t ed25519 -C "${USER}@$(hostname)" -f "$HOME/.ssh/id_ed25519"; then
        log_ok "SSH key generated: $HOME/.ssh/id_ed25519"
        log_info "Public key: $HOME/.ssh/id_ed25519.pub"
        log_info "Copy this key to GitHub: https://github.com/settings/keys"
    else
        log_error "Failed to generate SSH key"
        record_failure "ssh-keygen"
        return 1
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
# Main
#######################################
log_banner "Development Environment"

# --- Node.js category (fnm + pnpm + bun) ---
show_category_menu "Node.js" "fnm + Node LTS + pnpm + bun"
node_choice=$?

if [[ $node_choice -eq 0 ]]; then
    # Install all
    install_fnm
    install_node_lts
    install_global_npm
elif [[ $node_choice -eq 1 ]]; then
    # Choose individually
    if ask_tool "fnm (Node version manager)"; then
        install_fnm
        if ask_tool "Node.js LTS"; then
            install_node_lts
        fi
        if ask_tool "pnpm + bun (global npm packages)"; then
            install_global_npm
        fi
    fi
fi

# --- Python category (uv) ---
show_category_menu "Python" "uv + latest Python"
python_choice=$?

if [[ $python_choice -eq 0 ]]; then
    # Install all
    install_uv
    install_python
elif [[ $python_choice -eq 1 ]]; then
    # Choose individually
    if ask_tool "uv (Python package manager)"; then
        install_uv
        if ask_tool "Python (latest stable via uv)"; then
            install_python
        fi
    fi
fi

# --- SSH key (interactive only, default=No) ---
setup_ssh_key

# --- Summary ---
echo ""
log_info "Development environment setup complete"

# Show installed versions
if command -v fnm &>/dev/null; then
    log_ok "fnm: $(fnm --version 2>/dev/null || echo 'installed')"
fi
if command -v node &>/dev/null; then
    log_ok "Node.js: $(node --version 2>/dev/null || echo 'installed')"
fi
if command -v pnpm &>/dev/null; then
    log_ok "pnpm: $(pnpm --version 2>/dev/null || echo 'installed')"
fi
if command -v bun &>/dev/null; then
    log_ok "bun: $(bun --version 2>/dev/null || echo 'installed')"
fi
if command -v uv &>/dev/null; then
    log_ok "uv: $(uv --version 2>/dev/null || echo 'installed')"
fi

log_info "Shell integration loaded on next terminal session (fnm env, zoxide init)"

exit 0
