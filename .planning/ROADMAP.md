# Roadmap: OS Post-Install Scripts

## Overview

This roadmap transforms the os-postinstall-scripts codebase from its current brownfield state (duplicated code, incomplete platform support, inconsistent patterns) into a clean, maintainable system. The approach is dependency-driven: core infrastructure first (idempotency, error handling, logging), then consolidation (DRY), then platform implementations (macOS priority over Windows based on user need), and finally polish (UX, documentation). Each phase delivers observable user value while building foundation for subsequent phases.

## Milestones

- v1.0 MVP - Phases 1-8.2 (shipped 2026-02-08)
- v2.1 Feature Completion - Phases 9-10.1 (shipped 2026-02-17)
- v3.0 Quality & Parity - Phases 11-14 (in progress)

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

### v3.0 Quality & Parity (Phases 11-14)

- [ ] **Phase 11: Flag & Boolean Fixes** - Correct flag semantics (VERBOSE, NONINTERACTIVE, stale data, doc drift)
- [ ] **Phase 12: Structure & DRY Cleanup** - Extract shared PS helpers, merge directories, eliminate duplication
- [ ] **Phase 13: Windows Parity** - DryRun flag, step counters, completion summary, CmdletBinding for Windows
- [ ] **Phase 14: Testing & Documentation** - Unit tests for core modules, lint runners, README gaps

## Phase Details

<details>
<summary>v1.0 MVP + v2.1 Feature Completion (Phases 1-10.1) -- SHIPPED 2026-02-17</summary>

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

</details>

### Phase 11: Flag & Boolean Fixes
**Goal**: Correct flag semantics so VERBOSE, NONINTERACTIVE, and data files behave as documented
**Depends on**: Phase 10.1
**Requirements**: FLAG-01, FLAG-02, FLAG-03, FLAG-04
**Success Criteria** (what must be TRUE):
  1. Running with `VERBOSE=false ./setup.sh` produces no timestamp/debug output (boolean check uses `== "true"`, not `-n`)
  2. Running with `./setup.sh -y` suppresses all interactive prompts including apt confirmation (NONINTERACTIVE/UNATTENDED unified via bridge)
  3. Running `.\setup.ps1` on Windows does not attempt to install kite.kite (stale entry removed from winget.txt)
  4. ARCHITECTURE.md accurately describes the error handling strategy (no set -e, per ADR-001)
**Plans**: TBD

Plans:
- [ ] 11-01-PLAN.md — TBD
- [ ] 11-02-PLAN.md — TBD

### Phase 12: Structure & DRY Cleanup
**Goal**: Eliminate code duplication and unify directory structure so each concept has exactly one home
**Depends on**: Phase 11
**Requirements**: DRY-01, DRY-02, DRY-03, DRY-04
**Success Criteria** (what must be TRUE):
  1. Test-WinGetInstalled and Test-NpmInstalled exist in exactly one file (windows/core/idempotent.psm1) and all PS installers import from there
  2. Only one install directory exists under src/ (src/install/, not both src/install/ and src/installers/)
  3. Color/format variables are defined only in logging.sh (platform.sh has no independent color definitions)
  4. Running `./setup.sh` twice does not hit a readonly DATA_DIR collision error (guard protects re-source)
**Plans**: TBD

Plans:
- [ ] 12-01-PLAN.md — TBD
- [ ] 12-02-PLAN.md — TBD

### Phase 13: Windows Parity
**Goal**: Windows users see the same UX feedback as Unix users (flags, progress, summary)
**Depends on**: Phase 12
**Requirements**: WPAR-01, WPAR-02, WPAR-03, WPAR-04
**Success Criteria** (what must be TRUE):
  1. Running `.\setup.ps1 -DryRun` shows a DryRun banner and skips all mutations (matching Bash `--dry-run` behavior)
  2. Windows installation shows `[Step X/Y]` prefix for each dispatch step (matching Unix step counters)
  3. After Windows setup completes, user sees a summary with profile name, platform, duration, and failure count (matching Unix completion summary)
  4. All exported PowerShell functions use `[CmdletBinding()]` so `-Verbose` and `-Debug` propagate natively
**Plans**: TBD

Plans:
- [ ] 13-01-PLAN.md — TBD
- [ ] 13-02-PLAN.md — TBD

### Phase 14: Testing & Documentation
**Goal**: Validate final codebase correctness with unit tests and close documentation gaps
**Depends on**: Phase 13
**Requirements**: TEST-01, TEST-02, DOC-01, DOC-02
**Success Criteria** (what must be TRUE):
  1. Running `bats tests/test-core-*.bats` passes unit tests for logging.sh, errors.sh, packages.sh, and idempotent.sh
  2. Running `tools/lint.sh` executes ShellCheck on all .sh files and reports results (no CI required)
  3. README.md Customization section documents EXTRA_PACKAGES and SKIP_PACKAGES environment variables with examples
  4. README.md includes a Windows Troubleshooting section covering execution policy, WinGet availability, and PATH issues
**Plans**: TBD

Plans:
- [ ] 14-01-PLAN.md — TBD
- [ ] 14-02-PLAN.md — TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 8.1 -> 8.2 -> 9 -> 10 -> 10.1 -> 11 -> 12 -> 13 -> 14

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Infrastructure | 3/3 | Complete | 2026-02-05 |
| 2. Consolidation & Data Migration | 7/7 | Complete | 2026-02-05 |
| 3. Dotfiles Management | 4/4 | Complete | 2026-02-06 |
| 4. macOS Platform | 3/3 | Complete | 2026-02-06 |
| 5. Linux Enhancements | 6/6 | Complete | 2026-02-06 |
| 6. Windows Foundation | 2/2 | Complete | 2026-02-06 |
| 7. User Experience Polish | 3/3 | Complete | 2026-02-07 |
| 8. Documentation | 3/3 | Complete | 2026-02-07 |
| 8.1 Terminal Setup Windows | 1/1 | Complete | 2026-02-08 |
| 8.2 Audit Remediation | 4/4 | Complete | 2026-02-08 |
| 9. Terminal Blueprint | 2/2 | Complete | 2026-02-17 |
| 10. Windows Cross-Platform Installers | 2/2 | Complete | 2026-02-17 |
| 10.1 Process Debt Cleanup | 1/1 | Complete | 2026-02-17 |
| 11. Flag & Boolean Fixes | 0/? | Not started | - |
| 12. Structure & DRY Cleanup | 0/? | Not started | - |
| 13. Windows Parity | 0/? | Not started | - |
| 14. Testing & Documentation | 0/? | Not started | - |

---
*Roadmap created: 2026-02-04*
*Milestone v1.0 complete: 2026-02-08*
*Milestone v2.1 complete: 2026-02-17*
*Milestone v3.0 phases added: 2026-02-18*
*Depth: comprehensive*
*v1.0+v2.1 requirements coverage: 22/22 mapped -- all Complete*
*v3.0 requirements coverage: 16/16 mapped*
