---
phase: 04-macos-platform
plan: 01
subsystem: infra
tags: [homebrew, macos, package-manager, shell, idempotent]

# Dependency graph
requires:
  - phase: 01-core-infrastructure
    provides: logging.sh, idempotent.sh (ensure_line_in_file, is_installed)
provides:
  - Homebrew installation script (install_homebrew, configure_shell_path)
  - macOS install directory structure (src/platforms/macos/install/)
affects: [04-02 (brew.sh needs Homebrew), 04-03 (brew-cask.sh needs Homebrew)]

# Tech tracking
tech-stack:
  added: []
  patterns: [architecture detection via uname -m, NONINTERACTIVE=1 for Homebrew, main guard for sourceable scripts]

key-files:
  created:
    - src/platforms/macos/install/homebrew.sh
    - src/platforms/macos/install/.gitkeep
  modified: []

key-decisions:
  - "Main guard pattern: if [[ BASH_SOURCE == $0 ]] for dual sourceable/executable usage"
  - "Architecture detection: uname -m arm64 -> /opt/homebrew, else /usr/local"
  - "Xcode CLI Tools: interactive fallback with read -r prompt for GUI installer"

patterns-established:
  - "get_brew_prefix(): architecture-aware Homebrew prefix detection"
  - "Main guard: script can be sourced for functions or executed directly"
  - "macOS installer pattern: following apt.sh structure with macOS-specific adaptations"

# Metrics
duration: 2min
completed: 2026-02-06
---

# Phase 4 Plan 01: Homebrew Installer Summary

**Idempotent Homebrew installer with architecture detection (Apple Silicon/Intel), NONINTERACTIVE mode, and shell profile configuration via ensure_line_in_file**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-06T16:19:39Z
- **Completed:** 2026-02-06T16:21:43Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created homebrew.sh with install_homebrew() and configure_shell_path() functions
- Architecture detection for Apple Silicon (/opt/homebrew) vs Intel (/usr/local)
- Idempotent: skips installation if brew already in PATH or at expected prefix
- DRY_RUN == "true" checks before any mutation (consistent with Phase 3 decision)
- Shell profile configuration via ensure_line_in_file from idempotent.sh

## Task Commits

Each task was committed atomically:

1. **Task 2: Create install directory structure** - `c633b1e` (chore)
2. **Task 1: Create homebrew.sh installer** - `556a7db` (feat)

**Plan metadata:** pending (docs: complete homebrew installer plan)

## Files Created/Modified
- `src/platforms/macos/install/homebrew.sh` - Idempotent Homebrew installer with install_homebrew() and configure_shell_path()
- `src/platforms/macos/install/.gitkeep` - Directory placeholder for macOS installers

## Decisions Made
- Executed Task 2 (directory creation) before Task 1 (script creation) since directory is a prerequisite
- Used main guard pattern (`if [[ "${BASH_SOURCE[0]}" == "$0" ]]`) so script can be sourced for its functions or executed directly
- Removed SCRIPT_NAME constant (unused in this script, unlike apt.sh which uses it in cleanup)
- Xcode CLI Tools check uses interactive read -r prompt since GUI installer requires user action

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed shellcheck SC2086 quoting warnings**
- **Found during:** Task 1 (homebrew.sh creation)
- **Issue:** `${brew_prefix}/bin/brew` in command substitution not properly quoted
- **Fix:** Changed `$(${brew_prefix}/bin/brew shellenv)` to `$("${brew_prefix}"/bin/brew shellenv)`
- **Files modified:** src/platforms/macos/install/homebrew.sh
- **Verification:** shellcheck passes (only SC1091 info remaining, same as apt.sh)
- **Committed in:** 556a7db (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor quoting fix for shellcheck compliance. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Homebrew installer ready for use by brew.sh (04-02) and brew-cask.sh (04-03)
- macOS install directory structure created
- Script follows established apt.sh pattern for consistency

---
*Phase: 04-macos-platform*
*Completed: 2026-02-06*
