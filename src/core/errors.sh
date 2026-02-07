#!/usr/bin/env bash
#######################################
# Script: errors.sh
# Description: Error handling, failure tracking, and cleanup utilities
# Author: Bragatte
# Date: 2026-02-05
#######################################

# Prevent multiple sourcing
[[ -n "${_ERRORS_SOURCED:-}" ]] && return 0
readonly _ERRORS_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Source logging module for output
#######################################
# shellcheck source=logging.sh
if [[ -z "${_LOGGING_SOURCED:-}" ]]; then
    # Try to source from same directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${SCRIPT_DIR}/logging.sh" ]]; then
        source "${SCRIPT_DIR}/logging.sh"
    fi
fi

#######################################
# Retry with Exponential Backoff
#######################################

# retry_with_backoff - Retry a command with exponential backoff
# Usage: retry_with_backoff cmd arg1 arg2...
# Returns: 0 on success, 1 after all attempts exhausted
retry_with_backoff() {
    local max_attempts=3
    local -a delays=(5 15 30)
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            local delay="${delays[$((attempt - 1))]}"
            if type log_warn &>/dev/null; then
                log_warn "Retry ${attempt}/${max_attempts} in ${delay}s..."
            else
                echo "[WARN] Retry ${attempt}/${max_attempts} in ${delay}s..." >&2
            fi
            sleep "$delay"
        fi

        attempt=$((attempt + 1))
    done

    return 1
}

#######################################
# Failure Tracking
#######################################

# Array to track failed items (packages, operations, etc.)
declare -a FAILED_ITEMS=()

# record_failure - Add an item to the failure list
# Usage: record_failure "package-name"
record_failure() {
    local item="${1:-unknown}"
    FAILED_ITEMS+=("$item")

    # Cross-process: append to shared log if available
    if [[ -n "${FAILURE_LOG:-}" ]]; then
        echo "$item" >> "$FAILURE_LOG" 2>/dev/null
    fi

    # Log the failure if logging is available
    if type log_error &>/dev/null; then
        log_error "Failed: $item"
    else
        echo "[ERROR] Failed: $item" >&2
    fi
}

# show_failure_summary - Display all failed items at the end
# Usage: show_failure_summary
show_failure_summary() {
    local count="${#FAILED_ITEMS[@]}"

    if [[ "$count" -eq 0 ]]; then
        if type log_ok &>/dev/null; then
            log_ok "All operations completed successfully"
        else
            echo "[OK] All operations completed successfully"
        fi
        return 0
    fi

    echo ""
    if type log_warn &>/dev/null; then
        log_warn "Summary: $count item(s) failed"
    else
        echo "[WARN] Summary: $count item(s) failed"
    fi

    echo "  Failed items:"
    for item in "${FAILED_ITEMS[@]}"; do
        echo "    - $item"
    done
    echo ""

    return 0
}

# get_failure_count - Return the number of failed items
# Usage: count=$(get_failure_count)
get_failure_count() {
    echo "${#FAILED_ITEMS[@]}"
}

# clear_failures - Reset the failure list
# Usage: clear_failures
clear_failures() {
    FAILED_ITEMS=()
}

#######################################
# Temporary Directory Management
#######################################

# TEMP_DIR for operations that need temporary files
export TEMP_DIR=""

# create_temp_dir - Create a temp directory for this session
# Usage: create_temp_dir
create_temp_dir() {
    if [[ -z "$TEMP_DIR" || ! -d "$TEMP_DIR" ]]; then
        TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/os-postinstall-XXXXXX")
        export TEMP_DIR
    fi
}

# cleanup_temp_dir - Remove temp directory if it exists
# Usage: cleanup_temp_dir
cleanup_temp_dir() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        TEMP_DIR=""
    fi
}

#######################################
# Cleanup and Trap
#######################################

# cleanup - Main cleanup function called on exit
# Shows failure summary and cleans up temp files
# Per CONTEXT: Always exit 0 (pragmatic approach - summary shows what failed)
cleanup() {
    # Show what failed during this run
    show_failure_summary

    # Clean up temp files
    cleanup_temp_dir

    # Always exit 0 (per CONTEXT decision)
    exit 0
}

# setup_error_handling - Set up trap for cleanup on exit
# Usage: setup_error_handling
setup_error_handling() {
    # Create temp directory
    create_temp_dir

    # Set trap on EXIT, INT, TERM
    trap cleanup EXIT INT TERM
}

#######################################
# Export functions and variables
#######################################
export -f retry_with_backoff
export -f record_failure show_failure_summary get_failure_count clear_failures
export -f create_temp_dir cleanup_temp_dir cleanup setup_error_handling
export TEMP_DIR
