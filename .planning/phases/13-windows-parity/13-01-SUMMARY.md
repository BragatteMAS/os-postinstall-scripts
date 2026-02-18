---
phase: 13-windows-parity
plan: 01
subsystem: windows-ux-parity
tags: [feature, CLI-switches, step-counters, completion-summary, progress-module]
dependency_graph:
  requires: []
  provides: [progress.psm1, CLI-DryRun-switch, CLI-Verbose-switch, CLI-Unattended-switch, step-counters, completion-summary]
  affects: [setup.ps1, src/platforms/windows/main.ps1, tests/test-windows.ps1]
tech_stack:
  added: []
  patterns: [module-export, CmdletBinding-on-module-functions-only, env-var-mapping]
key_files:
  created:
    - src/platforms/windows/core/progress.psm1
  modified:
    - setup.ps1
    - src/platforms/windows/main.ps1
    - tests/test-windows.ps1
decisions:
  - "No CmdletBinding on setup.ps1 or main.ps1 (scripts, not module functions) -- avoids conflict with explicit -Verbose switch"
  - "CmdletBinding applied to all three progress.psm1 exported functions (module exports per WPAR-04)"
  - "Show-CompletionSummary reads FAILURE_LOG file internally -- replaces inline failure aggregation in setup.ps1"
metrics:
  duration: 4 min
  completed: 2026-02-18
---

# Phase 13 Plan 01: Windows CLI Switches, Step Counters & Completion Summary

**One-liner:** CLI flag switches (-DryRun, -Verbose, -Unattended) with env var mapping, [Step X/Y] dispatch counters, and rich completion summary matching Unix UX parity.

## What Was Done

### Task 1: Create progress.psm1 module and update setup.ps1 with CLI switches + summary (145043a)

**A. Created `src/platforms/windows/core/progress.psm1`** (133 lines, new file)

PowerShell equivalent of `src/core/progress.sh` with three exported functions:

| Function | Purpose | Parameters |
|----------|---------|------------|
| `Show-DryRunBanner` | Display DRY RUN warning banner | None (reads $env:DRY_RUN) |
| `Get-PlatformStepCount` | Count Windows-relevant entries in profile | `$ProfileFile` (mandatory) |
| `Show-CompletionSummary` | Rich end-of-run summary with duration/failures | `$Profile`, `$Platform`, `$StartTime` |

All three functions have `[CmdletBinding()]` as they are module exports (satisfies WPAR-04). The module imports `logging.psm1` at top (same pattern as `errors.psm1`).

**B. Modified `setup.ps1`** (84 lines, was 75)

- Added `-DryRun`, `-Verbose`, `-Unattended` switch parameters (no `[CmdletBinding()]` on script)
- Added env var mapping block: each switch sets its corresponding `$env:` variable
- Added `$StartTime = Get-Date` for duration tracking
- Updated help text with all new switches documented
- Added `progress.psm1` import alongside existing module imports
- Replaced inline failure aggregation + bare `=== Setup Complete ===` banner with `Show-CompletionSummary` call
- Kept FAILURE_LOG cleanup after summary call

**Files:** `src/platforms/windows/core/progress.psm1` (created), `setup.ps1` (modified)

### Task 2: Add step counters and DryRun banner to main.ps1 + extend tests (94822e2)

**A. Modified `src/platforms/windows/main.ps1`** (149 lines, was 141)

- Added `progress.psm1` import after existing module imports
- Added `Show-DryRunBanner` call before dispatch loop (banner appears before any installers run)
- Added `Get-PlatformStepCount` call to get total Windows-relevant steps
- Added `[Step X/Y]` prefix to each of the 4 dispatch messages (winget, cargo, npm, ai-tools)
- Default case (non-Windows files) unchanged -- no step counter for skipped entries

**B. Extended `tests/test-windows.ps1`** (198 lines, was 155)

Added 21 new Phase 13 test assertions in a new section:

| Category | Tests | What's Validated |
|----------|-------|-----------------|
| File existence | 1 | progress.psm1 exists |
| CLI switches | 3 | -DryRun, -Verbose, -Unattended in setup.ps1 |
| Env var mapping | 3 | DRY_RUN, VERBOSE, UNATTENDED env mappings |
| Timer + summary | 2 | StartTime capture, Show-CompletionSummary call |
| Module content | 4 | Three function declarations + Export-ModuleMember |
| Step counters | 4 | [Step X/Y] pattern, Get-PlatformStepCount, Show-DryRunBanner, progress import |
| Anti-patterns | 2 | No CmdletBinding in setup.ps1 or main.ps1 |

Total assertions: 58 (was 37, added 21).

**Files:** `src/platforms/windows/main.ps1` (modified), `tests/test-windows.ps1` (modified)

## Deviations from Plan

None -- plan executed exactly as written.

## Verification Results

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| DryRun/Verbose/Unattended in setup.ps1 | All 3 present | 13 matches | PASS |
| progress.psm1 exists | Yes | Yes | PASS |
| [Step X/Y] in main.ps1 | Present | 4 matches | PASS |
| Show-CompletionSummary in setup.ps1 | Present | 1 match | PASS |
| CmdletBinding in setup.ps1 | 0 | 0 | PASS |
| CmdletBinding in main.ps1 | 0 | 0 | PASS |
| Phase 13 tests in test-windows.ps1 | Present | Present | PASS |

## Self-Check: PASSED

All 4 files verified. Both commits (145043a, 94822e2) exist in git log.
