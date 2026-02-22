# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.0] - 2026-02-22

### Added
- 105 new tests: 83 bats (platform, progress, dotfiles, interactive, profile validation, integration, contract parity) + 22 Pester (logging, errors, packages, progress modules)
- `safe_curl_sh()` download-then-execute helper for all curl|sh sites (5 call sites migrated)
- Semantic exit codes (0/1/2) via `errors.sh` and `errors.psm1` with `compute_exit_code()`
- Exit code propagation through full parent-child orchestrator chain
- `verify_bash_version()` warn-not-block for macOS Bash 3.2 compatibility
- SECURITY.md with responsible disclosure policy and private vulnerability reporting
- NOTICE file for Apache 2.0 attribution
- `tests/contracts/bash-ps-parity.md` mapping 16 Bash↔PowerShell function pairs
- Fork-ready documentation: submodule init instructions, Pester prerequisites, test commands

### Changed
- License migrated from MIT to Apache 2.0 (attribution requirement)
- 36 broken Flatpak IDs corrected to valid reverse-DNS format across flatpak.txt and flatpak-post.txt
- `pipefail` added to all 12 subshell scripts
- README clone command now includes `--recurse-submodules`
- ADR-001 amended to document semantic exit code strategy
- ADR-009 added documenting curl|sh trust model

### Removed
- 3 discontinued apps archived (Skype, TogglDesktop, Workflow)

### Fixed
- EXIT trap bug: `cleanup()` now preserves non-zero exit codes
- Pester v5 module-scoped mocking: added `-ModuleName` to all Write-Host mocks
- SECURITY.md vs README vulnerability reporting contradiction resolved
- Version badge updated from 3.3.0 to 4.1.0
- `cargo.txt` duplicate entry removed
- `brew.txt` trailing whitespace cleaned

## [4.0.0] - 2026-02-18

### Added
- 37 bats-core unit tests covering logging.sh, errors.sh, packages.sh, idempotent.sh
- Lint runners: `tools/lint.sh` (ShellCheck for 30+ files) and `tools/lint.ps1` (PSScriptAnalyzer)
- Windows CLI switches: `-DryRun`, `-Verbose`, `-Unattended` matching Bash flag behavior
- Windows `[Step X/Y]` progress counters and completion summary (profile, platform, duration, failures)
- `[CmdletBinding()]` on all 12 exported PowerShell functions for native `-Verbose`/`-Debug` support
- Shared `idempotent.psm1` module with `Test-WinGetInstalled`, `Test-NpmInstalled`, `Test-CargoInstalled`
- README sections: EXTRA_PACKAGES/SKIP_PACKAGES customization, Windows Troubleshooting
- GitHub Release v4.0.0

### Changed
- VERBOSE check uses `== "true"` instead of `-n` (boolean correctness in 5 locations)
- NONINTERACTIVE/UNATTENDED unified via bridge in config.sh (6 downstream consumers)
- Merged `src/installers/` into `src/install/` (single directory)
- Color/format variables consolidated in logging.sh as SSoT (removed from platform.sh)
- DATA_DIR readonly guard prevents re-source collision

### Removed
- `kite.kite` from winget.txt (discontinued 2022)
- Duplicate `src/installers/` directory

### Fixed
- ARCHITECTURE.md corrected to reflect actual error handling strategy (no set -e, per ADR-001)
- PowerShell duplicate idempotent check functions consolidated

## [3.3.0] - 2026-02-08

### Added
- Cross-platform setup framework (Linux, macOS, Windows)
- Data-driven package management with `data/packages/*.txt`
- Profile composition system (minimal, developer, full)
- Core modules: platform detection, idempotency, logging, error handling
- Progress feedback with step counting and DRY_RUN banners
- Completion summary with timing and failure tracking
- Windows foundation with WinGet installer and orchestrator
- Modular dotfiles system with symlink manager
- Zsh installation script with profile selection
- Professional README with 23 sections
- CONTRIBUTING.md rewrite
- GitHub issue/PR templates with ShellCheck requirements
- 7 Architecture Decision Records for current codebase

