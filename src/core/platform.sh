#!/usr/bin/env bash
#######################################
# Script: platform.sh
# Description: Platform detection and verification utilities
# Author: Bragatte
# Date: 2026-02-05
#######################################

# Prevent multiple sourcing
[[ -n "${_PLATFORM_SOURCED:-}" ]] && return 0
readonly _PLATFORM_SOURCED=1

# NOTE: No set -e (per CONTEXT decision - conflicts with "continue on failure" strategy)

#######################################
# Exported variables (set by detect_platform)
#######################################
export DETECTED_OS=""
export DETECTED_DISTRO=""
export DETECTED_VERSION=""
export DETECTED_PKG=""
export DETECTED_ARCH=""
export DETECTED_BASH=""

#######################################
# Supported distros list
#######################################
readonly SUPPORTED_DISTROS="ubuntu debian pop linuxmint elementary zorin"

#######################################
# detect_platform()
# Detects OS, distro, package manager, architecture, and Bash version
# Sets all DETECTED_* variables
#######################################
detect_platform() {
    local os_name
    local arch_name

    # Detect OS via uname
    os_name=$(uname -s 2>/dev/null || echo "unknown")
    case "$os_name" in
        Darwin)
            DETECTED_OS="macos"
            ;;
        Linux)
            DETECTED_OS="linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            DETECTED_OS="windows"
            ;;
        *)
            DETECTED_OS="unknown"
            ;;
    esac

    # Detect architecture via uname -m
    arch_name=$(uname -m 2>/dev/null || echo "unknown")
    case "$arch_name" in
        x86_64|amd64)
            DETECTED_ARCH="x86_64"
            ;;
        arm64|aarch64)
            DETECTED_ARCH="arm64"
            ;;
        *)
            DETECTED_ARCH="$arch_name"
            ;;
    esac

    # Detect distro and version (Linux only)
    DETECTED_DISTRO=""
    DETECTED_VERSION=""
    if [[ "$DETECTED_OS" == "linux" ]]; then
        if [[ -f /etc/os-release ]]; then
            # Source os-release to get ID and VERSION_ID
            # shellcheck source=/dev/null
            source /etc/os-release 2>/dev/null || true
            DETECTED_DISTRO="${ID:-unknown}"
            DETECTED_VERSION="${VERSION_ID:-unknown}"
        else
            DETECTED_DISTRO="unknown"
            DETECTED_VERSION="unknown"
        fi
    elif [[ "$DETECTED_OS" == "macos" ]]; then
        DETECTED_DISTRO="macos"
        DETECTED_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    fi

    # Detect package manager
    DETECTED_PKG=""
    if command -v apt-get &>/dev/null; then
        DETECTED_PKG="apt"
    elif command -v brew &>/dev/null; then
        DETECTED_PKG="brew"
    elif command -v winget &>/dev/null; then
        DETECTED_PKG="winget"
    fi

    # Detect Bash version
    if [[ -n "${BASH_VERSINFO[0]:-}" ]]; then
        DETECTED_BASH="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]:-0}"
    else
        DETECTED_BASH="unknown"
    fi

    # Export all variables
    export DETECTED_OS DETECTED_DISTRO DETECTED_VERSION DETECTED_PKG DETECTED_ARCH DETECTED_BASH
}

#######################################
# verify_bash_version()
# Exits with instructions if Bash version < 4.0
# Returns: 0 if OK, 1 if version too old
#######################################
verify_bash_version() {
    local major="${BASH_VERSINFO[0]:-0}"

    if [[ "$major" -lt 4 ]]; then
        log_error "Bash version $DETECTED_BASH is too old. Version 4.0+ is required."
        echo ""
        echo "Upgrade instructions:"
        if [[ "$DETECTED_OS" == "macos" ]]; then
            echo "  brew install bash"
            echo "  # Then add /opt/homebrew/bin/bash to /etc/shells"
            echo "  # And run: chsh -s /opt/homebrew/bin/bash"
        elif [[ "$DETECTED_OS" == "linux" ]]; then
            echo "  sudo apt update && sudo apt install bash"
        else
            echo "  Please upgrade Bash to version 4.0 or later"
        fi
        echo ""
        return 1
    fi

    return 0
}

#######################################
# verify_supported_distro()
# Warns and prompts if distro is not in supported list
# Returns: 0 if OK or user continues, 1 if user cancels
#######################################
verify_supported_distro() {
    # Skip check for macOS (always supported)
    if [[ "$DETECTED_OS" == "macos" ]]; then
        return 0
    fi

    # Check if distro is in supported list
    local distro_found=false
    for distro in $SUPPORTED_DISTROS; do
        if [[ "$DETECTED_DISTRO" == "$distro" ]]; then
            distro_found=true
            break
        fi
    done

    if [[ "$distro_found" == "false" ]]; then
        log_warn "Distro '$DETECTED_DISTRO' is not officially supported."
        echo "  Supported distros: $SUPPORTED_DISTROS"
        echo ""

        # If not interactive, return error
        if [[ ! -t 0 ]]; then
            log_warn "Non-interactive mode. Continuing anyway..."
            return 0
        fi

        read -rp "Continue anyway? [y/N] " response
        case "$response" in
            [yY]|[yY][eE][sS])
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi

    return 0
}

