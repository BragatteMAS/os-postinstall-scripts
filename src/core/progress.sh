#!/usr/bin/env bash
#######################################
# Script: progress.sh
# Description: Step counter helpers and DRY_RUN banner for UX feedback
# Author: Bragatte
# Date: 2026-02-07
#######################################

# Prevent multiple sourcing
[[ -n "${_PROGRESS_SOURCED:-}" ]] && return 0
readonly _PROGRESS_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Source logging module for output
#######################################
# shellcheck source=logging.sh
if [[ -z "${_LOGGING_SOURCED:-}" ]]; then
    _PROGRESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${_PROGRESS_DIR}/logging.sh" ]]; then
        source "${_PROGRESS_DIR}/logging.sh"
    fi
fi

#######################################
# show_dry_run_banner()
# Display a prominent banner when DRY_RUN=true
# Does nothing if DRY_RUN is not "true"
#######################################
show_dry_run_banner() {
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_warn "========================================="
        log_warn "  DRY RUN MODE - No changes will be made"
        log_warn "========================================="
    fi
    return 0
}

#######################################
# count_platform_steps()
# Count how many package files in a profile are relevant to the given platform
# Args: $1 = profile_file path, $2 = platform ("linux" or "macos")
# Echoes: integer count to stdout
# Usage: total=$(count_platform_steps "$profile_file" "linux")
#######################################
count_platform_steps() {
    local profile_file="$1"
    local platform="$2"
    local count=0

    if [[ ! -f "$profile_file" ]]; then
        echo "0"
        return 0
    fi

    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        # Trim leading whitespace
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"

        # Skip comments and empty lines
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        # Filter by platform relevance
        case "$platform" in
            linux)
                case "$pkg_file" in
                    apt.txt|apt-post.txt)          count=$((count + 1)) ;;
                    flatpak.txt|flatpak-post.txt)  count=$((count + 1)) ;;
                    snap.txt|snap-post.txt)        count=$((count + 1)) ;;
                    cargo.txt)                     count=$((count + 1)) ;;
                    ai-tools.txt)                  count=$((count + 1)) ;;
                esac
                ;;
            macos)
                case "$pkg_file" in
                    brew.txt)       count=$((count + 1)) ;;
                    brew-cask.txt)  count=$((count + 1)) ;;
                    cargo.txt)      count=$((count + 1)) ;;
                    ai-tools.txt)   count=$((count + 1)) ;;
                esac
                ;;
        esac
    done < "$profile_file"

    echo "$count"
    return 0
}

#######################################
# Export functions for subshells
#######################################
export -f show_dry_run_banner count_platform_steps
