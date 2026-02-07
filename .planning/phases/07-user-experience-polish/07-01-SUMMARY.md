---
phase: 07-user-experience-polish
plan: 01
subsystem: ux
tags: [bash, progress-feedback, step-counter, dry-run, cli-ux]

# Dependency graph
requires:
  - phase: 05-linux-enhancements
    provides: Linux orchestrator with profile dispatch
  - phase: 04-macos-platform
    provides: macOS orchestrator with profile dispatch
  - phase: 01-core-infrastructure
    provides: logging.sh, errors.sh module patterns
provides:
  - src/core/progress.sh module with show_dry_run_banner() and count_platform_steps()
  - Step-counted Linux profile dispatch with [Step X/Y] prefix
  - Step-counted macOS profile dispatch with [Step X/Y] prefix
  - DRY_RUN banner display at install_profile start
affects: [07-02-dry-run-mode, 07-03-completion-summary]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Step counter: count_platform_steps() pre-counts, dispatch loop increments"
    - "DRY_RUN banner: show_dry_run_banner() called once at install_profile start"
    - "Platform filtering for step count: case statement matches dispatch case"

key-files:
  created:
    - src/core/progress.sh
  modified:
    - src/platforms/linux/main.sh
    - src/platforms/macos/main.sh

key-decisions:
  - "cargo.txt excluded from macOS step count (no macOS cargo installer exists)"
  - "macOS ai-tools.txt dispatch enabled (Phase 5 cross-platform installer exists)"
  - "winget.txt skip case added to both orchestrators (Windows-only file now in profiles)"
  - "Arithmetic uses $((count + 1)) instead of ((count++)) for Bash 3.2 compat"

patterns-established:
  - "Step counter pattern: count_platform_steps pre-count + current_step increment at dispatch"
  - "DRY_RUN banner pattern: show_dry_run_banner at top of install_profile"
  - "INSTALL_DIR variable: added to macOS main.sh for cross-platform installer access"

# Metrics
duration: 4min
completed: 2026-02-07
---

# Phase 7 Plan 01: Progress Feedback System Summary

**Step counter module (progress.sh) with [Step X/Y] prefixed dispatch in Linux and macOS orchestrators, plus DRY_RUN banner**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-07T13:05:42Z
- **Completed:** 2026-02-07T13:10:22Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created src/core/progress.sh with show_dry_run_banner() and count_platform_steps() helpers
- Linux main.sh shows [Step X/Y] for all 10 platform-relevant dispatch points (developer profile: 8 steps, full: 10)
- macOS main.sh shows [Step X/Y] for Homebrew + brew/brew-cask/ai-tools dispatch (minimal: 2, developer/full: 4)
- Step counts exclude non-platform files (no phantom brew steps on Linux, no apt steps on macOS)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create src/core/progress.sh module** - `94a5b62` (feat)
2. **Task 2: Add step counting to Linux and macOS orchestrators** - `07896da` (feat)

## Files Created/Modified

- `src/core/progress.sh` - Step counter helpers and DRY_RUN banner (new module)
- `src/platforms/linux/main.sh` - Step-counted profile dispatch with [Step X/Y] prefix
- `src/platforms/macos/main.sh` - Step-counted profile dispatch, ai-tools.txt enabled, INSTALL_DIR added

## Decisions Made

- **cargo.txt excluded from macOS count:** No macOS cargo installer exists yet. Including it would create a phantom step where the counter increments but nothing happens. The counter must match actual dispatch.
- **ai-tools.txt enabled for macOS:** The cross-platform src/install/ai-tools.sh exists (Phase 5). The old "requires Phase 5" skip was stale.
- **winget.txt skip added:** Profiles now include winget.txt (Phase 6). Both orchestrators need to silently skip it instead of showing "Unknown package file" warnings.
- **$((x + 1)) over ((x++)):** Bash 3.2 on macOS handles $((x + 1)) more reliably than ((x++)). Explicit assignment is also clearer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed macOS stale "requires Phase 5" skips**
- **Found during:** Task 2 (macOS orchestrator update)
- **Issue:** macOS main.sh skipped cargo.txt, npm.txt, and ai-tools.txt with "requires Phase 5" message, but Phase 5 is complete. ai-tools.txt has a working cross-platform installer.
- **Fix:** Enabled ai-tools.txt dispatch via INSTALL_DIR/ai-tools.sh. Updated cargo.txt skip message to "no macOS installer". npm.txt skip changed to "handled by dev-env".
- **Files modified:** src/platforms/macos/main.sh
- **Verification:** bash -n syntax check, step count verification
- **Committed in:** 07896da (Task 2 commit)

**2. [Rule 1 - Bug] Removed cargo.txt from macOS step count in progress.sh**
- **Found during:** Task 2 (macOS orchestrator update)
- **Issue:** Plan listed cargo.txt as macOS-relevant, but no macOS cargo installer exists. Counting it would create phantom step (counter goes 1/4, 2/4, 3/4 then done -- user never sees 4/4).
- **Fix:** Removed cargo.txt from macOS case in count_platform_steps()
- **Files modified:** src/core/progress.sh
- **Verification:** count_platform_steps returns 3 for macOS developer (brew.txt, brew-cask.txt, ai-tools.txt), matching dispatch
- **Committed in:** 07896da (Task 2 commit)

**3. [Rule 2 - Missing Critical] Added winget.txt skip case to both orchestrators**
- **Found during:** Task 2 (orchestrator updates)
- **Issue:** Phase 6 added winget.txt to all profiles but Linux/macOS main.sh had no case for it, causing "Unknown package file: winget.txt" warning on every run.
- **Fix:** Added winget.txt case with log_debug skip in both orchestrators
- **Files modified:** src/platforms/linux/main.sh, src/platforms/macos/main.sh
- **Verification:** No "Unknown package file" for winget.txt
- **Committed in:** 07896da (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 bug fixes, 1 missing critical)
**Impact on plan:** All fixes necessary for correct step counting and clean output. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Progress feedback module ready for Plans 07-02 (DRY_RUN mode) and 07-03 (completion summary)
- show_dry_run_banner is in place; Plan 07-02 adds --dry-run flag parsing and DRY_RUN guards to installers
- Step counter infrastructure supports future per-section duration tracking if needed

---
*Phase: 07-user-experience-polish*
*Completed: 2026-02-07*