#######################################
# verify_package_manager()
# Exits with error if no supported package manager found
# Returns: 0 if OK, 1 if unsupported
#######################################
verify_package_manager() {
    if [[ -z "$DETECTED_PKG" ]]; then
        log_error "No supported package manager found."
        echo "  Supported package managers: apt, brew, winget"
        echo ""

        # Give specific hints based on OS
        if [[ "$DETECTED_OS" == "linux" ]]; then
            if command -v pacman &>/dev/null; then
                echo "  Note: pacman is not supported. This project supports Debian-based distros."
            elif command -v dnf &>/dev/null; then
                echo "  Note: dnf is not supported. This project supports Debian-based distros."
            elif command -v yum &>/dev/null; then
                echo "  Note: yum is not supported. This project supports Debian-based distros."
            fi
        elif [[ "$DETECTED_OS" == "macos" ]]; then
            echo "  Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        fi

        return 1
    fi

    return 0
}

#######################################
# check_internet()
# Checks internet connectivity with 5s timeout
# Returns: 0 if OK or user continues, 1 if user cancels
#######################################
check_internet() {
    local timeout=5

    # Try to reach a reliable endpoint
    if curl -s --connect-timeout "$timeout" --max-time "$timeout" https://www.google.com >/dev/null 2>&1; then
        return 0
    fi

    log_warn "No internet connection detected."
    echo ""

    # If not interactive, continue with warning
    if [[ ! -t 0 ]]; then
        log_warn "Non-interactive mode. Continuing anyway..."
        return 0
    fi

    read -rp "Continue without internet? [y/N] " response
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#######################################
# request_sudo()
# Requests sudo access upfront
# Skips if DRY_RUN=true or if running as root
# Returns: 0 if OK, 1 if sudo unavailable/denied
#######################################
request_sudo() {
    # Skip in dry-run mode
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "Dry-run mode: skipping sudo request"
        return 0
    fi

    # Skip if already root
    if [[ "$(id -u)" -eq 0 ]]; then
        return 0
    fi

    # Skip on macOS for brew-only operations
    if [[ "$DETECTED_OS" == "macos" ]]; then
        # Still request for system-level operations
        if ! sudo -v 2>/dev/null; then
            log_warn "sudo access not granted. Some operations may fail."
            return 0
        fi
        return 0
    fi

    # Linux: sudo is required for apt
    if ! command -v sudo &>/dev/null; then
        log_error "sudo is not available. Cannot proceed."
        return 1
    fi

    log_info "Requesting sudo access..."
    if ! sudo -v; then
        log_error "sudo access denied."
        return 1
    fi

    return 0
}

#######################################
# verify_all()
# Runs all verifications in order: OS -> Bash -> Net -> Sudo
# Prints one-line detection output
# Returns: 0 if all pass, 1 if any fail
#######################################
verify_all() {
    # Ensure platform is detected
    if [[ -z "$DETECTED_OS" ]]; then
        detect_platform
    fi

    # Print detection output
    if [[ "$DETECTED_OS" == "macos" ]]; then
        log_ok "Detected: macOS $DETECTED_VERSION ($DETECTED_PKG)"
    elif [[ -n "$DETECTED_DISTRO" && "$DETECTED_DISTRO" != "unknown" ]]; then
        # Capitalize first letter of distro for display
        local display_distro
        display_distro="$(printf '%s' "${DETECTED_DISTRO:0:1}" | tr '[:lower:]' '[:upper:]')${DETECTED_DISTRO:1}"
        log_ok "Detected: $display_distro $DETECTED_VERSION ($DETECTED_PKG)"
    else
        log_ok "Detected: $DETECTED_OS ($DETECTED_PKG)"
    fi

    # Verify Bash version
    if ! verify_bash_version; then
        return 1
    fi

    # Verify supported distro (warns but continues if user agrees)
    if ! verify_supported_distro; then
        return 1
    fi

    # Verify package manager
    if ! verify_package_manager; then
        return 1
    fi

    # Check internet connection
    if ! check_internet; then
        return 1
    fi

    # Request sudo access
    if ! request_sudo; then
        return 1
    fi

    return 0
}

#######################################
# Export functions for subshells
#######################################
export -f detect_platform
export -f verify_bash_version
export -f verify_supported_distro
export -f verify_package_manager
export -f check_internet
export -f request_sudo
export -f verify_all
