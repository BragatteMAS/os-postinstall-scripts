#!/usr/bin/env bash
# tools/validate-profiles.sh — manual profile contract validator
#
# Purpose: prevent regression where package files leak between profiles
# (e.g. ai-tools.txt contaminating developer.txt).
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
# Rule 2 — Contract from config.sh:
#   minimal   = essential system packages only
#   developer = system + dev tools (cargo, npm) — NO AI tools
#   full      = everything including AI/MCP tools
# ---------------------------------------------------------------------------
bold "[2/5] minimal profile stays minimal (no dev/ai tools)"; echo
for forbidden in cargo.txt npm.txt ai-tools.txt; do
  if contains "$forbidden" "${MINIMAL[@]}"; then
    fail "minimal.txt must NOT include $forbidden"
  else
    pass "minimal does not include $forbidden"
  fi
done
echo

bold "[3/5] developer profile excludes AI tools"; echo
if contains "ai-tools.txt" "${DEVELOPER[@]}"; then
  fail "developer.txt must NOT include ai-tools.txt (AI is the 'full' differentiator)"
else
  pass "developer does not leak ai-tools.txt"
fi
for required in cargo.txt npm.txt; do
  if contains "$required" "${DEVELOPER[@]}"; then
    pass "developer includes $required"
  else
    fail "developer.txt must include $required"
  fi
done
echo

bold "[4/5] full profile delivers the AI differentiator"; echo
if contains "ai-tools.txt" "${FULL[@]}"; then
  pass "full includes ai-tools.txt"
else
  fail "full.txt must include ai-tools.txt"
fi
echo

# ---------------------------------------------------------------------------
# Rule 3 — No profile references a package file that doesn't exist on disk
#
# Most entries live in data/packages/, but a few have dedicated sibling
# directories handled by special loaders. Keep this allowlist in sync with
# src/core/defaults.sh and src/platforms/*/main.sh when you add a new one.
# ---------------------------------------------------------------------------
declare -A SPECIAL_LOCATIONS=(
  ["macos-defaults.txt"]="$REPO_ROOT/data/defaults/macos-defaults.txt"
)

bold "[5/5] All referenced package files exist on disk"; echo
missing_before=$errors
for profile in minimal developer full; do
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
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
