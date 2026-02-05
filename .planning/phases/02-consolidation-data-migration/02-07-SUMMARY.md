---
phase: 02-consolidation-data-migration
plan: 07
subsystem: packages
tags: [bash, shell, data-driven, load_packages, apt, snap, flatpak]

# Dependency graph
requires:
  - phase: 02-02
    provides: Package file format and load_packages() function
  - phase: 02-03
    provides: Data-driven installer pattern (cargo.sh)
provides:
  - Data-driven post_install.sh using load_packages()
  - Package files: apt-post.txt, snap-post.txt, flatpak-post.txt
  - Gap 2 (PKG-04) closure for post_install.sh
affects: [phase-05-cleanup, phase-08-documentation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Data-driven installation via load_packages()
    - Idempotent package checks for Snap/Flatpak

key-files:
  created:
    - data/packages/apt-post.txt
    - data/packages/snap-post.txt
    - data/packages/flatpak-post.txt
  modified:
    - src/platforms/linux/post_install.sh

key-decisions:
  - "Package format: one per line with # comments for categorization"
  - "Consistent load_packages() pattern across all installer scripts"

patterns-established:
  - "load_packages() before iteration: `if load_packages file.txt; then for pkg in PACKAGES[@]; do ...`"
  - "Idempotent snap check: `snap list pkg &>/dev/null`"
  - "Idempotent flatpak check: `flatpak list --app | grep pkg`"

# Metrics
duration: 2min
completed: 2026-02-05
---

# Phase 02 Plan 07: Post-install Data Separation Summary

**Refactored post_install.sh to use load_packages() for APT/Snap/Flatpak, closing Gap 2 (PKG-04 hardcoded arrays)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-05T19:16:24Z
- **Completed:** 2026-02-05T19:18:31Z
- **Tasks:** 2
- **Files created:** 3
- **Files modified:** 1

## Accomplishments

- Extracted 30+ APT packages to data/packages/apt-post.txt
- Extracted 7 Snap packages to data/packages/snap-post.txt
- Extracted 50+ Flatpak app IDs to data/packages/flatpak-post.txt
- Refactored post_install.sh to source packages.sh and use load_packages()
- Added proper idempotency checks for Snap and Flatpak installations
- Eliminated all hardcoded package arrays from post_install.sh

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract hardcoded arrays to data/packages/ files** - `2393b6b` (feat)
2. **Task 2: Refactor post_install.sh to use load_packages()** - `7a1a552` (refactor)

## Files Created/Modified

**Created:**
- `data/packages/apt-post.txt` - 30+ APT packages with category comments
- `data/packages/snap-post.txt` - 7 Snap packages with category comments
- `data/packages/flatpak-post.txt` - 50+ Flatpak app IDs with category comments

**Modified:**
- `src/platforms/linux/post_install.sh` - Now sources packages.sh and uses load_packages() for all package types

## Decisions Made

- **Followed established format:** One package per line, # comments for categorization (matches apt.txt, cargo.txt)
- **Consistent pattern:** Used same load_packages() pattern as cargo.sh for all three package managers
- **Improved idempotency:** Added proper Snap (`snap list`) and Flatpak (`flatpak list --app`) checks instead of incorrect `dpkg -l` checks

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Gap 2 (PKG-04) fully closed - post_install.sh now data-driven
- All Phase 2 gap closures complete
- Ready for Phase 3 (Testing Foundation)
- Remaining cleanup items for Phase 5: scripts/utils/ application-level scripts

---
*Phase: 02-consolidation-data-migration*
*Completed: 2026-02-05*
