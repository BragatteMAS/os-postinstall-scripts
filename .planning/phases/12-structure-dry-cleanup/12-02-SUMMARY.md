---
phase: 12-structure-dry-cleanup
plan: 02
subsystem: structure-dry
tags: [refactor, DRY, directory-consolidation, logging, readonly-guard]
dependency_graph:
  requires: []
  provides: [single-install-dir, platform-uses-logging-sh, safe-data-dir-readonly]
  affects: [setup.sh, src/core/platform.sh, src/core/packages.sh, src/install/dotfiles-install.sh, tests/test_harness.sh, README.md]
tech_stack:
  added: []
  patterns: [SSoT-logging, readonly-guard]
key_files:
  created: []
  modified:
    - src/install/dotfiles-install.sh
    - setup.sh
    - README.md
    - tests/test_harness.sh
    - src/core/platform.sh
    - src/core/packages.sh
decisions:
  - "Delete src/installers/CLAUDE.md rather than migrate (src/install/CLAUDE.md already exists)"
  - "Remove test_harness.sh src/installers check entirely (src/install check already on prior line)"
  - "Update README directory tree to show single install/ directory with dotfiles-install.sh"
metrics:
  duration: 3 min
  completed: 2026-02-18
---

# Phase 12 Plan 02: Bash-Side DRY Fixes Summary

**One-liner:** Consolidate src/installers/ into src/install/, strip duplicate color/logging from platform.sh to use logging.sh SSoT, guard DATA_DIR readonly to prevent re-source collision.

## What Was Done

### Task 1: Merge src/installers/ into src/install/ -- DRY-02 (1a9a82f)

Moved `dotfiles-install.sh` from `src/installers/` to `src/install/` using `git mv` to preserve blame history. The file's `REPO_ROOT` computation (`../../` relative path) still resolves correctly because both directories sit at the same depth under `src/`.

- **setup.sh**: Replaced 3 occurrences of `src/installers/dotfiles-install.sh` with `src/install/dotfiles-install.sh` (lines 144, 149, 201)
- **README.md**: Updated customization instructions path and collapsed the directory tree from two directories (`install/` + `installers/`) into one
- **tests/test_harness.sh**: Removed `test_directory_exists "src/installers"` line (line 132 already validates `src/install/`)
- **src/installers/**: Deleted `CLAUDE.md` via `git rm`, directory removed as empty

**Files:** `src/install/dotfiles-install.sh` (moved), `setup.sh`, `README.md`, `tests/test_harness.sh`

### Task 2: Remove duplicate colors from platform.sh -- DRY-03 (b1fa9de)

Removed the entire color definition block (`_RED`, `_GREEN`, `_YELLOW`, `_BLUE`, `_NC` -- 15 lines) and the four `_platform_*` helper function definitions (12 lines). Replaced all 14 callsites with their `logging.sh` equivalents:

| Old Call | New Call | Count |
|----------|---------|-------|
| `_platform_info` | `log_info` | 2 |
| `_platform_ok` | `log_ok` | 3 |
| `_platform_warn` | `log_warn` | 5 |
| `_platform_error` | `log_error` | 4 |

All three entry points (`setup.sh`, `linux/main.sh`, `macos/main.sh`) source `logging.sh` before `platform.sh`, so `log_*` functions are guaranteed available. No `source logging.sh` was added inside platform.sh.

**Files:** `src/core/platform.sh` (-50 lines, +14 lines)

### Task 3: Guard DATA_DIR readonly in packages.sh -- DRY-04 (07f8c8d)

Wrapped the `DATA_DIR` assignment and `readonly` declaration with a `-z` guard:

```bash
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
    readonly DATA_DIR
fi
```

This prevents the readonly collision when `config.sh` has already declared `readonly DATA_DIR="${PROJECT_ROOT}/data"`. The source guard (`_PACKAGES_SOURCED`) normally prevents this, but unit tests that reset `_PACKAGES_SOURCED` to re-source `packages.sh` hit the double-readonly error.

**Files:** `src/core/packages.sh` (2-line-to-4-line change)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing functionality] Updated README directory tree structure**
- **Found during:** Task 1
- **Issue:** The README directory tree showed `src/install/` as a non-final node (`|--`) and `src/installers/` as a separate subtree. After removing `src/installers/`, the tree needed restructuring to show `src/install/` as the final entry under `src/` (using `\--` connector).
- **Fix:** Reformatted the tree so `src/install/` uses the final-child connector and includes `dotfiles-install.sh` in the listing.
- **Files modified:** README.md
- **Commit:** 1a9a82f

## Verification Results

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| src/installers/ exists | No | No | PASS |
| src/install/dotfiles-install.sh exists | Yes | Yes | PASS |
| "src/installers" in setup.sh/tests/README | 0 matches | 0 matches | PASS |
| "src/install/dotfiles-install.sh" in setup.sh | 3 matches | 3 matches | PASS |
| Color vars in platform.sh | 0 | 0 | PASS |
| _platform_* calls in platform.sh | 0 | 0 | PASS |
| log_* calls in platform.sh | ~15 | 14 | PASS |
| DATA_DIR -z guard in packages.sh | Present | Present | PASS |
| Unguarded readonly DATA_DIR | 0 | 0 | PASS |

## Self-Check: PASSED

All 6 modified files exist. All 3 commits (1a9a82f, b1fa9de, 07f8c8d) verified in git log.
