#!/usr/bin/env bash
#######################################
# tools/preflight-brew-names.sh
#
# Validates every brew/cask/npm/PyPI name referenced by the macOS `full`
# profile *before* running setup.sh on a fresh machine. Combines:
#
#   1) Diff macOS `full` profile against the M1 inventory snapshot to
#      compute the exact set of items that will actually run an install
#      on a fresh machine (the rest will be idempotent skips).
#   2) For each "will install" name, hit the relevant registry (brew
#      info / npm / PyPI / curl URL) to confirm it resolves now.
#
# Read-only; no install side effects. Parallelized — runs ~30+ checks
# concurrently via xargs -P, taking ~5s instead of the ~35s sequential
# version.
#
# Usage:
#   bash tools/preflight-brew-names.sh           # full report
#   bash tools/preflight-brew-names.sh --quiet   # only failures
#######################################

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DATA_DIR="${REPO_ROOT}/data/packages"
SNAPSHOT_DIR="${REPO_ROOT}/.migration/MacBook-Pro-de-Fundacao-4-snapshot"
PARALLELISM="${PREFLIGHT_PARALLELISM:-10}"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: brew not in PATH. Run on a host with Homebrew installed." >&2
    exit 2
fi

# ── Helpers ──────────────────────────────────────────────────────

read_pkg_file() {
    grep -v "^[[:space:]]*#" "$1" 2>/dev/null | grep -v "^[[:space:]]*$" || true
}

read_inventory_names() {
    grep -v "^[[:space:]]*#" "$1" 2>/dev/null | awk 'NF { print $1 }' || true
}

# Strip a trailing "@<tag>" from a package spec for registry lookup.
# Tags are resolved at install time — registry URL must point to bare pkg.
#   @openai/codex@latest → @openai/codex
#   codex@latest         → codex
#   @openai/codex        → @openai/codex (unchanged)
strip_tag_for_url() {
    local spec="$1"
    if [[ "$spec" =~ ^(.+)@[^/@]+$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    else
        printf '%s' "$spec"
    fi
}

#######################################
# WORKER: classify one task and emit one line
# Input:  "<kind>|<name>" on stdin (or as positional argv via xargs -I {})
# Output: "<verdict>|<kind>|<name>" to stdout
# Verdicts:
#   ok | not-found | third-party-tap:<tap> | tap-not-added:<tap>
#######################################
classify_one() {
    local task="$1"
    local kind="${task%%|*}"
    local name="${task#*|}"
    local out tap verdict url

    case "$kind" in
        formula|cask)
            local flag="--formula"
            [[ "$kind" == "cask" ]] && flag="--cask"
            if ! out=$(brew info "$flag" "$name" 2>&1); then
                if grep -qE "requires the tap [^[:space:]]+" <<<"$out"; then
                    local needed_tap
                    needed_tap=$(grep -oE "requires the tap [^[:space:]]+" <<<"$out" | awk '{print $4}')
                    verdict="tap-not-added:${needed_tap}"
                else
                    verdict="not-found"
                fi
            else
                tap=$(grep -oE "From: https://github.com/[^/]+/homebrew-[^/]+" <<<"$out" | head -1)
                if [[ -n "$tap" ]] && ! grep -qE "github.com/Homebrew/homebrew-(core|cask)" <<<"$tap"; then
                    verdict="third-party-tap:${tap##*github.com/}"
                else
                    verdict="ok"
                fi
            fi
            ;;
        npm|bun)
            local pkg_for_url
            pkg_for_url=$(strip_tag_for_url "$name")
            url="https://registry.npmjs.org/${pkg_for_url}"
            if curl -fsSL --head --max-time 5 "$url" >/dev/null 2>&1; then
                verdict="ok"
            else
                verdict="not-found"
            fi
            ;;
        uv|pipx)
            local pkg_for_url
            pkg_for_url=$(strip_tag_for_url "$name")
            url="https://pypi.org/pypi/${pkg_for_url}/json"
            if curl -fsSL --head --max-time 5 "$url" >/dev/null 2>&1; then
                verdict="ok"
            else
                verdict="not-found"
            fi
            ;;
        curl)
            case "$name" in
                ollama) url="https://ollama.com/install.sh" ;;
                *)      printf 'skip|%s|%s\n' "$kind" "$name"; return 0 ;;
            esac
            if curl -fsSL --head --max-time 5 "$url" >/dev/null 2>&1; then
                verdict="ok"
            else
                verdict="not-found"
            fi
            ;;
        *)
            printf 'skip|%s|%s\n' "$kind" "$name"
            return 0
            ;;
    esac

    printf '%s|%s|%s\n' "$verdict" "$kind" "$name"
}
export -f classify_one strip_tag_for_url

