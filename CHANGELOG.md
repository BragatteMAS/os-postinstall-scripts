# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Upcoming
- Complete security tests for APT operations (v2.3.1)
- Implement bats-core testing framework (v2.4.0)
- Core/Adapters architecture (v2.5.0)
- Full platform parity (v3.0.0)

---

## OS Post-Install Scripts Releases

### [2.3.1-alpha.2] - 2025-07-23
#### Security
- ✅ Completed migration of ALL APT scripts to safe lock handling
- ✅ Removed all instances of dangerous `sudo rm /var/lib/dpkg/lock*` commands
- ✅ Implemented comprehensive error handling and recovery

#### Changed
- Updated ALL APT scripts (install/apt.sh, auto/auto_apt.sh, post_install.sh)
- Replaced force-removal with proper wait mechanisms across the codebase
- Added consistent logging and progress reporting

#### Added
- Safe wrapper functions for all APT operations
- Automatic dependency resolution for .deb packages
- Comprehensive operation logging with timestamps

#### Work in Progress (40% remaining)
- Security tests implementation for APT lock handling
- Integration tests for timeout scenarios
- Documentation of security best practices

### [2.3.1-alpha.1] - 2025-07-23
#### Security
- Implemented safe APT lock handling module (utils/package-manager-safety.sh)
- Added centralized logging system (utils/logging.sh)
- Started migration from dangerous force-removal to safe wait mechanisms

#### Changed
- Updated linux/install/apt.sh to use safe package manager operations
- Replaced `sudo rm /var/lib/dpkg/lock-frontend` with proper wait logic
- Added package name validation to prevent injection attacks

#### Added
- Package operation audit trail in /var/log/os-postinstall/
- Timeout and retry mechanisms for APT operations
- Progress indicators for package installation

#### Work in Progress
- Still updating: auto_apt.sh, post_install.sh, verify_apt.sh
- Security tests pending implementation

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