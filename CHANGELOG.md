# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Upcoming
- **v3.1.0**: bats-core testing framework
- **v3.2.0**: Enhanced platform detection
- **v4.0.0**: Full platform parity

## [3.0.0] - 2025-01-27

### Changed - BREAKING
- 🏗️ **Complete repository restructure** following Agile Repository Structure Guide
  - All scripts moved to organized `scripts/` directory
  - Platform-specific code consolidated in `platforms/`
  - Configuration files centralized in `configs/`
  - Documentation reorganized in `docs/`
  - Created clear separation of concerns
  
### Added
- 📁 **New directory structure**:
  - `scripts/install/` - All installation scripts
  - `scripts/setup/` - Setup and configuration scripts
  - `scripts/utils/` - Shared utilities
  - `platforms/` - OS-specific implementations
  - `configs/` - All configuration files
  - `tools/` - Development and maintenance tools
  - `share/` - Examples and exports
- 🔗 **Compatibility symlinks** for backward compatibility
- 📝 **README files** in each major directory
- 🔧 **Migration tools**:
  - `migrate-structure.sh` - Automated migration script
  - `verify-migration.sh` - Migration verification

### Improved
- 🧹 **Cleaner root directory** - Only essential files remain
- 📊 **Better organization** - Logical grouping by function
- 🔍 **Easier navigation** - Self-explanatory structure
- ♻️ **Eliminated duplicates** - Consolidated utils directories
- 📈 **Scalability** - Easy to add new features without clutter

### Migration Guide
1. Run `./migrate-structure.sh` to reorganize existing installation
2. Verify with `./verify-migration.sh`
3. Update any custom scripts to use new paths
4. Symlinks maintain backward compatibility

## [2.7.0] - 2025-01-27

### Added
- 🌍 **Complete Internationalization (i18n) - English Translation**
  - All user-facing content translated to English
  - All code comments translated to English
  - All documentation translated to English
  - Structured 4-phase translation approach:
    - Phase 1: Core documentation (CLAUDE.md, README.md, STATUS.md)
    - Phase 2: User-facing messages in shell scripts
    - Phase 3: Code comments and internal documentation
    - Phase 4: Function names (already in English, no changes needed)
  - New MIGRATION_PT_EN.md guide documenting all changes
  - Version tags for each phase completion (v2.7.0 through v2.7.3)

### Changed
- 📝 **Documentation**
  - docs/ai-tools-setup.md fully translated to English
  - All inline documentation in scripts translated
  - README.md and other core docs already in English
  
- 🔧 **Shell Scripts**
  - setup.sh: All user messages and comments translated
  - install_rust_tools.sh: All user messages and comments translated
  - Other scripts verified/updated as needed
  
- 💬 **Code Comments**
  - zshrc: All comments translated to English
  - All .sh files: Comments translated to English
  - Consistent English terminology throughout codebase

### Improved
- 🚀 **User Experience**
  - More accessible to international users
  - Consistent language throughout the project
  - Professional English terminology
  - No breaking changes - full compatibility maintained

## [2.6.0] - 2025-07-26

### Added
- 🔄 **BMAD Method Scripts**
  - New `install_bmad.sh` script for simple BMAD installation
  - New `update_bmad.sh` script for easy BMAD updates
  - Automatic version checking and comparison
  - Backup creation before updates
  - Native `.bmad-core/` location (gitignored for clean commits)
  - Preserves custom content (expansion packs, custom agents)
  - Shows changelog reference after update

### Changed
- 📦 **BMAD Method updated to v4.31.0**
  - Updated from v4.25.0 to latest v4.31.0
  - New templates and workflows included
  - Enhanced brainstorming and elicitation features
  - Improved core configuration structure
  - Better workflow management utilities
  - New brainstorming and elicitation methods

## [2.5.1] - 2025-07-25

