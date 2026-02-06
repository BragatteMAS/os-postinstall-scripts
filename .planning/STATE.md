# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-04)

**Core value:** Facil de manter. Simplicidade e manutenibilidade superam features e cobertura.
**Current focus:** Phase 4 - macOS Platform (COMPLETE)

## Current Position

Phase: 4 of 8 (macOS Platform) - COMPLETE
Plan: 3 of 3 in current phase - COMPLETE
Status: Phase complete
Last activity: 2026-02-06 - Completed 04-03-PLAN.md (macOS Main Orchestrator)

Progress: [██████████████████████████] 100% (Phases 1-4)

## Performance Metrics

**Velocity:**
- Total plans completed: 17
- Average duration: 2.5 min
- Total execution time: 42 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-core-infrastructure | 3/3 | 6 min | 2 min |
| 02-consolidation-data-migration | 7/7 | 20 min | 2.9 min |
| 03-dotfiles-management | 4/4 | 10 min | 2.5 min |
| 04-macos-platform | 3/3 | 6 min | 2 min |

**Recent Trend:**
- Last 5 plans: 03-03 (2 min), 03-04 (3 min), 04-01 (2 min), 04-02 (2 min), 04-03 (2 min)
- Trend: Stable at ~2.2 min for recent plans

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: Shell puro vs Rust/Zig — shell is the right tool for package managers
- [Init]: Zero deps externas — run on clean machine without installing anything first
- [Init]: git clone como fluxo principal — safer than curl|bash
- [01-01]: No set -e — conflicts with continue-on-failure strategy
- [01-01]: Non-interactive mode continues with warnings instead of prompts
- [01-01]: Verification order: OS -> Bash -> Net -> Sudo
- [01-02]: No version checking — KISS, let apt upgrade handle versions
- [01-02]: Multiple source protection via _SOURCED guard variables
- [01-03]: NO_COLOR standard for CI/automation compatibility
- [01-03]: Always exit 0, failures shown in summary
- [01-03]: VERBOSE controls timestamps and debug visibility
- [02-01]: Topic-centric dotfiles layout: data/dotfiles/{git,zsh,bash}/
- [02-01]: DATA_DIR validation in load_packages() before any file reads
- [02-01]: Package files use relative paths to data/packages/ or absolute paths
- [02-02]: Package format: one per line with # comments for categorization
- [02-02]: Profile composition: profiles list package files, not packages directly
- [02-02]: Preserved auto/ packages in flatpak.txt and snap.txt before removal
- [02-03]: Created new cargo.sh instead of migrating rust-tools.sh
- [02-03]: Deferred post_install.sh refactoring to gap closure plan
- [02-03]: Added cargo-binstall support for faster Rust tool installation
- [02-04]: Use 'macos' (not 'darwin') in case statement to match platform.sh output
- [02-04]: Config.sh only sets SCRIPT_DIR if not already defined by caller
- [02-05]: scripts/utils/ retained (application-level scripts, not duplicates)
- [02-05]: platforms/linux/install/ retained for Phase 5 (flatpak/snap logic)
- [02-06]: Bash dotfiles migrated to data/dotfiles/bash/ for consistent topic-based organization
- [02-06]: Legacy empty directories removed without backup (no content to preserve)
- [02-06]: check-installation.sh and post_install_new.sh removed (superseded)
- [02-07]: Consistent load_packages() pattern across all installer scripts
- [02-07]: Improved idempotency checks for Snap (snap list) and Flatpak (flatpak list --app)
- [03-01]: Flat backup naming: ~/.config/git/ignore -> config-git-ignore.bak.DATE
- [03-01]: Manifest format: TIMESTAMP | original -> backup
- [03-01]: Session tracking via array for show_backup_summary()
- [03-03]: Git config uses include for ~/.gitconfig.local (user identity separation)
- [03-03]: Starship disables noisy modules for clean prompt
- [03-03]: Template provides optional GPG, SSH signing, and includeIf examples
- [03-04]: setup.sh entry points: dotfiles (install) and unlink (remove with restore)
- [03-04]: zsh plugins installed via git clone to ~/.zsh/ (zsh-autosuggestions, zsh-syntax-highlighting)
- [03-04]: setup_git_user() prompts only in interactive mode, writes to ~/.gitconfig.local
- [03-04]: DRY_RUN check must use `== "true"` not `-n` (because config.sh sets DRY_RUN=false)
- [04-01]: Main guard pattern for dual sourceable/executable scripts
- [04-01]: Architecture detection: uname -m arm64 -> /opt/homebrew, else /usr/local
- [04-01]: Xcode CLI Tools: interactive fallback with read -r for GUI installer
- [04-02]: Cask detection uses `brew list --cask` locally (core is_brew_installed checks formulae only)
- [04-03]: MACOS_DIR instead of SCRIPT_DIR to avoid packages.sh readonly conflict
- [04-03]: Platform-agnostic profiles: one file per tier, not per-platform variants
- [04-03]: check_bash_upgrade warns but continues (user may need brew first to upgrade)

