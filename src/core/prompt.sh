#!/usr/bin/env bash
#######################################
# Script: prompt.sh
# Description: Single source of truth for interactive prompts that carry a
#   default. The visible hint is RENDERED from the default value, so a prompt
#   can never advertise a different default than the one it actually uses —
#   the bug class fixed piecemeal across v5.4.0 / v5.4.4 / v5.4.6
#   (show_category_menu, ask_tool, detect_previous_install,
#   offer_ollama_model, select_profile_interactive).
#
# Cross-OS contract (PowerShell sibling Prompt-Default mirrors this):
#   - Visible prompt always reads:  <text> [<keys>, default=<default>]:
#     with a timeout it widens to:  <text> [<keys>, default=<default>, <N>s]:
#   - <default> is BOTH displayed and returned — they cannot diverge.
#   - NONINTERACTIVE=true, empty input, and timeout all resolve to <default>.
#   - The unattended auto-pick logs "Auto-selected: <default>" to STDERR.
#   - ONLY the resolved value is written to STDOUT, so value=$(prompt_default ...)
#     is safe (logging.sh writes to stdout — callers must not capture it).
#   - Always returns 0; callers branch on the echoed value.
#
# Author: Bragatte
# Date: 2026-06-07
#######################################

# Prevent multiple sourcing
[[ -n "${_PROMPT_SOURCED:-}" ]] && return 0
readonly _PROMPT_SOURCED=1

# NOTE: No set -e (per project decision — continue on failure)

# Defensive: prompt.sh needs logging only for the unattended notice.
if ! type log_info >/dev/null 2>&1; then
    _PROMPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "${_PROMPT_DIR}/logging.sh" ]] && source "${_PROMPT_DIR}/logging.sh"
    unset _PROMPT_DIR
fi

#######################################
# prompt_default()
# Read one choice, rendering a hint that cannot lie about the default.
#
# Args: $1 = prompt text (NO trailing hint — it is rendered here)
#       $2 = default value (displayed AND returned on empty/timeout/unattended)
#       $3 = keys label shown in brackets (e.g. "1-4", "1/2/3/c", "Y/n"); optional
#       $4 = timeout in seconds (optional; empty/0/non-numeric = no timeout)
# Stdout: the resolved choice — and nothing else
# Stderr: the prompt and any auto-select / timeout notice
# Returns: 0
#######################################
prompt_default() {
    local text="$1" default="$2" keys="${3:-}" timeout="${4:-}"
    local hint answer has_timeout=0

    [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )) && has_timeout=1

    # Render the hint FROM the default so display and behaviour stay in lockstep.
    if [[ -n "$keys" ]]; then
        hint="[${keys}, default=${default}"
    else
        hint="[default=${default}"
    fi
    (( has_timeout )) && hint="${hint}, ${timeout}s"
    hint="${hint}]"

    # Unattended: take the default, announce on stderr (stdout stays clean).
    if [[ "${NONINTERACTIVE:-}" == "true" ]]; then
        log_info "Auto-selected: ${default}" >&2
        printf '%s\n' "$default"
        return 0
    fi

    # read -p writes the prompt to stderr, so it is safe under command substitution.
    if (( has_timeout )); then
        if ! read -r -t "$timeout" -p "${text} ${hint}: " answer; then
            printf '\n' >&2
            log_warn "Timeout — using default: ${default}" >&2
            printf '%s\n' "$default"
            return 0
        fi
    else
        read -r -p "${text} ${hint}: " answer
    fi

    printf '%s\n' "${answer:-$default}"
    return 0
}

export -f prompt_default
