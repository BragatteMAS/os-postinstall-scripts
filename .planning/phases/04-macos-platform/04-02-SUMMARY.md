---
phase: 04-macos-platform
plan: 02
subsystem: package-installation
tags: [homebrew, brew, cask, macos, data-driven, installer]
depends_on:
  requires: ["04-01"]
  provides: ["brew-formula-installer", "brew-cask-installer"]
  affects: ["04-03"]
tech-stack:
  added: []
  patterns: ["data-driven-installer", "idempotent-check", "cask-specific-detection"]
key-files:
  created:
    - src/platforms/macos/install/brew.sh
    - src/platforms/macos/install/brew-cask.sh
  modified: []
decisions:
  - id: "04-02-01"
    decision: "Cask detection uses brew list --cask (not core is_brew_installed)"
    reason: "is_brew_installed() from core uses `brew list` which only checks formulae; casks require the --cask flag"
metrics:
  duration: "2 min"
  completed: "2026-02-06"
---

# Phase 4 Plan 2: Brew Formula and Cask Installers Summary

Data-driven Homebrew installers for formulae (brew.txt) and casks (brew-cask.txt) mirroring apt.sh pattern with HOMEBREW_NO_INSTALL_UPGRADE=1 and DRY_RUN support.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create brew.sh formula installer | 5dd08f9 | src/platforms/macos/install/brew.sh |
| 2 | Create brew-cask.sh cask installer | 8f89a38 | src/platforms/macos/install/brew-cask.sh |

## Key Implementation Details

### brew.sh (Formulae)
- Sources 4 core utilities: logging.sh, idempotent.sh, errors.sh, packages.sh
- Verifies `brew` is available before any installation
- Uses `is_brew_installed()` from core/idempotent.sh (no redefinition)
- `_brew_formula_install()` helper with underscore prefix (private)
- `HOMEBREW_NO_INSTALL_UPGRADE=1` inline env var prevents unwanted upgrades
- DRY_RUN check uses `== "true"` (per Phase 3 decision)
- `record_failure()` + `show_failure_summary()` for failure tracking

### brew-cask.sh (GUI Applications)
- Same structure as brew.sh
- Local `_is_cask_installed()` uses `brew list --cask` (formulae-only check from core is insufficient)
- `_brew_cask_install()` helper uses `brew install --cask`
- Same DRY_RUN, failure tracking, and cleanup patterns

### Pattern Consistency with apt.sh
Both scripts follow the established data-driven installer pattern:
1. Source core utilities
2. Verify package manager available
3. Load packages from data file
4. Loop with idempotent check per package
5. Track failures, show summary
6. Always exit 0

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| 04-02-01 | Cask detection uses `brew list --cask` locally | Core `is_brew_installed()` uses `brew list` which only checks formulae; casks need the `--cask` flag |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All 9 verification criteria passed:
1. Both files exist and are executable
2. Both shellcheck clean (warning level)
3. Both source all 4 core utilities
4. brew.sh loads brew.txt, brew-cask.sh loads brew-cask.txt
5. Both use HOMEBREW_NO_INSTALL_UPGRADE=1
6. Both have cleanup traps
7. Both always exit 0
8. Both respect DRY_RUN=true (== "true" check)
9. brew.sh does NOT redefine is_brew_installed()

## Next Phase Readiness

Plan 04-03 (macOS defaults and integration) can proceed. The brew and cask installers are ready to be orchestrated by the macOS setup entry point.