### Patterns Established

- Source guard: `[[ -n "${_SOURCED:-}" ]] && return 0`
- TTY color detection: `if [[ -t 1 ]]`
- Export functions: `export -f function_name`
- PATH dedup: `case ":$PATH:" in *":$path:"`
- Backup suffix: `.bak.YYYY-MM-DD`
- Command detection: `command -v`
- Log format: `[OK]/[ERROR]/[WARN]/[INFO]/[DEBUG]`
- Failure tracking: `FAILED_ITEMS+=("$item")`
- Cleanup trap: `trap cleanup EXIT INT TERM`
- DATA_DIR pattern: `DATA_DIR="$(cd "${SCRIPT_DIR}/../../data" && pwd -P)"`
- Package loading: whitespace trimming and comment/empty line filtering
- Package file format: `# Comment`, blank lines ignored, one package per line
- Profile composition: list of package file names (apt.txt, cargo.txt, etc.)
- Data-driven installer: `load_packages("file.txt")` then iterate `PACKAGES[@]`
- Idempotent check pattern: `is_*_installed()` before installing
- Entry point pattern: setup.sh sources config.sh then core utilities
- SCRIPT_DIR conditional: `if [[ -z "${SCRIPT_DIR:-}" ]]`
- Cleanup verification: rg check before deletion
- Legacy removal: one-time migration helpers deleted after phase
- Topic-centric dotfiles: data/dotfiles/{topic}/ structure
- platforms/linux/ reserved for platform-specific installers only
- Idempotent snap check: `snap list pkg &>/dev/null`
- Idempotent flatpak check: `flatpak list --app | grep pkg`
- Dotfiles backup naming: `path_to_backup_name()` for flat path prefix names
- Symlink with backup: backup non-symlinks, replace symlinks without backup
- Parent directory creation: `mkdir -p "$(dirname "$target")"` before symlink
- Dotfiles with local override: main config includes local file
- Starship minimal: only essential modules enabled
- Symlink resolution: readlink -f with macOS fallback
- DOTFILES_DIR: derived from resolved script path
- Shell source order: path, env, aliases, functions, plugins, prompt
- Architecture detection: `get_brew_prefix()` returns /opt/homebrew (arm64) or /usr/local (x86_64)
- Main guard: `if [[ "${BASH_SOURCE[0]}" == "$0" ]]` for sourceable + executable scripts
- macOS installer pattern: follows apt.sh structure with macOS-specific adaptations
- Underscore prefix for private helpers: `_brew_formula_install()`, `_brew_cask_install()`
- HOMEBREW_NO_INSTALL_UPGRADE=1 inline env var to prevent upgrades during install
- MACOS_DIR pattern: dedicated variable when SCRIPT_DIR is clobbered by sourced modules
- Profile dispatch: read profile file, case-match on package file names, skip non-platform
- Dual-mode script: check $1 for unattended, fall through to interactive menu

