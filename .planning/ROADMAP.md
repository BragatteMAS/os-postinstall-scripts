# Roadmap: OS Post-Install Scripts

## Overview

This roadmap transforms the os-postinstall-scripts codebase from its current brownfield state (duplicated code, incomplete platform support, inconsistent patterns) into a clean, maintainable system. The approach is dependency-driven: core infrastructure first (idempotency, error handling, logging), then consolidation (DRY), then platform implementations (macOS priority over Windows based on user need), and finally polish (UX, documentation). Each phase delivers observable user value while building foundation for subsequent phases.

## Milestones

- v1.0 MVP - Phases 1-8.2 (shipped 2026-02-08)
- v2.1 Feature Completion - Phases 9-10.1 (shipped 2026-02-17)
- v3.0 Quality & Parity - Phases 11-14 (shipped 2026-02-18, tag v4.0.0) — [archive](.planning/milestones/v3.0-ROADMAP.md)
- **v4.1 Production Ready** - Phases 15-18 (in progress)

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

<details>
<summary>v1.0 MVP + v2.1 Feature Completion (Phases 1-10.1) -- SHIPPED 2026-02-17</summary>

- [x] **Phase 1: Core Infrastructure** - Foundation utilities for all platform code
- [x] **Phase 2: Consolidation & Data Migration** - DRY the codebase, extract data
- [x] **Phase 3: Dotfiles Management** - Symlink and shell configuration system
- [x] **Phase 4: macOS Platform** - Homebrew integration and system setup
- [x] **Phase 5: Linux Enhancements** - Feature additions to existing Linux support
- [x] **Phase 6: Windows Foundation** - Basic WinGet functionality
- [x] **Phase 7: User Experience Polish** - Progress feedback, dry-run, summary
- [x] **Phase 8: Documentation** - README, INSTALL, USAGE, CUSTOMIZE, CONTRIBUTING
- [x] **Phase 8.1: Terminal Setup Windows** - PowerShell terminal setup wizard (INSERTED)
- [x] **Phase 8.2: Audit Remediation** - Fix runtime bugs and test gaps from audit (INSERTED)
- [x] **Phase 9: Terminal Blueprint** - Terminal replication with p10k migration, Starship presets
- [x] **Phase 10: Windows Cross-Platform Installers** - PowerShell cargo, npm, ai-tools installers
- [x] **Phase 10.1: Process Debt Cleanup** - Missing verification, documentation drift (INSERTED)

</details>

## Phase Details

<details>
<summary>v1.0 MVP + v2.1 Feature Completion + v3.0 Quality & Parity (Phases 1-14) -- SHIPPED 2026-02-18</summary>

### Phase 1: Core Infrastructure
**Goal**: Establish robust foundation utilities that enforce safe patterns across all platform-specific code
**Depends on**: Nothing (first phase)
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04
**Success Criteria** (what must be TRUE):
  1. Running `./setup.sh` on any Unix system correctly identifies OS (macOS vs Linux) and distro
  2. Running any installer twice produces identical system state (no duplicate PATH entries, no re-downloads)
  3. When a package fails to install, user sees clear error message and script continues gracefully
  4. All script output uses consistent colored logging (info=blue, success=green, error=red, warning=yellow)
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Platform detection module (DETECTED_* exports, verification sequence)
- [x] 01-02-PLAN.md — Idempotency utilities (is_installed, ensure_*, PATH guards)
- [x] 01-03-PLAN.md — Error handling and logging system (trap, failure tracking, colors)

### Phase 2: Consolidation & Data Migration
**Goal**: Eliminate code duplication and separate code from data following DRY principle
**Depends on**: Phase 1
**Requirements**: MOD-01, MOD-02, MOD-03, PKG-04
**Success Criteria** (what must be TRUE):
  1. Project structure follows `src/` + `data/` + `docs/` layout
  2. No duplicate implementation exists between `scripts/` and `platforms/` directories (old structure removed)
  3. Package lists are in separate `.sh` or `.txt` files under `data/packages/`, not hardcoded in scripts
  4. Deprecated code (`scripts/common/`) is removed from codebase
**Plans**: 7 plans (5 original + 2 gap closure)

