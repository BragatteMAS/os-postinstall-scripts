#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: cargo.sh
# Description: Install Cargo (Rust) packages (cross-platform, data-driven)
# Author: Bragatte
# Date: 2026-02-05
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Source core utilities (src/install/ is sibling to src/core/)
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

#######################################
# Cargo Helper Functions
#######################################

# ensure_rust_installed - Make sure Rust/Cargo is available
# Returns: 0 if available, 1 if not
ensure_rust_installed() {
    if command -v cargo &>/dev/null; then
        log_debug "Cargo found: $(cargo --version)"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install Rust via rustup"
        return 0
    fi

    log_info "Rust not found, installing via rustup..."
    if safe_curl_sh "https://sh.rustup.rs" -- -y; then
        # Source cargo env for current session
        source "$HOME/.cargo/env" 2>/dev/null || true
        if command -v cargo &>/dev/null; then
            log_ok "Rust installed successfully"
            return 0
        fi
    fi

    log_error "Failed to install Rust"
    return 1
}

# is_cargo_installed - Check if a package is already installed via cargo
# Args: $1 = package name
# Returns: 0 if installed, 1 if not
is_cargo_installed() {
    local pkg="$1"
    # Check if binary exists or if cargo list shows it
    command -v "${pkg%%-*}" &>/dev/null || cargo install --list 2>/dev/null | grep -q "^$pkg "
}

# cargo_install - Install a single package via cargo
# Args: $1 = package name
# Returns: 0 on success, 1 on failure
cargo_install() {
    local pkg="$1"

    if is_cargo_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would cargo install: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"

    # Try cargo-binstall first (faster binary downloads)
    if command -v cargo-binstall &>/dev/null; then
        if cargo binstall -y --no-confirm "$pkg" 2>/dev/null; then
            log_ok "Installed via binstall: $pkg"
            return 0
        fi
    fi

    # Fallback to cargo install
    if cargo install "$pkg" 2>/dev/null; then
        log_ok "Installed: $pkg"
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

# ensure_binstall - Install cargo-binstall for faster installations
ensure_binstall() {
    if command -v cargo-binstall &>/dev/null; then
        log_debug "cargo-binstall already available"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install cargo-binstall"
        return 0
    fi

    log_info "Installing cargo-binstall for faster downloads..."
    if safe_curl_sh "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh"; then
        log_ok "cargo-binstall installed"
        return 0
    else
        log_warn "cargo-binstall not available, using cargo install (slower)"
        return 1
    fi
}

#######################################
# Cleanup function
#######################################
cleanup() {
    local exit_code=$?
    # Show failure summary if any
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed packages: ${FAILED_ITEMS[*]}"
    fi
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Track failed installations
declare -a FAILED_ITEMS=()

#######################################
# Main
#######################################

log_banner "Cargo Package Installer"

# Ensure Rust is installed
if ! ensure_rust_installed; then
    log_error "Cannot proceed without Rust/Cargo"
    exit 1
fi

# Load packages from data file
if ! load_packages "cargo.txt"; then
    log_error "Failed to load cargo packages from data/packages/cargo.txt"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} packages from cargo.txt"

# Try to install binstall for faster downloads
ensure_binstall

# Install packages
log_info "Installing ${#PACKAGES[@]} Cargo packages..."

for pkg in "${PACKAGES[@]}"; do
    if ! cargo_install "$pkg"; then
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
