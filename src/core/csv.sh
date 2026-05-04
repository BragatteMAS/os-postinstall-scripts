#!/usr/bin/env bash
#######################################
# Script: csv.sh
# Description: Install Rust tools from data/packages.csv (Onda 5 pilot).
#              Sourced by macos/main.sh and linux/main.sh.
# Author: Bragatte
# Date: 2026-05-04
#######################################

# Prevent multiple sourcing
[[ -n "${_CSV_SOURCED:-}" ]] && return 0
readonly _CSV_SOURCED=1

# NOTE: No set -e (per Phase 1 decision)

#######################################
# read_csv_category(category, csv_file)
# Emit pipe-separated rows for a given category, skipping headers and comments.
# Output: name|brew|cargo|binary|prefer|description
#######################################
read_csv_category() {
    local category="$1" csv_file="$2"
    [[ -f "$csv_file" ]] || return 1
    LC_ALL=C awk -F',' -v cat="$category" '
        /^#/ { next }
        NR==1 || $1=="category" { next }
        $1 == cat {
            printf "%s|%s|%s|%s|%s|%s\n", $2, $3, $4, $5, $6, $7
        }
    ' "$csv_file"
}

#######################################
# _csv_install_brew(pkg) — internal
#######################################
_csv_install_brew() {
    local pkg="$1"
    [[ -z "$pkg" ]] && return 1
    if brew list "$pkg" &>/dev/null; then
        return 0
    fi
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would brew install: $pkg"
        return 0
    fi
    HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "$pkg" 2>/dev/null
}

#######################################
# _csv_install_cargo(pkg) — internal
# Uses cargo-binstall when available, fallback to cargo install.
#######################################
_csv_install_cargo() {
    local pkg="$1"
    [[ -z "$pkg" ]] && return 1
    if cargo install --list 2>/dev/null | grep -q "^$pkg "; then
        return 0
    fi
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would cargo install: $pkg"
        return 0
    fi
    if ! command -v cargo &>/dev/null; then
        log_warn "cargo not available — cannot install $pkg via cargo"
        return 1
    fi
    if command -v cargo-binstall &>/dev/null; then
        cargo binstall -y --no-confirm "$pkg" 2>/dev/null && return 0
    fi
    cargo install "$pkg" 2>/dev/null
}

#######################################
# install_csv_category(category)
# Install all entries of a CSV category respecting prefer + idempotent guard.
# Requires: ${DATA_DIR} or ${PROJECT_ROOT}/data set.
#######################################
install_csv_category() {
    local category="$1"
    local csv_file="${DATA_DIR:-${PROJECT_ROOT}/data}/packages.csv"

    if [[ ! -f "$csv_file" ]]; then
        log_warn "CSV not found: $csv_file (csv:$category skipped)"
        return 1
    fi

    local total=0 installed=0 failed=0
    while IFS='|' read -r name brew_pkg cargo_pkg binary prefer description; do
        [[ -z "$name" ]] && continue
        total=$((total + 1))
        local bin="${binary:-$name}"

        # Idempotent: skip if binary already in PATH
        if command -v "$bin" >/dev/null 2>&1; then
            log_debug "Already in PATH: $bin (csv:$category/$name)"
            installed=$((installed + 1))
            continue
        fi

        log_info "Installing $name (csv:$category, prefer=$prefer)"

        local ok=1
        case "$prefer" in
            brew)
                if [[ -n "$brew_pkg" ]] && _csv_install_brew "$brew_pkg"; then
                    ok=0
                elif [[ -n "$cargo_pkg" ]] && _csv_install_cargo "$cargo_pkg"; then
                    ok=0
                fi
                ;;
            cargo)
                if [[ -n "$cargo_pkg" ]] && _csv_install_cargo "$cargo_pkg"; then
                    ok=0
                elif [[ -n "$brew_pkg" ]] && _csv_install_brew "$brew_pkg"; then
                    ok=0
                fi
                ;;
            *)
                # default: try brew first, cargo fallback
                if [[ -n "$brew_pkg" ]] && _csv_install_brew "$brew_pkg"; then
                    ok=0
                elif [[ -n "$cargo_pkg" ]] && _csv_install_cargo "$cargo_pkg"; then
                    ok=0
                fi
                ;;
        esac

        if [[ "$ok" -eq 0 ]]; then
            log_ok "Installed: $name"
            installed=$((installed + 1))
        else
            log_warn "Failed: $name"
            failed=$((failed + 1))
            type record_failure &>/dev/null && record_failure "$name (csv:$category)"
        fi
    done < <(read_csv_category "$category" "$csv_file")

    log_info "csv:$category — $installed installed, $failed failed (total $total)"
    return $((failed > 0 ? 1 : 0))
}

# Export for subshells
export -f read_csv_category _csv_install_brew _csv_install_cargo install_csv_category 2>/dev/null || true
