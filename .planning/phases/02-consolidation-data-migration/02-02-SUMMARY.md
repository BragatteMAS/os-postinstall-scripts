---
phase: 02-consolidation-data-migration
plan: 02
subsystem: data
tags: [bash, shell, packages, data-driven, profiles]

# Dependency graph
requires:
  - phase: 02-01
    provides: packages.sh with load_packages(), load_profile(), get_packages_for_manager()
provides:
  - 9 package list files under data/packages/
  - 3 profile composition files under data/packages/profiles/
  - Extracted packages from platforms/linux/auto/ before removal
affects: [02-03, 02-04, 02-05, 03-entry-points, 04-macos-platform]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One package per line with # comments for categories"
    - "Profile files list other package files to include"

key-files:
  created:
    - data/packages/apt.txt
    - data/packages/brew.txt
    - data/packages/brew-cask.txt
    - data/packages/cargo.txt
    - data/packages/npm.txt
    - data/packages/winget.txt
    - data/packages/ai-tools.txt
    - data/packages/flatpak.txt
    - data/packages/snap.txt
    - data/packages/profiles/minimal.txt
    - data/packages/profiles/developer.txt
    - data/packages/profiles/full.txt
  modified: []

key-decisions:
  - "Package format: one per line with # comments for categorization"
  - "Profile composition: profiles list package files to include, not packages directly"
  - "Preserved auto/ packages in flatpak.txt and snap.txt before directory removal"

patterns-established:
  - "Package file format: # Comment, blank lines ignored, one package per line"
  - "Profile composition: list of package file names (apt.txt, cargo.txt, etc.)"

# Metrics
duration: 5min
completed: 2026-02-05
---

# Phase 2 Plan 2: Extract Package Lists Summary

**9 package list files and 3 profile composition files extracted from hardcoded arrays, enabling data-driven package installation**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-05T18:25:00Z
- **Completed:** 2026-02-05T18:30:xx
- **Tasks:** 3
- **Files created:** 12

## Accomplishments

- Extracted 406 total package entries from hardcoded arrays into 9 .txt files
- Created 3 profile composition files (minimal, developer, full) for tiered installation
- Preserved packages from platforms/linux/auto/ (flatpak.txt, snap.txt) before directory removal
- Validated end-to-end functionality: load_packages(), load_profile(), get_packages_for_manager()

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract package lists from scripts to .txt files** - `cad55d2` (feat)
2. **Task 2: Create profile composition files** - `ee8e4f6` (feat)
3. **Task 3: Validate package loading** - checkpoint:validation (user approved)

## Files Created

**Package Lists (data/packages/):**
- `apt.txt` - 77 lines: APT packages (git, curl, zsh, build-essential, etc.)
- `brew.txt` - 32 lines: Homebrew formulae for macOS
- `brew-cask.txt` - 31 lines: Homebrew casks (GUI apps)
- `cargo.txt` - 59 lines: Rust tools (bat, eza, fd-find, ripgrep, etc.)
- `npm.txt` - 21 lines: Global npm packages
- `winget.txt` - 67 lines: Windows packages for win11.ps1
- `ai-tools.txt` - 21 lines: AI/MCP tools (Claude CLI, etc.)
- `flatpak.txt` - 50 lines: Flatpak packages from auto/auto_flat.sh
- `snap.txt` - 48 lines: Snap packages from auto/auto_snap.sh

**Profile Files (data/packages/profiles/):**
- `minimal.txt` - Base system (apt.txt only)
- `developer.txt` - Developer profile (apt + cargo + npm)
- `full.txt` - All packages (apt + cargo + npm + ai-tools)

## Validation Results

All validation tests passed:

| Test | Result |
|------|--------|
| `load_packages("apt.txt")` | 46 packages loaded |
| `load_profile("developer")` | 84 packages loaded |
| `get_packages_for_manager("cargo")` | 30 packages loaded |
| Error handling (missing file) | Exit code: 1 (graceful) |

## Decisions Made

1. **Package file format:** One package per line with `#` comments for categorization. Blank lines and comments ignored during parsing.
2. **Profile composition approach:** Profile files list other package files (apt.txt, cargo.txt) rather than packages directly. This allows profiles to compose multiple managers.
3. **Preserved auto/ packages:** Extracted flatpak.txt and snap.txt from platforms/linux/auto/ before the directory is removed in plan 02-05.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for:**
- Plan 02-03: Migrate platforms/linux/ to src/platforms/linux/
- Plan 02-04: Consolidate dotfile configurations to data/dotfiles/
- Plan 02-05: Delete obsolete auto/ directory (packages now extracted)

**Data foundation complete:**
- All package data separated from code
- Package loading functions tested and working
- Profile system ready for Phase 4 interactive selection UI

---
*Phase: 02-consolidation-data-migration*
*Plan: 02*
*Completed: 2026-02-05*
