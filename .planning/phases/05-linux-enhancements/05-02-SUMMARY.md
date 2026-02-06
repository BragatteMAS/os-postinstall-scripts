---
phase: 05-linux-enhancements
plan: 02
subsystem: infra
tags: [flatpak, snap, linux, package-manager, data-driven, idempotent]

# Dependency graph
requires:
  - phase: 01-core-infrastructure
    provides: logging.sh, idempotent.sh, errors.sh (retry_with_backoff, record_failure)
  - phase: 02-consolidation-data-migration
    provides: packages.sh (load_packages), data/packages/{flatpak,snap}*.txt
provides:
  - Data-driven Flatpak installer at src/platforms/linux/install/flatpak.sh
  - Data-driven Snap installer at src/platforms/linux/install/snap.sh
  - Classic confinement support via classic: prefix convention
  - Flathub remote auto-configuration
  - Two-pass install (--post flag) for both installers
affects: [05-linux-enhancements, linux-main-orchestrator]

# Tech tracking
tech-stack:
  added: []
  patterns: [flatpak-data-driven-installer, snap-classic-prefix-convention]

key-files:
  created:
    - src/platforms/linux/install/flatpak.sh
    - src/platforms/linux/install/snap.sh
  modified: []

key-decisions:
  - "Flatpak idempotency uses flatpak list --app --columns=application (not dpkg)"
  - "Snap idempotency uses snap list with trailing space to prevent partial matches"
  - "Classic confinement declared via classic: prefix in data files (no auto-detect)"
  - "retry_with_backoff from core/errors.sh, NOT defined locally"

patterns-established:
  - "Flatpak installer: ensure_flathub_remote() before install loop"
  - "Snap classic prefix: classic:pkg-name convention in data files"
  - "Two-pass install: --post flag switches to *-post.txt data files"

# Metrics
duration: 2min
completed: 2026-02-06
---

# Phase 5 Plan 2: Flatpak & Snap Installers Summary

**Data-driven Flatpak and Snap installers with retry logic, idempotency via native checks, Flathub remote auto-config, and Snap classic: prefix convention**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-06T20:59:34Z
- **Completed:** 2026-02-06T21:01:12Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 deleted)

## Accomplishments
- Created data-driven Flatpak installer following apt.sh pattern with Flathub remote setup
- Created data-driven Snap installer with classic confinement support via prefix convention
- Removed legacy hardcoded scripts from platforms/linux/install/
- Both installers use core retry_with_backoff, record_failure, and load_packages

## Task Commits

Each task was committed atomically:

1. **Task 1: Create data-driven Flatpak installer** - `350ff31` (feat)
2. **Task 2: Create data-driven Snap installer and remove legacy scripts** - `8374333` (feat)

## Files Created/Modified
- `src/platforms/linux/install/flatpak.sh` - Data-driven Flatpak installer with Flathub remote setup and idempotent checks
- `src/platforms/linux/install/snap.sh` - Data-driven Snap installer with classic confinement support
- `platforms/linux/install/flatpak.sh` - Deleted (legacy hardcoded script)
- `platforms/linux/install/snap.sh` - Deleted (legacy hardcoded script)

## Decisions Made
- Flatpak idempotency uses `flatpak list --app --columns=application` (correct native check, not dpkg)
- Snap idempotency uses `snap list` with trailing space to prevent partial matches
- Classic confinement must be explicitly declared via `classic:` prefix in data files (no auto-detect, which can mask real errors)
- `retry_with_backoff` is sourced from core/errors.sh -- not redefined locally (DRY)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Flatpak and Snap installers at parity with APT installer pattern
- Both support two-pass install via --post flag for orchestrator integration
- Legacy scripts removed; only desktop-environments.sh remains in platforms/linux/install/
- Ready for Phase 5 Plan 3 (Linux main orchestrator) to dispatch to these installers

---
*Phase: 05-linux-enhancements*
*Completed: 2026-02-06*