### Changed
- 🔄 **CI/CD Workflows converted to manual execution only**
  - All workflows now use `workflow_dispatch` instead of automatic triggers
  - Removed automatic execution on push, pull_request, and schedule
  - Added required `reason` input field for audit trail
  - Added `confirm_major_change` option in test-scripts workflow
  - Added `check_type` selector in dependency-check workflow
  - **BREAKING CHANGE**: Workflows no longer run automatically

### Added
- 📋 **Testing Guidelines Documentation**
  - Created `.github/TESTING_GUIDELINES.md` with comprehensive testing strategy
  - Defined when tests are mandatory vs optional
  - Instructions for running tests via GitHub UI and CLI
  - Local testing recommendations to save CI/CD resources

### Security
- 🔒 Reduced attack surface by eliminating automatic workflow execution
- 🛡️ All CI/CD operations now require explicit human approval

## [2.5.0] - 2025-07-24

### Added
- 🤖 **AI Development Tools Integration**
  - MCPs (Model Context Protocol) configuration support
  - 4 essential MCPs: context7, fetch, sequential-thinking, serena
  - BMAD Method v4.31.0 agent-based integration
  - Cross-platform installer for AI tools (`install_ai_tools.sh`)
  - Diagnostic script to verify installations (`check_ai_tools.sh`)
  - Quick start guide for AI-powered development
- 🎯 **Product-Focused Git Configuration System**
  - Global git template system for automatic .github/ structure
  - Smart git hooks for automatic commit prefixing
  - Product-focused git aliases (logp, diffp, statusp)
  - Shell functions for project management (gnew, ginit, gcheck)
  - Migration tools for existing projects
  - Comprehensive documentation (`docs/product-focused-git.md`)
- 📚 **Context Engineering Documentation**
  - CLAUDE.md v2.3.0 - AI collaboration guidelines
  - CLAUDE-EXTENDED.md - Detailed implementation guides
  - Integration with BMAD methodology

### Changed
- Updated LICENSE copyright to "Bragatte, M.A.S"
- Repository structure reorganization (AI tools → .github/)
- Improved .gitignore for .github/AI_TOOLKIT directories
- Enhanced setup.sh with AI tools and product-focused git options

### Fixed
- Corrected claude.json filename references (was claude_desktop_config.json)
- Fixed profile configurations to use correct MCP config filename

## [2.4.0-alpha.1] - 2025-07-23
### Added
- 🎯 **Profile-based installation system**
  - 5 pre-configured profiles: developer-standard, developer-minimal, devops, data-scientist, student
  - setup-with-profile.sh for interactive profile selection
  - YAML-based profile configuration
  - Dry-run mode to preview installations
  - Custom profile support
- 📚 **Comprehensive user documentation**
  - quick-start.md - Fast onboarding guide
  - modern-cli-tools.md - Detailed tool usage guides
  - shell-customization.md - Zsh/Oh-My-Zsh configuration
  - installation-profiles.md - Complete profile documentation
  - troubleshooting.md - Common issues and solutions
  - versioning-guide.md - Clear semantic versioning strategy

### Changed
- Updated setup.sh to support --profile and --minimal arguments
- Transformed user-guide.md to focus on actual usage instead of BMAD methodology
- Added versioning strategy to CLAUDE-EXTENDED.md

## [2.3.1] - 2025-07-23
### Security
- ✅ **Fixed critical APT lock vulnerability (ADR-005)**
  - Removed all dangerous `sudo rm /var/lib/dpkg/lock*` commands
  - Implemented safe wait mechanisms for package managers
  - Added package-manager-safety.sh module
  - 100% of APT scripts now use safe operations

### Added
- Comprehensive security test suite
  - test_apt_lock_safety.sh - 10 security validations
  - test_apt_timeout_scenarios.sh - 5 integration scenarios
  - test_apt_safety_simple.sh - CI/CD friendly tests
  - Security test documentation (tests/security/README.md)

### Changed
- Made logging.sh compatible with Bash 3.2 (macOS support)
- Repository reorganized for user-focused navigation
- Moved development docs to .github/PROJECT_DOCS/
- Moved AI context to .github/AI_CONTEXT/

