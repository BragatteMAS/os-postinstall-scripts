# Technology Stack

**Analysis Date:** 2026-02-08

## Languages

**Primary:**
- Bash 4.0+ - Core installation automation, all platform scripts in `src/`
- PowerShell 5.1+ - Windows platform support in `src/platforms/windows/`

**Secondary:**
- YAML/TOML - Configuration (starship.toml, gitconfig)
- Plain text - Package lists in `data/packages/*.txt`

## Runtime

**Environment:**
- Bash 4.0+ (required for associative arrays and modern features)
- Zsh 5.0+ (target shell for dotfiles configuration)
- PowerShell 5.1+ (Windows scripts)

**Package Managers (installed by scripts):**
- System: apt (Debian/Ubuntu), Homebrew (macOS), WinGet (Windows)
- Language: cargo (Rust), npm (Node.js), uv (Python)
- Container: snap, flatpak (Linux)

## Frameworks

**Core:**
- Custom bash module system in `src/core/` with sourced modules
- Data-driven package loading from `data/packages/*.txt`

**Testing:**
- Manual test scripts in `tests/`
- ShellCheck for linting

## Key Dependencies

**System (Required):**
- Git 2.25+ - Version control
- curl or wget - HTTP downloads
- Bash 4.0+ - Script execution

**Installed by Scripts:**
- Modern CLI: bat, eza, fd, ripgrep, zoxide, starship, delta
- Python: uv (package manager)
- Node.js: fnm (version manager)
- AI tools: Claude Code, Gemini CLI, Codex CLI, Ollama

## Platform Requirements

**Linux:** Ubuntu 20.04+, Fedora 36+, Arch (current), Debian 11+
**macOS:** 12+ (Monterey) - requires Bash upgrade from default 3.2
**Windows:** 11 with PowerShell 5.1+ and WinGet

---

*Stack analysis: 2026-02-08*