Plans:
- [x] 02-01-PLAN.md — Create directory structure and migrate core utilities to src/core/
- [x] 02-02-PLAN.md — Extract package lists to data/packages/*.txt files
- [x] 02-03-PLAN.md — Migrate Linux platform code to src/platforms/linux/
- [x] 02-04-PLAN.md — Create setup.sh entry point and config.sh
- [x] 02-05-PLAN.md — Remove deprecated code and clean up old directories
- [x] 02-06-PLAN.md — [GAP CLOSURE] Remove remaining legacy platforms/linux/ content
- [x] 02-07-PLAN.md — [GAP CLOSURE] Refactor post_install.sh to use load_packages()

### Phase 3: Dotfiles Management
**Goal**: Implement topic-centric dotfiles system with safe symlink management
**Depends on**: Phase 2
**Requirements**: DOT-01, DOT-02, DOT-03, DOT-04
**Success Criteria** (what must be TRUE):
  1. Running setup creates symlinks in `$HOME` for all configs in `data/dotfiles/`
  2. Existing user configs are backed up with timestamp before any symlink overwrites them
  3. Shell configuration (zshrc or bashrc) is properly linked and sources required scripts
  4. Git configuration (gitconfig) is properly linked with user-specific values preserved
**Plans**: 4 plans

Plans:
- [x] 03-01-PLAN.md — Core symlink manager with backup functionality (src/core/dotfiles.sh)
- [x] 03-02-PLAN.md — Shell configurations (shared, zsh, bash)
- [x] 03-03-PLAN.md — Git and Starship configurations
- [x] 03-04-PLAN.md — Setup.sh integration and verification

### Phase 4: macOS Platform
**Goal**: Bring macOS support from 20% to functional parity with Linux
**Depends on**: Phase 3
**Requirements**: PKG-01, PROF-01, PROF-02, PROF-03, PROF-04
**Success Criteria** (what must be TRUE):
  1. Running `./setup.sh` on macOS installs Homebrew if not present (non-interactive mode)
  2. User can select profile (minimal, developer, full) via interactive menu
  3. Packages from selected profile are installed via `brew install` and `brew install --cask`
  4. Setup can be re-run on existing macOS installation without breaking anything (idempotent)
  5. Bash 4+ is available after setup completes (upgrade provided if needed)
**Plans**: 3 plans

Plans:
- [x] 04-01-PLAN.md — Homebrew installation script (idempotent, NONINTERACTIVE mode, PATH configuration)
- [x] 04-02-PLAN.md — Brew formula and cask installers (data-driven from brew.txt and brew-cask.txt)
- [x] 04-03-PLAN.md — macOS main orchestrator with profile selection menu

### Phase 5: Linux Enhancements
**Goal**: Add feature-specific packages and enhance existing Linux support with hardened installers, cross-platform dev tools, and profile-based orchestration
**Depends on**: Phase 4
**Requirements**: PKG-02, FEAT-01, FEAT-02, FEAT-03
**Success Criteria** (what must be TRUE):
  1. APT package installation works reliably (proper lock handling, retries)
  2. AI/MCP integration tools are installed in developer/full profile
  3. Rust CLI tools (bat, eza, fd, rg, zoxide, delta) are installed and working in developer/full profile
  4. Development environment (Node via fnm, Python via uv) is configured in developer/full profile
**Plans**: 6 plans

Plans:
- [x] 05-01-PLAN.md — APT hardening (lock timeout, retry backoff, two-pass install, DEBIAN_FRONTEND)
- [x] 05-02-PLAN.md — Flatpak/Snap data-driven rewrite (retry, idempotency, legacy removal)
- [x] 05-03-PLAN.md — Rust CLI tools installer (apt/brew + symlinks + dotfile integration)
- [x] 05-04-PLAN.md — Dev environment setup (fnm + uv + Node LTS + pnpm + bun + SSH)
- [x] 05-05-PLAN.md — AI coding tools installer (claude-code, codex, gemini-cli, ollama + profiles)
- [x] 05-06-PLAN.md — Linux main.sh orchestrator with profile dispatch and tests

### Phase 6: Windows Foundation
**Goal**: Establish basic Windows support via PowerShell and WinGet
**Depends on**: Phase 2 (can parallelize with 3-5 after consolidation)
**Requirements**: PKG-03
**Success Criteria** (what must be TRUE):
  1. Running `.\setup.ps1` on Windows installs packages via WinGet
  2. Script detects if WinGet is available and provides guidance if not
  3. Basic package list from profile is installed successfully
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md — PowerShell core modules (logging, packages, errors) and setup.ps1 entry point
- [x] 06-02-PLAN.md — WinGet data-driven installer and Windows orchestrator with profile dispatch

### Phase 7: User Experience Polish
**Goal**: Provide excellent user feedback during execution
**Depends on**: Phase 5
**Requirements**: UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. User sees real-time progress during installation (current step, package being installed)
  2. Running with `--dry-run` shows what would be installed without making changes
  3. After completion, user sees summary of what was installed/configured
  4. Single command `./setup.sh` starts the entire process with sensible defaults
**Plans**: 3 plans

Plans:
- [x] 07-01-PLAN.md — Progress feedback system (step counters in orchestrators, DRY_RUN banner, progress.sh module)
- [x] 07-02-PLAN.md — Dry-run mode (CLI flag parsing in setup.sh, DRY_RUN guards in 9 scripts)
- [x] 07-03-PLAN.md — Completion summary and one-command setup (rich summary with duration, SECONDS timer)

### Phase 8: Documentation
**Goal**: Comprehensive documentation for users and contributors (single README with all content, CONTRIBUTING rewrite, community health files)
**Depends on**: Phase 7
**Requirements**: MOD-04
**Success Criteria** (what must be TRUE):
  1. README.md explains what the project does and how to get started (23-section single document)
  2. README.md covers prerequisites, installation, usage, customization (merged per CONTEXT decision)
  3. CONTRIBUTING.md provides project-specific guidelines for contributors (no BMAD boilerplate)
  4. CODE_OF_CONDUCT.md exists (Contributor Covenant v2.1)
  5. GitHub templates and repo metadata are current
**Plans**: 3 plans

Plans:
- [x] 08-01-PLAN.md -- README.md complete rewrite (23 sections) + demo GIF placeholder
- [x] 08-02-PLAN.md -- CONTRIBUTING.md + GitHub templates update (CODE_OF_CONDUCT descoped, Pitfall 14)
- [x] 08-03-PLAN.md -- GitHub repo metadata + cross-link verification + visual check

### Phase 8.1: Terminal Setup for Windows (INSERTED)
**Goal**: Create `terminal-setup.ps1` for Windows, providing equivalent terminal configuration wizard to the existing `terminal-setup.sh` (Unix)
**Depends on**: Phase 8
**Plans**: 1 plan

Plans:
- [x] PLAN.md — Standalone terminal-setup.ps1 (547 lines, 10/10 must-haves verified)

### Phase 8.2: Audit Remediation (INSERTED)
**Goal**: Address technical debt identified by 4-agent codebase audit (Linux, macOS, Windows, Docs/Tests specialists). Fix runtime bugs, security issues, test gaps, and documentation drift.
**Depends on**: Phase 8.1
**Constraint**: NO CI/CD automation — all tests are manual execution only
**Success Criteria** (what must be TRUE):
  1. `post_install.sh` is either deprecated with clear notice or migrated to modern architecture
  2. Manual test suites exist for macOS and Windows platforms (test-macos.sh, test-windows.ps1)
  3. Windows `main.ps1` dispatches cargo.txt, npm.txt, and ai-tools.txt profiles (not silent skip)
  4. `homebrew.sh` propagates failure exit code to macOS `main.sh`
  5. `terminal-setup.sh` respects dry-run mode for all install operations including curl|sh
  6. Orchestrators (macOS main.sh, Windows main.ps1) aggregate failure summaries from child processes
  7. CODE_OF_CONDUCT.md exists (Contributor Covenant v2.1, deferred from Phase 8)
**Plans**: 4 plans

Plans:
- [x] 08.2-01-PLAN.md — Deprecate post_install.sh + update test_harness.sh + create CODE_OF_CONDUCT.md
- [x] 08.2-02-PLAN.md — homebrew.sh exit code propagation + cross-process failure aggregation (macOS/Linux/Windows)
- [x] 08.2-03-PLAN.md — terminal-setup.sh dry-run fix + Windows main.ps1 WARN dispatch
- [x] 08.2-04-PLAN.md — Static test suites for macOS (test-macos.sh) and Windows (test-windows.ps1)

### Phase 9: Terminal Blueprint
**Goal**: Standalone terminal replication subproduct with automated p10k → Starship migration, curated presets, and one-command setup within examples/terminal/
**Depends on**: Phase 8.2
**Success Criteria** (what must be TRUE):
  1. `examples/terminal/` directory exists with modular scripts (setup.sh, migrate-p10k.sh)
  2. At least 3 Starship presets available in `examples/terminal/presets/` (minimal, powerline, p10k-alike)
  3. migrate-p10k.sh detects p10k installation, backs up config, removes p10k, and installs Starship equivalent
  4. Standalone README.md in `examples/terminal/` with migration guide and before/after comparison
  5. Existing `examples/terminal-setup.sh` functionality preserved (backward compatible entry point)
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md — Starship presets (3 TOML files) + p10k migration script
- [x] 09-02-PLAN.md — Modular setup.sh, backward-compat wrapper, standalone README

### Phase 10: Windows Cross-Platform Installers [GAP CLOSURE]
**Goal**: Implement PowerShell equivalents for cross-platform installers (cargo, npm, ai-tools) on Windows, closing integration gap from v2.1 audit
**Depends on**: Phase 6
**Gap Closure**: Closes v2.1 audit integration gaps (Windows cargo.txt, npm.txt, ai-tools.txt)
**Success Criteria** (what must be TRUE):
  1. Windows `main.ps1` dispatches `cargo.txt` to a working PowerShell installer (not WARN skip)
  2. Windows `main.ps1` dispatches `npm.txt` to a working PowerShell installer (not WARN skip)
  3. Windows `main.ps1` dispatches `ai-tools.txt` to a working PowerShell installer (not WARN skip)
  4. Developer/full profiles on Windows install all listed packages from cargo/npm/ai-tools
**Plans**: 2 plans

Plans:
- [x] 10-01-PLAN.md — Create cargo.ps1, npm.ps1, ai-tools.ps1 (three Windows installers)
- [x] 10-02-PLAN.md — Wire dispatch in main.ps1 + extend test-windows.ps1

### Phase 10.1: Process Debt Cleanup (INSERTED) [GAP CLOSURE]
**Goal**: Close process gaps from v2.1 audit — missing verification file, documentation drift
**Depends on**: Phase 10
**Gap Closure**: Closes v2.1 audit tech debt (Phase 08 VERIFICATION.md, MOD-04 drift)
**Success Criteria** (what must be TRUE):
  1. Phase 08 has VERIFICATION.md with passing status confirming all success criteria
  2. MOD-04 marked "Complete" in REQUIREMENTS.md traceability table
**Plans**: 1 plan

Plans:
- [x] 10.1-01-PLAN.md — Phase 08 VERIFICATION.md + MOD-04 traceability update

- [x] **Phase 11: Flag & Boolean Fixes** - Correct flag semantics (VERBOSE, NONINTERACTIVE, stale data, doc drift) (completed 2026-02-18)
- [x] **Phase 12: Structure & DRY Cleanup** - Extract shared PS helpers, merge directories, eliminate duplication (completed 2026-02-18)
- [x] **Phase 13: Windows Parity** - DryRun flag, step counters, completion summary, CmdletBinding for Windows (completed 2026-02-18)
- [x] **Phase 14: Testing & Documentation** - Unit tests for core modules, lint runners, README gaps (completed 2026-02-18)

</details>

### v4.1 Production Ready (Phases 15-18)

- [ ] **Phase 15: Data & Compatibility Fixes** - Fix Flatpak IDs, remove discontinued apps, Bash 3.2 warn, pipefail, minor convergent fixes
- [ ] **Phase 16: Exit Codes & Security** - Semantic exit codes, propagation, safe_curl_sh helper, ADR-009
- [ ] **Phase 17: Test Expansion - Bash** - bats tests for 4 untested modules, profile validation, integration tests, contract parity
- [ ] **Phase 18: Polish & OSS Health** - Pester tests for PS modules, SECURITY.md, GitHub Releases, demo GIF

### Phase 15: Data & Compatibility Fixes
**Goal**: Fix broken Flatpak IDs, remove discontinued apps, resolve Bash 3.2 chicken-and-egg on macOS, add pipefail to all scripts, and apply minor convergent fixes
**Depends on**: Phase 14
**Requirements**: DATA-01, DATA-02, DATA-03, COMPAT-01, QUAL-01, QUAL-02
**Success Criteria** (what must be TRUE):
  1. All entries in `flatpak.txt` use valid reverse-DNS Flatpak IDs (0 short names)
  2. All entries in `flatpak-post.txt` use valid reverse-DNS Flatpak IDs (0 short names)
  3. Discontinued apps removed (TogglDesktop, Skype archived)
  4. `verify_bash_version()` warns but does NOT block on macOS with Bash 3.2
  5. `set -o pipefail` present in all scripts executed as subshell (not just setup.sh)
  6. PS `-Profile` parameter uses `[ValidateSet()]`, `Test-CargoInstalled` is multiline-safe, `node` removed from brew.txt, `fzf` added to brew.txt
**Plans**: ~2 plans

### Phase 16: Exit Codes & Security
**Goal**: Replace universal `exit 0` with semantic exit codes (0/1/2), propagate through parent-child chain, add download-then-execute helper for curl|sh, document trust model in ADR-009
**Depends on**: Phase 15
**Requirements**: EXIT-01, EXIT-02, SEC-01, SEC-02
**Success Criteria** (what must be TRUE):
  1. `EXIT_SUCCESS=0`, `EXIT_PARTIAL_FAILURE=1`, `EXIT_CRITICAL=2` constants defined in errors.sh and errors.psm1
  2. `compute_exit_code()` function in errors.sh returns code based on FAILURE_LOG/FAILED_ITEMS
  3. All 9 child installer scripts exit with semantic code (not hardcoded 0)
  4. Parent orchestrators (setup.sh, main.sh, main.ps1) track worst exit code from children
  5. `safe_curl_sh()` helper in src/core/ downloads to temp file before executing (5 call sites migrated)
  6. ADR-009 documents curl|sh trust model (HTTPS-only, no checksum — industry standard)
  7. ADR-001 amended to reflect semantic exit codes (preserving continue-on-failure intent)
**Plans**: ~2 plans

### Phase 17: Test Expansion - Bash
**Goal**: Expand bats coverage from 37 to ~100+ tests covering the 4 untested core modules (platform, progress, dotfiles, interactive), add profile validation tests, integration tests, and Bash/PS contract parity file
**Depends on**: Phase 16 (tests verify exit code behavior)
**Requirements**: TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08, TEST-09
**Success Criteria** (what must be TRUE):
  1. `test-core-platform.bats` exists with ~15-18 tests (mock uname, detect_platform, verify_bash_version, verify_package_manager)
  2. `test-core-progress.bats` exists with ~10-12 tests (show_dry_run_banner, count_platform_steps, show_completion_summary)
  3. `test-core-dotfiles.bats` exists with ~18-22 tests (path_to_backup_name, create_dotfile_symlink, backup_with_manifest in tmpdir)
  4. `test-core-interactive.bats` exists with ~6-8 tests (non-interactive paths of show_category_menu and ask_tool)
  5. `test-data-validation.bats` verifies all profile .txt references exist and no orphans
  6. `test-integration.bats` runs `setup.sh --dry-run` for each profile, `--help`, unknown flag
  7. `tests/contracts/api-parity.txt` maps Bash functions to PS equivalents with validation tests
  8. All tests pass: `bats tests/*.bats` exits 0
**Plans**: ~3 plans

### Phase 18: Polish & OSS Health
**Goal**: Add Pester unit tests for PowerShell modules, create SECURITY.md, format GitHub Releases, and produce demo GIF for README
**Depends on**: Phase 17
**Requirements**: TEST-10, OSS-01, OSS-02, OSS-03
**Success Criteria** (what must be TRUE):
  1. Pester tests exist for logging.psm1, errors.psm1, packages.psm1, progress.psm1 (~15-20 tests total)
  2. `SECURITY.md` exists in repo root with responsible disclosure policy
  3. GitHub Release for v4.0.0 formatted with changelog from tag
  4. Demo GIF (asciinema + agg) or improved placeholder in README
  5. Pester tests pass: `Invoke-Pester tests/pester/*.Tests.ps1` exits 0
**Plans**: ~2 plans

## Progress

All 3 milestones shipped. 48 plans executed across 14 phases. v4.1 in progress.

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 MVP | 1-8.2 | 41 | 2026-02-08 |
| v2.1 Feature Completion | 9-10.1 | 5 | 2026-02-17 |
| v3.0 Quality & Parity | 11-14 | 7 | 2026-02-18 |
| v4.1 Production Ready | 15-18 | ~9 | In progress |

See `.planning/milestones/` for detailed archives.

---
*Roadmap created: 2026-02-04*
*Milestone v1.0 complete: 2026-02-08*
*Milestone v2.1 complete: 2026-02-17*
*Milestone v3.0 complete: 2026-02-18 (tag v4.0.0)*
*Milestone v4.1 started: 2026-02-19*
*Total: 48 plans shipped, ~9 planned for v4.1*
