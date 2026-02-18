---
phase: 11-flag-boolean-fixes
plan: 01
subsystem: core-flags
tags: [bugfix, flags, boolean, documentation, data-cleanup]
dependency_graph:
  requires: []
  provides: [correct-verbose-checks, noninteractive-propagation, clean-winget-list, accurate-docs]
  affects: [src/core/logging.sh, config.sh, setup.sh, data/packages/winget.txt, .planning/codebase/ARCHITECTURE.md, .planning/codebase/CONVENTIONS.md]
tech_stack:
  added: []
  patterns: [string-boolean-comparison]
key_files:
  created: []
  modified:
    - src/core/logging.sh
    - config.sh
    - setup.sh
    - data/packages/winget.txt
    - .planning/codebase/ARCHITECTURE.md
    - .planning/codebase/CONVENTIONS.md
decisions:
  - "VERBOSE checks use == 'true' string comparison instead of -n/-z tests"
  - "NONINTERACTIVE uses two-site bridge: config.sh for env-var path, setup.sh for -y flag path"
metrics:
  duration: 2 min
  completed: 2026-02-18
---

# Phase 11 Plan 01: Flag & Boolean Fixes Summary

**One-liner:** Fix VERBOSE boolean semantics, add NONINTERACTIVE propagation bridge, remove defunct Kite package, align docs with ADR-001.

## What Was Done

### Task 1: Fix VERBOSE boolean checks and NONINTERACTIVE bridge (93281db)

**FLAG-01 -- logging.sh VERBOSE boolean fix (5 locations):**
Changed all VERBOSE checks from `-n`/`-z` tests to string comparison `== "true"` / `!= "true"`. The old `-n "${VERBOSE:-}"` evaluated true for any non-empty string including "false", causing timestamps and debug output to always appear even when `VERBOSE=false` (the config.sh default).

- `log_ok`, `log_error`, `log_warn`, `log_info`: `-n "${VERBOSE:-}"` to `"${VERBOSE:-}" == "true"`
- `log_debug`: `-z "${VERBOSE:-}"` to `"${VERBOSE:-}" != "true"`

**FLAG-02 -- NONINTERACTIVE propagation (two-site bridge):**
Downstream scripts (apt.sh, interactive.sh, ai-tools.sh, dev-env.sh) check `NONINTERACTIVE` but it was never set. Added propagation for both invocation paths:

- **config.sh**: Bridge `NONINTERACTIVE="${NONINTERACTIVE:-${UNATTENDED}}"` after UNATTENDED default, plus added to export line. Handles `UNATTENDED=true ./setup.sh` path.
- **setup.sh**: `export NONINTERACTIVE=true` in parse_flags `-y` branch. Handles `./setup.sh -y` path where parse_flags runs after config.sh sourcing.

**Files:** `src/core/logging.sh`, `config.sh`, `setup.sh`

### Task 2: Remove stale winget entry and fix documentation drift (8191c99)

**FLAG-03 -- Remove kite.kite from winget.txt:**
Removed defunct `kite.kite` entry (Kite AI shut down November 2022, package ID no longer in WinGet). The `# Productivity - Data` section header remains with `UniversityOfWaikato.Weka`.

**FLAG-04 -- Fix ARCHITECTURE.md and CONVENTIONS.md:**
- ARCHITECTURE.md: Replaced "Fail-fast with tracking" with "Continue on failure with tracking. No set -e anywhere (per ADR-001)". Replaced `set -euo pipefail` with explicit no-set-e description.
- CONVENTIONS.md: Updated 3 locations from `set -euo pipefail` to `set -o pipefail` with ADR-001 references.

**Files:** `data/packages/winget.txt`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONVENTIONS.md`

## Deviations from Plan

None -- plan executed exactly as written.

## Verification Results

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Old -n VERBOSE pattern count | 0 | 0 | PASS |
| String "true" comparison count | 5 | 5 | PASS |
| NONINTERACTIVE in config.sh | 2+ lines | 3 lines | PASS |
| NONINTERACTIVE=true in setup.sh | 1 | 1 | PASS |
| kite in winget.txt | 0 | 0 | PASS |
| set -euo pipefail in docs | 0 | 0 | PASS |

## Self-Check: PASSED

All 6 modified files exist. Both commits (93281db, 8191c99) verified in git log.
