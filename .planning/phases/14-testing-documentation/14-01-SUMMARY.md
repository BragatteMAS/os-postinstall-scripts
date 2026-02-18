---
phase: 14-testing-documentation
plan: 01
subsystem: testing-linting
tags: [bats-core, shellcheck, psscriptanalyzer, unit-tests, lint-runners]
dependency_graph:
  requires: []
  provides: [bats-unit-tests, shellcheck-runner, psscriptanalyzer-runner, lint-configs]
  affects: [src/core/logging.sh, src/core/errors.sh, src/core/idempotent.sh, src/core/packages.sh]
tech_stack:
  added: [bats-core, bats-support, bats-assert]
  patterns: [git-submodules-for-test-deps, data-driven-test-fixtures, sleep-override-in-retry-tests]
key_files:
  created:
    - tests/test-core-logging.bats
    - tests/test-core-errors.bats
    - tests/test-core-idempotent.bats
    - tests/test-core-packages.bats
    - tests/fixtures/packages/test-apt.txt
    - tests/fixtures/packages/with-comments.txt
    - tools/lint.sh
    - tools/lint.ps1
    - .shellcheckrc
    - PSScriptAnalyzerSettings.psd1
  modified: []
decisions:
  - "bats-core installed via git submodules (not Homebrew) for portability"
  - "sleep override via export -f sleep in errors.bats setup() to avoid 20s retry delays"
  - "show_failure_summary tested without run (bash arrays do not propagate to subshells)"
  - "DATA_DIR set before sourcing packages.sh to use test fixtures instead of real data/"
  - ".shellcheckrc suppresses SC2034 and SC1091 project-wide (export -f false positives)"
metrics:
  duration: 3 min
  completed: 2026-02-18
---

# Phase 14 Plan 01: Core Unit Tests and Lint Runners Summary

37 bats unit tests across 4 core modules (logging, errors, idempotent, packages) plus ShellCheck/PSScriptAnalyzer lint runner scripts with config files.

## What Was Done

### Task 1: bats-core submodules, test fixtures, and unit tests (e01a6b9)

**Submodules installed:**
- `tests/lib/bats-core` (v1.13.0-33)
- `tests/lib/bats-support` (v0.3.0-37)
- `tests/lib/bats-assert` (v2.2.4-2)

**Test fixtures:**
- `tests/fixtures/packages/test-apt.txt` -- 4 packages (curl, wget, git, jq)
- `tests/fixtures/packages/with-comments.txt` -- 3 packages mixed with comments and blank lines

**Test files (37 total tests):**

| File | Tests | Coverage |
|------|-------|----------|
| test-core-logging.bats | 10 | log_ok, log_error, log_warn, log_info, log_debug (VERBOSE gating), setup_colors (NO_COLOR), backward compat aliases, log_banner |
| test-core-errors.bats | 9 | record_failure, get_failure_count, clear_failures, show_failure_summary, retry_with_backoff (success + failure), create_temp_dir, cleanup_temp_dir |
| test-core-idempotent.bats | 11 | is_installed (found/not found/empty), ensure_line_in_file (create + idempotent), ensure_dir, ensure_symlink, add_to_path (add + idempotent), backup_if_exists (exists + nonexistent) |
| test-core-packages.bats | 7 | load_packages (no arg/missing file/success/comment filtering), get_packages_for_manager (no arg/unknown), PACKAGES array reset |

### Task 2: Lint runners and config files (81bfbf0)

- **`.shellcheckrc`** -- Suppresses SC2034 (unused vars from export -f) and SC1091 (dynamic source paths)
- **`PSScriptAnalyzerSettings.psd1`** -- Excludes PSAvoidUsingWriteHost (appropriate for CLI tools)
- **`tools/lint.sh`** -- ShellCheck runner: finds all .sh files in src/ and tests/ (excluding bats lib), checks root scripts, per-file OK/ISSUES reporting, exit 0/1
- **`tools/lint.ps1`** -- PSScriptAnalyzer runner: checks src/platforms/windows, setup.ps1, tests/*.ps1, uses settings file, per-file reporting

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| bats tests/test-core-*.bats | 37 pass | 37 pass |
| test-core-logging.bats | 10 pass | 10 pass |
| test-core-errors.bats | 9 pass | 9 pass |
| test-core-idempotent.bats | 11 pass | 11 pass |
| test-core-packages.bats | 7 pass | 7 pass |
| git submodule status | 3 submodules | 3 submodules |
| tests/fixtures/packages/ | 2 files | 2 files |
| bash tools/lint.sh | runs, reports per-file | 30 files checked |
| tools/lint.ps1 exists | yes | yes |
| .shellcheckrc SC2034+SC1091 | suppressed | suppressed |
| PSScriptAnalyzerSettings.psd1 | PSAvoidUsingWriteHost excluded | excluded |

## Deviations from Plan

None -- plan executed exactly as written.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | e01a6b9 | test(14-01): add bats-core unit tests for all 4 core shell modules |
| 2 | 81bfbf0 | feat(14-01): add lint runner scripts and config files |

## Self-Check: PASSED

- All 10 created files verified on disk
- Both commits (e01a6b9, 81bfbf0) verified in git log
- 37/37 bats tests pass
- tools/lint.sh executes and reports 30 files checked
