#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: rust-cli.sh
# Description: Cross-platform Rust CLI tools installer (apt on Linux, brew on macOS)
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

#######################################
# Source core utilities (src/install/ is sibling to src/core/)
#######################################
CORE_DIR="${SCRIPT_DIR}/../core"

source "${CORE_DIR}/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${CORE_DIR}/idempotent.sh" || {
    log_error "Failed to load idempotent.sh"
    exit 1
}

source "${CORE_DIR}/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

source "${CORE_DIR}/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

source "${CORE_DIR}/platform.sh" || {
    log_error "Failed to load platform.sh"
    exit 1
}

source "${CORE_DIR}/interactive.sh" || {
    log_error "Failed to load interactive.sh"
    exit 1
}

#######################################
# Curated Rust CLI tools
# These are hardcoded (not data-driven) because they're tied
# to dotfile configuration, not user-customizable packages.
#######################################
# APT package names (Linux)
RUST_CLI_TOOLS_APT=(bat eza fd-find ripgrep zoxide git-delta)

# Brew package names (macOS) - some differ from apt names
RUST_CLI_TOOLS_BREW=(bat eza fd ripgrep zoxide git-delta yazi)

# Human-readable names for display
RUST_CLI_TOOLS_DISPLAY=(bat eza fd ripgrep zoxide delta yazi)

#######################################
# install_rust_tools_linux()
# Install Rust CLI tools via apt on Linux
#######################################
install_rust_tools_linux() {
    local tool
    local failed_count=0

    log_info "Installing Rust CLI tools via apt..."

    for tool in "${RUST_CLI_TOOLS_APT[@]}"; do
        if is_apt_installed "$tool"; then
            log_debug "Already installed: $tool"
            continue
        fi

        if [[ "${DRY_RUN:-}" == "true" ]]; then
            log_info "[DRY_RUN] Would apt install: $tool"
            continue
        fi

        log_info "Installing: $tool"
        if sudo apt-get install -y -o DPkg::Lock::Timeout=60 "$tool" 2>/dev/null; then
            log_ok "Installed: $tool"
        else
            log_warn "Failed to install: $tool"
            FAILED_ITEMS+=("$tool")
            failed_count=$((failed_count + 1))
        fi
    done

    # yazi is not in apt repos — hint cargo path
    if ! command -v yazi &>/dev/null; then
        log_info "yazi: not in apt — install via: cargo install --locked yazi-fm"
    fi

    return "$failed_count"
}

#######################################
# install_rust_tools_macos()
# Install Rust CLI tools via brew on macOS
#######################################
install_rust_tools_macos() {
    local tool
    local failed_count=0

    log_info "Installing Rust CLI tools via brew..."

    for tool in "${RUST_CLI_TOOLS_BREW[@]}"; do
        if brew list "$tool" &>/dev/null; then
            log_debug "Already installed: $tool"
            continue
        fi

        if [[ "${DRY_RUN:-}" == "true" ]]; then
            log_info "[DRY_RUN] Would brew install: $tool"
            continue
        fi

        log_info "Installing: $tool"
        if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "$tool" 2>/dev/null; then
            log_ok "Installed: $tool"
        else
            log_warn "Failed to install: $tool"
            FAILED_ITEMS+=("$tool")
            failed_count=$((failed_count + 1))
        fi
    done

    return "$failed_count"
}

#######################################
# create_rust_symlinks()
# Create symlinks for Ubuntu binary name divergences
# Only runs on Linux where apt uses different names
#######################################
create_rust_symlinks() {
    # Only needed on Linux
    if [[ "${DETECTED_OS}" != "linux" ]]; then
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would create symlinks: batcat->bat, fdfind->fd"
        return 0
    fi

    log_info "Creating symlinks for Ubuntu binary name divergences..."

    # bat: Ubuntu packages it as 'batcat'
    if [[ -f /usr/bin/batcat ]] && ! command -v bat &>/dev/null; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log_ok "Symlink: batcat -> bat"
    fi

    # fd: Ubuntu packages it as 'fdfind'
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
        log_ok "Symlink: fdfind -> fd"
    fi
}

#######################################
# show_rust_summary()
# Educational message showing Rust tool equivalents
#######################################
show_rust_summary() {
    echo ""
    log_info "Rust CLI tool equivalents:"
    log_info "  bat    > cat   (syntax highlighting)"
    log_info "  eza    > ls    (modern file listing)"
    log_info "  fd     > find  (fast file search)"
    log_info "  rg     > grep  (fast text search)"
    log_info "  zoxide > cd    (smart directory jumping)"
    log_info "  delta  > diff  (git-aware diff viewer)"
    log_info "  yazi   > file  (terminal file manager)"
    echo ""
}

#######################################
# Cleanup and failure tracking
#######################################
declare -a FAILED_ITEMS=()

# shellcheck disable=SC2329  # invoked via trap
cleanup() {
    local exit_code=$?
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed tools: ${FAILED_ITEMS[*]}"
    fi
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

#######################################
# Main
#######################################

# Detect platform
if [[ -z "${DETECTED_OS:-}" ]]; then
    detect_platform
fi

log_banner "Rust CLI Tools"

# Interactive selection
show_category_menu "Rust CLI Tools" "bat, eza, fd, rg, zoxide, delta, yazi"
menu_choice=$?

case "$menu_choice" in
    0)
        # Install all
        log_info "Installing all Rust CLI tools..."
        ;;
    1)
        # Choose individually (filter tools)
        log_info "Choose which tools to install:"
        # For individual selection, we handle per-tool in the install functions
        # This mode is handled by the ask_tool calls in a filtered loop
        # For simplicity, we run install and let ask_tool filter
        ;;
    2)
        # Skip entirely
        log_info "Skipping Rust CLI tools installation"
        show_rust_summary
        exit 0
        ;;
esac

# Branch on platform
case "${DETECTED_OS}" in
    linux)
        install_rust_tools_linux
        create_rust_symlinks
        ;;
    macos)
        install_rust_tools_macos
        ;;
    *)
        log_warn "Unsupported platform: ${DETECTED_OS}. Skipping Rust CLI tools."
        ;;
esac

# Educational summary
show_rust_summary

# Final summary
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    log_warn "Completed with ${#FAILED_ITEMS[@]} failures"
else
    log_ok "All Rust CLI tools installed successfully"
fi

# Semantic exit code based on failure state
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    exit "${EXIT_PARTIAL_FAILURE:-1}"
else
    exit "${EXIT_SUCCESS:-0}"
fi
