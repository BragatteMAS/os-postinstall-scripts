---
phase: 16-exit-codes-security
plan: 01
subsystem: error-handling
tags: [exit-codes, bash, powershell, error-resilience, semantic-codes]

# Dependency graph
requires:
  - phase: 01-core-infrastructure
    provides: errors.sh with FAILED_ITEMS tracking, cleanup(), setup_error_handling()
  - phase: 13-windows-parity
    provides: errors.psm1 with Add-FailedItem, Show-FailureSummary, Get-FailureCount
provides:
  - EXIT_SUCCESS=0, EXIT_PARTIAL_FAILURE=1, EXIT_CRITICAL=2 constants in errors.sh and errors.psm1
  - compute_exit_code() and Get-ExitCode functions
  - signal_cleanup() for INT/TERM (exit 130)
  - _worst_exit tracking in all Bash parent orchestrators
  - $worstExit tracking in all PowerShell parent orchestrators
  - Semantic exit codes in all 15 child scripts (11 Bash + 4 PowerShell)
affects: [17-input-validation, 18-documentation-release]

# Tech tracking
tech-stack:
  added: []
  patterns: [semantic-exit-codes, worst-exit-propagation, signal-cleanup-separation]

key-files:
  created: []
  modified:
    - src/core/errors.sh
    - src/platforms/windows/core/errors.psm1
    - tests/test-core-errors.bats
    - setup.sh
    - src/platforms/linux/main.sh
    - src/platforms/macos/main.sh
    - setup.ps1
    - src/platforms/windows/main.ps1
    - src/platforms/linux/install/apt.sh
    - src/platforms/linux/install/flatpak.sh
    - src/platforms/linux/install/snap.sh
    - src/platforms/linux/install/cargo.sh
    - src/platforms/macos/install/brew.sh
    - src/platforms/macos/install/brew-cask.sh
    - src/install/ai-tools.sh
    - src/install/dev-env.sh
    - src/install/rust-cli.sh
    - src/install/fnm.sh
    - src/install/uv.sh
    - src/platforms/windows/install/winget.ps1
    - src/platforms/windows/install/cargo.ps1
    - src/platforms/windows/install/npm.ps1
    - src/platforms/windows/install/ai-tools.ps1
    - .planning/adrs/ADR-001-error-resilience.md

key-decisions:
  - "Semantic exit codes (0/1/2) replace hardcoded exit 0 while preserving continue-on-failure"
  - "INT/TERM traps separated from EXIT trap; Ctrl+C exits 130"
  - "Early-return exit 0 lines preserved (skip/not-applicable scenarios are not failures)"
  - "ADR-001 amended rather than replaced, documenting extension of original decision"

patterns-established:
  - "Pattern: EXIT_PARTIAL_FAILURE:-1 fallback syntax for safety if constants unavailable"
  - "Pattern: _worst_exit / $worstExit tracking after each child bash/ps1 dispatch"
  - "Pattern: compute_exit_code() reads FAILURE_LOG before cleanup_temp_dir deletes it"

# Metrics
duration: 6min
completed: 2026-02-21
---

# Phase 16 Plan 01: Exit Codes Summary

**Semantic exit codes (0=success, 1=partial failure, 2=critical) across 23 Bash/PowerShell scripts with worst-code propagation through parent-child chain**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-21T20:03:32Z
- **Completed:** 2026-02-21T20:09:32Z
- **Tasks:** 2
- **Files modified:** 24

## Accomplishments
- EXIT_SUCCESS/EXIT_PARTIAL_FAILURE/EXIT_CRITICAL constants and compute_exit_code()/Get-ExitCode functions in core error modules
- All 11 Bash child scripts and 4 PowerShell child scripts exit with semantic codes instead of hardcoded 0
- All 5 parent orchestrators (setup.sh, linux/main.sh, macos/main.sh, setup.ps1, windows/main.ps1) track worst exit code from children
- Ctrl+C exits 130 via separate signal_cleanup() trap
- ADR-001 amended to document semantic exit codes while preserving continue-on-failure intent
- 14 bats tests pass (9 original + 5 new)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add exit code constants, compute_exit_code(), and refactor cleanup/trap** - `0171841` (feat)
2. **Task 2: Update all child scripts, parent orchestrators, and amend ADR-001** - `0b91dfa` (feat)

