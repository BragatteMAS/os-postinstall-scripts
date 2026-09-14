#!/usr/bin/env bash
#######################################
# Script: brew-taps.sh
# Description: Make third-party taps usable before installing from them.
#   Homebrew >= 7 refuses formulae/casks from taps the user has not trusted and
#   skips them with a warning while the run still looks successful
#   (PITFALLS 12.8, fresh M5 2026-09-14). Sourced by brew.sh and brew-cask.sh
#   right after load_packages: PACKAGES[@] is scanned for tap-qualified names.
# Author: Bragatte
# Date: 2026-09-14
#######################################

# brew_taps_in_packages - print each "user/repo" tap referenced by PACKAGES[@] once
# A tap-qualified entry looks like user/repo/name; anything else is ignored.
brew_taps_in_packages() {
    local pkg tap seen=" "
    for pkg in "${PACKAGES[@]}"; do
        [[ "$pkg" == */*/* ]] || continue
        tap="${pkg%/*}"
        [[ "$seen" == *" $tap "* ]] && continue
        seen+="$tap "
        printf '%s\n' "$tap"
    done
}

# ensure_brew_taps - brew tap + brew trust --tap every tap in PACKAGES[@]
# Idempotent. A failure is recorded (tap:<name> / trust:<name>) but does not
# abort the wave: the per-package install then fails loudly with the
# "tap not trusted" reason instead of being skipped in silence.
ensure_brew_taps() {
    local tap tapped
    local -a taps=()
    while IFS= read -r tap; do
        [[ -n "$tap" ]] && taps+=("$tap")
    done < <(brew_taps_in_packages)
    (( ${#taps[@]} == 0 )) && return 0

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would tap + trust: ${taps[*]}"
        return 0
    fi

    tapped=$(brew tap 2>/dev/null || true)
    for tap in "${taps[@]}"; do
        if ! grep -qx "$tap" <<<"$tapped"; then
            log_info "Tapping $tap..."
            if ! brew tap "$tap" >/dev/null 2>&1; then
                log_warn "brew tap $tap failed — its packages will not install"
                record_failure "tap:$tap"
                continue
            fi
        fi
        # `brew trust` exists from Homebrew 7; older versions load taps freely.
        if brew trust --help >/dev/null 2>&1; then
            if brew trust --tap "$tap" >/dev/null 2>&1; then
                log_ok "Trusted tap: $tap"
            else
                log_warn "brew trust --tap $tap failed — Homebrew will ignore its packages"
                record_failure "trust:$tap"
            fi
        fi
    done
    return 0
}
