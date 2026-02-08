#!/usr/bin/env bash
#######################################
# Script: packages.sh
# Description: Package loading utilities for data-driven installation
# Author: Bragatte
# Date: 2026-02-05
#######################################

# Prevent multiple sourcing
[[ -n "${_PACKAGES_SOURCED:-}" ]] && return 0
readonly _PACKAGES_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Directory Setup
#######################################

# Get directory where THIS script lives
# NOTE: Uses _PACKAGES_DIR (not SCRIPT_DIR) to avoid readonly collision
# with other scripts that set SCRIPT_DIR for their own source paths.
_PACKAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly _PACKAGES_DIR

# Data directory relative to this script
DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
readonly DATA_DIR

#######################################
# Global array for loaded packages
#######################################
declare -a PACKAGES=()

#######################################
# _log_packages_error - Internal error logging
# Falls back to echo if logging module not available
#######################################
_log_packages_error() {
    if type log_error &>/dev/null; then
        log_error "$@"
    else
        echo "[ERROR] $*" >&2
    fi
}

#######################################
# _log_packages_warn - Internal warning logging
# Falls back to echo if logging module not available
#######################################
_log_packages_warn() {
    if type log_warn &>/dev/null; then
        log_warn "$@"
    else
        echo "[WARN] $*" >&2
    fi
}

#######################################
# _log_packages_debug - Internal debug logging
# Falls back to nothing if logging module not available
#######################################
_log_packages_debug() {
    if type log_debug &>/dev/null; then
        log_debug "$@"
    fi
}

#######################################
# _log_packages_info - Internal info logging
# Falls back to echo if logging module not available
#######################################
_log_packages_info() {
    if type log_info &>/dev/null; then
        log_info "$@"
    else
        echo "[INFO] $*"
    fi
}

#######################################
# load_packages()
# Load packages from a text file into PACKAGES array
#
# Args: $1 = filename (relative to data/packages/) or absolute path
# Sets: PACKAGES array
# Returns: 0 on success, 1 on error
#######################################
load_packages() {
    local file="${1:-}"
    PACKAGES=()

    # Validate argument
    if [[ -z "$file" ]]; then
        _log_packages_error "load_packages: no file specified"
        return 1
    fi

    # Validate DATA_DIR exists
    if [[ -z "$DATA_DIR" || ! -d "$DATA_DIR" ]]; then
        _log_packages_error "load_packages: DATA_DIR not found: ${DATA_DIR:-undefined}"
        return 1
    fi

    # Resolve relative paths to DATA_DIR/packages/
    if [[ "$file" != /* ]]; then
        file="${DATA_DIR}/packages/${file}"
    fi

    # Validate file exists
    if [[ ! -f "$file" ]]; then
        _log_packages_error "Package file not found: $file"
        return 1
    fi

    # Validate file is readable
    if [[ ! -r "$file" ]]; then
        _log_packages_error "Package file not readable: $file"
        return 1
    fi

    # Read lines, skip comments and empty
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        PACKAGES+=("$line")
    done < "$file"

    _log_packages_debug "Loaded ${#PACKAGES[@]} packages from $(basename "$file")"
    return 0
}

#######################################
# load_profile()
# Load all packages from a profile (which lists other package files to include)
#
# Args: $1 = profile name (e.g., "developer")
# Sets: PACKAGES array (combined from all files)
# Returns: 0 on success, 1 if profile not found
#######################################
load_profile() {
    local profile_name="${1:-}"
    local profile_file="${DATA_DIR}/packages/profiles/${profile_name}.txt"
    local all_packages=()

    # Validate argument
    if [[ -z "$profile_name" ]]; then
        _log_packages_error "load_profile: no profile name specified"
        return 1
    fi

    # Validate DATA_DIR exists
    if [[ -z "$DATA_DIR" || ! -d "$DATA_DIR" ]]; then
        _log_packages_error "load_profile: DATA_DIR not found: ${DATA_DIR:-undefined}"
        return 1
    fi

    # Validate profile file exists
    if [[ ! -f "$profile_file" ]]; then
        _log_packages_error "Profile not found: $profile_name"
        return 1
    fi

    # Read each file listed in profile
    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        # Trim whitespace
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"
        pkg_file="${pkg_file%"${pkg_file##*[![:space:]]}"}"

        # Skip empty lines and comments
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        # Load packages from this file
        if load_packages "$pkg_file"; then
            all_packages+=("${PACKAGES[@]}")
        else
            _log_packages_warn "Skipping package file: $pkg_file"
        fi
    done < "$profile_file"

    PACKAGES=("${all_packages[@]}")
    _log_packages_info "Profile '$profile_name': ${#PACKAGES[@]} total packages"
    return 0
}

#######################################
# get_packages_for_manager()
# Load packages for a specific package manager
#
# Args: $1 = manager name (apt, brew, cargo, npm, winget)
# Sets: PACKAGES array
# Returns: 0 on success, 1 if file not found
#######################################
get_packages_for_manager() {
    local manager="${1:-}"

    # Validate argument
    if [[ -z "$manager" ]]; then
        _log_packages_error "get_packages_for_manager: no manager specified"
        return 1
    fi

    local file="${DATA_DIR}/packages/${manager}.txt"

    if [[ -f "$file" ]]; then
        load_packages "$file"
    else
        PACKAGES=()
        _log_packages_warn "No package list for manager: $manager"
        return 1
    fi
}

#######################################
# Export functions
#######################################
export -f load_packages load_profile get_packages_for_manager
export -f _log_packages_error _log_packages_warn _log_packages_debug _log_packages_info
export DATA_DIR
