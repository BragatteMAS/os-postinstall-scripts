# Roadmap: OS Post-Install Scripts

## Overview

This roadmap transforms the os-postinstall-scripts codebase from its current brownfield state (duplicated code, incomplete platform support, inconsistent patterns) into a clean, maintainable system. The approach is dependency-driven: core infrastructure first (idempotency, error handling, logging), then consolidation (DRY), then platform implementations (macOS priority over Windows based on user need), and finally polish (UX, documentation). Each phase delivers observable user value while building foundation for subsequent phases.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Core Infrastructure** - Foundation utilities for all platform code
- [x] **Phase 2: Consolidation & Data Migration** - DRY the codebase, extract data
- [x] **Phase 3: Dotfiles Management** - Symlink and shell configuration system
- [x] **Phase 4: macOS Platform** - Homebrew integration and system setup
- [x] **Phase 5: Linux Enhancements** - Feature additions to existing Linux support
- [ ] **Phase 6: Windows Foundation** - Basic WinGet functionality
- [ ] **Phase 7: User Experience Polish** - Progress feedback, dry-run, summary
- [ ] **Phase 8: Documentation** - README, INSTALL, USAGE, CUSTOMIZE, CONTRIBUTING

## Phase Details

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
**Plans**: TBD

Plans:
- [ ] 06-01: PowerShell entry point and utilities
- [ ] 06-02: WinGet integration

### Phase 7: User Experience Polish
**Goal**: Provide excellent user feedback during execution
**Depends on**: Phase 5
**Requirements**: UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. User sees real-time progress during installation (current step, package being installed)
  2. Running with `--dry-run` shows what would be installed without making changes
  3. After completion, user sees summary of what was installed/configured
  4. Single command `./setup.sh` starts the entire process with sensible defaults
**Plans**: TBD

Plans:
- [ ] 07-01: Progress feedback system
- [ ] 07-02: Dry-run mode implementation
- [ ] 07-03: Completion summary

### Phase 8: Documentation
**Goal**: Comprehensive documentation for users and contributors
**Depends on**: Phase 7
**Requirements**: MOD-04
**Success Criteria** (what must be TRUE):
  1. README.md explains what the project does and how to get started
  2. INSTALL.md covers prerequisites and installation steps for all platforms
  3. USAGE.md documents all commands, flags, and profiles
  4. CUSTOMIZE.md explains how to add packages and modify configurations
  5. CONTRIBUTING.md provides guidelines for contributors
**Plans**: TBD

Plans:
- [ ] 08-01: User documentation (README, INSTALL, USAGE)
- [ ] 08-02: Customization and contribution guides

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Infrastructure | 3/3 | Complete | 2026-02-05 |
| 2. Consolidation & Data Migration | 7/7 | Complete | 2026-02-05 |
| 3. Dotfiles Management | 4/4 | Complete | 2026-02-06 |
| 4. macOS Platform | 3/3 | Complete | 2026-02-06 |
| 5. Linux Enhancements | 6/6 | Complete | 2026-02-06 |
| 6. Windows Foundation | 0/2 | Not started | - |
| 7. User Experience Polish | 0/3 | Not started | - |
| 8. Documentation | 0/2 | Not started | - |

---
*Roadmap created: 2026-02-04*
*Phase 1 completed: 2026-02-05*
*Phase 2 completed: 2026-02-05*
*Phase 3 completed: 2026-02-06*
*Phase 4 completed: 2026-02-06*
*Phase 5 completed: 2026-02-06*
*Depth: comprehensive (8 phases)*
*Requirements coverage: 22/22 mapped*
