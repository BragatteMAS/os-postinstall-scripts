---
phase: 17-test-expansion-bash
plan: 03
subsystem: testing
tags: [bats, integration-tests, contract-parity, api-mapping, cross-platform]

# Dependency graph
requires:
  - phase: 14-01
    provides: "bats-core infrastructure (git submodules, test patterns, NO_COLOR convention)"
  - phase: 17-01
    provides: "platform.sh, progress.sh, interactive.sh unit tests and mock patterns"
  - phase: 17-02
    provides: "dotfiles.sh, data validation tests"
provides:
  - "8 integration tests for setup.sh CLI end-to-end behavior (TEST-08)"
  - "4 contract validation tests for Bash/PS API parity (TEST-09)"
  - "Declarative Bash/PowerShell API parity mapping (16 data lines, 5 paired modules)"
affects: [test-coverage, regression-detection, cross-platform-maintenance]

# Tech tracking
tech-stack:
  added: []
  patterns: [subprocess-integration-testing, contract-file-validation, export-cross-reference]

key-files:
  created:
    - "tests/test-integration.bats"
    - "tests/contracts/api-parity.txt"
    - "tests/test-contracts.bats"
  modified: []

key-decisions:
  - "All integration tests use --dry-run except --help and unknown flag; never run setup.sh without --dry-run"
  - "Unknown flag test uses assert_output only, not assert_failure, due to EXIT trap bug (Pitfall 5)"
  - "Contract validation cross-references Bash exports against source files; PS side is informational"
  - "Contract file uses pipe-separated 5-column format for human readability and machine parsability"

patterns-established:
  - "run bash subprocess pattern: clean environment via run bash $SETUP_SH for integration tests"
  - "Contract parity file: declarative Bash/PS function mapping for maintenance tracking"
  - "Export cross-reference: validate contract entries against actual export -f lines in source"

# Metrics
duration: 10min
completed: 2026-02-21
---

# Phase 17 Plan 03: Integration Tests and Contract Parity Summary

**8 integration tests for setup.sh CLI (--help, --dry-run for 3 profiles, platform detection, unknown flag, default profile, completion summary) plus 4 contract validation tests and a 16-line Bash/PS API parity mapping**

## Performance

- **Duration:** 10 min (dominated by integration test execution -- each --dry-run invokes platform detection + internet check)
- **Started:** 2026-02-21T21:38:32Z
- **Completed:** 2026-02-21T21:48:35Z
- **Tasks:** 2
- **Files created:** 3 (+ 1 directory: tests/contracts/)

## Accomplishments
- Created test-integration.bats with 8 tests covering all setup.sh CLI entry points via --dry-run subprocess invocation
- Created tests/contracts/api-parity.txt with 16 data lines mapping all 5 paired Bash/PS modules (logging, errors, packages, idempotent, progress)
- Created test-contracts.bats with 4 tests validating contract format, Bash export coverage with source-file cross-reference, and PS export coverage
- Total bats test suite: 120 tests (44 original + 36 Plan 01 + 28 Plan 02 + 12 Plan 03), 0 failures, 0 regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: test-integration.bats (8 tests)** - `da5ad46` (test)
2. **Task 2: api-parity.txt + test-contracts.bats (4 tests)** - `585a85e` (test)

## Files Created
- `tests/test-integration.bats` (61 lines) - setup.sh CLI integration tests: --help, --dry-run (minimal/developer/full), platform detection, unknown flag, default profile, completion summary
- `tests/contracts/api-parity.txt` (27 lines, 16 data) - Declarative mapping of 5 paired Bash/PS modules with function-level correspondence and behavior descriptions
- `tests/test-contracts.bats` (93 lines) - Contract format validation, Bash export cross-reference against source files, PS export validation

## Decisions Made
- All integration tests invoke setup.sh as a clean subprocess (`run bash "$SETUP_SH"`), ensuring no source guard conflicts and clean environment per test
- Unknown flag test (`--invalid-flag`) documents the EXIT trap bug with a comment and validates output content only -- cannot assert_failure because the EXIT trap's cleanup() overrides exit 1 to exit 0 via `_worst_exit` default
- Contract validation Test 3 cross-references each expected Bash function against both the contract file AND the actual `export -f` line in the source file, catching both missing contract entries and deregistered exports
- PS side validation (Test 4) checks only against contract entries, not by running pwsh -- this is a Bash test suite per research recommendation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Integration tests are slow (~10-15 seconds each for --dry-run profiles) due to the full setup.sh execution path including platform detection and internet connectivity check, but this is expected behavior documented in the plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 17 test expansion is now complete: all 3 plans executed
- 120 total bats tests passing (0 failures) across 11 test files
- All 8 core Bash modules now have test coverage
- Integration tests verify end-to-end CLI behavior
- Contract file provides cross-platform maintenance reference for future Pester alignment
- Satisfies Success Criterion 8: "All tests pass: bats tests/*.bats exits 0"

## Self-Check: PASSED

All 3 created files verified present. Both task commits (da5ad46, 585a85e) confirmed in git log. 120 bats tests pass (12 new + 108 existing).

---
*Phase: 17-test-expansion-bash*
*Completed: 2026-02-21*
