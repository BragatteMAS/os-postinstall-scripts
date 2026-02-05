---
phase: 02-consolidation-data-migration
plan: 06
subsystem: infra
tags: [migration, cleanup, dotfiles, bash, legacy-removal]

# Dependency graph
requires:
  - phase: 02-05
    provides: Migration verification and initial cleanup
provides:
  - Clean platforms/linux/ with only install/ remaining
  - Bash dotfiles properly located in data/dotfiles/bash/
  - Gap 1 (platforms/linux/ legacy) fully closed
affects: [phase-05-cleanup, platform-linux-install]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dotfiles organized by topic in data/dotfiles/{git,zsh,bash}/"

key-files:
  created: []
  modified:
    - data/dotfiles/bash/bashrc.sh
    - data/dotfiles/bash/.bashrc_example
    - data/dotfiles/bash/vscode_list_extensions.txt

key-decisions:
  - "Bash dotfiles migrated to data/dotfiles/bash/ for consistent topic-based organization"
  - "Legacy empty directories removed without migration (config/, distros/) - no content to preserve"
  - "check-installation.sh removed - superseded by new verification approach"
  - "post_install_new.sh stub removed - only redirect script with no unique functionality"

patterns-established:
  - "Topic-centric dotfiles: data/dotfiles/{topic}/ structure"
  - "platforms/linux/ reserved for platform-specific installers only"

# Metrics
duration: 2min
completed: 2026-02-05
---

# Phase 02 Plan 06: Legacy Directory Cleanup Summary

**Migrated bash dotfiles to data/dotfiles/bash/ and removed remaining legacy directories from platforms/linux/**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-05T19:15:55Z
- **Completed:** 2026-02-05T19:17:47Z
- **Tasks:** 2
- **Files modified:** 6 (3 migrated, 3 deleted)

## Accomplishments

- Migrated bashrc.sh, .bashrc_example, vscode_list_extensions.txt to data/dotfiles/bash/
- Removed empty platforms/linux/config/ directory
- Removed empty platforms/linux/distros/ directory (Mint/, POP-OS/, Ubuntu/)
- Removed platforms/linux/verify/ with legacy check-installation.sh
- Removed platforms/linux/post_install_new.sh stub file
- platforms/linux/ now contains only install/ (deferred to Phase 5)

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate platforms/linux/bash/ content to data/dotfiles/bash/** - `165fb9d` (chore)
2. **Task 2: Remove empty legacy directories and stub files** - No commit (directories were untracked)

**Plan metadata:** Pending

## Files Created/Modified

- `data/dotfiles/bash/bashrc.sh` - Bash configuration template (migrated from platforms/linux/bash/)
- `data/dotfiles/bash/.bashrc_example` - Bashrc example file (migrated from platforms/linux/bash/)
- `data/dotfiles/bash/vscode_list_extensions.txt` - VSCode extensions list (migrated from platforms/linux/bash/)

### Removed Files/Directories

- `platforms/linux/bash/` - Directory and contents (migrated)
- `platforms/linux/config/` - Empty directory removed
- `platforms/linux/distros/` - Empty directory tree removed (Mint/, POP-OS/, Ubuntu/)
- `platforms/linux/verify/check-installation.sh` - Legacy verification script
- `platforms/linux/post_install_new.sh` - Stub redirect script

## Decisions Made

- **Migrate rather than delete bash content:** Preserved valuable configuration files by moving to data/dotfiles/bash/ rather than discarding
- **No backup of empty directories:** config/ and distros/ were empty with no tracked content, no backup needed
- **Remove verify/check-installation.sh:** Legacy script superseded by new verification approach in Phase 3
- **Remove post_install_new.sh:** Only contained redirect to main.sh with no unique functionality

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Task 2 had no commit:** The directories platforms/linux/config/, platforms/linux/distros/, platforms/linux/verify/, and post_install_new.sh were never tracked by git (untracked files). Physical deletion succeeded but produced no git changes to commit. This is expected behavior - they existed only in working directory.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- platforms/linux/ now contains only install/ directory (flatpak.sh, snap.sh, desktop-environments.sh)
- These installers will be addressed in Phase 5 (Cleanup & Optimization)
- data/dotfiles/bash/ has proper content for bash configuration
- Gap 1 from VERIFICATION.md fully closed

### Phase 2 Status

With this plan complete:
- **Gap 1:** platforms/linux/ legacy content - CLOSED
- **Gap 2:** Remaining gaps - See 02-07-PLAN.md
- Phase 2 (Consolidation & Data Migration) nearing completion

---
*Phase: 02-consolidation-data-migration*
*Completed: 2026-02-05*
