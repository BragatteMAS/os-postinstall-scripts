#!/usr/bin/env bash
#######################################
# Script: logging.sh
# Description: Unified logging utilities with color auto-detection (SSoT)
# Author: Bragatte
# Date: 2026-02-05
#######################################

# Prevent multiple sourcing
[[ -n "${_LOGGING_SOURCED:-}" ]] && return 0
readonly _LOGGING_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Color Variables (set by setup_colors)
#######################################
RED=""
GREEN=""
YELLOW=""
BLUE=""
GRAY=""
NC=""

#######################################
# setup_colors()
# Detects terminal color support and respects NO_COLOR standard
# Sets color variables to empty strings if colors disabled
#######################################
setup_colors() {
    # Default: no colors
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    GRAY=""
    NC=""

    # Respect NO_COLOR standard (https://no-color.org)
    if [[ -n "${NO_COLOR:-}" ]]; then
        return 0
    fi

    # Check if stdout is a TTY
    if [[ ! -t 1 ]]; then
        return 0
    fi

    # Check if terminal supports colors (tput colors >= 8)
    local colors
    colors=$(tput colors 2>/dev/null || echo 0)
    if [[ "$colors" -lt 8 ]]; then
        return 0
    fi

    # Terminal supports colors, set them
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    GRAY='\033[0;90m'
    NC='\033[0m'
}

#######################################
# Internal helper: strip ANSI color codes
#######################################
_strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

#######################################
# Internal helper: timestamp for verbose mode
#######################################
_timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

#######################################
# Internal helper: write to log file (without colors)
#######################################
_write_log() {
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$*" | _strip_colors >> "$LOG_FILE"
    fi
}

#######################################
# Core Logging Functions
# Format: [TAG] message (with optional timestamp in verbose mode)
#######################################

# log_ok - Success messages (green)
# Usage: log_ok "message"
log_ok() {
    local msg="$*"
    local prefix=""

    if [[ "${VERBOSE:-}" == "true" ]]; then
        prefix="[$(_timestamp)] "
    fi

    echo -e "${GREEN}[OK]${NC} ${prefix}${msg}"
    _write_log "[OK] ${prefix}${msg}"
}

# log_error - Error messages (red, to stderr)
# Usage: log_error "message"
log_error() {
    local msg="$*"
    local prefix=""

    if [[ "${VERBOSE:-}" == "true" ]]; then
        prefix="[$(_timestamp)] "
    fi

    echo -e "${RED}[ERROR]${NC} ${prefix}${msg}" >&2
    _write_log "[ERROR] ${prefix}${msg}"
}

# log_warn - Warning messages (yellow)
# Usage: log_warn "message"
log_warn() {
    local msg="$*"
    local prefix=""

    if [[ "${VERBOSE:-}" == "true" ]]; then
        prefix="[$(_timestamp)] "
    fi

    echo -e "${YELLOW}[WARN]${NC} ${prefix}${msg}"
    _write_log "[WARN] ${prefix}${msg}"
}

# log_info - Info messages (blue)
# Usage: log_info "message"
log_info() {
    local msg="$*"
    local prefix=""

    if [[ "${VERBOSE:-}" == "true" ]]; then
        prefix="[$(_timestamp)] "
    fi

    echo -e "${BLUE}[INFO]${NC} ${prefix}${msg}"
    _write_log "[INFO] ${prefix}${msg}"
}

# log_debug - Debug messages (gray, only if VERBOSE set)
# Usage: log_debug "message"
log_debug() {
    # Only show debug messages in verbose mode
    if [[ "${VERBOSE:-}" != "true" ]]; then
        return 0
    fi

    local msg="$*"
    local prefix
    prefix="[$(_timestamp)] "

    echo -e "${GRAY}[DEBUG]${NC} ${prefix}${msg}"
    _write_log "[DEBUG] ${prefix}${msg}"
}

#######################################
# log_banner - Simple one-line banner
# Usage: log_banner "name" "version"
#######################################
log_banner() {
    local name="${1:-Script}"
    local version="${2:-}"

    if [[ -n "$version" ]]; then
        echo -e "${BLUE}=== ${name} v${version} ===${NC}"
        _write_log "=== ${name} v${version} ==="
    else
        echo -e "${BLUE}=== ${name} ===${NC}"
        _write_log "=== ${name} ==="
    fi
}

#######################################
# Aliases for backward compatibility
#######################################
log() { log_info "$@"; }
log_success() { log_ok "$@"; }
log_warning() { log_warn "$@"; }
info() { log_info "$@"; }
error() { log_error "$@"; }
warning() { log_warn "$@"; }
success() { log_ok "$@"; }

#######################################
# Initialize colors on source
#######################################
setup_colors

#######################################
# Export functions for subshells
#######################################
export -f setup_colors
export -f log_ok log_error log_warn log_info log_debug log_banner
export -f log log_success log_warning info error warning success
export -f _strip_colors _timestamp _write_log
export RED GREEN YELLOW BLUE GRAY NC
