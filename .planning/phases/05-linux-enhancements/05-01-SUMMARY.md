---
phase: 05-linux-enhancements
plan: 01
subsystem: infra
tags: [apt, dpkg, retry, backoff, non-interactive, linux]

# Dependency graph
requires:
  - phase: 01-core-infrastructure
    provides: retry_with_backoff, record_failure, is_apt_installed, load_packages, logging
  - phase: 02-consolidation-data-migration
    provides: data-driven installer pattern, apt.txt package files
provides:
  - Hardened APT installer with dpkg lock handling, network retry, two-pass support
affects: [05-linux-enhancements (remaining plans), linux main.sh orchestrator]

# Tech tracking
tech-stack:
  added: []
  patterns: [DPkg::Lock::Timeout=60 for lock handling, retry_with_backoff wrapper for apt commands, APT_NONINTERACTIVE_OPTS array pattern, two-pass install via --post flag]

key-files:
  created: []
  modified: [src/platforms/linux/install/apt.sh]

key-decisions:
  - "DPkg::Lock::Timeout=60 replaces manual fuser loop (simpler, built-in apt feature)"
  - "retry_with_backoff from core/errors.sh (no local redefinition)"
  - "is_apt_installed from core/idempotent.sh (removed local duplicate)"
  - "log_warn on install failure (not log_error) -- script continues"
  - "No autoclean/autoremove (setup script, not maintenance tool)"

patterns-established:
  - "APT lock handling: -o DPkg::Lock::Timeout=60 instead of fuser polling"
  - "Two-pass install: --post flag selects apt-post.txt"
  - "Non-interactive opts: APT_NONINTERACTIVE_OPTS array appended to command"

# Metrics
duration: 2min
completed: 2026-02-06
---

# Phase 5 Plan 1: Hardened APT Installer Summary

**APT installer with DPkg::Lock::Timeout=60 lock handling, retry_with_backoff on update/install, DEBIAN_FRONTEND conditional with --force-confold, and --post flag for two-pass installation**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-06T20:58:52Z
- **Completed:** 2026-02-06T21:00:35Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Replaced fragile fuser lock-polling loop with built-in DPkg::Lock::Timeout=60
- Added retry_with_backoff (3 retries, exponential backoff) to both apt-get update and install
- Added DEBIAN_FRONTEND=noninteractive with --force-confold for non-interactive mode
- Added two-pass install support via --post flag (apt.txt first pass, apt-post.txt second pass)
- Removed autoclean/autoremove (setup script, not maintenance tool)
- Removed local is_apt_installed duplicate in favor of core/idempotent.sh version

## Task Commits

Each task was committed atomically:

1. **Task 1: Add retry_with_backoff() and harden safe_apt_update()** - `ef71d1c` (feat)
2. **Task 2: Add two-pass install support (--post flag)** - `05ae37c` (feat)

## Files Created/Modified
- `src/platforms/linux/install/apt.sh` - Hardened APT installer with lock handling, retry, two-pass support

## Decisions Made
- Used DPkg::Lock::Timeout=60 instead of manual fuser loop -- simpler, built-in apt feature, no race conditions
- Reused retry_with_backoff from core/errors.sh instead of defining locally -- DRY principle
- Used is_apt_installed from core/idempotent.sh instead of local duplicate -- SSoT
- Changed install failure from log_error to log_warn -- script continues, failure tracked via record_failure
- No autoclean/autoremove -- this is a setup script, not a maintenance tool

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- APT installer hardened and ready for integration with Linux main.sh orchestrator
- Two-pass support (apt.txt + apt-post.txt) ready for profile-based dispatch
- Same hardening pattern (DPkg::Lock::Timeout + retry_with_backoff) can be applied to other Linux installers

---
*Phase: 05-linux-enhancements*
*Completed: 2026-02-06*
