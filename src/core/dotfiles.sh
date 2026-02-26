#!/usr/bin/env bash
#######################################
# Script: dotfiles.sh
# Description: Dotfiles symlink manager with backup functionality
# Author: Bragatte
# Date: 2026-02-06
#######################################

# Prevent multiple sourcing
[[ -n "${_DOTFILES_SOURCED:-}" ]] && return 0
readonly _DOTFILES_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Source dependencies
#######################################
# shellcheck source=./logging.sh
DOTFILES_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${DOTFILES_SCRIPT_DIR}/logging.sh"

#######################################
# Constants
#######################################
BACKUP_DIR="${HOME}/.dotfiles-backup"
MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"

# Session tracking for backup summary
declare -a SESSION_BACKUPS=()

#######################################
# path_to_backup_name()
# Convert file path to flat backup name with path prefix
# Algorithm:
#   1. Remove $HOME prefix
#   2. Remove leading dots and slashes
#   3. Replace remaining "/" with "-"
#   4. Append ".bak.YYYY-MM-DD"
#
# Usage: path_to_backup_name <file_path>
# Example: ~/.config/git/ignore -> config-git-ignore.bak.2026-02-05
# Example: ~/.zshrc -> zshrc.bak.2026-02-05
#######################################
path_to_backup_name() {
    local file="$1"
    [[ -z "$file" ]] && return 1

    local name="${file#"$HOME"/}"      # Remove $HOME/
    name="${name#.}"                  # Remove leading dot
    name="${name//\//-}"              # Replace / with -
    echo "${name}.bak.$(date +%Y-%m-%d)"
}

#######################################
# backup_with_manifest()
# Backup a file to BACKUP_DIR with manifest entry
#
# Usage: backup_with_manifest <source_file>
# Returns: 0 on success, 1 on failure (abort signal)
#######################################
backup_with_manifest() {
    local source_file="$1"
    [[ -z "$source_file" ]] && return 1

    local backup_name
    backup_name=$(path_to_backup_name "$source_file")
    local backup_path="${BACKUP_DIR}/${backup_name}"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # DRY_RUN mode: log what would happen but don't modify
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would backup: ${source_file} -> ${backup_path}"
        return 0
    fi

    # Create backup directory if missing
    if [[ ! -d "$BACKUP_DIR" ]]; then
        if ! mkdir -p "$BACKUP_DIR"; then
            log_error "Failed to create backup directory: ${BACKUP_DIR}"
            return 1
        fi
        log_debug "Created backup directory: ${BACKUP_DIR}"
    fi

    # Handle name collision (same file backed up same day)
    if [[ -e "$backup_path" ]]; then
        backup_name="${backup_name%.bak.*}.bak.$(date +%Y-%m-%d-%H%M%S)"
        backup_path="${BACKUP_DIR}/${backup_name}"
    fi

    # Copy with preserved permissions
    if ! cp -p "$source_file" "$backup_path"; then
        log_error "Failed to backup: ${source_file}"
        return 1
    fi

    # Append to manifest
    echo "${timestamp} | ${source_file} -> ${backup_path}" >> "$MANIFEST_FILE"

    # Track for session summary
    SESSION_BACKUPS+=("${source_file} -> ${backup_path}")

    log_info "Backed up: ${source_file} -> ${backup_path}"
    return 0
}

#######################################
# create_dotfile_symlink()
# Create a symlink from target (in $HOME) to source (in data/dotfiles/)
# Backs up existing non-symlink files before replacement
#
# Usage: create_dotfile_symlink <source> <target>
#   source: absolute path in data/dotfiles/
#   target: absolute path in $HOME
# Returns: 0 on success, 1 on failure
#######################################
create_dotfile_symlink() {
    local source="$1"
    local target="$2"

    [[ -z "$source" || -z "$target" ]] && return 1

    # Verify source exists
    if [[ ! -e "$source" ]]; then
        log_error "Source does not exist: ${source}"
        return 1
    fi

    # Create parent directory if missing (e.g., ~/.config/git/ for ~/.config/git/ignore)
    local target_dir
    target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        if [[ "${DRY_RUN:-}" == "true" ]]; then
            log_info "[DRY_RUN] Would create directory: ${target_dir}"
        else
            if ! mkdir -p "$target_dir"; then
                log_error "Failed to create directory: ${target_dir}"
                return 1
            fi
            log_debug "Created directory: ${target_dir}"
        fi
    fi

    # Handle existing target
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            # Existing symlink: replace without backup (per CONTEXT.md)
            log_debug "Replacing existing symlink: ${target}"
        else
            # Existing non-symlink file: backup first
            if ! backup_with_manifest "$target"; then
                log_error "Backup failed, aborting symlink creation for: ${target}"
                return 1
            fi
        fi
    fi

    # Create symlink
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would link: ${target} -> ${source}"
        return 0
    fi

    # ln -sfn: symbolic, force, no-dereference (replace symlink itself)
    if ! ln -sfn "$source" "$target"; then
        log_error "Failed to create symlink: ${target} -> ${source}"
        return 1
    fi

    log_ok "Linked: ${target} -> ${source}"
    return 0
}

