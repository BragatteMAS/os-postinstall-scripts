---
phase: 13-windows-parity
plan: 02
subsystem: windows-core-modules
tags: [powershell, cmdletbinding, wpar-04, backward-compatible]
dependency_graph:
  requires: [13-01]
  provides: [cmdletbinding-all-core-modules, verbose-debug-propagation]
  affects: [setup.ps1-callers, main.ps1-callers, install-scripts]
tech_stack:
  added: []
  patterns: [CmdletBinding-on-all-exported-functions, empty-param-for-parameterless-functions]
key_files:
  created: []
  modified:
    - src/platforms/windows/core/logging.psm1
    - src/platforms/windows/core/errors.psm1
    - src/platforms/windows/core/packages.psm1
    - src/platforms/windows/core/idempotent.psm1
    - tests/test-windows.ps1
decisions:
  - "Bare [CmdletBinding()] only -- no ShouldProcess (per STATE.md project decision)"
  - "Functions without param blocks get [CmdletBinding()] + empty param() added"
metrics:
  duration: 2 min
  completed: 2026-02-18
---

# Phase 13 Plan 02: CmdletBinding Core Modules Summary

Add [CmdletBinding()] to all 9 exported functions across 4 core PowerShell modules for native -Verbose/-Debug propagation (WPAR-04).

## What Was Done

### Task 1: Add [CmdletBinding()] to 9 exported functions (885e318)

Added `[CmdletBinding()]` attribute to every exported function in the 4 core modules:

- **logging.psm1** (1 function): Write-Log
- **errors.psm1** (4 functions): Add-FailedItem, Show-FailureSummary, Get-FailureCount, Clear-Failures
- **packages.psm1** (1 function): Read-PackageFile
- **idempotent.psm1** (3 functions): Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled

For 3 parameterless functions (Show-FailureSummary, Get-FailureCount, Clear-Failures), added both `[CmdletBinding()]` and an empty `param()` block -- required by PowerShell for CmdletBinding to take effect.

No ShouldProcess. No signature changes. 100% backward compatible.

### Task 2: CmdletBinding verification tests (a18e205)

Added 13 new test assertions to `tests/test-windows.ps1`:

- 4 Assert-Contains: CmdletBinding presence in each core module
- 4 Assert-Pass: exact CmdletBinding count per module (1+4+1+3=9)
- 4 Assert-NotContains: no ShouldProcess in any core module
- 1 Assert-Contains: progress.psm1 CmdletBinding (from 13-01)

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| logging.psm1 CmdletBinding count | 1 | 1 |
| errors.psm1 CmdletBinding count | 4 | 4 |
| packages.psm1 CmdletBinding count | 1 | 1 |
| idempotent.psm1 CmdletBinding count | 3 | 3 |
| Total across 4 modules | 9 | 9 |
| ShouldProcess in core/*.psm1 | 0 | 0 |
| CmdletBinding in setup.ps1 | 0 | 0 |
| CmdletBinding in main.ps1 | 0 | 0 |

## Deviations from Plan

None -- plan executed exactly as written.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 885e318 | feat(13-02): add [CmdletBinding()] to all 9 exported functions in 4 core modules |
| 2 | a18e205 | test(13-02): add CmdletBinding verification tests for WPAR-04 |

## Self-Check: PASSED

- All 5 modified files exist on disk
- Both commits (885e318, a18e205) verified in git log
- CmdletBinding counts match expected (1+4+1+3=9)
- No ShouldProcess found
- No CmdletBinding in scripts (setup.ps1, main.ps1)