### Pending Todos

None.

### Blockers/Concerns

- macOS ships Bash 3.2; check_bash_upgrade() warns but continues (addressed in Phase 4)
- scripts/utils/ application-level scripts not yet consolidated (Phase 5)
- Linux main.sh does not yet use profile-based dispatch (deferred to Phase 5)

## Phase 2 Deliverables

**Structure:**
- src/core/: logging.sh, platform.sh, idempotent.sh, errors.sh, packages.sh
- src/platforms/: linux/, macos/, windows/
- data/packages/: apt.txt, apt-post.txt, brew.txt, brew-cask.txt, cargo.txt, npm.txt, winget.txt, flatpak.txt, flatpak-post.txt, snap.txt, snap-post.txt, ai-tools.txt, profiles/
- data/dotfiles/: git/, zsh/, bash/
- Entry points: setup.sh, config.sh

**Removed:**
- scripts/common/ (deprecated)
- platforms/linux/auto/ (packages extracted)
- platforms/linux/utils/ (empty)
- platforms/linux/bash/ (migrated to data/dotfiles/bash/)
- platforms/linux/config/ (empty, removed)
- platforms/linux/distros/ (empty, removed)
- platforms/linux/verify/ (legacy, removed)
- platforms/linux/post_install_new.sh (stub, removed)
- Legacy migration scripts (5 files)
- Hardcoded arrays from post_install.sh (extracted to data files)

**Remaining in platforms/linux/:**
- install/ (flatpak.sh, snap.sh, desktop-environments.sh) - deferred to Phase 5

## Gap Closures Complete

- Gap 1: Missing error handling functions - CLOSED (01-03)
- Gap 2: post_install.sh hardcoded arrays - CLOSED (02-07)
- All PKG-04 violations resolved

## Phase 3 Deliverables

**Structure:**
- src/core/: dotfiles.sh (new)
- data/dotfiles/: git/, zsh/, bash/, shared/, starship/ (new)
- tests/: test-dotfiles.sh (new)

**Created:**
- src/core/dotfiles.sh - Dotfiles symlink manager utility
- tests/test-dotfiles.sh - Integration tests
- data/dotfiles/shared/path.sh - PATH management with dedup
- data/dotfiles/shared/env.sh - Environment variables
- data/dotfiles/shared/aliases.sh - Cross-shell aliases
- data/dotfiles/zsh/zshrc - Main zsh configuration
- data/dotfiles/zsh/functions.sh - Zsh functions (mkcd, extract)
- data/dotfiles/zsh/plugins.sh - Plugin loading
- data/dotfiles/bash/bashrc - Main bash configuration
- data/dotfiles/git/gitconfig - Global git configuration
- data/dotfiles/git/gitignore - Global gitignore patterns
- data/dotfiles/git/gitconfig.local.template - Local config template
- data/dotfiles/starship/starship.toml - Starship prompt configuration

## Phase 4 Deliverables (COMPLETE)

**Created:**
- src/platforms/macos/install/homebrew.sh - Idempotent Homebrew installer
- src/platforms/macos/install/brew.sh - Data-driven formula installer (brew.txt)
- src/platforms/macos/install/brew-cask.sh - Data-driven cask installer (brew-cask.txt)
- src/platforms/macos/main.sh - Main orchestrator with profile menu and dual-mode operation

**Modified:**
- data/packages/profiles/minimal.txt - Added brew.txt
- data/packages/profiles/developer.txt - Added brew.txt and brew-cask.txt
- data/packages/profiles/full.txt - Added brew.txt and brew-cask.txt

## Session Continuity

Last session: 2026-02-06
Stopped at: Completed 04-03-PLAN.md (macOS Main Orchestrator) - Phase 4 COMPLETE
Resume file: None

---
*Next action: Phase 5 planning (Linux Enhancements)*
