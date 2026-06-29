#!/usr/bin/env bash
#######################################
# Script: wizard.sh
# Description: Interactive profile selector for setup.sh
# Used when: no profile arg + TTY available + not --unattended
# Author: Bragatte
# Date: 2026-05-04
#######################################

# Prevent multiple sourcing
[[ -n "${_WIZARD_SOURCED:-}" ]] && return 0
readonly _WIZARD_SOURCED=1

# NOTE: No set -e (per project decision — continue on failure)

# Try to source dependencies if running standalone (defensive — usually setup.sh sources them first)
if ! type log_info >/dev/null 2>&1; then
    _WIZARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "${_WIZARD_DIR}/logging.sh" ]] && source "${_WIZARD_DIR}/logging.sh"
    [[ -f "${_WIZARD_DIR}/progress.sh" ]] && source "${_WIZARD_DIR}/progress.sh"
    unset _WIZARD_DIR
fi

# prompt_default() lives in prompt.sh — pull it if a caller didn't source it.
if ! type prompt_default >/dev/null 2>&1; then
    _WIZARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "${_WIZARD_DIR}/prompt.sh" ]] && source "${_WIZARD_DIR}/prompt.sh"
    unset _WIZARD_DIR
fi

#######################################
# preview_profile_packages()
# List what a profile would install — its package groups and CSV categories —
# read straight from the profile manifest. Output goes to STDERR (the menu's
# return value stays on STDOUT). Read-only: no changes are made.
#
# Self-contained on purpose: select_profile_interactive runs inside a
# command-substitution subshell, so toggling DRY_RUN here could not reach the
# parent shell that performs the install. Listing the manifest sidesteps that.
#
# Args: $1 = profile (minimal|developer|full), $2 = platform
#######################################
preview_profile_packages() {
    local profile="$1" platform="$2"
    local profile_file="${DATA_DIR:-}/packages/profiles/${profile}.txt"
    local count line
    count=$(count_packages_in_profile "$profile" "$platform" 2>/dev/null || echo "?")

    echo "" >&2
    echo "── Preview: ${profile} (~${count} packages on ${platform}) ──" >&2
    if [[ -n "${DATA_DIR:-}" && -f "$profile_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"   # left-trim
            [[ -z "$line" || "$line" == \#* ]] && continue
            if [[ "$line" == csv:* ]]; then
                echo "    • CSV category: ${line#csv:}" >&2
            else
                echo "    • package group: ${line}" >&2
            fi
        done < "$profile_file"
    else
        echo "    (package manifest unavailable — DATA_DIR not set)" >&2
    fi
    echo "    No changes made — preview only." >&2
    echo "" >&2
}

#######################################
# select_profile_interactive()
# Show profile menu with live package counts and time estimates.
# Confirmation step supports "back" to re-pick.
# Usage: profile=$(select_profile_interactive "$DETECTED_OS") || exit 0
# Args:  $1 = platform (linux|macos|windows)
# Echoes: selected profile name (minimal|developer|full) on success
# Returns: 0 on selection, 1 on cancel/quit
#######################################
select_profile_interactive() {
    local platform="${1:-}"
    local choice profile confirm pkg_count
    local p

    # NOTE: All UI output is redirected to stderr (>&2) because callers use
    # command substitution: profile=$(select_profile_interactive ...).
    # Only the final selected profile name is echoed to stdout — that is the
    # function's return value. Without this, the menu would be swallowed by $().
    while true; do
        echo "" >&2
        echo "Choose installation profile:" >&2
        echo "" >&2

        for p in minimal developer full; do
            pkg_count=$(count_packages_in_profile "$p" "$platform" 2>/dev/null || echo "?")
            case "$p" in
                minimal)
                    printf "  1) %-12s ~5 min,  %s packages\n" "minimal" "$pkg_count" >&2
                    echo   "                Modern Rust CLI baseline only (bat, eza, rg, fd, zoxide, delta + 14 more)" >&2
                    ;;
                developer)
                    printf "  2) %-12s ~15 min, %s packages  (default)\n" "developer" "$pkg_count" >&2
                    echo   "                Neutral dev env: editors, Docker/OrbStack, browsers (Firefox+Chromium)," >&2
                    echo   "                Rust dev tools, GUI apps defensible to most devs" >&2
                    ;;
                full)
                    printf "  3) %-12s ~30 min, %s packages\n" "full" "$pkg_count" >&2
                    echo   "                developer + curator's pick (Chrome, Zen, Cursor, Claude, ChatGPT," >&2
                    echo   "                AI/MCP tools, design apps) — opinionated" >&2
                    ;;
            esac
            echo "" >&2
        done
        echo "  p) preview a profile's package list (no changes)" >&2
        echo "  c) cancel and exit" >&2
        echo "" >&2
        echo "  Tip: add --dry-run to preview the full install; type 'h' after setup for help." >&2
        echo "" >&2

        choice=$(prompt_default "Choice" "2" "1/2/3/p/c")

        case "$choice" in
            1|min|minimal)               profile="minimal" ;;
            2|dev|developer|"")          profile="developer" ;;
            3|full)                      profile="full" ;;
            p|P|preview)
                local preview_pick
                preview_pick=$(prompt_default "Preview which profile?" "2" "1/2/3")
                case "$preview_pick" in
                    1|min|minimal) preview_profile_packages "minimal" "$platform" ;;
                    3|full)        preview_profile_packages "full" "$platform" ;;
                    *)             preview_profile_packages "developer" "$platform" ;;
                esac
                continue
                ;;
            c|C|cancel|q|Q|quit|exit|x|X) return 1 ;;
            *)
                echo "" >&2
                echo "Invalid choice: '${choice}' — try 1, 2, 3, p, or c (or run with --help)." >&2
                continue
                ;;
        esac

        # Confirmation step (with back option)
        pkg_count=$(count_packages_in_profile "$profile" "$platform" 2>/dev/null || echo "?")
        echo "" >&2
        printf "Selected: %s (~%s packages on %s)\n" "$profile" "$pkg_count" "$platform" >&2
        if [[ "${DRY_RUN:-}" == "true" ]]; then
            echo "Mode: DRY-RUN — no changes will be made, only preview" >&2
        fi
        echo "" >&2
        confirm=$(prompt_default "Proceed?" "Y" "Y/n/b=back")

        case "$confirm" in
            [yY]*|yes)        echo "$profile"; return 0 ;;
            [bB]*|back)       continue ;;       # loop back to menu
            [nN]*|no|cancel)  return 1 ;;
            *)                echo "$profile"; return 0 ;;
        esac
    done
}

# Export for subshells (parallel to interactive.sh / progress.sh)
export -f select_profile_interactive preview_profile_packages
