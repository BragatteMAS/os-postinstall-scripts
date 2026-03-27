#!/usr/bin/env bash
#######################################
# Script: state.sh
# Description: Package state tracking for drift detection (inspired by nix-darwin)
# Author: Bragatte
# Date: 2026-03-26
#######################################

# Prevent multiple sourcing
[[ -n "${_STATE_SOURCED:-}" ]] && return 0
readonly _STATE_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Directory Setup
#######################################

_STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly _STATE_DIR

# Data directory (guarded to avoid readonly collision)
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_STATE_DIR}/../../data" 2>/dev/null && pwd -P)"
fi

# State file location (overridable for testing)
if [[ -z "${_STATE_FILE:-}" ]]; then
    _STATE_FILE="${HOME}/.config/os-postinstall/package-state.txt"
fi

#######################################
# Internal logging helpers
#######################################
_log_state_error() {
    if type log_error &>/dev/null; then
        log_error "$@"
    else
        echo "[ERROR] $*" >&2
    fi
}

_log_state_info() {
    if type log_info &>/dev/null; then
        log_info "$@"
    else
        echo "[INFO] $*"
    fi
}

_log_state_debug() {
    if type log_debug &>/dev/null; then
        log_debug "$@"
    fi
}

_log_state_warn() {
    if type log_warn &>/dev/null; then
        log_warn "$@"
    else
        echo "[WARN] $*" >&2
    fi
}

#######################################
# save_package_state()
# Record a package installation in the state file
# Idempotent: updates existing entry rather than duplicating
#
# Args: $1 = manager (brew, brew-cask, apt, snap, flatpak, cargo)
#       $2 = package name
#       $3 = profile name
# Returns: 0 on success, 1 on error
#######################################
save_package_state() {
    local manager="${1:-}" package="${2:-}" profile="${3:-unknown}"

    [[ -z "$manager" || -z "$package" ]] && return 1

    # Skip in DRY_RUN
    [[ "${DRY_RUN:-}" == "true" ]] && return 0

    # Ensure state directory exists
    local state_dir
    state_dir="$(dirname "$_STATE_FILE")"
    mkdir -p "$state_dir" || return 1

    local timestamp
    timestamp="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    local entry="${manager}|${package}|${timestamp}|${profile}"

    # Remove existing entry for this manager+package (idempotent update)
    if [[ -f "$_STATE_FILE" ]]; then
        local tmp_file
        tmp_file=$(mktemp "${state_dir}/state.XXXXXX") || return 1
        grep -v "^${manager}|${package}|" "$_STATE_FILE" > "$tmp_file" 2>/dev/null || true
        echo "$entry" >> "$tmp_file"
        mv "$tmp_file" "$_STATE_FILE" || {
            rm -f "$tmp_file"
            return 1
        }
    else
        # Create new state file with header
        {
            echo "# Package state - managed by os-postinstall-scripts"
            echo "# Format: manager|package|install_date|profile"
            echo "$entry"
        } > "$_STATE_FILE"
    fi

    return 0
}

#######################################
# load_package_state()
# Load packages from state file for a given manager
#
# Args: $1 = manager (e.g., "brew", "apt")
# Sets: STATE_PACKAGES[] array
# Returns: 0 on success, 1 if no state file
#######################################
declare -a STATE_PACKAGES=()

load_package_state() {
    local manager="${1:-}"
    STATE_PACKAGES=()

    [[ -z "$manager" ]] && return 1

    if [[ ! -f "$_STATE_FILE" ]]; then
        return 1
    fi

    while IFS='|' read -r m pkg _ts _prof || [[ -n "$m" ]]; do
        # Skip comments and empty lines
        [[ -z "$m" || "$m" == \#* ]] && continue
        [[ "$m" == "$manager" ]] && STATE_PACKAGES+=("$pkg")
    done < "$_STATE_FILE"

    return 0
}

#######################################
# detect_drift()
# Compare current data file packages against state file
#
# Args: $1 = manager, $2 = data file path (relative to data/packages/ or absolute)
# Echoes: packages in state but NOT in data file (removed)
# Returns: 0 if no drift, 1 if drift detected
#######################################
detect_drift() {
    local manager="${1:-}" data_file="${2:-}"

    [[ -z "$manager" || -z "$data_file" ]] && return 0

    # Load state
    load_package_state "$manager" || return 0
    [[ ${#STATE_PACKAGES[@]} -eq 0 ]] && return 0

    # Resolve data file path
    if [[ "$data_file" != /* ]]; then
        data_file="${DATA_DIR}/packages/${data_file}"
    fi

    [[ ! -f "$data_file" ]] && return 0

    # Load current packages from data file
    local current_packages=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        current_packages+=("$line")
    done < "$data_file"

    # Find packages in state but not in current data file
    local drift_found=0
    local state_pkg
    for state_pkg in "${STATE_PACKAGES[@]}"; do
        local found=0
        local current_pkg
        for current_pkg in "${current_packages[@]}"; do
            if [[ "$state_pkg" == "$current_pkg" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            echo "$state_pkg"
            drift_found=1
        fi
    done

    [[ $drift_found -eq 0 ]]
}

#######################################
# show_drift_report()
# Display a human-readable drift report for all managers
#
# Returns: 0 if no drift, 1 if drift detected
#######################################
show_drift_report() {
    if [[ ! -f "$_STATE_FILE" ]]; then
        _log_state_debug "No state file found, skipping drift detection"
        return 0
    fi

    local drift_found=0

    # Manager → data file mapping
    local -A manager_files=(
        [brew]="brew.txt"
        [brew-cask]="brew-cask.txt"
        [apt]="apt.txt"
        [flatpak]="flatpak.txt"
        [snap]="snap.txt"
        [cargo]="cargo.txt"
    )

    local manager data_file
    for manager in "${!manager_files[@]}"; do
        data_file="${manager_files[$manager]}"

        # Skip managers without data files
        [[ ! -f "${DATA_DIR}/packages/${data_file}" ]] && continue

        local drift
        drift=$(detect_drift "$manager" "$data_file") || continue

        if [[ -n "$drift" ]]; then
            if [[ $drift_found -eq 0 ]]; then
                _log_state_warn "Package drift detected:"
                drift_found=1
            fi
            echo "  Packages no longer in ${data_file} (previously installed by ${manager}):"
            while IFS= read -r pkg; do
                echo "    - $pkg"
            done <<< "$drift"
        fi
    done

    if [[ $drift_found -eq 1 ]]; then
        echo ""
        _log_state_info "To resolve: remove packages manually or re-add to data files"
    fi

    [[ $drift_found -eq 0 ]]
}

#######################################
# clear_package_state()
# Remove a package from state tracking
#
# Args: $1 = manager, $2 = package
# Returns: 0 on success
#######################################
clear_package_state() {
    local manager="${1:-}" package="${2:-}"

    [[ -z "$manager" || -z "$package" ]] && return 1
    [[ ! -f "$_STATE_FILE" ]] && return 0

    local state_dir
    state_dir="$(dirname "$_STATE_FILE")"
    local tmp_file
    tmp_file=$(mktemp "${state_dir}/state.XXXXXX") || return 1

    grep -v "^${manager}|${package}|" "$_STATE_FILE" > "$tmp_file" 2>/dev/null || true
    mv "$tmp_file" "$_STATE_FILE" || {
        rm -f "$tmp_file"
        return 1
    }

    return 0
}

#######################################
# Export functions for subshells
#######################################
export -f save_package_state load_package_state detect_drift
export -f show_drift_report clear_package_state
export -f _log_state_error _log_state_info _log_state_debug _log_state_warn
export _STATE_FILE
