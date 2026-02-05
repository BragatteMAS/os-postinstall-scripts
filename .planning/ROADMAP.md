# Roadmap: OS Post-Install Scripts

## Overview

This roadmap transforms the os-postinstall-scripts codebase from its current brownfield state (duplicated code, incomplete platform support, inconsistent patterns) into a clean, maintainable system. The approach is dependency-driven: core infrastructure first (idempotency, error handling, logging), then consolidation (DRY), then platform implementations (macOS priority over Windows based on user need), and finally polish (UX, documentation). Each phase delivers observable user value while building foundation for subsequent phases.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Core Infrastructure** - Foundation utilities for all platform code
- [ ] **Phase 2: Consolidation & Data Migration** - DRY the codebase, extract data
- [ ] **Phase 3: Dotfiles Management** - Symlink and shell configuration system
- [ ] **Phase 4: macOS Platform** - Homebrew integration and system setup
- [ ] **Phase 5: Linux Enhancements** - Feature additions to existing Linux support
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
**Plans**: TBD

Plans:
- [ ] 02-01: Create new directory structure
- [ ] 02-02: Extract package lists to data files
- [ ] 02-03: Consolidate duplicate code
- [ ] 02-04: Remove deprecated code

### Phase 3: Dotfiles Management
**Goal**: Implement topic-centric dotfiles system with safe symlink management
**Depends on**: Phase 2
**Requirements**: DOT-01, DOT-02, DOT-03, DOT-04
**Success Criteria** (what must be TRUE):
  1. Running setup creates symlinks in `$HOME` for all configs in `data/dotfiles/`
  2. Existing user configs are backed up with timestamp before any symlink overwrites them
  3. Shell configuration (zshrc or bashrc) is properly linked and sources required scripts
  4. Git configuration (gitconfig) is properly linked with user-specific values preserved
**Plans**: TBD

Plans:
- [ ] 03-01: Symlink manager implementation
- [ ] 03-02: Shell configuration (zsh/bash)
- [ ] 03-03: Git configuration

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
**Plans**: TBD

Plans:
- [ ] 04-01: Homebrew integration
- [ ] 04-02: Profile system implementation
- [ ] 04-03: macOS-specific utilities

### Phase 5: Linux Enhancements
**Goal**: Add feature-specific packages and enhance existing Linux support
**Depends on**: Phase 4
**Requirements**: PKG-02, FEAT-01, FEAT-02, FEAT-03
**Success Criteria** (what must be TRUE):
  1. APT package installation works reliably (proper lock handling, retries)
  2. AI/MCP integration tools are installed in developer/full profile
  3. Rust CLI tools (bat, eza, fd, rg, zoxide) are installed and working in developer/full profile
  4. Development environment (Node via nvm, Python via uv) is configured in developer/full profile
**Plans**: TBD

Plans:
- [ ] 05-01: Enhanced APT integration
- [ ] 05-02: AI/MCP tools installation
- [ ] 05-03: Rust CLI tools installation
- [ ] 05-04: Development environment setup

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
| 2. Consolidation & Data Migration | 0/4 | Not started | - |
| 3. Dotfiles Management | 0/3 | Not started | - |
| 4. macOS Platform | 0/3 | Not started | - |
| 5. Linux Enhancements | 0/4 | Not started | - |
| 6. Windows Foundation | 0/2 | Not started | - |
| 7. User Experience Polish | 0/3 | Not started | - |
| 8. Documentation | 0/2 | Not started | - |

---
*Roadmap created: 2026-02-04*
*Phase 1 completed: 2026-02-05*
*Depth: comprehensive (8 phases)*
*Requirements coverage: 22/22 mapped*