#######################################
# unlink_dotfiles()
# Remove a dotfile symlink and restore from backup if available
#
# Usage: unlink_dotfiles <target>
#   target: path to symlink to remove
# Returns: 0 on success, 1 on failure
#######################################
unlink_dotfiles() {
    local target="$1"
    [[ -z "$target" ]] && return 1

    # Check if target is a symlink
    if [[ ! -L "$target" ]]; then
        if [[ -e "$target" ]]; then
            log_warn "Not a symlink, skipping: ${target}"
        else
            log_debug "Does not exist: ${target}"
        fi
        return 0
    fi

    # Find backup from manifest (most recent entry for this target)
    local backup_path=""
    local backup_count=0

    if [[ -f "$MANIFEST_FILE" ]]; then
        # Read manifest to find backups for this target
        while IFS= read -r line; do
            if [[ "$line" == *"| ${target} -> "* ]]; then
                backup_path="${line##* -> }"
                ((backup_count++))
            fi
        done < "$MANIFEST_FILE"
    fi

    if [[ $backup_count -gt 1 ]]; then
        log_warn "Multiple backups found for ${target}, using most recent: ${backup_path}"
    fi

    # Remove symlink
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would remove symlink: ${target}"
        if [[ -n "$backup_path" && -f "$backup_path" ]]; then
            log_info "[DRY_RUN] Would restore from: ${backup_path}"
        fi
        return 0
    fi

    if ! rm "$target"; then
        log_error "Failed to remove symlink: ${target}"
        return 1
    fi
    log_info "Removed symlink: ${target}"

    # Restore backup if found
    if [[ -n "$backup_path" && -f "$backup_path" ]]; then
        if ! cp -p "$backup_path" "$target"; then
            log_error "Failed to restore backup: ${backup_path}"
            return 1
        fi
        log_ok "Restored: ${backup_path} -> ${target}"
    else
        log_debug "No backup found for: ${target}"
    fi

    return 0
}

#######################################
# show_backup_summary()
# Display summary of all backups made in current session
#
# Usage: show_backup_summary
#######################################
show_backup_summary() {
    if [[ ${#SESSION_BACKUPS[@]} -eq 0 ]]; then
        log_info "No backups created in this session"
        return 0
    fi

    echo ""
    log_info "Backup Summary (${#SESSION_BACKUPS[@]} files):"
    echo "----------------------------------------"
    for backup in "${SESSION_BACKUPS[@]}"; do
        echo "  Backed up: ${backup}"
    done
    echo "----------------------------------------"
    echo "  Backup location: ${BACKUP_DIR}"
    echo "  Manifest: ${MANIFEST_FILE}"
    echo ""
}

#######################################
# list_backups()
# List all backups in BACKUP_DIR
#
# Usage: list_backups
#######################################
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "No backup directory found: ${BACKUP_DIR}"
        return 0
    fi

    local count
    count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$count" -eq 0 ]]; then
        log_info "No backups found in ${BACKUP_DIR}"
        return 0
    fi

    log_info "Backups in ${BACKUP_DIR} (${count} files):"
    echo "----------------------------------------"
    find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" -exec basename {} \; 2>/dev/null | sort
    echo "----------------------------------------"
}

#######################################
# Export functions for subshells
#######################################
export -f path_to_backup_name
export -f backup_with_manifest
export -f create_dotfile_symlink
export -f unlink_dotfiles
export -f show_backup_summary
export -f list_backups

export BACKUP_DIR MANIFEST_FILE
