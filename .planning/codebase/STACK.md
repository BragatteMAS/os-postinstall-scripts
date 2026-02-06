# Technology Stack

**Analysis Date:** 2026-02-04

## Languages

**Primary:**
- Bash 4.0+ - Core installation automation, all platform-specific scripts in `scripts/` and `installers/`
- JavaScript (Node.js) - CLI tools and installer utilities in `.github/BMAD/tools/installer/` and `.github/BMAD/ai-context-template/`
- Shell scripting (Bash/Zsh) - Configuration and setup utilities across all platforms

**Secondary:**
- YAML - Configuration files for profiles and tool definitions in `platforms/*/`

## Runtime

**Environment:**
- Node.js 14.0.0+ (minimum, with 20.0.0+ recommended for BMAD tools)
- Bash 4.0+ (required for associative arrays and modern features)
- Zsh 5.0+ (recommended for shell configuration)

**Package Manager:**
- npm (Node.js packages for MCPs and BMAD CLI)
- System package managers: apt (Debian/Ubuntu), dnf (Fedora), pacman (Arch), zypper (openSUSE)
- Homebrew (macOS)

## Frameworks

**Core Installation:**
- Custom bash framework with modular architecture in `scripts/` (setup, install, check, utils subdirectories)
- Commander.js - CLI argument parsing for BMAD installer at `.github/BMAD/tools/installer/` (chalk v5.4.1, commander v14.0.0)
- Inquirer.js - Interactive prompts for setup tools at `.github/BMAD/ai-context-template/` and BMAD installer (inquirer v8.2.5+)

**Development/Build:**
- Makefile-based orchestration in root `Makefile` - serves as command dispatcher for setup, testing, and documentation
- Shell script runners for platform-specific installation
- Local development environment via npm workspaces pointing to `tools/local-dev`

**Testing:**
- Manual testing framework (no automated test runner) - tests defined in `tests/manual/` with smoke, integration, acceptance, and security test suites
- ShellCheck integration via Makefile for linting (`make lint`)

## Key Dependencies

**Critical (Direct Dependencies):**
- chalk v5.4.1 - Terminal output formatting for BMAD installer
- commander v14.0.0 - CLI argument parsing
- inquirer v8.2.5+ - Interactive shell prompts for setup wizards
- fs-extra v11.1.0+ - Enhanced file system operations
- js-yaml v4.1.0 - YAML parsing for configuration files
- ora v8.2.0 - Elegant terminal spinners for progress indication

**System Dependencies (Required):**
- Git 2.25+ - Version control, cloning repositories
- curl or wget - HTTP downloads for tool installations
- jq 1.6+ - JSON/YAML processing in bash scripts
- zsh - Shell configuration target

**Platform-Specific Package Managers:**
- Homebrew - macOS package installation
- apt - Debian/Ubuntu package manager
- dnf - Fedora package manager
- pacman - Arch Linux package manager
- zypper - openSUSE package manager

## Configuration

**Environment:**
- Environment variables defined in `.env.local.example` for local development:
  - `NODE_ENV` - development/production mode
  - `TEST_MODE` - local testing mode
  - `OS_TARGET` - target platform (linux, windows, darwin)
  - `ENABLE_DEBUG`, `VERBOSE_OUTPUT` - debugging flags
  - `PREFERRED_SHELL` - shell selection (bash/zsh)
- Configuration sourced from system detection in `scripts/setup/main.sh` at runtime

**Build:**
- `package.json` at root with workspace configuration pointing to `tools/local-dev`
- Three separate `package.json` files for modular Node.js components:
  - Root: `package.json` - development scripts with cross-env for platform testing
  - BMAD installer: `.github/BMAD/tools/installer/package.json` (v4.32.0)
  - AI context template: `.github/BMAD/ai-context-template/package.json` (v1.0.0)
- No lock files tracked (npm packages used but lockfiles not committed)
- Shell scripts use `set -euo pipefail` for error handling and safety

## Platform Requirements

**Development:**
- macOS 10.15+ (Catalina) or later - requires Bash upgrade from default 3.2
- Linux: Ubuntu 20.04+, Fedora 34+, Arch (current), Debian 11+
- Windows 10/11 with WSL2 or Git Bash environment
- Modern shell environment (Bash 4.0+, Git 2.25+)
- curl/wget for downloading remote resources
- jq for JSON processing in bash

**Production (Installation Target):**
- Same OS support as development (macOS, Linux, Windows via WSL)
- Fresh OS installation (post-install scripts assume clean system)
- Internet connectivity for downloading packages and tools
- Appropriate package manager for target system

## Tool Installations

**Post-Install Tools Configured:**
- Version Control: Git, Git LFS, GitHub CLI
- Containers: Docker, Docker Compose, Podman
- Languages: Python, Node.js, Rust, Go, Java
- Editors: VS Code, Vim, Neovim
- Build Tools: Make, CMake, GCC
- Modern CLI tools: bat (code display), eza (ls replacement), fd (find replacement), ripgrep (search), zoxide (cd replacement), starship (shell prompt)
- Python tools: uv (package manager), polars (data processing)
- Node.js MCPs: context7, fetch, sequential-thinking, serena (via BMAD integration)

---

*Stack analysis: 2026-02-04*
