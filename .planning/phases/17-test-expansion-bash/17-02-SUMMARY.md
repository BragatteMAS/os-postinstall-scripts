---
phase: 17-test-expansion-bash
plan: 02
subsystem: testing
tags: [bats, unit-tests, dotfiles, data-validation, tmpdir-isolation]

# Dependency graph
requires:
  - phase: 14-01
    provides: "bats-core infrastructure (git submodules, test patterns, NO_COLOR convention)"
  - phase: 17-01
    provides: "established mock patterns (uname dispatch, command -v passthrough)"
provides:
  - "22 unit tests for dotfiles.sh (path_to_backup_name, backup_with_manifest, create_dotfile_symlink, unlink_dotfiles, show_backup_summary, list_backups)"
  - "6 data integrity tests for profile and package file validation"
affects: [test-coverage, regression-detection, data-integrity]

# Tech tracking
tech-stack:
  added: []
  patterns: [tmpdir-home-isolation, source-time-variable-override, manifest-driven-restore, data-integrity-validation]

key-files:
  created:
    - "tests/test-core-dotfiles.bats"
    - "tests/test-data-validation.bats"
  modified: []

key-decisions:
  - "HOME overridden BEFORE sourcing dotfiles.sh to ensure BACKUP_DIR/MANIFEST_FILE use tmpdir (Pitfall 4)"
  - "backup_with_manifest called directly (not via run) for manifest restore test to populate MANIFEST_FILE in same shell"
  - "((count++)) replaced with count=$((count + 1)) to avoid bash arithmetic exit code 1 on zero"
  - "Orphan detection uses grep ^filename$ matching to avoid false positives from substrings"
  - "Data validation tests require no module sourcing -- pure filesystem checks"

patterns-established:
  - "tmpdir HOME isolation: mktemp -d + HOME override + BACKUP_DIR/MANIFEST_FILE set before source"
  - "Manifest-driven restore testing: direct call for state population, run for assertion"
  - "Data integrity guard: profile-to-package reference validation as regression tests"

# Metrics
duration: 2min
completed: 2026-02-21
---

# Phase 17 Plan 02: Dotfiles Tests + Data Validation Summary

**28 bats tests covering all 6 dotfiles.sh exported functions via tmpdir HOME isolation plus 6 data integrity tests validating profile-to-package reference consistency**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-21T21:38:18Z
- **Completed:** 2026-02-21T21:40:34Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- Created test-core-dotfiles.bats with 22 tests covering all 6 exported functions (path_to_backup_name, backup_with_manifest, create_dotfile_symlink, unlink_dotfiles, show_backup_summary, list_backups)
- Created test-data-validation.bats with 6 tests validating profile existence, reference integrity, orphan detection, content validation, and text format
- Total bats test suite expanded from 102 to 130 tests (28 new), 0 failures, 0 regressions
- All filesystem operations isolated in tmpdir -- no real HOME touched

## Task Commits

Each task was committed atomically:

1. **Task 1: test-core-dotfiles.bats (22 tests)** - `b010ef6` (test)
2. **Task 2: test-data-validation.bats (6 tests)** - `001661e` (test)

## Files Created
- `tests/test-core-dotfiles.bats` (256 lines) - path_to_backup_name (4), backup_with_manifest (6), create_dotfile_symlink (6), unlink_dotfiles (4), show_backup_summary (1), list_backups (1)
- `tests/test-data-validation.bats` (96 lines) - profile existence, reference integrity, non-empty profiles, orphan detection, package content, text format

## Decisions Made
- HOME must be overridden BEFORE sourcing dotfiles.sh because BACKUP_DIR and MANIFEST_FILE are set at source time (Pitfall 4: source-time expansion)
- For restore-from-manifest test, backup_with_manifest is called directly (not via `run`) so MANIFEST_FILE and SESSION_BACKUPS are populated in the same shell context, then symlink is created manually, then `run unlink_dotfiles` is used for assertion
- `((count++))` replaced with `count=$((count + 1))` in data validation tests because bash arithmetic returns exit code 1 when the result is 0 (first increment from 0 to 1)
- Orphan detection uses `grep -q "^filename$"` to avoid false positives from substring matches (e.g., "apt.txt" matching "apt-post.txt")
- Data validation tests are pure filesystem checks -- no module sourcing needed, making them fast and dependency-free

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bash arithmetic exit code in count loops**
- **Found during:** Task 2
- **Issue:** `((count++))` returns exit code 1 when count is 0 (incrementing 0 to 1), causing bats to treat it as a test failure
- **Fix:** Replaced `((count++))` with `count=$((count + 1))` which always returns exit code 0
- **Files modified:** tests/test-data-validation.bats
- **Commit:** 001661e (included in same commit)

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 6 dotfiles.sh functions now fully tested with tmpdir isolation
- Data integrity guard prevents broken profile-to-package references from being committed
- 130 total bats tests passing, 0 regressions
- Ready for Plan 17-03 (integration tests, contract parity) if it exists

## Self-Check: PASSED

All 2 created files verified present. Both task commits (b010ef6, 001661e) confirmed in git log. 130 bats tests pass (28 new + 102 existing).

---
*Phase: 17-test-expansion-bash*
*Completed: 2026-02-21*
