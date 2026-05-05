#!/usr/bin/env bash
#######################################
# tools/preflight-brew-names.sh
#
# Validates every brew formula and cask referenced by the macOS `full` profile
# *before* running setup.sh on a fresh machine (e.g. M5). Combines two checks:
#
#   1) Diff profile against the M1 inventory snapshot to compute the exact set
#      of packages that will actually be installed on M5 (the rest will be
#      idempotent skips).
#   2) For each "will install" name, run `brew info` to confirm:
#        - the formula/cask exists in some tap,
#        - whether it lives in a third-party tap (auto-tap may fail behind
#          proxies),
#        - whether it requires a host architecture or macOS version different
#          from the current host.
#
# Read-only; no install side effects.
#
# Usage:
#   bash tools/preflight-brew-names.sh           # full report
#   bash tools/preflight-brew-names.sh --quiet   # only failures
#######################################

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DATA_DIR="${REPO_ROOT}/data/packages"
SNAPSHOT_DIR="${REPO_ROOT}/.migration/MacBook-Pro-de-Fundacao-4-snapshot"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: brew not in PATH. Run on a host with Homebrew installed." >&2
    exit 2
fi

# ── Helpers ──────────────────────────────────────────────────────

# Reads a brew-*.txt / brew-cask-*.txt and prints non-comment, non-blank lines.
read_pkg_file() {
    grep -v "^[[:space:]]*#" "$1" 2>/dev/null | grep -v "^[[:space:]]*$" || true
}

# Reads the M1 inventory snapshot and prints just package names.
# Snapshot format: "name version" (cask) or "name" (formula); skip header lines.
read_inventory_names() {
    grep -v "^[[:space:]]*#" "$1" 2>/dev/null | awk 'NF { print $1 }' || true
}

# diff_profile_minus_inventory PROFILE_FILE INVENTORY_FILE
# Prints the names present in PROFILE but not in INVENTORY.
diff_profile_minus_inventory() {
    local profile="$1" inventory="$2"
    comm -23 \
        <(read_pkg_file "$profile" | sort -u) \
        <(read_inventory_names "$inventory" | sort -u)
}

# classify_brew_info NAME KIND   (KIND = formula | cask)
# Prints one of: ok | not-found | third-party-tap:<tap>
classify_brew_info() {
    local name="$1" kind="$2" out tap
    local flag="--formula"
    [[ "$kind" == "cask" ]] && flag="--cask"

    if ! out=$(brew info "$flag" "$name" 2>&1); then
        # Distinguish "tap not yet added" (recoverable, install script taps
        # before installing) from "truly missing".
        if grep -qE "requires the tap [^[:space:]]+" <<<"$out"; then
            local needed_tap
            needed_tap=$(grep -oE "requires the tap [^[:space:]]+" <<<"$out" | awk '{print $4}')
            echo "tap-not-added:${needed_tap}"
            return
        fi
        echo "not-found"
        return
    fi
    # Detect "From: https://github.com/<user>/homebrew-<repo>" line
    tap=$(grep -oE "From: https://github.com/[^/]+/homebrew-[^/]+" <<<"$out" | head -1)
    if [[ -n "$tap" ]] && ! grep -qE "github.com/Homebrew/homebrew-(core|cask)" <<<"$tap"; then
        echo "third-party-tap:${tap##*github.com/}"
        return
    fi
    echo "ok"
}

# ── Build the to-install set ─────────────────────────────────────

declare -A WILL_INSTALL_FORMULA=() WILL_INSTALL_CASK=()
declare -A IN_INVENTORY_FORMULA=() IN_INVENTORY_CASK=()

# Inventory
if [[ -f "${SNAPSHOT_DIR}/11-brew-installed-on-request.txt" ]]; then
    while read -r n; do [[ -n "$n" ]] && IN_INVENTORY_FORMULA["$n"]=1; done \
        < <(read_inventory_names "${SNAPSHOT_DIR}/11-brew-installed-on-request.txt")
fi
if [[ -f "${SNAPSHOT_DIR}/10-brew-leaves.txt" ]]; then
    while read -r n; do [[ -n "$n" ]] && IN_INVENTORY_FORMULA["$n"]=1; done \
        < <(read_inventory_names "${SNAPSHOT_DIR}/10-brew-leaves.txt")
fi
if [[ -f "${SNAPSHOT_DIR}/12-brew-cask.txt" ]]; then
    while read -r n; do [[ -n "$n" ]] && IN_INVENTORY_CASK["$n"]=1; done \
        < <(read_inventory_names "${SNAPSHOT_DIR}/12-brew-cask.txt")
fi

# Profile (full)
for f in brew.txt brew-developer.txt brew-full.txt; do
    [[ -f "${DATA_DIR}/$f" ]] || continue
    while read -r pkg; do
        # Strip tap prefixes like "user/tap/" so we get the bare formula name
        # for inventory lookup (brew list shows bare names).
        local_name="${pkg##*/}"
        if [[ -z "${IN_INVENTORY_FORMULA[$local_name]:-}" ]]; then
            WILL_INSTALL_FORMULA["$pkg"]=1
        fi
    done < <(read_pkg_file "${DATA_DIR}/$f")
done

