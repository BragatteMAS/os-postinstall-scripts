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
# Exit Code Constants
#######################################
readonly EXIT_SUCCESS=0
readonly EXIT_PARTIAL_FAILURE=1
readonly EXIT_CRITICAL=2

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

# compute_exit_code - Return semantic exit code based on failure state
# Returns: 0 (success) or 1 (partial failure)
# Note: Code 2 (critical) is set explicitly by callers for pre-flight failures
compute_exit_code() {
    local fail_count=0
    if [[ -n "${FAILURE_LOG:-}" && -f "$FAILURE_LOG" && -s "$FAILURE_LOG" ]]; then
        fail_count=$(wc -l < "$FAILURE_LOG" | tr -d ' ')
    elif [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        fail_count=${#FAILED_ITEMS[@]}
    fi
    if [[ "$fail_count" -gt 0 ]]; then
        return $EXIT_PARTIAL_FAILURE
    fi
    return $EXIT_SUCCESS
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
# Shows failure summary and exits with semantic exit code based on failure state
cleanup() {
    show_failure_summary
    compute_exit_code
    local _exit_code=$?
    cleanup_temp_dir
    exit "$_exit_code"
}

# signal_cleanup - Cleanup for INT/TERM signals (Ctrl+C)
# Exits with 130 (standard signal exit code)
signal_cleanup() {
    trap - EXIT
    cleanup_temp_dir
    exit 130
}

# setup_error_handling - Set up trap for cleanup on exit
# Usage: setup_error_handling
setup_error_handling() {
    # Create temp directory
    create_temp_dir

    # Separate traps: EXIT for normal cleanup, INT/TERM for signal cleanup
    trap cleanup EXIT
    trap signal_cleanup INT TERM
}

#######################################
# Safe curl|sh -- Download-then-execute
#######################################

# safe_curl_sh -- Download installer to temp file before executing.
# Prevents partial download execution (the most practical curl|sh risk).
# Usage: safe_curl_sh URL [script_args...]
# Returns: exit code of the downloaded script, or 1 on download failure
safe_curl_sh() {
    local url="$1"
    shift

    if [[ -z "$url" ]]; then
        log_error "safe_curl_sh: no URL provided"
        return 1
    fi

    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/installer-XXXXXX.sh")

    if ! curl -fsSL "$url" -o "$tmp"; then
        rm -f "$tmp"
        log_error "Failed to download: $url"
        return 1
    fi

    local rc=0
    bash "$tmp" "$@" || rc=$?

    rm -f "$tmp"
    return "$rc"
}

#######################################
# Export functions and variables
#######################################
export -f retry_with_backoff
export -f record_failure show_failure_summary get_failure_count clear_failures
export -f compute_exit_code
export -f safe_curl_sh
export -f create_temp_dir cleanup_temp_dir cleanup signal_cleanup setup_error_handling
export EXIT_SUCCESS EXIT_PARTIAL_FAILURE EXIT_CRITICAL
export TEMP_DIR
