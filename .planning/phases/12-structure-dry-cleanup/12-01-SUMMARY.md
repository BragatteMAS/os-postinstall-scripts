---
phase: 12-structure-dry-cleanup
plan: 01
subsystem: windows-powershell-modules
tags: [dry, refactor, powershell, idempotent, ssot]
dependency_graph:
  requires: []
  provides: [idempotent.psm1, shared-test-functions]
  affects: [winget.ps1, cargo.ps1, npm.ps1, ai-tools.ps1]
tech_stack:
  added: []
  patterns: [Import-Module shared module, Export-ModuleMember]
key_files:
  created:
    - src/platforms/windows/core/idempotent.psm1
  modified:
    - src/platforms/windows/install/winget.ps1
    - src/platforms/windows/install/cargo.ps1
    - src/platforms/windows/install/npm.ps1
    - src/platforms/windows/install/ai-tools.ps1
decisions:
  - Extract Test-CargoInstalled into shared module even though not duplicated (future-proofing for Phase 13)
metrics:
  duration: 2 min
  completed: 2026-02-18
  tasks: 2/2
---

# Phase 12 Plan 01: DRY-01 Idempotent Check Module Summary

Extracted Test-WinGetInstalled (3x duplication), Test-NpmInstalled (2x duplication), and Test-CargoInstalled into a single shared idempotent.psm1 module, rewiring all four PS1 installer scripts to import from it.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Create idempotent.psm1 shared module | ed237a6 | New module with 3 exported functions |
| 2 | Rewire all PS1 installers | 82d4939 | 4 files: removed 133 lines of duplicate code, added imports |

## What Changed

### New File: idempotent.psm1

Created `src/platforms/windows/core/idempotent.psm1` with three exported functions:
- `Test-WinGetInstalled` -- checks winget package by exact ID
- `Test-NpmInstalled` -- checks npm global package
- `Test-CargoInstalled` -- checks cargo installed packages

Follows existing module style (see logging.psm1): `#Requires -Version 5.1`, comment block header, `.SYNOPSIS` help comments, `Export-ModuleMember` at end.

### Modified Files: 4 PS1 Installers

Each file received one line added (`Import-Module idempotent.psm1 -Force`) and local function definitions removed:

| File | Functions Removed | Lines Removed |
|------|------------------|---------------|
| winget.ps1 | Test-WinGetInstalled | 21 |
| cargo.ps1 | Test-WinGetInstalled, Test-CargoInstalled | 43 |
| npm.ps1 | Test-NpmInstalled | 20 |
| ai-tools.ps1 | Test-NpmInstalled, Test-WinGetInstalled | 45 |

Net change: +74 lines (new module), -133 lines (removed duplicates) = **-59 lines**.

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| function Test-WinGetInstalled in src/platforms/windows/ | 1 match (idempotent.psm1) | 1 match |
| function Test-NpmInstalled in src/platforms/windows/ | 1 match (idempotent.psm1) | 1 match |
| function Test-CargoInstalled in src/platforms/windows/ | 1 match (idempotent.psm1) | 1 match |
| Files importing idempotent.psm1 | 4 files | 4 files |

## Deviations from Plan

### Pre-staged File Rename Captured

The Task 1 commit (ed237a6) also captured a pre-staged `git mv` rename of `src/installers/dotfiles-install.sh` to `src/install/dotfiles-install.sh` that was already in the git index before plan execution began. This rename is part of DRY-02 (Plan 02 scope), not Plan 01. It was not added by this execution -- it was already staged. No other unintended changes.

## Decisions Made

1. **Include Test-CargoInstalled in shared module** -- Even though it was only defined in cargo.ps1 (not duplicated), the research explicitly recommended extraction. Phase 13 (Windows Parity) may need it elsewhere, and it costs nothing to include.

## Self-Check: PASSED

- FOUND: src/platforms/windows/core/idempotent.psm1
- FOUND: 12-01-SUMMARY.md
- FOUND: commit ed237a6
- FOUND: commit 82d4939
