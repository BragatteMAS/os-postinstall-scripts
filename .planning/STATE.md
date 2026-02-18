# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-04)

**Core value:** Facil de manter. Simplicidade e manutenibilidade superam features e cobertura.
**Current focus:** Phase 10.1 - Process Debt Cleanup (COMPLETE)

## Current Position

Phase: 10.1 of 10.1 (Process Debt Cleanup) — COMPLETE
Plan: 1 of 1 in current phase
Status: All plans complete
Last activity: 2026-02-17 - Plan 10.1-01 complete (Phase 08 VERIFICATION.md + MOD-04 traceability)

Progress: [████████████████████████████████] 100% (41/41 plans total)

## Performance Metrics

**Velocity:**
- Total plans completed: 41
- Average duration: 2.4 min
- Total execution time: 98 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-core-infrastructure | 3/3 | 6 min | 2 min |
| 02-consolidation-data-migration | 7/7 | 20 min | 2.9 min |
| 03-dotfiles-management | 4/4 | 10 min | 2.5 min |
| 04-macos-platform | 3/3 | 6 min | 2 min |
| 05-linux-enhancements | 6/6 | 13 min | 2.2 min |
| 06-windows-foundation | 2/2 | 5 min | 2.5 min |
| 07-user-experience-polish | 3/3 | 10 min | 3.3 min |
| 08-documentation | 3/3 | 15 min | 5 min |
| 08.1-terminal-setup-windows | 1/1 | 3 min | 3 min |

| 08.2-audit-remediation | 4/4 | 6 min | 1.5 min |
| 09-terminal-blueprint | 2/2 | 6 min | 3 min |
| 10-windows-cross-platform-installers | 2/2 | 5 min | 2.5 min |
| 10.1-process-debt-cleanup | 1/1 | 1 min | 1 min |

