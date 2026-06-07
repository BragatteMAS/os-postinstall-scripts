#!/usr/bin/env bash
#######################################
# Script: interactive.sh
# Description: Shared interactive selection functions for cross-platform installers
# Author: Bragatte
# Date: 2026-02-06
#######################################

# Prevent multiple sourcing
[[ -n "${_INTERACTIVE_SOURCED:-}" ]] && return 0
readonly _INTERACTIVE_SOURCED=1

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

#######################################
# Source logging module for output
#######################################
# shellcheck source=logging.sh
if [[ -z "${_LOGGING_SOURCED:-}" ]]; then
    # Try to source from same directory
    _INTERACTIVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${_INTERACTIVE_DIR}/logging.sh" ]]; then
        source "${_INTERACTIVE_DIR}/logging.sh"
    fi
    unset _INTERACTIVE_DIR
fi

# prompt_default() lives in prompt.sh — pull it if a caller didn't source it.
if ! type prompt_default >/dev/null 2>&1; then
    _INTERACTIVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "${_INTERACTIVE_DIR}/prompt.sh" ]] && source "${_INTERACTIVE_DIR}/prompt.sh"
    unset _INTERACTIVE_DIR
fi

#######################################
# show_category_menu()
# Interactive menu for category-level install selection
#
# Args: $1 = category name, $2 = description
# Returns: 0 = install all, 1 = choose individually, 2 = skip
#######################################
show_category_menu() {
    local category="${1:-Tools}"
    local description="${2:-}"

    # Non-interactive mode: install all (matches profile intent)
    if [[ "${NONINTERACTIVE:-}" == "true" || ! -t 0 ]]; then
        return 0
    fi

    echo ""
    echo "Install ${category}? (${description})"
    echo "  1) All  (recommended — matches profile)"
    echo "  2) Choose individually"
    echo "  3) Skip this category"
    local choice
    # Default 1 (All) so a timeout follows the profile the user picked.
    # Previously this defaulted to 3 (Skip) which silently un-did dev-env
    # for users who took longer than 30s to read the menu.
    choice=$(prompt_default "Select" "1" "1-3" 30)

    case "$choice" in
        1) return 0 ;;
        2) return 1 ;;
        3) return 2 ;;
        *) log_warn "Invalid choice '${choice}' — installing all (default)"
           return 0 ;;
    esac
}

#######################################
# ask_tool()
# Ask whether to install a single tool
#
# Args: $1 = tool name
# Returns: 0 = yes (install), 1 = no (skip)
#######################################
ask_tool() {
    local tool="${1:-tool}"

    # Non-interactive mode: install
    if [[ "${NONINTERACTIVE:-}" == "true" || ! -t 0 ]]; then
        return 0
    fi

    local answer
    # Default "y" matches the [Y/n] prompt convention (capital = default).
    # Previously the prompt said [Y/n] but the actual default on timeout was
    # "n" — UX bug (the user expected Enter to mean "yes install").
    answer=$(prompt_default "Install ${tool}?" "y" "Y/n" 30)

    case "$answer" in
        [nN]*) return 1 ;;
        *)     return 0 ;;
    esac
}

#######################################
# Export functions for subshells
#######################################
export -f show_category_menu ask_tool
