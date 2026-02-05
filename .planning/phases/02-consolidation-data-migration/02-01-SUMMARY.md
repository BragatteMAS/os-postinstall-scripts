---
phase: 02-consolidation-data-migration
plan: 01
subsystem: infra
tags: [bash, shell, core-utilities, data-driven, packages]

# Dependency graph
requires:
  - phase: 01-core-infrastructure
    provides: Phase 1 utilities (logging, platform, idempotent, errors)
provides:
  - src/core/ directory with all Phase 1 utilities migrated
  - data/packages/ directory structure for data-driven package lists
  - data/dotfiles/ topic-centric directory structure (git/, zsh/, bash/)
  - packages.sh module with load_packages(), load_profile(), get_packages_for_manager()
affects: [02-02, 02-03, 02-04, 02-05, 03-entry-points]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DATA_DIR relative to SCRIPT_DIR for data file access"
    - "load_packages() validates DATA_DIR before file reads"

key-files:
  created:
    - src/core/packages.sh
    - data/packages/.gitkeep
    - data/packages/profiles/.gitkeep
    - data/dotfiles/git/.gitkeep
    - data/dotfiles/zsh/.gitkeep
    - data/dotfiles/bash/.gitkeep
  modified:
    - src/core/logging.sh (moved from scripts/utils/)
    - src/core/platform.sh (moved from scripts/utils/)
    - src/core/idempotent.sh (moved from scripts/utils/)
    - src/core/errors.sh (moved from scripts/utils/)

key-decisions:
  - "Topic-centric dotfiles layout: data/dotfiles/{git,zsh,bash}/ per CONTEXT.md"
  - "DATA_DIR validation in load_packages() before any file reads"
  - "Package files use relative paths to data/packages/ or absolute paths"

patterns-established:
  - "DATA_DIR pattern: DATA_DIR=$(cd ${SCRIPT_DIR}/../../data && pwd -P)"
  - "Package loading with whitespace trimming and comment/empty line filtering"

# Metrics
duration: 3min
completed: 2026-02-05
---

# Phase 2 Plan 1: Directory Structure and Core Migration Summary

**src/core/ established with Phase 1 utilities, packages.sh for data-driven installation, and data/ directories for package lists and dotfiles**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-05T18:20:04Z
- **Completed:** 2026-02-05T18:23:xx
- **Tasks:** 2
- **Files created/modified:** 9

## Accomplishments
- Created src/core/, src/platforms/, data/packages/, data/dotfiles/ directory structure
- Migrated all Phase 1 utilities (logging.sh, platform.sh, idempotent.sh, errors.sh) to src/core/
- Created packages.sh module with load_packages(), load_profile(), get_packages_for_manager() functions
- Established topic-centric dotfiles layout: data/dotfiles/{git,zsh,bash}/

## Task Commits

Each task was committed atomically:

1. **Task 1: Create directory structure and migrate core utilities** - `8bc53db` (refactor)
2. **Task 2: Create packages.sh module with load_packages()** - `eddc703` (feat)

## Files Created/Modified

**Created:**
- `src/core/packages.sh` - Package loading utilities (load_packages, load_profile, get_packages_for_manager)
- `data/packages/.gitkeep` - Placeholder for package list files
- `data/packages/profiles/.gitkeep` - Placeholder for profile files
- `data/dotfiles/git/.gitkeep` - Git dotfiles (topic-centric)
- `data/dotfiles/zsh/.gitkeep` - Zsh dotfiles (topic-centric)
- `data/dotfiles/bash/.gitkeep` - Bash dotfiles (topic-centric)

**Moved (git history preserved):**
- `scripts/utils/logging.sh` -> `src/core/logging.sh` - Unified logging with color auto-detection
- `scripts/utils/platform.sh` -> `src/core/platform.sh` - Platform detection and verification
- `scripts/utils/idempotent.sh` -> `src/core/idempotent.sh` - Idempotency utilities
- `scripts/utils/errors.sh` -> `src/core/errors.sh` - Error handling and failure tracking

## Decisions Made

1. **Topic-centric dotfiles layout:** Created data/dotfiles/{git,zsh,bash}/ subdirectories per CONTEXT.md specification (vs flat structure)
2. **DATA_DIR validation first:** packages.sh validates DATA_DIR exists before attempting any file reads, returning error gracefully
3. **Relative path resolution:** load_packages() accepts relative paths (resolved to data/packages/) or absolute paths

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **zsh export warning:** When sourcing packages.sh in zsh (macOS default), `export -f` shows warnings because zsh doesn't support function export. Verified it works correctly in bash (the target shell). This is expected behavior and not a bug.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for:**
- Plan 02-02: Extract package lists to data/packages/*.txt files
- Plan 02-03: Migrate platforms/linux/ to src/platforms/linux/
- All subsequent plans can now import from src/core/

**Notes:**
- Old scripts/utils/ files still referenced by other scripts (will be handled by subsequent plans)
- src/core/packages.sh ready to load package files once they are extracted in 02-02

---
*Phase: 02-consolidation-data-migration*
*Plan: 01*
*Completed: 2026-02-05*
