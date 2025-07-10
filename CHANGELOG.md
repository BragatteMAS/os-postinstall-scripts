# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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