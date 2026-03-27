#!/usr/bin/env bash
#######################################
# Script: defaults.sh
# Description: macOS system defaults management (inspired by nix-darwin system.defaults)
# Author: Bragatte
# Date: 2026-03-26
#######################################

# Prevent multiple sourcing
[[ -n "${_DEFAULTS_SOURCED:-}" ]] && return 0
readonly _DEFAULTS_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Directory Setup
#######################################

_DEFAULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly _DEFAULTS_DIR

# Data directory (guarded to avoid readonly collision)
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_DEFAULTS_DIR}/../../data" 2>/dev/null && pwd -P)"
fi

# State directory for backups (overridable for testing)
if [[ -z "${_DEFAULTS_STATE_DIR:-}" ]]; then
    _DEFAULTS_STATE_DIR="${HOME}/.config/os-postinstall"
fi

#######################################
# Global arrays for loaded defaults
#######################################
declare -a DEFAULTS_DOMAINS=()
declare -a DEFAULTS_KEYS=()
declare -a DEFAULTS_TYPES=()
declare -a DEFAULTS_VALUES=()

#######################################
# Internal logging helpers
# Falls back to echo if logging module not available
#######################################
_log_defaults_error() {
    if type log_error &>/dev/null; then
        log_error "$@"
    else
        echo "[ERROR] $*" >&2
    fi
}

_log_defaults_warn() {
    if type log_warn &>/dev/null; then
        log_warn "$@"
    else
        echo "[WARN] $*" >&2
    fi
}

_log_defaults_info() {
    if type log_info &>/dev/null; then
        log_info "$@"
    else
        echo "[INFO] $*"
    fi
}

_log_defaults_debug() {
    if type log_debug &>/dev/null; then
        log_debug "$@"
    fi
}

_log_defaults_ok() {
    if type log_ok &>/dev/null; then
        log_ok "$@"
    else
        echo "[OK] $*"
    fi
}

