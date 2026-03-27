#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: defaults.sh
# Description: Apply macOS system defaults from data file (data-driven)
# Author: Bragatte
# Date: 2026-03-26
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

source "${SCRIPT_DIR}/../../../core/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../../core/defaults.sh" || {
    log_error "Failed to load defaults.sh"
    exit 1
}

#######################################
# Verify running on macOS
#######################################

if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "defaults.sh is macOS only"
    exit 1
fi

#######################################
# Track which services need restart
#######################################
declare -A _NEEDS_RESTART=()

# Track defaults that require service restarts
_track_restart_needs() {
    local domain="$1"
    case "$domain" in
        com.apple.dock)
            _NEEDS_RESTART[Dock]=1 ;;
        com.apple.finder)
            _NEEDS_RESTART[Finder]=1 ;;
        com.apple.screencapture)
            _NEEDS_RESTART[SystemUIServer]=1 ;;
    esac
}

#######################################
# Restart affected services
#######################################
_restart_services() {
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        if [[ ${#_NEEDS_RESTART[@]} -gt 0 ]]; then
            log_info "[DRY_RUN] Would restart: ${!_NEEDS_RESTART[*]}"
        fi
        return 0
    fi

    local service
    for service in "${!_NEEDS_RESTART[@]}"; do
        log_info "Restarting ${service}..."
        killall "$service" 2>/dev/null || true
    done
}

#######################################
# Cleanup function
#######################################
# shellcheck disable=SC2329  # invoked via trap
cleanup() {
    local exit_code=$?
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

#######################################
# Main
#######################################

log_banner "macOS System Defaults"

# Apply all defaults from data file
if ! apply_all_defaults "macos-defaults.txt"; then
    log_warn "Some defaults failed to apply"
fi

# Track which services need restart based on loaded domains
for i in "${!DEFAULTS_DOMAINS[@]}"; do
    _track_restart_needs "${DEFAULTS_DOMAINS[$i]}"
done

# Restart affected services
_restart_services

log_info "macOS defaults configuration complete"
exit "${EXIT_SUCCESS:-0}"