**Recent Trend:**
- Last 5 plans: 09-01 (2 min), 09-02 (4 min), 10-01 (3 min), 10-02 (2 min), 10.1-01 (1 min)
- Trend: Stable at ~1-4 min

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
- [05-01]: DPkg::Lock::Timeout=60 replaces manual fuser loop (simpler, built-in apt feature)
- [05-01]: retry_with_backoff from core/errors.sh reused in apt.sh (no local redefinition)
- [05-01]: log_warn on install failure (not log_error) -- script continues
- [05-01]: No autoclean/autoremove in apt.sh (setup script, not maintenance tool)
- [05-02]: Flatpak idempotency uses flatpak list --app --columns=application (not dpkg)
- [05-02]: Snap idempotency uses snap list with trailing space to prevent partial matches
- [05-02]: Classic confinement declared via classic: prefix in data files (no auto-detect)
- [05-02]: retry_with_backoff from core/errors.sh, NOT defined locally (DRY)
- [05-03]: Hardcoded tool list (not data-driven) when tools are tied to dotfile configuration
- [05-03]: Separate APT/Brew package name arrays for cross-platform installer
- [05-03]: interactive.sh in src/core/ as shared module for all cross-platform installers
- [05-03]: src/install/ directory for cross-platform installers (sibling to src/core/)
- [05-04]: fnm --skip-shell prevents shell config modification (dotfiles handle PATH)
- [05-04]: SSH key generation default=No, only offered interactively
- [05-04]: Global npm packages (pnpm, bun) installed via npm install -g after Node LTS
- [05-05]: Prefix-based dispatch: npm:/curl:/npx:/uv: prefixes route to different install methods
- [05-05]: Bare words and npx:/uv: entries silently skipped (informational only, not installable)
- [05-05]: Node.js availability checked before npm install -g (warn + skip if missing)
- [05-05]: npm list -g for idempotent npm check (scoped packages need npm-level check)
- [05-06]: LINUX_DIR instead of SCRIPT_DIR to avoid packages.sh readonly conflict
- [05-06]: dev-env + rust-cli run before dispatch loop (structural Node.js guarantee)
- [05-06]: assert_fail helper for inverted test assertions (! doesn't work in $@ expansion)
- [06-01]: Single Write-Log function with -Level parameter (PowerShell-idiomatic)
- [06-01]: No Read-Profile in packages.psm1 (orchestrators dispatch directly, KISS)
- [06-01]: Simple @() array for failure tracking (KISS over ArrayList/List)
- [06-01]: No WinGet check in setup.ps1 (each installer checks its own tools)
- [06-01]: $ErrorActionPreference = 'Continue' in scripts, not modules (inherit from caller)
- [06-02]: winget list --id --exact AND output match for idempotent check (double-check needed)
- [06-02]: Non-Windows package files skipped with DEBUG log (not WARN), matching macOS pattern
- [06-02]: Show-FailureSummary in interactive exit only (setup.ps1 calls it in unattended path)
- [07-01]: cargo.txt excluded from macOS step count (no macOS cargo installer exists)
- [07-01]: ai-tools.txt dispatch enabled for macOS (Phase 5 cross-platform installer exists)
- [07-01]: winget.txt skip case added to both Linux/macOS orchestrators
- [07-01]: $((count + 1)) arithmetic over ((count++)) for Bash 3.2 compat
- [07-02]: parse_flags() before main() with REMAINING_ARGS passthrough
- [07-02]: Unknown CLI flags cause error + exit 1 (no silent ignore)
- [07-02]: DRY_RUN guard placed after idempotency check, before mutation
- [07-03]: SECONDS builtin for duration tracking (no external date math)
- [07-03]: _SUMMARY_SHOWN guard prevents double summary on normal vs abnormal exit
- [07-03]: Cleanup trap overridden in setup.sh after setup_error_handling
- [07-03]: No per-package installed/skipped counters (orchestrator-level only)
- [08-01]: No fake demo.gif; HTML comment placeholder + italic text instead of broken img tag
- [08-01]: CODE_OF_CONDUCT.md link temporarily broken (Plan 08-02 creates it)
- [08-01]: Inverted pyramid README structure: instant value -> quick start -> features -> architecture -> reference
- [08.1-01]: Write-Err function name avoids collision with built-in Write-Error cmdlet
- [08.1-01]: ASCII-safe > symbol in starship config instead of Unicode arrows (cross-terminal compat)
- [08.1-01]: Per-user font path ($env:LOCALAPPDATA) avoids requiring admin elevation
- [08.1-01]: Remove built-in aliases before defining replacement functions (PS alias conflict)
- [08.2-03]: Explicit DRY_RUN guard for curl|sh pipes (run() cannot guard pipe right side)
- [08.2-03]: WARN level for known-unimplemented Windows dispatchers (gap is intentional, not broken)
- [08.2-03]: Keep default case at DEBUG for truly unrelated platform files
- [08.2-02]: homebrew.sh exits 1 on failure (exception to always-exit-0 for hard prerequisites)
- [08.2-02]: FAILURE_LOG write in homebrew.sh guarded by `[[ -n FAILURE_LOG ]]` for standalone safety
- [08.2-02]: Orchestrator cleanup checks -f and -s before reading FAILURE_LOG
- [08.2-02]: PS Add-FailedItem writes to $env:FAILURE_LOG with Split-Path parent dir check
- [08.2-02]: setup.ps1 creates FAILURE_LOG using $PID for unique temp file name
- [08.2-04]: grep -E (POSIX extended) instead of grep -P (Perl) for macOS BSD grep compatibility
- [08.2-04]: PS test file resolves $ProjectRoot from $PSScriptRoot/.. for portable path resolution
- [09-01]: ASCII > character for all presets (per project decision 08.1-01)
- [09-01]: mktemp + mv for .zshrc editing (portable, no sed -i)
- [09-01]: Default deactivate + backup (safe); --remove flag for full cleanup
- [09-01]: Preset selection gated by [[ -t 0 ]] for interactive-only
- [09-02]: terminal/setup.sh is SSoT -- all logic moved from terminal-setup.sh
- [09-02]: terminal-setup.sh is pure wrapper (24 lines, exec delegation)
- [09-02]: offer_migration() uses bash subprocess, never source
- [09-02]: setup_starship() has inline TOML fallback when presets/ missing
- [09-02]: --migrate flag for explicit non-interactive migration
- [10-01]: WinGet-first strategy for cargo.txt packages (17 WinGet IDs, 11 cargo-install fallback)
- [10-01]: Do NOT auto-install Rust/rustup (per research decision, avoids MSVC trap)
- [10-01]: zellij in SkipOnWindows (no Windows support, different semantic from null WinGet mapping)
- [10-01]: curl:ollama maps to winget install Ollama.Ollama on Windows
- [10-01]: Each PS script self-contained with own helper functions (separate process execution)
- [10-01]: npm list -g for idempotent check (handles scoped @scope/pkg per Phase 5 decision)
- [10-02]: Header comments updated to list all dispatched package types (winget, cargo, npm, ai-tools)

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
- APT lock handling: `-o DPkg::Lock::Timeout=60` instead of fuser polling
- Two-pass install: `--post` flag selects apt-post.txt / flatpak-post.txt / snap-post.txt
- Non-interactive opts: `APT_NONINTERACTIVE_OPTS` array appended to command
- Flatpak installer: `ensure_flathub_remote()` with `--if-not-exists` before install loop
- Snap classic prefix: `classic:pkg-name` convention in data files for classic confinement
- Cross-platform installer: branch on DETECTED_OS for apt vs brew in src/install/
- Ubuntu symlink pattern: `/usr/local/bin/` symlinks for binary name divergences (batcat->bat, fdfind->fd)
- Interactive selection: `show_category_menu()` -> All/Choose/Skip menu
- Shell integration pattern: `command -v tool && eval "$(tool init shell)"` guard
- Curl-based installer: idempotent check, curl install, PATH update, verify
- Orchestrator sources sub-installers: main guard prevents double execution
- Interactive category menu: group+custom selection for tool categories
- Prefix dispatch: `case "${entry%%:*}"` for multi-method installer
- Installable filter: only npm: and curl: entries shown in interactive choose mode
- API key info summary: `show_ai_summary()` for post-install guidance
- LINUX_DIR pattern: matches MACOS_DIR, avoids packages.sh SCRIPT_DIR overwrite
- Orchestrator pre-dispatch: dev-env + rust-cli before profile loop for dependency ordering
- assert_fail: inverted assertion helper for shell anti-pattern tests
- PowerShell module pattern: `#Requires -Version 5.1` + `Export-ModuleMember`
- Write-Log single function: `-Level` parameter replaces 6 Bash functions
- PS DataDir resolution: `Resolve-Path "$PSScriptRoot/../../../.."` for robust path
- Import-Module -Force: ensures fresh load on re-import
- PS always exit 0: matches Bash convention for pragmatic failure handling
- WinGet idempotent: `winget list --id --exact` + output match before install
- PS dual-mode orchestrator: `-Profile` param for unattended, `do {} while` for interactive
- PS profile dispatch: `Get-Content` reads profile directly, `switch` dispatches to installers
- PS platform filtering: `default` case skips non-Windows files with DEBUG log
- Step counter pattern: count_platform_steps() pre-count + current_step increment at dispatch
- DRY_RUN banner: show_dry_run_banner() at top of install_profile()
- INSTALL_DIR variable: cross-platform installers directory (src/install/)
- CLI flag parsing: `parse_flags()` with while/case/shift, REMAINING_ARGS passthrough
- DRY_RUN guard pattern: after idempotency check, before mutation, `[DRY_RUN]` log prefix
- Completion summary: show_completion_summary() at end of main() with profile/platform/duration/failures
- _SUMMARY_SHOWN guard: cleanup trap checks flag to prevent duplicate summaries
- SECONDS timer: reset to 0 at main() start, read at summary for Xm Ys format
- Inverted pyramid documentation: instant value -> quick start -> features -> architecture -> reference
- Collapsible sections: `<details><summary>` for long content in README
- Badge layout: 2 rows of 3, centered div, shields.io flat style
- Portfolio showcase: Engineering Highlights section explaining WHY not just WHAT
- Standalone PS wizard: CmdletBinding + param block + feature flags + wizard + main
- Per-user font install: LOCALAPPDATA fonts dir + HKCU registry entries (no admin)
- PS profile append: marker check, backup, Add-Content with UTF8 encoding
- PS alias conflict resolution: Remove-Item Alias:name before function definition
- curl|sh guard: explicit DRY_RUN check wrapping entire pipeline, not run() on left side
- Known-gap logging: WARN level for dispatchers that exist on other platforms but not current
- Hard prerequisite exit: exit 1 + FAILURE_LOG write for must-have dependencies (homebrew.sh)
- Orchestrator FAILURE_LOG aggregation: cleanup() reads shared log and reports child failures
- PS FAILURE_LOG lifecycle: setup.ps1 creates -> errors.psm1 writes -> setup.ps1 reads + removes
- macOS test suite: assert_pass/assert_fail with POSIX grep -E (BSD compatible)
- PS test suite: Assert-Pass (scriptblock), Assert-Contains/Assert-NotContains (Select-String)
- Starship preset files: static TOML in presets/ directory with $schema for editor validation
- Starship palette: `palette = "name"` + `[palettes.name]` for DRY color definitions in TOML
- Migration script: detect + backup + clean + optional remove pattern for safe config migration
- Temp file editing: mktemp + grep -v + mv instead of sed -i for portable .zshrc modification
- Interactive gate: `[[ -t 0 ]]` check before interactive prompts in migration scripts
- SSoT wrapper: pure exec delegation wrapper (~20 lines) replacing full script
- Subprocess migration: `bash "${SCRIPT_DIR}/script.sh"` instead of source for zero coupling
- Inline TOML fallback: hardcoded config when presets/ directory is missing
- WinGet-first cargo: `$script:WinGetMap` maps cargo names to WinGet IDs, cargo install fallback
- PS SkipOnWindows: `$script:SkipOnWindows = @('pkg')` for packages with no Windows support
- PS cargo idempotent: `cargo install --list` + regex match `^packagename ` pattern
- PS npm idempotent: `npm list -g $pkg | Out-Null` + `$LASTEXITCODE -eq 0` for scoped support
- PS prefix dispatch: `$Entry.Split(':', 2)` + `switch ($prefix)` for multi-method installer
- PS curl-to-WinGet mapping: Windows maps curl-installed tools to WinGet equivalents (ollama)
- PS self-contained helpers: duplicate helper functions across scripts (separate process execution)

### Roadmap Evolution

- Phase 8.1 inserted after Phase 8: terminal-setup.ps1 for Windows (COMPLETE)
- Phase 8.2 inserted after Phase 8.1: Audit remediation from 4-agent review (COMPLETE)
- Phase 9 added: Terminal Blueprint — terminal replication with p10k migration, Starship presets, standalone setup
- Phase 10 added: Windows Cross-Platform Installers — cargo.ps1, npm.ps1, ai-tools.ps1 closing v2.1 audit gaps
- Phase 10.1 inserted after Phase 10: Process Debt Cleanup — Phase 08 VERIFICATION.md + MOD-04 traceability (COMPLETE)

### Pending Todos

Phase 8.2 — 7 priority items from codebase audit:
1. [Alta] Deprecate/migrate post_install.sh
2. [Alta] Expand manual test coverage (macOS, Windows, core modules) -- DONE (08.2-04)
3. [Média] Windows main.ps1 cross-platform dispatch -- DONE (10-02, dispatch wiring replaces WARN placeholders)
4. [Média] homebrew.sh exit code propagation -- FIXED (08.2-02)
5. [Média] terminal-setup.sh dry-run bypass -- FIXED (08.2-03)
6. [Média] Cross-process failure tracking -- FIXED (08.2-02)
7. [Baixa] CODE_OF_CONDUCT.md creation

### Blockers/Concerns

- macOS ships Bash 3.2; check_bash_upgrade() warns but continues (addressed in Phase 4)
- scripts/utils/ application-level scripts not yet consolidated
- NO CI/CD automation — explicit owner decision (2026-02-08). Tests are manual only.

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
- install/ (desktop-environments.sh only) - flatpak.sh and snap.sh removed in Phase 5

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

## Phase 5 Deliverables (COMPLETE)

**Modified:**
- src/platforms/linux/install/apt.sh - Hardened with dpkg lock timeout, retry, two-pass, non-interactive support

**Created:**
- src/platforms/linux/install/flatpak.sh - Data-driven Flatpak installer with Flathub remote setup
- src/platforms/linux/install/snap.sh - Data-driven Snap installer with classic confinement support

**Removed:**
- platforms/linux/install/flatpak.sh - Legacy hardcoded script
- platforms/linux/install/snap.sh - Legacy hardcoded script

**Created (05-03):**
- src/core/interactive.sh - Shared interactive selection functions
- src/install/rust-cli.sh - Cross-platform Rust CLI tools installer

**Modified (05-03):**
- data/dotfiles/shared/aliases.sh - eza alias with --group-directories-first
- data/dotfiles/git/gitconfig - Delta pager, interactive diffFilter, delta section, zdiff3
- data/dotfiles/bash/bashrc - zoxide init bash, fnm env
- data/dotfiles/zsh/zshrc - zoxide init zsh, fnm env

**Created (05-04):**
- src/install/fnm.sh - Cross-platform fnm installer (fnm + Node LTS + pnpm + bun)
- src/install/uv.sh - Cross-platform uv installer (uv + Python)
- src/install/dev-env.sh - Dev environment orchestrator with interactive selection and SSH

**Created (05-05):**
- src/install/ai-tools.sh - Cross-platform AI tools installer with prefix-based dispatch

**Modified (05-05):**
- data/packages/ai-tools.txt - Added AI CLI entries (npm:claude-code, npm:codex, npm:gemini-cli, curl:ollama)
- data/packages/profiles/developer.txt - Added apt-post.txt, ai-tools.txt, flatpak.txt, snap.txt
- data/packages/profiles/full.txt - Added apt-post.txt, flatpak-post.txt, snap-post.txt

**Modified (05-06):**
- src/platforms/linux/main.sh - Rewritten with profile dispatch, dual-mode, LINUX_DIR

**Created (05-06):**
- tests/test-linux.sh - Linux platform test suite (24 tests)

## Phase 6 Deliverables (COMPLETE)

**Created (06-01):**
- setup.ps1 - Windows entry point with profile parameter and dispatch to main.ps1
- src/platforms/windows/core/logging.psm1 - Write-Log with OK/ERROR/WARN/INFO/DEBUG/BANNER levels
- src/platforms/windows/core/packages.psm1 - Read-PackageFile from data/packages/
- src/platforms/windows/core/errors.psm1 - Add-FailedItem, Show-FailureSummary, Get-FailureCount, Clear-Failures

**Created (06-02):**
- src/platforms/windows/install/winget.ps1 - Data-driven WinGet installer with idempotent checks
- src/platforms/windows/main.ps1 - Windows orchestrator with interactive menu and unattended mode

**Modified (06-02):**
- data/packages/profiles/minimal.txt - Added winget.txt
- data/packages/profiles/developer.txt - Added winget.txt
- data/packages/profiles/full.txt - Added winget.txt

**Removed (06-02):**
- platforms/windows/win11.ps1 - Legacy hardcoded script (superseded by data-driven winget.ps1)

## Phase 7 Deliverables (COMPLETE)

**Created (07-01):**
- src/core/progress.sh - Step counter helpers and DRY_RUN banner

**Modified (07-01):**
- src/platforms/linux/main.sh - Step-counted profile dispatch with [Step X/Y] prefix
- src/platforms/macos/main.sh - Step-counted profile dispatch, ai-tools.txt enabled, INSTALL_DIR added

**Modified (07-02):**
- setup.sh - CLI flag parsing (--dry-run, --verbose, --unattended) + updated help text
- src/platforms/linux/install/apt.sh - DRY_RUN guards in safe_apt_update() and apt_hardened_install()
- src/platforms/linux/install/flatpak.sh - DRY_RUN guards in ensure_flathub_remote() and flatpak_install()
- src/platforms/linux/install/snap.sh - DRY_RUN guard in snap_install()
- src/platforms/linux/install/cargo.sh - DRY_RUN guards in ensure_rust_installed(), cargo_install(), ensure_binstall()
- src/install/rust-cli.sh - DRY_RUN guards in install_rust_tools_linux(), install_rust_tools_macos(), create_rust_symlinks()
- src/install/fnm.sh - DRY_RUN guards in install_fnm(), install_node_lts(), install_global_npm()
- src/install/uv.sh - DRY_RUN guards in install_uv(), install_python()
- src/install/ai-tools.sh - DRY_RUN guards in install_ai_tool() (npm + curl branches)
- src/install/dev-env.sh - DRY_RUN guard in setup_ssh_key()

**Modified (07-03):**
- src/core/progress.sh - Added show_completion_summary() with profile, platform, duration, failure integration
- setup.sh - Sources progress.sh, SECONDS timer, show_completion_summary call, cleanup trap override

## Phase 8 Deliverables (COMPLETE)

**Created (08-01):**
- assets/.gitkeep - Directory placeholder for future terminal demo GIF
- README.md - Complete 23-section professional documentation (602 lines, rewritten)

## Phase 8.1 Deliverables (COMPLETE)

**Created (08.1-01):**
- examples/terminal-setup.ps1 - Standalone PowerShell terminal setup wizard (547 lines)

## Phase 8.2 Deliverables (COMPLETE)

**Modified (08.2-03):**
- examples/terminal-setup.sh - DRY_RUN guards on zoxide and starship curl|sh pipelines
- src/platforms/windows/main.ps1 - WARN logging for cargo.txt, npm.txt, ai-tools.txt in switch dispatch

**Modified (08.2-02):**
- src/platforms/macos/install/homebrew.sh - Exit 1 on failure + FAILURE_LOG write
- src/platforms/macos/main.sh - Cleanup reads FAILURE_LOG and reports child failures
- src/platforms/linux/main.sh - Cleanup reads FAILURE_LOG and reports child failures
- src/platforms/windows/core/errors.psm1 - Add-FailedItem writes to $env:FAILURE_LOG file
- setup.ps1 - FAILURE_LOG lifecycle: create, read at exit, remove temp file

**Created (08.2-04):**
- tests/test-macos.sh - macOS platform static test suite (16 tests)
- tests/test-windows.ps1 - Windows platform static test suite (18 tests)

## Phase 9 Deliverables (COMPLETE)

**Created (09-01):**
- examples/terminal/presets/minimal.toml - ASCII-safe Starship preset (project default style)
- examples/terminal/presets/powerline.toml - Nerd Font preset with palette and colored segments
- examples/terminal/presets/p10k-alike.toml - p10k Lean approximation with username/hostname/git_state
- examples/terminal/migrate-p10k.sh - Standalone p10k migration script (7-method detection, backup, cleanup)

**Created (09-02):**
- examples/terminal/setup.sh - Canonical terminal setup script (SSoT, 408 lines)
- examples/terminal/README.md - Standalone migration guide with preset comparison (144 lines)

**Modified (09-02):**
- examples/terminal-setup.sh - Converted to 24-line pure wrapper (was 493 lines)

## Phase 10 Deliverables (COMPLETE)

**Created (10-01):**
- src/platforms/windows/install/cargo.ps1 - WinGet-first Cargo package installer (226 lines)
- src/platforms/windows/install/npm.ps1 - npm global package installer (126 lines)
- src/platforms/windows/install/ai-tools.ps1 - Prefix-based AI tools installer (226 lines)

**Modified (10-02):**
- src/platforms/windows/main.ps1 - Dispatch wiring: cargo.txt/npm.txt/ai-tools.txt to install/*.ps1 (replaces WARN-skip)
- tests/test-windows.ps1 - Extended from 18 to 39 tests covering new installer scripts

## Pending Items

- [ ] Terminal screenshot (static PNG) for README hero image
- [ ] Terminal demo video (asciinema + agg -> GIF) for README
- [ ] Social preview image via socialify.git.ci

## Phase 8.2 Audit Context

**Source**: 4-agent parallel review (2026-02-08)
- linux-reviewer: 6 CRITICAL, 13 WARNING, 6 INFO
- macos-reviewer: 2 CRITICAL, 7 WARNING, 7 INFO
- windows-reviewer: 4 CRITICAL, 8 WARNING, 7 INFO + 12 GAPs
- docs-tests-reviewer: 4 CRITICAL, 8 WARNING, 5 INFO + 6 TEST GAPs

**Tier 1 fixes applied** (same session): SCRIPT_DIR collision, GNU sed portability, test_harness paths, README accuracy, Bash 4+ compat

## Session Continuity

Last session: 2026-02-17
Stopped at: Completed 10.1-01-PLAN.md (ALL PLANS COMPLETE — v2.1 process debt closed)
Resume file: None

---
*ALL 41 PLANS COMPLETE. Milestone v1.0 + Phase 8.1/8.2 insertions + Phase 9 Terminal Blueprint + Phase 10 Windows Installers + Phase 10.1 Process Debt Cleanup.*
