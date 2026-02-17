---
phase: 10-windows-cross-platform-installers
plan: 01
subsystem: windows-installers
tags: [windows, powershell, cargo, npm, ai-tools, winget, installer]
dependency_graph:
  requires: [06-01, 06-02]
  provides: [windows-cargo-installer, windows-npm-installer, windows-ai-tools-installer]
  affects: [src/platforms/windows/install/, src/platforms/windows/main.ps1]
tech_stack:
  added: []
  patterns: [winget-first-cargo-fallback, prefix-based-dispatch, self-contained-helpers]
key_files:
  created:
    - src/platforms/windows/install/cargo.ps1
    - src/platforms/windows/install/npm.ps1
    - src/platforms/windows/install/ai-tools.ps1
  modified: []
decisions:
  - "WinGet-first strategy for cargo.txt packages (17 WinGet IDs, 11 cargo-install fallback)"
  - "Do NOT auto-install Rust/rustup (per research decision)"
  - "zellij in SkipOnWindows list (no Windows support, different from null WinGet mapping)"
  - "curl:ollama maps to winget install Ollama.Ollama on Windows"
  - "Each script is self-contained with own helper functions (separate process execution)"
  - "npm list -g for idempotent check (handles scoped @scope/pkg packages per Phase 5 decision)"
metrics:
  duration: 3 min
  completed: 2026-02-17
---

# Phase 10 Plan 01: Windows Cross-Platform Installers Summary

**One-liner:** Three PowerShell installer scripts (cargo.ps1, npm.ps1, ai-tools.ps1) using WinGet-first strategy for cargo packages, npm install -g for npm packages, and prefix-based dispatch for AI tools.

## What Was Done

### Task 1: Create cargo.ps1 - WinGet-first Cargo package installer
**Commit:** 4c9bb7f

Created `src/platforms/windows/install/cargo.ps1` (226 lines) following the exact winget.ps1 structure:

- **WinGetMap hashtable**: 28 entries total -- 17 with WinGet IDs (bat, eza, fd-find, lsd, ripgrep, dust, bottom, procs, tokei, hyperfine, zoxide, git-delta, gitui, starship, nu, helix, atuin), 11 with $null (sd, bacon, xsv, jql, htmlq, cargo-watch, cargo-edit, cargo-update, cargo-audit, cargo-expand, cargo-outdated, cargo-binstall)
- **SkipOnWindows**: zellij excluded entirely (no Windows support)
- **Three-tier Install-CargoPackage**: (1) check SkipOnWindows, (2) try WinGet if mapping exists, (3) fall back to `cargo install`
- **Test-WinGetInstalled**: Exact copy from winget.ps1 (winget list --id --exact + output match)
- **Test-CargoInstalled**: cargo install --list + regex match
- DRY_RUN guards after idempotent checks, before mutations
- WinGet availability check at top (not fatal -- cargo might still work)

### Task 2: Create npm.ps1 - npm global package installer
**Commit:** c9f16d7

Created `src/platforms/windows/install/npm.ps1` (126 lines) following the exact winget.ps1 structure:

- **Test-NpmInstalled**: `npm list -g $PackageName` -- works for both scoped (@scope/pkg) and unscoped packages
- **Install-NpmPackage**: Idempotent check, DRY_RUN guard, `npm install -g`, LASTEXITCODE check, Add-FailedItem on failure
- **Node.js availability guard**: Checks both `node` and `npm` commands. Graceful exit with install guidance (WinGet fnm or nodejs.org)
- Count check: skip if 0 packages loaded

### Task 3: Create ai-tools.ps1 - prefix-based AI tools installer
**Commit:** 52c0742

Created `src/platforms/windows/install/ai-tools.ps1` (226 lines) porting prefix dispatch from `src/install/ai-tools.sh`:

- **Install-AiTool** with `switch ($prefix)` dispatch:
  - `npm:` -- npm install -g with Node.js check and Test-NpmInstalled idempotent check
  - `curl:ollama` -- maps to `winget install Ollama.Ollama` (Windows-native, no curl needed)
  - `curl:*` -- DEBUG skip unknown tool
  - `npx:` -- DEBUG skip (runs on demand)
  - `uv:` -- DEBUG skip (runs on demand)
  - bare words -- DEBUG skip (informational only)
- **Self-contained helpers**: Test-NpmInstalled and Test-WinGetInstalled duplicated (each script runs in separate process)
- **Show-AiSummary**: API key configuration guidance (ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY)

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **WinGet-first for cargo packages**: 17 of 28 cargo.txt packages have WinGet pre-built binaries. Avoids MSVC build tools requirement and 10x faster installs.
2. **No Rust auto-install**: If cargo is not available, cargo-install-only packages are skipped with WARN. Keeps scripts simple and avoids MSVC dependency trap.
3. **zellij in SkipOnWindows**: Separate semantic from null WinGet mapping. zellij has no Windows support at all, while null-mapped packages can still be installed via cargo.
4. **curl:ollama -> WinGet on Windows**: Native Windows package available via `winget install Ollama.Ollama`.
5. **Self-contained helpers**: Each script includes its own Test-NpmInstalled/Test-WinGetInstalled because scripts run as separate processes from main.ps1.
6. **npm list -g for idempotent check**: Works for both scoped (@anthropic-ai/claude-code) and unscoped packages.

## Verification Results

| Check | Result |
|-------|--------|
| cargo.ps1 #Requires -Version 5.1 | PASS |
| cargo.ps1 Import-Module (3 modules) | PASS |
| cargo.ps1 WinGetMap (28 entries, 17 non-null) | PASS |
| cargo.ps1 SkipOnWindows with zellij | PASS |
| cargo.ps1 Test-WinGetInstalled | PASS |
| cargo.ps1 Test-CargoInstalled | PASS |
| cargo.ps1 Install-CargoPackage | PASS |
| cargo.ps1 Read-PackageFile cargo.txt | PASS |
| cargo.ps1 DRY_RUN check | PASS |
| cargo.ps1 Show-FailureSummary | PASS |
| cargo.ps1 exit 0 | PASS |
| cargo.ps1 >= 80 lines (226 lines) | PASS |
| npm.ps1 #Requires -Version 5.1 | PASS |
| npm.ps1 Import-Module (3 modules) | PASS |
| npm.ps1 Test-NpmInstalled with npm list -g | PASS |
| npm.ps1 Install-NpmPackage with npm install -g | PASS |
| npm.ps1 Get-Command node check | PASS |
| npm.ps1 Read-PackageFile npm.txt | PASS |
| npm.ps1 DRY_RUN check | PASS |
| npm.ps1 Show-FailureSummary | PASS |
| npm.ps1 exit 0 | PASS |
| npm.ps1 >= 50 lines (126 lines) | PASS |
| ai-tools.ps1 #Requires -Version 5.1 | PASS |
| ai-tools.ps1 Import-Module (3 modules) | PASS |
| ai-tools.ps1 Install-AiTool with switch ($prefix) | PASS |
| ai-tools.ps1 npm/curl/npx/uv cases | PASS |
| ai-tools.ps1 Ollama.Ollama WinGet ID | PASS |
| ai-tools.ps1 Read-PackageFile ai-tools.txt | PASS |
| ai-tools.ps1 DRY_RUN check | PASS |
| ai-tools.ps1 Show-AiSummary with API keys | PASS |
| ai-tools.ps1 Show-FailureSummary | PASS |
| ai-tools.ps1 exit 0 | PASS |
| ai-tools.ps1 >= 70 lines (226 lines) | PASS |

## Self-Check: PASSED

- FOUND: src/platforms/windows/install/cargo.ps1
- FOUND: src/platforms/windows/install/npm.ps1
- FOUND: src/platforms/windows/install/ai-tools.ps1
- FOUND: 4c9bb7f (Task 1 commit)
- FOUND: c9f16d7 (Task 2 commit)
- FOUND: 52c0742 (Task 3 commit)
