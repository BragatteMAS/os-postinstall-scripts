---
phase: 05-linux-enhancements
plan: 03
subsystem: cli-tools
tags: [rust, bat, eza, fd, ripgrep, zoxide, delta, cross-platform]

# Dependency graph
requires:
  - phase: 01-core-infrastructure
    provides: "logging.sh, idempotent.sh, errors.sh, packages.sh, platform.sh"
  - phase: 03-dotfiles-management
    provides: "aliases.sh, gitconfig, bashrc, zshrc dotfile templates"
provides:
  - "src/core/interactive.sh - shared interactive selection functions"
  - "src/install/rust-cli.sh - cross-platform Rust CLI tools installer"
  - "Dotfile updates: eza --group-directories-first, delta git pager, zoxide/fnm shell init"
affects: [05-04, 05-05, 06-testing]

# Tech tracking
tech-stack:
  added: [bat, eza, fd-find, ripgrep, zoxide, git-delta, fnm]
  patterns: [cross-platform-installer, interactive-selection, ubuntu-symlinks]

key-files:
  created:
    - src/core/interactive.sh
    - src/install/rust-cli.sh
  modified:
    - data/dotfiles/shared/aliases.sh
    - data/dotfiles/git/gitconfig
    - data/dotfiles/bash/bashrc
    - data/dotfiles/zsh/zshrc

key-decisions:
  - "Hardcoded tool list (not data-driven) because tools are tied to dotfile configuration"
  - "Separate APT and Brew package name arrays for cross-platform support"
  - "interactive.sh in src/core/ as shared module for all cross-platform installers"

patterns-established:
  - "Cross-platform installer: branch on DETECTED_OS for apt vs brew"
  - "Ubuntu symlink pattern: create /usr/local/bin/ symlinks for name divergences"
  - "Interactive selection: show_category_menu() -> All/Choose/Skip"
  - "src/install/ directory for cross-platform installers (sibling to src/core/)"

# Metrics
duration: 2min
completed: 2026-02-06
---

# Phase 5 Plan 3: Rust CLI Tools Summary

**Cross-platform Rust CLI installer (bat, eza, fd, rg, zoxide, delta) with apt/brew branching, Ubuntu symlinks, and dotfile integration (delta pager, zoxide init, fnm env, eza --group-directories-first)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-06T21:00:29Z
- **Completed:** 2026-02-06T21:02:48Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Created shared interactive.sh module for category-level and per-tool selection
- Created cross-platform Rust CLI installer with apt (Linux) and brew (macOS) support
- Ubuntu binary name symlinks (batcat->bat, fdfind->fd)
- Updated eza alias with --group-directories-first
- Added delta as git pager with interactive diffFilter and zdiff3 merge conflict style
- Added zoxide init and fnm env shell integration to both bashrc and zshrc

## Task Commits

Each task was committed atomically:

1. **Task 0: Create src/core/interactive.sh** - `8568824` (feat)
2. **Task 1: Create cross-platform Rust CLI tools installer** - `c94bdb9` (feat)
3. **Task 2: Update dotfiles for Rust CLI tool integration** - `2cd611e` (feat)

## Files Created/Modified
- `src/core/interactive.sh` - Shared interactive selection functions (show_category_menu, ask_tool)
- `src/install/rust-cli.sh` - Cross-platform Rust CLI tools installer with apt/brew branching
- `data/dotfiles/shared/aliases.sh` - eza ll alias updated with --group-directories-first
- `data/dotfiles/git/gitconfig` - Delta pager, interactive diffFilter, delta section, zdiff3
- `data/dotfiles/bash/bashrc` - zoxide init bash and fnm env shell integration
- `data/dotfiles/zsh/zshrc` - zoxide init zsh and fnm env shell integration

## Decisions Made
- Hardcoded tool list instead of data-driven because tools are tightly coupled to dotfile configuration
- Separate RUST_CLI_TOOLS_APT and RUST_CLI_TOOLS_BREW arrays since package names differ between managers
- interactive.sh placed in src/core/ as shared module (not per-installer)
- Added fnm (Fast Node Manager) shell integration alongside zoxide as both are modern tool-chain inits

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- interactive.sh available for dev-env.sh and ai-tools.sh installers
- src/install/ directory established for cross-platform installers
- Dotfiles ready with Rust CLI tool integration (aliases, git pager, shell init)

---
*Phase: 05-linux-enhancements*
*Completed: 2026-02-06*
