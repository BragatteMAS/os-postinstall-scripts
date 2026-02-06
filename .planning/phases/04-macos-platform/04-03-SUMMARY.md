---
phase: 04-macos-platform
plan: 03
subsystem: installer
tags: [bash, macos, homebrew, brew, profiles, orchestrator]

# Dependency graph
requires:
  - phase: 04-01
    provides: homebrew.sh installer with architecture detection
  - phase: 04-02
    provides: brew.sh and brew-cask.sh data-driven installers
  - phase: 02-02
    provides: profile system with minimal/developer/full definitions
provides:
  - macOS main.sh orchestrator with profile-based installation
  - Interactive menu for direct execution
  - Unattended mode for setup.sh integration
  - Platform-agnostic profile files with brew package support
affects: [05-cross-platform, linux-main-profile-migration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MACOS_DIR pattern: avoid SCRIPT_DIR conflict when sourcing packages.sh"
    - "Platform-agnostic profiles: single file lists all platforms, main.sh filters"
    - "Dual-mode entry: $1 check for unattended, menu loop for interactive"

key-files:
  created:
    - src/platforms/macos/main.sh
  modified:
    - data/packages/profiles/minimal.txt
    - data/packages/profiles/developer.txt
    - data/packages/profiles/full.txt

key-decisions:
  - "MACOS_DIR instead of SCRIPT_DIR to avoid packages.sh readonly conflict"
  - "Platform-agnostic profiles: one file per tier, not per-platform variants"
  - "check_bash_upgrade warns but continues (user may need brew first to upgrade)"

patterns-established:
  - "MACOS_DIR: use dedicated variable when SCRIPT_DIR is clobbered by sourced modules"
  - "Profile dispatch: read profile file, case-match on package file names, skip non-platform"
  - "Dual-mode script: check $1 for unattended, fall through to interactive menu"

# Metrics
duration: 2min
completed: 2026-02-06
---

# Phase 4 Plan 3: macOS Main Orchestrator Summary

**Profile-based macOS orchestrator with interactive menu and unattended mode, dispatching to homebrew/brew/cask installers**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-06T16:30:24Z
- **Completed:** 2026-02-06T16:32:30Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- macOS main.sh with dual-mode operation (interactive menu + unattended from setup.sh)
- Profile-based installation dispatching to homebrew.sh, brew.sh, brew-cask.sh
- Platform-agnostic profiles updated with brew.txt and brew-cask.txt
- Bash version check with upgrade instructions for macOS Bash 3.2

## Task Commits

Each task was committed atomically:

1. **Task 1: Create macOS main.sh orchestrator** - `6f79e1b` (feat)
2. **Task 2: Update profiles to include brew packages** - `281b798` (feat)

## Files Created/Modified
- `src/platforms/macos/main.sh` - Main orchestrator with profile menu, install_profile(), check_bash_upgrade()
- `data/packages/profiles/minimal.txt` - Added brew.txt for macOS
- `data/packages/profiles/developer.txt` - Added brew.txt and brew-cask.txt for macOS
- `data/packages/profiles/full.txt` - Added brew.txt and brew-cask.txt for macOS

## Decisions Made
- **MACOS_DIR variable:** Used `MACOS_DIR` instead of `SCRIPT_DIR` because packages.sh overwrites SCRIPT_DIR with its own location (src/core/) and makes it readonly. This avoids the path conflict when dispatching to install/ sub-scripts.
- **Platform-agnostic profiles:** Single profile files list all platforms (apt.txt, brew.txt, etc.). Each platform's main.sh contains a case statement that processes its own files and silently skips others. This avoids duplicating profile definitions per-platform.
- **Bash check warns but continues:** check_bash_upgrade() warns about Bash < 4.0 but does not exit, because the user may need to install Homebrew first (via this script) to get a newer Bash.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] SCRIPT_DIR conflict with packages.sh**
- **Found during:** Task 1 (main.sh creation)
- **Issue:** packages.sh unconditionally sets SCRIPT_DIR to its own directory (src/core/) and marks it readonly. If main.sh set SCRIPT_DIR first, it would be overwritten, breaking dispatch paths like `${SCRIPT_DIR}/install/brew.sh`.
- **Fix:** Used `MACOS_DIR` as the script's own directory variable, leaving SCRIPT_DIR for packages.sh to manage.
- **Files modified:** src/platforms/macos/main.sh
- **Verification:** All dispatch paths (homebrew.sh, brew.sh, brew-cask.sh) use MACOS_DIR
- **Committed in:** 6f79e1b (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Variable naming change to avoid runtime conflict. No scope creep.

## Issues Encountered
None beyond the SCRIPT_DIR conflict noted in deviations.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 4 complete: all 3 plans (homebrew installer, brew/cask installers, main orchestrator) delivered
- setup.sh dispatch to macos/main.sh now works (file exists at expected path)
- Linux main.sh asymmetry noted: does not yet use profile-based dispatch (deferred to Phase 5)
- macOS ships Bash 3.2: check_bash_upgrade() warns but continues (user can upgrade after brew install)

---
*Phase: 04-macos-platform*
*Completed: 2026-02-06*
