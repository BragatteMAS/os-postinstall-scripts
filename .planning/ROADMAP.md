# Roadmap: OS Post-Install Scripts

## Overview

This roadmap transforms the os-postinstall-scripts codebase from its current brownfield state (duplicated code, incomplete platform support, inconsistent patterns) into a clean, maintainable system. The approach is dependency-driven: core infrastructure first (idempotency, error handling, logging), then consolidation (DRY), then platform implementations (macOS priority over Windows based on user need), and finally polish (UX, documentation). Each phase delivers observable user value while building foundation for subsequent phases.

## Milestones

- v1.0 MVP - Phases 1-8.2 (shipped 2026-02-08)
- v2.1 Feature Completion - Phases 9-10.1 (shipped 2026-02-17)
- v3.0 Quality & Parity - Phases 11-14 (shipped 2026-02-18, tag v4.0.0) -- [archive](milestones/v3.0-ROADMAP.md)
- v4.1 Production Ready - Phases 15-18 (shipped 2026-02-22, tag v4.1.0) -- [archive](milestones/v4.1-ROADMAP.md)

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

<details>
<summary>v3.0 Quality & Parity (Phases 11-14) -- SHIPPED 2026-02-18</summary>

- [x] **Phase 11: Flag & Boolean Fixes** - Correct flag semantics (VERBOSE, NONINTERACTIVE, stale data, doc drift)
- [x] **Phase 12: Structure & DRY Cleanup** - Extract shared PS helpers, merge directories, eliminate duplication
- [x] **Phase 13: Windows Parity** - DryRun flag, step counters, completion summary, CmdletBinding for Windows
- [x] **Phase 14: Testing & Documentation** - Unit tests for core modules, lint runners, README gaps

</details>

<details>
<summary>v4.1 Production Ready (Phases 15-18) -- SHIPPED 2026-02-22</summary>

- [x] **Phase 15: Data & Compatibility Fixes** - Fix Flatpak IDs, remove discontinued apps, Bash 3.2 warn, pipefail (completed 2026-02-21)
- [x] **Phase 16: Exit Codes & Security** - Semantic exit codes, propagation, safe_curl_sh helper, ADR-009 (completed 2026-02-21)
- [x] **Phase 17: Test Expansion - Bash** - bats tests for 4 untested modules, profile validation, integration tests, contract parity (completed 2026-02-21)
- [x] **Phase 18: Polish & OSS Health** - Pester tests for PS modules, SECURITY.md, GitHub Releases, demo GIF (completed 2026-02-22)

</details>

## Progress

All 4 milestones shipped. 62 plans executed across 18 phases.

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 MVP | 1-8.2 | 41 | 2026-02-08 |
| v2.1 Feature Completion | 9-10.1 | 5 | 2026-02-17 |
| v3.0 Quality & Parity | 11-14 | 7 | 2026-02-18 |
| v4.1 Production Ready | 15-18 | 9 | 2026-02-22 |

See `.planning/milestones/` for detailed archives.

---
*Roadmap created: 2026-02-04*
*Milestone v1.0 complete: 2026-02-08*
*Milestone v2.1 complete: 2026-02-17*
*Milestone v3.0 complete: 2026-02-18 (tag v4.0.0)*
*Milestone v4.1 complete: 2026-02-22 (tag v4.1.0)*
*Total: 62 plans shipped across 4 milestones*
