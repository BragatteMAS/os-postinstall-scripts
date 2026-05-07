#!/usr/bin/env bash
#######################################
# Script: group-selector.sh
# Description: Interactive multi-select for cask groups (--groups mode).
#
# Reads groups from data/packages/groups/<name>.txt — each file is a list
# of brew cask names plus a leading "# <Group Name> — <description>" line
# used for the menu display.
#
# UI: prefers `gum choose --no-limit` when available (charmbracelet/gum,
# brew installable). Falls back to a numbered comma-separated prompt with
# pure bash if gum is missing.
#
# Author: Bragatte
# Date: 2026-05-06
#######################################

[[ -n "${_GROUP_SELECTOR_SOURCED:-}" ]] && return 0
readonly _GROUP_SELECTOR_SOURCED=1

# NOTE: Caller is expected to have logging.sh sourced.

#######################################
# _groups_dir() — locate data/packages/groups/
#######################################
_groups_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    printf '%s\n' "${script_dir}/../../data/packages/groups"
}

#######################################
# _group_description(name) — read first comment line as menu label.
# File format: "# <Group Name> — <description>"
#######################################
_group_description() {
    local file="$1"
    local first_comment
    first_comment=$(grep -m 1 "^# " "$file" 2>/dev/null | sed 's/^# //')
    printf '%s\n' "${first_comment:-$(basename "$file" .txt)}"
}

#######################################
# _group_list_packages(file) — emit non-comment, non-blank lines.
#######################################
_group_list_packages() {
    grep -v "^[[:space:]]*#" "$1" 2>/dev/null | grep -v "^[[:space:]]*$" || true
}

#######################################
# _ensure_gum() — try to install gum if missing. Falls through if install
# fails (caller will use bash fallback).
#######################################
_ensure_gum() {
    command -v gum &>/dev/null && return 0
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install gum for interactive selector"
        return 1
    fi
    if command -v brew &>/dev/null; then
        log_info "Installing gum (interactive selector backend)..."
        brew install gum &>/dev/null && return 0
    fi
    return 1
}

#######################################
# select_groups() — present multi-select; emit chosen group names on stdout.
# Args: $1 = absolute path to groups dir (default: data/packages/groups)
# Stdout: one group name per line (e.g. "browsers", "ai-editors")
# Stderr: UI rendering. Caller reads stdout: groups=$(select_groups)
# Returns: 0 on success (any selection, including empty)
#######################################
select_groups() {
    local dir="${1:-$(_groups_dir)}"
    local files=() names=() labels=()
    local f name label

    if [[ ! -d "$dir" ]]; then
        log_error "Groups directory not found: $dir" >&2
        return 1
    fi

    for f in "$dir"/*.txt; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .txt)
        label=$(_group_description "$f")
        files+=("$f")
        names+=("$name")
        labels+=("$label")
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        log_warn "No groups found in $dir" >&2
        return 0
    fi

    # Try gum first
    if _ensure_gum; then
        # gum choose returns chosen labels on stdout. We map back to group names.
        local chosen_labels chosen_label
        # shellcheck disable=SC2016
        chosen_labels=$(printf '%s\n' "${labels[@]}" | \
            gum choose --no-limit --header "Select cask groups to install (Space toggles, Enter confirms):")
        [[ -z "$chosen_labels" ]] && return 0
        while IFS= read -r chosen_label; do
            for ((i = 0; i < ${#labels[@]}; i++)); do
                if [[ "${labels[i]}" == "$chosen_label" ]]; then
                    printf '%s\n' "${names[i]}"
                    break
                fi
            done
        done <<<"$chosen_labels"
        return 0
    fi

    # Bash fallback — numbered menu, comma-separated input.
    {
        echo
        echo "Available cask groups:"
        for ((i = 0; i < ${#labels[@]}; i++)); do
            printf '  %2d) %-15s %s\n' "$((i + 1))" "${names[i]}" "${labels[i]#* — }"
        done
        echo
    } >&2

    local input
    read -r -p "Enter group numbers (comma-separated, e.g. 1,3,5), 'all', or 'none' [default=none]: " input >&2

    case "$input" in
        ""|none|skip) return 0 ;;
        all)
            printf '%s\n' "${names[@]}"
            return 0
            ;;
    esac

    # Parse comma/space-separated numbers
    local n
    for n in ${input//,/ }; do
        if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#names[@]} )); then
            printf '%s\n' "${names[n - 1]}"
        else
            log_warn "Ignoring invalid input: '$n'" >&2
        fi
    done
}

#######################################
# install_groups(group_names...) — install casks from each named group.
# Args: positional list of group names
# Side effects: brew install --cask for each package not already installed.
# Honours DRY_RUN. Records failures via record_failure() if available.
# Returns: 0 always (continues on per-package failure)
#######################################
install_groups() {
    local dir
    dir=$(_groups_dir)
    local group file pkg installed=0 skipped=0 failed=0

    for group in "$@"; do
        file="${dir}/${group}.txt"
        if [[ ! -f "$file" ]]; then
            log_warn "Group not found: $group (no $file)"
            continue
        fi

        log_info "Installing group: $group"
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue

            if brew list --cask "$pkg" &>/dev/null; then
                log_info "[skip] $pkg (already installed)"
                skipped=$((skipped + 1))
                continue
            fi

            if [[ "${DRY_RUN:-}" == "true" ]]; then
                log_info "[DRY_RUN] Would install cask: $pkg"
                installed=$((installed + 1))
                continue
            fi

            log_info "Installing: $pkg"
            local err_buf rc=0
            err_buf=$(HOMEBREW_NO_INSTALL_UPGRADE=1 brew install --cask "$pkg" 2>&1 >/dev/null) || rc=$?

            if [[ -n "${BREW_LOG:-}" ]]; then
                {
                    echo "=== brew install --cask $pkg (rc=$rc, group=$group) ==="
                    [[ -n "$err_buf" ]] && echo "$err_buf"
                } >> "$BREW_LOG" 2>/dev/null
            fi

            if (( rc == 0 )); then
                log_ok "Installed: $pkg"
                installed=$((installed + 1))
            else
                log_error "Failed to install: $pkg (group=$group, rc=$rc)"
                failed=$((failed + 1))
                type record_failure &>/dev/null && record_failure "$pkg (group:$group)"
            fi
        done < <(_group_list_packages "$file")
    done

    log_info "Groups summary: $installed installed, $skipped skipped, $failed failed"
    return 0
}

# Export for subshells
export -f select_groups install_groups
