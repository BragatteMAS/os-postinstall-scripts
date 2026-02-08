#!/usr/bin/env bash
#######################################
# Script: homebrew.sh
# Description: Install Homebrew package manager for macOS (idempotent)
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
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

#######################################
# Architecture Detection
#######################################

# get_brew_prefix - Return the correct Homebrew prefix for this architecture
# Apple Silicon: /opt/homebrew
# Intel: /usr/local
# Returns: path string
get_brew_prefix() {
    local arch
    arch="$(uname -m)"
    if [[ "$arch" == "arm64" ]]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

#######################################
# install_homebrew - Install Homebrew if not already present
# Idempotent: skips if brew already in PATH
# Respects DRY_RUN for preview mode
# Returns: 0 on success, 1 on failure
#######################################
install_homebrew() {
    # Check if brew is already installed
    if command -v brew &>/dev/null; then
        log_ok "Homebrew already installed: $(brew --version | head -1)"
        return 0
    fi

    # Also check default prefix in case PATH is not yet configured
    local brew_prefix
    brew_prefix="$(get_brew_prefix)"
    if [[ -x "${brew_prefix}/bin/brew" ]]; then
        log_info "Homebrew found at ${brew_prefix}/bin/brew but not in PATH"
        log_info "Configuring PATH for current session..."
        eval "$("${brew_prefix}"/bin/brew shellenv)"
        log_ok "Homebrew available: $(brew --version | head -1)"
        return 0
    fi

    # DRY_RUN check before any mutation
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install Homebrew via official installer"
        log_info "[DRY_RUN] Would configure shell PATH for brew at ${brew_prefix}"
        return 0
    fi

    log_info "Installing Homebrew..."

    # Check for Xcode Command Line Tools (required by Homebrew installer)
    if ! xcode-select -p &>/dev/null; then
        log_info "Xcode Command Line Tools not found. Installing..."
        xcode-select --install 2>/dev/null || true
        log_warn "Xcode CLI Tools installation started (GUI prompt)."
        log_warn "Press Enter after the installation completes..."
        read -r
        # Verify installation succeeded
        if ! xcode-select -p &>/dev/null; then
            log_error "Xcode Command Line Tools installation failed or was cancelled"
            return 1
        fi
        log_ok "Xcode Command Line Tools installed"
    else
        log_debug "Xcode Command Line Tools already installed"
    fi

    # Install Homebrew non-interactively
    # NONINTERACTIVE=1 skips all y/n prompts
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_ok "Homebrew installed successfully"
    else
        log_error "Homebrew installation failed"
        return 1
    fi

    # Configure PATH for current session
    if [[ -x "${brew_prefix}/bin/brew" ]]; then
        eval "$("${brew_prefix}"/bin/brew shellenv)"
        log_debug "Configured brew shellenv for current session"
    else
        log_error "Homebrew binary not found at expected path: ${brew_prefix}/bin/brew"
        return 1
    fi

    # Verify brew command works
    if command -v brew &>/dev/null; then
        log_ok "Homebrew verified: $(brew --version | head -1)"
    else
        log_error "brew command not available after installation"
        return 1
    fi

    return 0
}

#######################################
# configure_shell_path - Add brew shellenv to shell profile
# Idempotent: uses ensure_line_in_file (skips if already present)
# Respects DRY_RUN for preview mode
# Returns: 0 on success, 1 on failure
#######################################
configure_shell_path() {
    local brew_prefix
    brew_prefix="$(get_brew_prefix)"

    # Determine shell profile file
    local rc_file
    local current_shell
    current_shell="$(basename "${SHELL:-/bin/zsh}")"

    case "$current_shell" in
        zsh)
            rc_file="${HOME}/.zprofile"
            ;;
        bash)
            rc_file="${HOME}/.bash_profile"
            ;;
        *)
            log_warn "Unknown shell: $current_shell. Defaulting to ~/.profile"
            rc_file="${HOME}/.profile"
            ;;
    esac

    local shellenv_line="eval \"\$(${brew_prefix}/bin/brew shellenv)\""

    # Check if already configured
    if [[ -f "$rc_file" ]] && grep -q "brew shellenv" "$rc_file"; then
        log_ok "Shell profile already configured: $rc_file"
        return 0
    fi

    # DRY_RUN check before modifying shell profile
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would add brew shellenv to $rc_file"
        return 0
    fi

    log_info "Adding brew shellenv to $rc_file"
    if ensure_line_in_file "$shellenv_line" "$rc_file"; then
        log_ok "Shell profile configured: $rc_file"
    else
        log_error "Failed to configure shell profile: $rc_file"
        return 1
    fi

    return 0
}

#######################################
# Main (only when executed directly)
#######################################
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    log_banner "Homebrew Installer"

    if ! install_homebrew; then
        log_error "Homebrew installation failed"
        # Exception to always-exit-0: Homebrew is a hard prerequisite
        # for all subsequent macOS installs. Signal failure to caller.
        if [[ -n "${FAILURE_LOG:-}" ]]; then
            echo "homebrew-install" >> "$FAILURE_LOG"
        fi
        exit 1
    fi

    configure_shell_path

    log_ok "Homebrew setup complete"

    # Success path: exit 0
    exit 0
fi
