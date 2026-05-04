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
        echo "  c) cancel and exit" >&2
        echo "" >&2

        read -r -p "Choice [1/2/3/c, default=2]: " choice
        choice="${choice:-2}"

        case "$choice" in
            1|min|minimal)               profile="minimal" ;;
            2|dev|developer|"")          profile="developer" ;;
            3|full)                      profile="full" ;;
            c|C|cancel|q|Q|quit|exit|x|X) return 1 ;;
            *)
                echo "" >&2
                echo "Invalid choice: '${choice}' — try 1, 2, 3, or c." >&2
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
        read -r -p "Proceed? [Y/n/b=back]: " confirm
        confirm="${confirm:-Y}"

        case "$confirm" in
            [yY]*|yes)        echo "$profile"; return 0 ;;
            [bB]*|back)       continue ;;       # loop back to menu
            [nN]*|no|cancel)  return 1 ;;
            *)                echo "$profile"; return 0 ;;
        esac
    done
}

# Export for subshells (parallel to interactive.sh / progress.sh)
export -f select_profile_interactive