# ── Build inventory + to-install set ─────────────────────────────

declare -A IN_INVENTORY_FORMULA=() IN_INVENTORY_CASK=()
declare -A WILL_INSTALL_FORMULA=() WILL_INSTALL_CASK=()

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

for f in brew.txt brew-developer.txt brew-full.txt; do
    [[ -f "${DATA_DIR}/$f" ]] || continue
    while read -r pkg; do
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

# Hardcoded brew references in install scripts (not in any .txt profile)
declare -a SCRIPT_REFS=(
    "formula|fnm"
    "formula|uv"
    "formula|pnpm"
    "formula|mise"
    "cask|oven-sh/bun/bun"
)

# ── Build unified task list ──────────────────────────────────────

TASKS=()
for name in "${!WILL_INSTALL_FORMULA[@]}"; do TASKS+=("formula|$name"); done
for name in "${!WILL_INSTALL_CASK[@]}";    do TASKS+=("cask|$name");    done
for ref  in "${SCRIPT_REFS[@]}";           do TASKS+=("$ref");          done

AI_TOOLS_FILE="${DATA_DIR}/ai-tools-full.txt"
if [[ -f "$AI_TOOLS_FILE" ]]; then
    while read -r entry; do
        [[ -z "$entry" ]] && continue
        TASKS+=("${entry/:/|}")
    done < <(read_pkg_file "$AI_TOOLS_FILE")
fi

total_formula=${#WILL_INSTALL_FORMULA[@]}
total_cask=${#WILL_INSTALL_CASK[@]}
total_tasks=${#TASKS[@]}

if (( ! QUIET )); then
    echo "Preflight against M1 inventory ($SNAPSHOT_DIR)"
    echo "  formulae to install on a fresh M5: $total_formula"
    echo "  casks to install on a fresh M5:    $total_cask"
    echo "  total registry checks:             $total_tasks (parallelism=$PARALLELISM)"
    echo
fi

# ── Run all checks in parallel via xargs -P ──────────────────────

RESULTS=$(printf '%s\n' "${TASKS[@]}" \
    | xargs -P "$PARALLELISM" -I {} bash -c 'classify_one "$@"' _ {})

# ── Aggregate results ────────────────────────────────────────────

declare -a FAIL=() THIRDPARTY=() TAP_NEEDED=()

while IFS='|' read -r verdict kind name; do
    [[ -z "$verdict" ]] && continue
    case "$verdict" in
        ok)
            (( QUIET )) || printf "  [OK]      %-7s %s\n" "$kind" "$name"
            ;;
        not-found)
            FAIL+=("$kind: $name (not found in registry)")
            printf "  [FAIL]    %-7s %s — not found\n" "$kind" "$name"
            ;;
        third-party-tap:*)
            THIRDPARTY+=("$kind: $name (${verdict#third-party-tap:})")
            (( QUIET )) || printf "  [3rd-tap] %-7s %s — %s\n" "$kind" "$name" "${verdict#third-party-tap:}"
            ;;
        tap-not-added:*)
            TAP_NEEDED+=("$kind: $name (tap ${verdict#tap-not-added:} required)")
            (( QUIET )) || printf "  [tap req] %-7s %s — needs tap %s\n" "$kind" "$name" "${verdict#tap-not-added:}"
            ;;
        skip)
            (( QUIET )) || printf "  [skip]    %-7s %s — no preflight available\n" "$kind" "$name"
            ;;
    esac
done <<<"$RESULTS"

# ── Summary ─────────────────────────────────────────────────────

echo
echo "Preflight summary:"
printf "  total to install:    %d formulae + %d casks + %d ai-tools\n" \
    "$total_formula" "$total_cask" $((total_tasks - total_formula - total_cask - ${#SCRIPT_REFS[@]}))
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