### Fixed
- APT lock timeout issues
- Package validation to prevent injection attacks
- Error handling and recovery mechanisms

---

## OS Post-Install Scripts Releases

## Pre-release History

### [2.3.1-alpha.4] - 2025-07-23 (Superseded by 2.3.1 release)
- Completed security test suite
- Fixed Bash 3.2 compatibility
- Repository reorganization

### [2.3.1-alpha.3] - 2025-07-23
- Repository reorganized for user focus
- Moved docs to appropriate directories

### [2.3.1-alpha.2] - 2025-07-23  
- Completed migration of ALL APT scripts
- Added safe wrapper functions

### [2.3.1-alpha.1] - 2025-07-23
- Initial security module implementation
- Started APT script migration

### [2.3.0] - 2025-07-23
#### Added
- CLAUDE.md v2.3.0 integration for Context Engineering
- PRD.md with comprehensive project requirements
- STORIES.md with user journey mapping and Epic 0
- STATUS.md for project health tracking
- TESTING.md with Testing Trophy strategy
- 8 Architecture Decision Records (ADRs)
- BMAD Method v4.30 integration

#### Changed
- Project now follows Context Engineering principles
- Documentation structure aligned with CLAUDE.md standards
- Adopted transparent communication about test coverage

#### Security
- Discovered critical APT lock vulnerability (see v2.3.1)

---

## CLAUDE.md Framework Updates
*These entries document the evolution of the CLAUDE.md AI interaction framework:*

### [2.3.0] - 2025-07-23
#### Added
- Quick Start section at the beginning of the document
- Serena as 4th essential MCP
- Instructions to activate the 4 MCPs by default
- Separation of changelog into dedicated file

#### Changed
- Reorganization for better reading flow
- MCPs are now 4 by default (Context7, fetch, sequential-thinking, serena)
- Consolidated links to avoid redundancy

#### Removed
- Changelog from main file (moved to dedicated file)
- Unnecessary external references (books, communities)

### [2.2.0] - 2025-07-22
#### Added
- Specific technical preferences:
  - Python: UV for environments, Polars > pandas
  - Rust: Explicit typing and memory management
  - React: Epic Stack patterns
- Direct links to Epic Stack and modern tools

#### Changed
- More specific code patterns section by language
- Updated recommended versions

### [2.1.0] - 2025-07-22
#### Added
- Contextual self-modulation system with flow diagram
- Detailed protocol for existing projects
- Integrated bioinformatics specific examples
- STORIES → CLAUDE.md decision table
- Section on how decisions filter the document

#### Changed
- Reorganization to highlight adaptive flow at top
- Improvements in code examples with bioinformatics cases
- Expansion of startup protocol to include PRD verification

#### Fixed
- Clarification that not all sections always apply
- Alignment with real flow STATUS → PRD → STORIES → CLAUDE

### [2.0.0] - 2025-07-19
#### Added
- CLAUDE-EXTENDED.md as complementary document
- Context Engineering vs Prompt Engineering complete section
- Testing Trophy with detailed philosophy
- Essential MCPs (Context7, fetch, sequential-thinking)
- Prompt capture protocol [prompt-saved]

#### Changed
- Major restructuring to separate basic vs. advanced content
- All extensive examples moved to EXTENDED
- Focus on being an operational document, not encyclopedic

### [1.5.0] - 2025-07-16
#### Added
- "Never Do" section expanded with 13 items
- Cross-platform compatibility with pathlib
- Conventional commit patterns
- Tripartite quality checklist

#### Changed
- Code examples now with mandatory ## comments
- Better organization of quick references

### [1.0.0] - 2025-07-12
#### Added
- Official integration with BMAD Method
- Essential documents system (red/purple/yellow)
- ADRs with mandatory Mermaid diagrams
- Simplicity philosophy with quotes

#### Changed
- Migration from loose guidelines to structured system
- Prioritization of STATUS.md as entry point

### [0.5.0] - 2025-07-08
#### Added
- Session startup protocol
- Why-What-How as standard structure
- Rules for artifacts
- "Always Do" section

