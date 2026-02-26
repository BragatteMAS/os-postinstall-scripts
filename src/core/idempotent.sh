#!/usr/bin/env bash
#######################################
# Script: idempotent.sh
# Description: Idempotency utilities for safe repeated execution
# Author: Bragatte
# Date: 2026-02-05
#######################################

# Prevent multiple sourcing
[[ -n "${_IDEMPOTENT_SOURCED:-}" ]] && return 0
readonly _IDEMPOTENT_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Command Check Functions
#######################################

# Check if a command exists in PATH
# Usage: is_installed <command>
# Returns: 0 if installed, 1 if not
is_installed() {
    local cmd="${1:-}"
    [[ -z "$cmd" ]] && return 1
    command -v "$cmd" >/dev/null 2>&1
}

# Check if an apt package is installed (Debian/Ubuntu)
# Usage: is_apt_installed <package>
# Returns: 0 if installed, 1 if not
is_apt_installed() {
    local pkg="${1:-}"
    [[ -z "$pkg" ]] && return 1
    dpkg -s "$pkg" >/dev/null 2>&1
}

# Check if a brew package is installed (macOS/Linux)
# Usage: is_brew_installed <package>
# Returns: 0 if installed, 1 if not
is_brew_installed() {
    local pkg="${1:-}"
    [[ -z "$pkg" ]] && return 1
    # Check if brew is available first
    command -v brew >/dev/null 2>&1 || return 1
    brew list "$pkg" >/dev/null 2>&1
}

#######################################
# File Manipulation Guards
#######################################

# Add a line to a file only if not already present
# Usage: ensure_line_in_file <line> <file>
# Returns: 0 on success, 1 on failure
ensure_line_in_file() {
    local line="${1:-}"
    local file="${2:-}"

    [[ -z "$line" || -z "$file" ]] && return 1

    # Create file if it doesn't exist
    if [[ ! -f "$file" ]]; then
        touch "$file" || return 1
    fi

    # Add line only if not present (fixed string match)
    if ! grep -qF -- "$line" "$file"; then
        echo "$line" >> "$file"
    fi

    return 0
}

# Create directory if it doesn't exist
# Usage: ensure_dir <path>
# Returns: 0 on success, 1 on failure
ensure_dir() {
    local path="${1:-}"
    [[ -z "$path" ]] && return 1
    mkdir -p "$path"
}

# Create or update a symlink
# Usage: ensure_symlink <source> <target>
# Returns: 0 on success, 1 on failure
ensure_symlink() {
    local source="${1:-}"
    local target="${2:-}"

    [[ -z "$source" || -z "$target" ]] && return 1

    # ln -sfn: symbolic, force (overwrite), no-dereference (replace symlink itself)
    ln -sfn "$source" "$target"
}

#######################################
# PATH Management
#######################################

# Add a path to PATH only if not already present
# Usage: add_to_path <path>
# Returns: 0 always (idempotent)
add_to_path() {
    local new_path="${1:-}"
    [[ -z "$new_path" ]] && return 0

    # Check if path is already in PATH
    case ":$PATH:" in
        *":$new_path:"*)
            # Already present, do nothing
            return 0
            ;;
    esac

    # Add to PATH
    export PATH="$new_path:$PATH"
    return 0
}

# Prepend path to PATH only if not already present
# Usage: prepend_to_path <path>
# Alias for add_to_path (adds to front)
prepend_to_path() {
    add_to_path "$@"
}

# Append path to PATH only if not already present
# Usage: append_to_path <path>
# Returns: 0 always (idempotent)
append_to_path() {
    local new_path="${1:-}"
    [[ -z "$new_path" ]] && return 0

    # Check if path is already in PATH
    case ":$PATH:" in
        *":$new_path:"*)
            return 0
            ;;
    esac

    # Add to end of PATH
    export PATH="$PATH:$new_path"
    return 0
}

#######################################
# Backup Utilities
#######################################

# Create backup of file if it exists
# Usage: backup_if_exists <file>
# Returns: 0 on success (or if file doesn't exist), 1 on failure
backup_if_exists() {
    local file="${1:-}"
    [[ -z "$file" ]] && return 1

    # If file doesn't exist, nothing to backup
    [[ ! -e "$file" ]] && return 0

    local backup_suffix
    backup_suffix=".bak.$(date +%Y-%m-%d)"
    local backup_file="${file}${backup_suffix}"

    # If backup already exists today, add timestamp
    if [[ -e "$backup_file" ]]; then
        backup_suffix=".bak.$(date +%Y-%m-%d-%H%M%S)"
        backup_file="${file}${backup_suffix}"
    fi

    cp -p "$file" "$backup_file"
}

# Backup existing file and copy new file in its place
# Usage: backup_and_copy <source> <dest>
# Returns: 0 on success, 1 on failure
backup_and_copy() {
    local source="${1:-}"
    local dest="${2:-}"

    [[ -z "$source" || -z "$dest" ]] && return 1
    [[ ! -f "$source" ]] && return 1

    # Backup existing destination if it exists
    if [[ -e "$dest" ]]; then
        backup_if_exists "$dest" || return 1
    fi

    # Copy source to destination
    cp -p "$source" "$dest"
}

#######################################
# Export functions for subshells
#######################################

export -f is_installed is_apt_installed is_brew_installed
export -f ensure_line_in_file ensure_dir ensure_symlink
export -f add_to_path prepend_to_path append_to_path
export -f backup_if_exists backup_and_copy
