#!/usr/bin/env bash
#######################################
# Script: hooks.sh
# Description: Post-install hook runner (inspired by nix-darwin activation scripts)
# Author: Bragatte
# Date: 2026-03-26
#######################################

# Prevent multiple sourcing
[[ -n "${_HOOKS_SOURCED:-}" ]] && return 0
readonly _HOOKS_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Directory Setup
#######################################

_HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly _HOOKS_DIR

# Data directory (guarded to avoid readonly collision)
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_HOOKS_DIR}/../../data" 2>/dev/null && pwd -P)"
fi

#######################################
# Internal logging helpers
#######################################
_log_hooks_error() {
    if type log_error &>/dev/null; then
        log_error "$@"
    else
        echo "[ERROR] $*" >&2
    fi
}

_log_hooks_info() {
    if type log_info &>/dev/null; then
        log_info "$@"
    else
        echo "[INFO] $*"
    fi
}

_log_hooks_debug() {
    if type log_debug &>/dev/null; then
        log_debug "$@"
    fi
}

_log_hooks_warn() {
    if type log_warn &>/dev/null; then
        log_warn "$@"
    else
        echo "[WARN] $*" >&2
    fi
}

#######################################
# run_hooks()
# Execute all hooks in data/hooks/ in sorted order
#
# Hooks are filtered by platform via naming convention:
#   *-macos-*  → only runs when platform is "macos"
#   *-linux-*  → only runs when platform is "linux"
#   no marker  → runs on all platforms
#
# Args: $1 = platform filter ("macos", "linux", or "all")
# Returns: 0 on full success, 1 on any failure
#######################################
run_hooks() {
    local platform="${1:-all}"
    local hooks_dir="${DATA_DIR}/hooks"

    if [[ ! -d "$hooks_dir" ]]; then
        _log_hooks_debug "No hooks directory found: $hooks_dir"
        return 0
    fi

    # Collect and sort hooks
    local hooks=()
    local hook
    for hook in "$hooks_dir"/*.sh; do
        [[ ! -f "$hook" ]] && continue
        hooks+=("$hook")
    done

    if [[ ${#hooks[@]} -eq 0 ]]; then
        _log_hooks_debug "No hooks found in $hooks_dir"
        return 0
    fi

    # Sort hooks (already sorted by glob, but ensure)
    mapfile -t hooks < <(printf '%s\n' "${hooks[@]}" | sort)

    local count=0 failed=0

    for hook in "${hooks[@]}"; do
        local basename_hook
        basename_hook="$(basename "$hook")"

        # Platform filter: skip hooks not matching current platform
        case "$basename_hook" in
            *-macos-*)
                [[ "$platform" != "macos" ]] && continue
                ;;
            *-linux-*)
                [[ "$platform" != "linux" ]] && continue
                ;;
        esac

        count=$((count + 1))

        # DRY_RUN guard
        if [[ "${DRY_RUN:-}" == "true" ]]; then
            _log_hooks_info "[DRY_RUN] Would execute hook: $basename_hook"
            continue
        fi

        _log_hooks_info "Running hook: $basename_hook"

        if bash "$hook"; then
            _log_hooks_debug "Hook completed: $basename_hook"
        else
            _log_hooks_warn "Hook failed: $basename_hook"
            # Record failure if errors module is loaded
            if type record_failure &>/dev/null; then
                record_failure "hook:${basename_hook}"
            fi
            failed=$((failed + 1))
        fi
    done

    _log_hooks_debug "Executed $count hook(s), $failed failed"
    [[ $failed -eq 0 ]]
}

#######################################
# Export functions for subshells
#######################################
export -f run_hooks
export -f _log_hooks_error _log_hooks_info _log_hooks_debug _log_hooks_warn
