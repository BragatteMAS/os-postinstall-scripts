#!/usr/bin/env bash
# tools/validate-profiles.sh — manual profile contract validator
#
# Purpose: prevent regression where package files leak between profiles
# (e.g. -full files appearing in developer; -developer files in minimal).
# Validates the convention: <source>.txt = base, <source>-developer.txt = dev+full,
# <source>-full.txt = full only. csv:<category> entries validated against
# data/packages.csv rows.
#
# This is a MANUAL check. Per project policy (see CLAUDE.md: "NO CI/CD
# Automation"), it is never wired into hooks, GitHub Actions, or pre-commit.
# Run it yourself before releases or when editing profile definitions:
#
#     bash tools/validate-profiles.sh
#
# Exit codes:
#   0  all profile contracts satisfied
#   1  one or more contract violations found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
PROFILES_DIR="$REPO_ROOT/data/packages/profiles"
PACKAGES_DIR="$REPO_ROOT/data/packages"

red()   { printf "\033[1;31m%s\033[0m" "$1"; }
green() { printf "\033[1;32m%s\033[0m" "$1"; }
yellow(){ printf "\033[1;33m%s\033[0m" "$1"; }
bold()  { printf "\033[1m%s\033[0m"    "$1"; }

errors=0

fail() {
  red "  ✗ FAIL"; echo ": $1"
  errors=$((errors + 1))
}

pass() {
  green "  ✓ PASS"; echo ": $1"
}

# List of package files referenced by a profile (comments and blanks stripped)
profile_entries() {
  local profile="$1"
  grep -vE '^\s*(#|$)' "$PROFILES_DIR/$profile.txt" 2>/dev/null || true
}

contains() {
  local needle="$1"; shift
  for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
  return 1
}

echo
bold "=== Profile contract validator ==="
echo "Profiles dir: $PROFILES_DIR"
echo

# ---------------------------------------------------------------------------
# Rule 1 — All three canonical profiles exist
# ---------------------------------------------------------------------------
bold "[1/5] Canonical profiles exist"; echo
for p in minimal developer full; do
  if [[ -f "$PROFILES_DIR/$p.txt" ]]; then
    pass "$p.txt present"
  else
    fail "$p.txt missing"
  fi
done
echo

# Collect entries once
mapfile -t MINIMAL   < <(profile_entries minimal)
mapfile -t DEVELOPER < <(profile_entries developer)
mapfile -t FULL      < <(profile_entries full)

# ---------------------------------------------------------------------------
# Rule 2 — Naming convention reflects profile membership:
#   <source>.txt              base — included by every profile that uses this source
#   <source>-developer.txt    developer + full only (not in minimal)
#   <source>-full.txt         full only (Bragatte's personal pick)
# ---------------------------------------------------------------------------
bold "[2/5] minimal profile stays minimal (no -developer or -full files)"; echo
for entry in "${MINIMAL[@]}"; do
  if [[ "$entry" == *-developer.txt || "$entry" == *-full.txt ]]; then
    fail "minimal.txt must NOT include $entry (only base <source>.txt allowed in minimal)"
  fi
done
pass "minimal contains only base <source>.txt entries"
echo

bold "[3/5] developer profile excludes -full files (those are Bragatte's pick)"; echo
for entry in "${DEVELOPER[@]}"; do
  if [[ "$entry" == *-full.txt ]]; then
    fail "developer.txt must NOT include $entry (-full is full-only)"
  fi
done
pass "developer does not leak -full files"
for required in npm-developer.txt; do
  if contains "$required" "${DEVELOPER[@]}"; then
    pass "developer includes $required"
  else
    fail "developer.txt must include $required"
  fi
done

# Rust tools moved to data/packages.csv (Onda 5) — developer must include csv:rust-cli at minimum
if contains "csv:rust-cli" "${DEVELOPER[@]}"; then
  pass "developer includes csv:rust-cli (Rust baseline)"
else
  fail "developer.txt must include csv:rust-cli"
fi
echo

bold "[4/5] full profile delivers the AI differentiator"; echo
if contains "ai-tools-full.txt" "${FULL[@]}"; then
  pass "full includes ai-tools-full.txt"
else
  fail "full.txt must include ai-tools-full.txt"
fi
echo

# ---------------------------------------------------------------------------
# Rule 3 — No profile references a package file that doesn't exist on disk
#
# Most entries live in data/packages/, but a few have dedicated sibling
# directories handled by special loaders. Keep this allowlist in sync with
# src/core/defaults.sh and src/platforms/*/main.sh when you add a new one.
#
# csv:<category> entries are resolved against data/packages.csv (column 1).
# ---------------------------------------------------------------------------
declare -A SPECIAL_LOCATIONS=(
  ["macos-defaults.txt"]="$REPO_ROOT/data/defaults/macos-defaults.txt"
)
CSV_FILE="$REPO_ROOT/data/packages.csv"

bold "[5/5] All referenced package files exist on disk"; echo
missing_before=$errors
for profile in minimal developer full; do
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    # csv:<category> entries — validate against data/packages.csv
    if [[ "$entry" == csv:* ]]; then
      cat_name="${entry#csv:}"
      if [[ ! -f "$CSV_FILE" ]]; then
        fail "$profile.txt references $entry but data/packages.csv is missing"
        continue
      fi
      if ! awk -F',' -v cat="$cat_name" 'NR>1 && $1==cat {found=1} END{exit !found}' "$CSV_FILE"; then
        fail "$profile.txt references $entry but no rows with category=$cat_name in data/packages.csv"
      fi
      continue
    fi
    special="${SPECIAL_LOCATIONS[$entry]:-}"
    if [[ -n "$special" && -f "$special" ]]; then
      continue  # resolved via allowlist
    fi
    if [[ ! -f "$PACKAGES_DIR/$entry" ]]; then
      fail "$profile.txt references $entry but it doesn't exist at $PACKAGES_DIR/$entry"
    fi
  done < <(profile_entries "$profile")
done
[[ $errors -eq $missing_before ]] && pass "every listed package file resolves"
echo

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
if [[ $errors -eq 0 ]]; then
  green "✓ All profile contracts satisfied."; echo
  exit 0
else
  red "✗ $errors contract violation(s) found."; echo
  yellow "  Review the FAILs above and fix the profile file(s)."; echo
  exit 1
fi