### Changed
- Complete repository restructure to `src/`, `data/`, `platforms/` layout
- Package lists extracted from scripts to `data/packages/*.txt`
- Platform orchestrators migrated to `src/platforms/`
- Dotfiles translated to English, Claude-specific config moved to `.zshrc.local`
- Setup entry point with `--dry-run`, `--verbose`, `--unattended` CLI flags and positional profile argument

### Removed
- Legacy BMAD framework and agent-os artifacts
- 300+ obsolete files (backup dirs, legacy docs, empty stubs)
- CI/CD workflows (manual execution only going forward)
- Outdated ADRs, test guides, and manual test scripts
- Dead symlinks and migration tools

### Fixed
- All internal paths updated to match new structure
- Cross-process failure tracking via shared log file
- Broken cargo.txt path reference
- Dead `setup-with-profile.sh` references replaced

---

> **Nota:** As versões abaixo são registro histórico. Alguns diretórios e ferramentas
> referenciados (`.agent-os/`, `tools/`, `scripts/`, `platforms/`, `configs/`,
> symlinks de compatibilidade, migration tools) foram removidos ou reestruturados na v3.3.0.

## [3.2.2] - 2025-08-03

### Fixed
- Standardized documentation references and file extensions
- Fixed inconsistencies between symlinks and actual file locations
- Translated remaining Portuguese sections to English

## [3.2.1] - 2025-08-03

### Added
- Documentation symlinks for backward compatibility
- Global documentation structure

## [3.2.0] - 2025-08-03

### Added
- Lightweight agent orchestration system (`.agent-os/`)
- Documentation agent for automated doc maintenance

### Changed
- Updated dependencies and integration tooling

### Fixed
- Trailing whitespace cleanup in configuration files

## [3.1.5] - 2025-07-01

### Added
- MCP configuration with 7 essential MCPs (Context7, fetch, sequential-thinking, serena, FastAPI, A2A, system-prompts)

### Changed
- CLAUDE.md updated to v2.3.1

## [3.1.4] - 2025-07-28

### Added
- CLAUDE.md v2.3.0 with Context Engineering documentation
- CLAUDE-EXTENDED.md for detailed implementation guidance

### Changed
- Synchronized .zshrc configuration with latest shell setup

## [3.1.3] - 2025-07-27

### Fixed
- Translated remaining Portuguese sections to English across documentation

## [3.1.2] - 2025-07-27

### Fixed
- Corrected timeline dates in ROADMAP.md, PRD.md, and STORIES.md

## [3.1.1] - 2025-07-27

### Added
- Comprehensive PRD v2.0.0 with brownfield analysis
- STORIES.md aligned with PRD (user stories for recommendations, platform parity)
- PO validation deliverables (gap analysis, story tasks)

### Changed
- Testing philosophy shifted to manual-only approach
- Profile system deprecation in favor of intelligent recommendations

## [3.1.0] - 2025-07-27

### Added
- YAML/JSON/TOML configuration templates system
- Template manager (`tools/templates/manager.sh`)
- Unattended installation mode with `--unattended` flag
- CI/CD pipeline support via environment variables

### Changed
- Documentation structure aligned with CLAUDE.md requirements
- Critical docs (STATUS.md, PRD.md, STORIES.md) moved to root

### Fixed
- Documentation discovery issues
- Version consistency across project files

## [3.0.0] - 2025-01-27

### Changed - BREAKING
- Complete repository restructure following Agile Repository Structure Guide
- Scripts organized into `scripts/` directory by function
- Platform-specific code consolidated in `platforms/`
- Configuration files centralized in `configs/`

### Added
- New directory layout: `scripts/install/`, `scripts/setup/`, `scripts/utils/`, `platforms/`, `configs/`, `tools/`, `share/`
- Compatibility symlinks for backward compatibility
- Migration tools (`migrate-structure.sh`, `verify-migration.sh`)