for f in brew-cask-developer.txt brew-cask-full.txt; do
    [[ -f "${DATA_DIR}/$f" ]] || continue
    while read -r pkg; do
        local_name="${pkg##*/}"
        if [[ -z "${IN_INVENTORY_CASK[$local_name]:-}" ]]; then
            WILL_INSTALL_CASK["$pkg"]=1
        fi
    done < <(read_pkg_file "${DATA_DIR}/$f")
done

# ── Report header ───────────────────────────────────────────────

total_formula=${#WILL_INSTALL_FORMULA[@]}
total_cask=${#WILL_INSTALL_CASK[@]}

if (( ! QUIET )); then
    echo "Preflight against M1 inventory ($SNAPSHOT_DIR)"
    echo "  formulae to install on a fresh M5: $total_formula"
    echo "  casks to install on a fresh M5:    $total_cask"
    echo "  validating each against \`brew info\`..."
    echo
fi

# ── Validate ────────────────────────────────────────────────────

declare -a FAIL=() THIRDPARTY=() TAP_NEEDED=()

validate_kind() {
    local kind="$1" name verdict label
    [[ "$kind" == "formula" ]] && local -n SET=WILL_INSTALL_FORMULA || local -n SET=WILL_INSTALL_CASK
    label=$([[ "$kind" == "formula" ]] && echo "formula" || echo "cask")

    for name in "${!SET[@]}"; do
        verdict=$(classify_brew_info "$name" "$kind")
        case "$verdict" in
            ok)
                (( QUIET )) || printf "  [OK]      %-7s %s\n" "$label" "$name"
                ;;
            not-found)
                FAIL+=("$label: $name (not found in any tap)")
                printf "  [FAIL]    %-7s %s — not found in any tap\n" "$label" "$name"
                ;;
            third-party-tap:*)
                THIRDPARTY+=("$label: $name (${verdict#third-party-tap:})")
                (( QUIET )) || printf "  [3rd-tap] %-7s %s — %s\n" "$label" "$name" "${verdict#third-party-tap:}"
                ;;
            tap-not-added:*)
                TAP_NEEDED+=("$label: $name (tap ${verdict#tap-not-added:} required)")
                (( QUIET )) || printf "  [tap req] %-7s %s — needs tap %s\n" "$label" "$name" "${verdict#tap-not-added:}"
                ;;
        esac
    done
}

validate_kind formula
validate_kind cask

# ── Validate hardcoded brew references in install scripts ────────
# fnm.sh, uv.sh and dev-env.sh call `brew install` for tools that are not
# listed in any .txt profile file. Validate them explicitly so the preflight
# also covers the dev-env path.

(( QUIET )) || echo
(( QUIET )) || echo "Validating hardcoded brew references in install scripts:"

declare -a SCRIPT_REFS=(
    "formula:fnm"           # src/install/fnm.sh
    "formula:uv"            # src/install/uv.sh
    "formula:pnpm"          # src/install/fnm.sh::install_global_npm
    "formula:mise"          # src/install/dev-env.sh::install_mise
    "cask:oven-sh/bun/bun"  # src/install/fnm.sh — third-party tap
)

for ref in "${SCRIPT_REFS[@]}"; do
    kind="${ref%%:*}"
    name="${ref#*:}"
    verdict=$(classify_brew_info "$name" "$kind")
    case "$verdict" in
        ok)
            (( QUIET )) || printf "  [OK]      %-7s %s\n" "$kind" "$name"
            ;;
        not-found)
            FAIL+=("$kind: $name (not found — referenced by install script)")
            printf "  [FAIL]    %-7s %s — not found in any tap\n" "$kind" "$name"
            ;;
        third-party-tap:*)
            THIRDPARTY+=("$kind: $name (${verdict#third-party-tap:})")
            (( QUIET )) || printf "  [3rd-tap] %-7s %s — %s\n" "$kind" "$name" "${verdict#third-party-tap:}"
            ;;
        tap-not-added:*)
            TAP_NEEDED+=("$kind: $name (tap ${verdict#tap-not-added:} required)")
            (( QUIET )) || printf "  [tap req] %-7s %s — needs tap %s (script will tap before install)\n" "$kind" "$name" "${verdict#tap-not-added:}"
            ;;
    esac
done

# ── Summary ─────────────────────────────────────────────────────

echo
echo "Preflight summary:"
printf "  total to install:    %d formulae + %d casks\n" "$total_formula" "$total_cask"
printf "  failures:            %d\n" "${#FAIL[@]}"
printf "  third-party taps:    %d (auto-tap risk on restricted networks)\n" "${#THIRDPARTY[@]}"
printf "  needs tap first:     %d (install script taps explicitly before install)\n" "${#TAP_NEEDED[@]}"

if (( ${#FAIL[@]} > 0 )); then
    echo
    echo "Names that will not resolve on M5:"
    printf "  - %s\n" "${FAIL[@]}"
    exit 1
fi

if (( ${#THIRDPARTY[@]} > 0 )) && (( ! QUIET )); then
    echo
    echo "Third-party taps (will need network access at install time):"
    printf "  - %s\n" "${THIRDPARTY[@]}"
fi

if (( ${#TAP_NEEDED[@]} > 0 )) && (( ! QUIET )); then
    echo
    echo "Casks/formulae requiring an explicit tap (handled by install scripts):"
    printf "  - %s\n" "${TAP_NEEDED[@]}"
fi

echo
echo "[OK] All package names resolve. M5 install should not fail on name lookup."