## Files Created/Modified
- `src/core/errors.sh` - EXIT_SUCCESS/PARTIAL_FAILURE/CRITICAL constants, compute_exit_code(), signal_cleanup(), refactored cleanup()
- `src/platforms/windows/core/errors.psm1` - PS exit constants, Get-ExitCode function, updated exports
- `tests/test-core-errors.bats` - 5 new tests for constants and compute_exit_code
- `setup.sh` - _worst_exit tracking, verify_all defensive check, platform dispatch tracking
- `src/platforms/linux/main.sh` - _worst_exit tracking after each child dispatch, return $_worst_exit
- `src/platforms/macos/main.sh` - _worst_exit tracking after each child dispatch, return $_worst_exit
- `setup.ps1` - $worstExit tracking, handler-not-found exits 2
- `src/platforms/windows/main.ps1` - $worstExit tracking after each dispatch, unattended exit uses worstExit
- `src/platforms/linux/install/apt.sh` - Semantic exit code
- `src/platforms/linux/install/flatpak.sh` - Semantic exit code
- `src/platforms/linux/install/snap.sh` - Semantic exit code
- `src/platforms/linux/install/cargo.sh` - Semantic exit code
- `src/platforms/macos/install/brew.sh` - Semantic exit code
- `src/platforms/macos/install/brew-cask.sh` - Semantic exit code
- `src/install/ai-tools.sh` - Semantic exit code (final exit only; skip/load-fail exit 0 preserved)
- `src/install/dev-env.sh` - Semantic exit code
- `src/install/rust-cli.sh` - Semantic exit code (skip menu exit 0 preserved)
- `src/install/fnm.sh` - Semantic exit code in main guard
- `src/install/uv.sh` - Semantic exit code in main guard
- `src/platforms/windows/install/winget.ps1` - Get-ExitCode instead of exit 0
- `src/platforms/windows/install/cargo.ps1` - Get-ExitCode instead of exit 0
- `src/platforms/windows/install/npm.ps1` - Get-ExitCode instead of exit 0
- `src/platforms/windows/install/ai-tools.ps1` - Get-ExitCode instead of exit 0
- `.planning/adrs/ADR-001-error-resilience.md` - Amended with semantic exit codes section

## Decisions Made
- Semantic exit codes (0/1/2) replace hardcoded exit 0 -- enables automation callers to distinguish success from failure
- INT/TERM traps separated from EXIT trap; signal_cleanup() exits 130 for Ctrl+C
- Early-return `exit 0` lines in child scripts preserved (e.g., flatpak not found, user chose skip) -- these are "not applicable" not "failure"
- ADR-001 amended (not replaced) to document the extension while preserving original rationale
- `compute_exit_code()` runs BEFORE `cleanup_temp_dir()` because FAILURE_LOG lives in TEMP_DIR

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bats test for compute_exit_code return 1**
- **Found during:** Task 1 (test verification)
- **Issue:** Test `compute_exit_code returns 1 when failures exist` used bare `compute_exit_code` which triggers bats' implicit error-on-nonzero. The `return 1` from compute_exit_code was treated as a test failure by bats.
- **Fix:** Wrapped in `run compute_exit_code` and checked `$status` instead of `$?`
- **Files modified:** tests/test-core-errors.bats
- **Verification:** All 14 tests pass
- **Committed in:** 0171841 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary fix for test correctness. No scope creep.

## Issues Encountered
None beyond the test fix documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Exit code infrastructure complete; all scripts now report semantic exit codes
- Ready for Phase 16 Plan 02 (input validation / security hardening)
- Future CI/CD (if ever added) can now distinguish success from partial failure from critical

## Self-Check: PASSED

- All 24 modified files verified present on disk
- Commit 0171841 (Task 1) verified in git log
- Commit 0b91dfa (Task 2) verified in git log
- 14/14 bats tests pass
- All 11 Bash scripts pass syntax check (bash -n)

---
*Phase: 16-exit-codes-security*
*Completed: 2026-02-21*