## [2.7.0] - 2025-01-27

### Added
- Complete internationalization (English translation)
  - All user-facing content, code comments, and documentation translated
  - 4-phase structured translation approach

### Changed
- All shell scripts translated (setup.sh, install_rust_tools.sh, etc.)
- Consistent English terminology throughout codebase

## [2.6.0] - 2025-07-26

### Added
- Automated installation and update scripts for development tools
- Automatic version checking and backup creation before updates

## [2.5.1] - 2025-07-25

### Changed
- **BREAKING**: CI/CD workflows converted to manual execution only (`workflow_dispatch`)
- All workflows now require explicit `reason` input for audit trail

### Added
- Testing guidelines documentation

### Security
- Reduced attack surface by eliminating automatic workflow execution

## [2.5.0] - 2025-07-24

### Added
- AI development tools integration (MCPs configuration support)
- Cross-platform installer for AI tools (`install_ai_tools.sh`)
- Diagnostic script for installation verification
- Product-focused git configuration system (templates, hooks, aliases)
- Context Engineering documentation (CLAUDE.md v2.3.0)

### Changed
- Updated LICENSE copyright to "Bragatte, M.A.S"

### Fixed
- Corrected `claude.json` filename references

## [2.4.0-alpha.1] - 2025-07-23

### Added
- Profile-based installation system with 5 pre-configured profiles
- Interactive profile selection via `setup-with-profile.sh`
- Comprehensive user documentation (quick-start, modern-cli-tools, shell-customization, troubleshooting)

## [2.3.1] - 2025-07-23

### Security
- Fixed critical APT lock vulnerability (removed dangerous force-removal commands)
- Implemented safe wait mechanisms for package managers
- Added `package-manager-safety.sh` module

### Added
- Security test suite (10 validations, 5 integration scenarios)

### Changed
- Made `logging.sh` compatible with Bash 3.2 (macOS support)
- Repository reorganized for user-focused navigation

## [2.3.0] - 2025-07-23

### Added
- CLAUDE.md v2.3.0 for Context Engineering
- PRD.md, STORIES.md, STATUS.md, TESTING.md
- 8 Architecture Decision Records

### Changed
- Project follows Context Engineering principles
- Transparent communication about test coverage

## [2.2.0] - 2025-07-10

### Added
- Modular directory structure (install/, utils/, verify/)
- Central orchestrator script with interactive menu
- Comprehensive verification system
- Interactive desktop environment installer

### Changed
- Standardized naming convention (hyphens over underscores)
- All scripts with proper shebangs and error handling

### Fixed
- All 50 tests passing
- Script permission issues resolved

## [2.1.0] - 2025-07-10

### Added
- Test harness for validating script functionality
- Logging system and safe APT lock handling
- Security improvements across all scripts

### Changed
- All scripts use `set -euo pipefail`
- Fixed placeholder URLs (SEU_USUARIO to BragatteMAS)

### Security
- Safe APT lock waiting instead of force removal
- Logging for audit trails

## [2.0.0] - 2024-12-15

### Added
- Advanced shell enhancements (13 features):
  - Universal package manager function
  - Git credential security setup
  - Configuration backup system with rotation
  - WSL support, Docker/Podman integration
  - Adaptive themes, performance monitoring
  - Lazy loading for nvm/rbenv
  - Built-in documentation system (`zdoc`)
  - Interactive quick menu (`qm`)
  - SSH agent management, feature flags (`.zshrc.flags`)

### Changed
- Fixed sed alias conflict (renamed to `sdr`)
- Optimized xargs usage to prevent quote errors
- Removed terminal clearing from welcome message

### Fixed
- Conda access syntax errors
- Help system category navigation
- Terminal clearing issues

## [1.0.0] - Initial Release

### Features
- Basic post-install scripts for Linux
- Windows 11 setup with winget
- Anaconda installation script
- Basic zshrc configuration
