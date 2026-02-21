---
phase: 15-data-compatibility-fixes
plan: 02
subsystem: bash-compat-quality
tags: [bash-3.2, pipefail, powershell, validate-set, brew-data, macOS-compat]
dependency_graph:
  requires: []
  provides: [bash-3.2-macos-compat, pipefail-all-subshells, ps-param-validation, clean-brew-list]
  affects: [src/core/platform.sh, setup.sh, setup.ps1, src/platforms/windows/main.ps1]
tech_stack:
  added: []
  patterns: [warn-not-block, defensive-variable-expansion, multiline-regex]
key_files:
  created: []
  modified:
    - src/core/platform.sh
    - src/platforms/linux/main.sh
    - src/platforms/macos/main.sh
    - src/platforms/linux/install/apt.sh
    - src/platforms/linux/install/flatpak.sh
    - src/platforms/linux/install/snap.sh
    - src/platforms/linux/install/cargo.sh
    - src/platforms/macos/install/homebrew.sh
    - src/platforms/macos/install/brew.sh
    - src/platforms/macos/install/brew-cask.sh
    - src/install/dev-env.sh
    - src/install/rust-cli.sh
    - src/install/ai-tools.sh
    - setup.ps1
    - src/platforms/windows/main.ps1
    - src/platforms/windows/core/idempotent.psm1
    - data/packages/brew.txt
decisions:
  - "verify_bash_version() warns and returns 0 on macOS Bash < 4 (no Bash 4+ features used)"
  - "Used ${DETECTED_OS:-} defensive expansion in bash version check for safety"
  - "node removed from brew.txt -- conflicts with fnm (src/install/fnm.sh)"
  - "fzf added under dedicated Terminal - Fuzzy Finder section (Go binary, not Rust)"
  - "main.ps1 ValidateSet includes empty string '' for interactive menu mode"
metrics:
  duration: 2 min
  completed: 2026-02-21
---

# Phase 15 Plan 02: Bash 3.2 Compat, Pipefail, and Quality Fixes Summary

Bash 3.2 warn-not-block on macOS so setup.sh can bootstrap Homebrew before upgrading Bash, pipefail added to all 12 subshell scripts per CONVENTIONS.md, PowerShell parameter validation, cargo check multiline fix, and brew.txt data corrections.

## What Was Done

### Task 1: Fix verify_bash_version() macOS warn-not-block and add pipefail to all subshell scripts (c39f2d2)

**COMPAT-01:**
- Modified `verify_bash_version()` in `src/core/platform.sh` to detect macOS via `${DETECTED_OS:-}` and return 0 with `log_warn` instead of blocking with `log_error` + return 1
- Updated function header comment to reflect new behavior
- Linux and other platforms still block on Bash < 4

**QUAL-01:**
- Added `set -o pipefail` as line 2 (after shebang, before header comment) to all 12 subshell scripts:
  - `src/platforms/linux/main.sh`, `src/platforms/macos/main.sh`
  - `src/platforms/linux/install/apt.sh`, `flatpak.sh`, `snap.sh`, `cargo.sh`
  - `src/platforms/macos/install/homebrew.sh`, `brew.sh`, `brew-cask.sh`
  - `src/install/dev-env.sh`, `rust-cli.sh`, `ai-tools.sh`
- `set -o pipefail` available since Bash 3.0, safe on macOS Bash 3.2

### Task 2: Apply PowerShell ValidateSet, multiline-safe cargo check, and brew.txt corrections (951860b)

**QUAL-02a:** Added `[ValidateSet]` to `-Profile` parameter in both `setup.ps1` (minimal/developer/full) and `main.ps1` (includes empty string for interactive mode)

**QUAL-02b:** Made `Test-CargoInstalled` in `idempotent.psm1` multiline-safe: `(cargo install --list 2>$null) -join` with `(?m)` regex flag so `^` anchors at each line start

**QUAL-02c:** Removed `node` from `brew.txt` (conflicts with fnm), added explanatory comment

**QUAL-02d:** Added `fzf` to `brew.txt` under new "Terminal - Fuzzy Finder" section

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| macOS warn path (return 0) | present | present |
| Pipefail missing count | 0 | 0 |
| ValidateSet in setup.ps1 | 1 | 1 |
| ValidateSet in main.ps1 | 1 | 1 |
| -join in idempotent.psm1 | 1 | 1 |
| node in brew.txt | 0 | 0 |
| fzf in brew.txt | 1 | 1 |

## Deviations from Plan

None -- plan executed exactly as written.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | c39f2d2 | feat(15-02): fix Bash 3.2 warn-not-block on macOS and add pipefail to subshell scripts |
| 2 | 951860b | fix(15-02): add PS ValidateSet, multiline-safe cargo check, and brew.txt corrections |

## Self-Check: PASSED

- All 17 modified files verified on disk
- Both commits (c39f2d2, 951860b) verified in git log
- verify_bash_version() contains macOS return 0 path
- All 12 subshell scripts have pipefail within first 3 lines
- PowerShell ValidateSet present in both setup.ps1 and main.ps1
- brew.txt: node removed, fzf added