#### Changed
- Refinement of fundamental principles
- Better definition of intellectual partnership

### [0.2.0] - 2025-07-04
#### Added
- Basic fundamental principles
- Initial comment structure for R/Python
- "Documentation is code" concept

### [0.1.0] - 2025-07-01
- First draft of CLAUDE.md
- Initial idea to prevent vibe-coding
- Basic structure inspired by README.md

## OS Post-Install Scripts Updates

## [2.2.0] - 2025-07-10

### Added
- New modular directory structure (install/, utils/, verify/)
- Central orchestrator script (main.sh) with interactive menu
- Comprehensive verification system (check-installation.sh)
- Interactive desktop environment installer
- Backward compatibility wrappers

### Changed
- Reorganized all scripts into logical directories
- Standardized naming convention (hyphens instead of underscores)
- Converted flavors.sh into interactive desktop-environments.sh
- All scripts now have proper shebangs and error handling

### Fixed
- All 50 tests now passing
- Missing shebangs in bashrc.sh and flavors.sh
- Script permission issues resolved
- Test harness now ignores test files for URL checks

## [2.1.0] - 2025-07-10

### Added
- Comprehensive test harness for validating script functionality
- Script inventory documentation
- Logging system for all scripts
- Safe APT lock handling mechanism
- BMad Method integration with AI-assisted development
- Dual Makefile system (BMad + Project-specific targets)
- Security improvements across all scripts

### Changed
- All scripts now use `set -euo pipefail` for better error handling
- Fixed placeholder URLs (SEU_USUARIO → BragatteMAS)
- Improved script permissions (all scripts now executable)
- Reorganized documentation structure

### Fixed
- Security vulnerabilities in APT lock handling
- Missing error handling in scripts
- Non-executable script permissions
- Placeholder URLs causing script failures

### Security
- Added proper error trapping to prevent silent failures
- Implemented safe APT lock waiting instead of force removal
- Added logging for audit trails

## [2.0.0] - 2024-12-15

### Added
- **Section 22: Advanced Enhancements** - 13 major new features:
  - Universal package manager function (`install_tool`)
  - Git credential security setup (`setup_git_credentials`)
  - Configuration backup system with rotation (`backup_configs`)
  - Full WSL (Windows Subsystem for Linux) support
  - Docker/Podman integration with custom aliases
  - Adaptive themes based on system preferences
  - Performance monitoring (`shell_benchmark`)
  - Secure environment variables loading from `.env.local`
  - Lazy loading for nvm and rbenv
  - Built-in documentation system (`zdoc`)
  - Interactive quick menu (`qm`)
  - Automatic SSH agent management
  - Feature flags support via `.zshrc.flags`

- **Enhanced Welcome Message**:
  - Shows current git branch
  - Organized command categories with tree structure
  - Dynamic status indicators (conda env, secure env)
  - Compact version available (`welcomec`)

- **Improved Help System**:
  - `zdoc` - Complete function documentation
  - Better organized help categories
  - `ac rust` - List all Rust tools

### Changed
- Fixed sed alias conflict - renamed to `sdr` for sd (Rust tool)
- Improved help functions to use `\sed` bypassing aliases
- Enhanced `nu_compare` function for better compatibility
- Optimized xargs usage in command tracking to prevent quote errors
- Removed terminal clearing from welcome message
- Removed blocking "Press Enter" prompts
- Quick menu no longer clears screen

### Fixed
- Conda access issues due to syntax errors
- Help system "halp by category" not working
- "xargs: unterminated quote" error in command tracking
- Terminal being cleared unexpectedly
- Quick menu (`qm`) clearing terminal history

### Improved
- Cross-platform compatibility (macOS/Linux/WSL)
- Performance with lazy loading
- Security with credential management
- User experience with non-intrusive prompts

## [1.0.0] - Initial Release

### Features
- Basic post-install scripts for Linux
- Windows 11 setup with winget
- Anaconda installation script
- Basic zshrc configuration