#######################################
# load_defaults_file()
# Load defaults from a pipe-delimited text file into parallel arrays
#
# Args: $1 = filename (relative to data/defaults/ or absolute path)
# Sets: DEFAULTS_DOMAINS[], DEFAULTS_KEYS[], DEFAULTS_TYPES[], DEFAULTS_VALUES[]
# Returns: 0 on success, 1 on error
#######################################
load_defaults_file() {
    local file="${1:-}"
    DEFAULTS_DOMAINS=()
    DEFAULTS_KEYS=()
    DEFAULTS_TYPES=()
    DEFAULTS_VALUES=()

    if [[ -z "$file" ]]; then
        _log_defaults_error "load_defaults_file: no file specified"
        return 1
    fi

    # Resolve relative paths to DATA_DIR/defaults/
    if [[ "$file" != /* ]]; then
        file="${DATA_DIR}/defaults/${file}"
    fi

    if [[ ! -f "$file" ]]; then
        _log_defaults_error "Defaults file not found: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        _log_defaults_error "Defaults file not readable: $file"
        return 1
    fi

    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))

        # Trim leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Parse pipe-delimited: domain|key|type|value
        local domain key type value
        IFS='|' read -r domain key type value <<< "$line"

        # Validate all 4 fields present
        if [[ -z "$domain" || -z "$key" || -z "$type" || -z "$value" ]]; then
            _log_defaults_warn "Malformed line $line_num: $line (expected domain|key|type|value)"
            continue
        fi

        # Validate type
        case "$type" in
            bool|int|float|string) ;;
            *)
                _log_defaults_warn "Unknown type '$type' at line $line_num: $line"
                continue
                ;;
        esac

        DEFAULTS_DOMAINS+=("$domain")
        DEFAULTS_KEYS+=("$key")
        DEFAULTS_TYPES+=("$type")
        DEFAULTS_VALUES+=("$value")
    done < "$file"

    _log_defaults_debug "Loaded ${#DEFAULTS_DOMAINS[@]} defaults from $(basename "$file")"
    return 0
}

#######################################
# get_current_default()
# Read the current value of a macOS default
#
# Args: $1 = domain, $2 = key
# Echoes: current value or empty string
# Returns: 0 if key exists, 1 if not set
#######################################
get_current_default() {
    local domain="${1:-}" key="${2:-}"

    [[ -z "$domain" || -z "$key" ]] && return 1

    defaults read "$domain" "$key" 2>/dev/null
}

#######################################
# apply_default()
# Write a single macOS default idempotently
# Pattern: check current → DRY_RUN guard → defaults write
#
# Args: $1 = domain, $2 = key, $3 = type, $4 = value
# Returns: 0 on success (or already set), 1 on failure
#######################################
apply_default() {
    local domain="$1" key="$2" type="$3" value="$4"

    # 1. Idempotency check
    local current
    current=$(get_current_default "$domain" "$key") || current=""

    # Normalize boolean comparison (defaults read returns 1/0 for bools)
    local normalized_value="$value"
    if [[ "$type" == "bool" ]]; then
        case "$value" in
            true)  normalized_value="1" ;;
            false) normalized_value="0" ;;
        esac
    fi

    if [[ "$current" == "$normalized_value" || "$current" == "$value" ]]; then
        _log_defaults_debug "Already set: ${domain} ${key} = ${value}"
        return 0
    fi

    # 2. DRY_RUN guard
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        _log_defaults_info "[DRY_RUN] Would set: ${domain} ${key} = ${value} (current: ${current:-unset})"
        return 0
    fi

    # 3. Mutation
    local type_flag
    case "$type" in
        bool)   type_flag="-bool" ;;
        int)    type_flag="-int" ;;
        float)  type_flag="-float" ;;
        string) type_flag="-string" ;;
        *)      _log_defaults_error "Unknown type: $type"; return 1 ;;
    esac

    if defaults write "$domain" "$key" "$type_flag" "$value"; then
        _log_defaults_ok "Set: ${domain} ${key} = ${value}"
        return 0
    else
        _log_defaults_error "Failed: defaults write ${domain} ${key}"
        return 1
    fi
}

#######################################
# backup_current_defaults()
# Snapshot all keys about to be changed into a backup file
#
# Args: $1 = defaults data file path (optional, uses loaded arrays if omitted)
# Creates: ~/.config/os-postinstall/defaults-backup-YYYY-MM-DD.txt
# Returns: 0 on success
#######################################
backup_current_defaults() {
    local data_file="${1:-}"
    local backup_dir="${_DEFAULTS_STATE_DIR}"
    local backup_file
    backup_file="${backup_dir}/defaults-backup-$(date +%Y-%m-%d).txt"

    # If backup already exists today, add timestamp
    if [[ -f "$backup_file" ]]; then
        backup_file="${backup_dir}/defaults-backup-$(date +%Y-%m-%d-%H%M%S).txt"
    fi

    # Load file if provided and arrays are empty
    if [[ -n "$data_file" && ${#DEFAULTS_DOMAINS[@]} -eq 0 ]]; then
        load_defaults_file "$data_file" || return 1
    fi

    if [[ ${#DEFAULTS_DOMAINS[@]} -eq 0 ]]; then
        _log_defaults_warn "No defaults loaded, nothing to backup"
        return 0
    fi

    # Ensure backup directory exists
    mkdir -p "$backup_dir" || {
        _log_defaults_error "Cannot create backup directory: $backup_dir"
        return 1
    }

    # Write backup atomically (temp file then mv)
    local tmp_file
    tmp_file=$(mktemp "${backup_dir}/defaults-backup.XXXXXX") || return 1

    {
        echo "# Defaults backup - $(date -Iseconds)"
        echo "# Format: domain|key|type|previous_value"
        echo "# Restore with: ./setup.sh defaults-restore <this-file>"
        echo ""
    } > "$tmp_file"

    local i
    for i in "${!DEFAULTS_DOMAINS[@]}"; do
        local domain="${DEFAULTS_DOMAINS[$i]}"
        local key="${DEFAULTS_KEYS[$i]}"
        local type="${DEFAULTS_TYPES[$i]}"
        local current
        current=$(get_current_default "$domain" "$key") || current="__UNSET__"

        echo "${domain}|${key}|${type}|${current}" >> "$tmp_file"
    done

    mv "$tmp_file" "$backup_file" || {
        _log_defaults_error "Failed to write backup: $backup_file"
        rm -f "$tmp_file"
        return 1
    }

    _log_defaults_info "Backup saved: $backup_file"
    echo "$backup_file"
    return 0
}

#######################################
# restore_defaults_from_backup()
# Apply a previously saved backup to restore original values
#
# Args: $1 = backup file path
# Returns: 0 on success, 1 on error
#######################################
restore_defaults_from_backup() {
    local backup_file="${1:-}"

    if [[ -z "$backup_file" ]]; then
        _log_defaults_error "restore_defaults_from_backup: no backup file specified"
        return 1
    fi

    if [[ ! -f "$backup_file" ]]; then
        _log_defaults_error "Backup file not found: $backup_file"
        return 1
    fi

    local restored=0 failed=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip comments and empty lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        local domain key type prev_value
        IFS='|' read -r domain key type prev_value <<< "$line"

        [[ -z "$domain" || -z "$key" || -z "$type" ]] && continue

        if [[ "$prev_value" == "__UNSET__" ]]; then
            # Key was not set before — delete it
            if [[ "${DRY_RUN:-}" == "true" ]]; then
                _log_defaults_info "[DRY_RUN] Would delete: ${domain} ${key}"
            else
                if defaults delete "$domain" "$key" 2>/dev/null; then
                    _log_defaults_ok "Deleted: ${domain} ${key}"
                    restored=$((restored + 1))
                else
                    _log_defaults_warn "Could not delete: ${domain} ${key}"
                    failed=$((failed + 1))
                fi
            fi
        else
            # Restore previous value
            if apply_default "$domain" "$key" "$type" "$prev_value"; then
                restored=$((restored + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done < "$backup_file"

    _log_defaults_info "Restore complete: ${restored} restored, ${failed} failed"
    [[ $failed -eq 0 ]]
}

#######################################
# list_backups()
# List available defaults backup files
# Echoes: one backup file path per line (newest first)
# Returns: 0 if backups found, 1 if none
#######################################
list_backups() {
    local backup_dir="${_DEFAULTS_STATE_DIR}"

    if [[ ! -d "$backup_dir" ]]; then
        return 1
    fi

    local found=0
    # Sort by modification time, newest first
    while IFS= read -r -d '' file; do
        echo "$file"
        found=1
    done < <(find "$backup_dir" -name 'defaults-backup-*.txt' -print0 2>/dev/null | sort -rz)

    [[ $found -eq 1 ]]
}

#######################################
# apply_all_defaults()
# Main entry point: load file, backup current, apply all, report
#
# Args: $1 = defaults data file (optional, defaults to macos-defaults.txt)
# Returns: 0 on full success, 1 on partial failure
#######################################
apply_all_defaults() {
    local data_file="${1:-macos-defaults.txt}"

    # Load defaults
    load_defaults_file "$data_file" || return 1

    if [[ ${#DEFAULTS_DOMAINS[@]} -eq 0 ]]; then
        _log_defaults_info "No defaults to apply"
        return 0
    fi

    _log_defaults_info "Applying ${#DEFAULTS_DOMAINS[@]} macOS system defaults..."

    # Backup current values (skip in DRY_RUN)
    if [[ "${DRY_RUN:-}" != "true" ]]; then
        backup_current_defaults || {
            _log_defaults_warn "Backup failed, continuing anyway..."
        }
    fi

    # Apply each default
    local applied=0 skipped=0 failed=0
    local i
    for i in "${!DEFAULTS_DOMAINS[@]}"; do
        if apply_default \
            "${DEFAULTS_DOMAINS[$i]}" \
            "${DEFAULTS_KEYS[$i]}" \
            "${DEFAULTS_TYPES[$i]}" \
            "${DEFAULTS_VALUES[$i]}"; then
            applied=$((applied + 1))
        else
            failed=$((failed + 1))
        fi
    done

    _log_defaults_info "Defaults complete: ${applied} applied, ${failed} failed"

    [[ $failed -eq 0 ]]
}

#######################################
# Export functions for subshells
#######################################
export -f load_defaults_file get_current_default apply_default
export -f backup_current_defaults restore_defaults_from_backup list_backups
export -f apply_all_defaults
export -f _log_defaults_error _log_defaults_warn _log_defaults_info _log_defaults_debug _log_defaults_ok
export _DEFAULTS_STATE_DIR
