# Technology Stack

**Project:** OS Post-Install Scripts
**Researched:** 2026-02-04
**Confidence:** HIGH (verified with official documentation and multiple sources)

## Executive Summary

For cross-platform post-install scripts and dotfiles management in 2025-2026, the **pure shell approach** (Bash + PowerShell) remains the optimal choice when zero external dependencies is a constraint. This stack leverages native OS capabilities, avoids bootstrap problems, and aligns with the project's KISS/FAIR principles.

**Key recommendation:** Keep the native shell approach. Do NOT adopt dotfiles managers (chezmoi, stow) as they introduce dependencies that conflict with the "run on fresh machine" requirement.

---

## Recommended Stack

### Core Scripting Languages

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Bash | 4.0+ | Unix scripting (Linux, macOS) | Native on Linux, upgradeable on macOS. Associative arrays, better string handling |
| Zsh | 5.8+ | Alternative Unix shell | Native on macOS since Catalina, good Bash compatibility |
| PowerShell | 5.1+ / 7.x | Windows scripting | Native on Windows, PowerShell 7 adds cross-platform but 5.1 sufficient for Windows-only |

**Rationale:** Native shells require zero bootstrap. A fresh OS can run scripts immediately without installing anything first.

### Package Managers (per platform)

| Platform | Manager | Version | Purpose | Why |
|----------|---------|---------|---------|-----|
| macOS | Homebrew | Latest | Package installation | De facto standard, excellent ecosystem |
| Linux (Debian/Ubuntu) | APT | System | Package installation | Native, stable, well-documented |
| Linux (Fedora/RHEL) | DNF | System | Package installation | Native replacement for yum |
| Linux (Arch) | Pacman | System | Package installation | Native, fast |
| Linux (universal) | Snap | System | Sandboxed apps | Canonical-backed, cross-distro |
| Linux (universal) | Flatpak | System | Sandboxed apps | DE-agnostic, growing ecosystem |
| Windows | winget | 1.6+ | Package installation | Native since Win11, available on Win10, Server 2025 |

### Development Tools

| Tool | Purpose | When to Install |
|------|---------|-----------------|
| shellcheck | Static analysis for shell scripts | Development only |
| shfmt | Shell script formatter | Development only |
| bat | Modern cat replacement | User preference |
| eza | Modern ls replacement | User preference |
| fd | Modern find replacement | User preference |
| ripgrep | Modern grep replacement | User preference |
| zoxide | Smart cd replacement | User preference |

### Quality Assurance

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| ShellCheck | 0.9+ | Bash/sh linting | Industry standard, catches common bugs |
| shfmt | 3.7+ | Shell formatting | Consistent style, CI integration |
| bats-core | 1.10+ | Bash testing | Simple, native bash testing framework |

---

## Architecture Decisions

### Decision 1: Native Shell over Cross-Platform Tools

**Choose:** Bash (Unix) + PowerShell (Windows) with platform detection

**NOT:** Python, Ansible, chezmoi, or other tools requiring pre-installation

**Rationale:**
- Zero bootstrap problem: scripts run on fresh OS
- No dependency hell: nothing to install first
- Native performance: shell is optimized for system calls
- Simpler maintenance: familiar tooling for sysadmins

### Decision 2: Bash 4+ Minimum (not POSIX sh)

**Choose:** Bash 4.0+ with `#!/usr/bin/env bash`

**NOT:** POSIX sh for maximum compatibility

**Rationale:**
- Bash 4 features (associative arrays, `${var,,}` case conversion) significantly simplify code
- Bash is available on all target platforms (Linux native, macOS upgradeable, Windows via Git Bash/WSL)
- POSIX sh would require ~30% more code for equivalent functionality
- Project explicitly requires Bash 4+ (see REQUIREMENTS.md)

**Trade-off:** macOS ships with Bash 3.2. Users must upgrade via Homebrew or use the provided upgrade script.

### Decision 3: No External Parsers

**Choose:** Shell arrays in `.sh` files + plain `.txt` lists

**NOT:** JSON/YAML/TOML with jq/yq parsers

**Rationale:**
- jq is not pre-installed on any major OS
- Parsing in pure bash is verbose but eliminates dependencies
- Arrays in shell are native and fast
- Configuration complexity doesn't warrant structured data

**Example pattern:**
```bash
# data/packages/cli-tools.sh
CLI_TOOLS=(
    "bat"
    "eza"
    "fd"
    "ripgrep"
    "zoxide"
)
```

### Decision 4: Platform Separation over Abstraction

**Choose:** Separate implementations per platform with shared utilities

**NOT:** Single abstraction layer trying to unify all platforms

**Rationale:**
- Package managers have fundamentally different APIs
- Path conventions differ (Windows: `C:\`, Unix: `/`)
- Shell syntax differs (Bash vs PowerShell)
- Attempting full abstraction creates more complexity than it solves
- "Functional equivalence" is more maintainable than "identical code"

---

## Alternatives Considered

### Dotfiles Managers

| Tool | Stars | Why NOT for this project |
|------|-------|--------------------------|
| chezmoi | 17.7k | Requires binary installation before use. Excellent for personal dotfiles, wrong for "fresh OS setup" |
| GNU Stow | N/A | Unix-only, requires installation, symlink-based (not copy) |
| yadm | 5k | Requires git + yadm installation first |
| dotbot | 7k | Requires Python + git first |

**Verdict:** These tools solve a different problem (personal dotfiles sync) than this project (fresh machine automation).

### Cross-Platform Languages

| Language | Why NOT |
|----------|---------|
| Python | Not pre-installed on Windows, version conflicts on Linux/macOS |
| Ansible | Requires Python, YAML files, overkill for personal use |
| Rust (via installer) | Requires Rust toolchain first |
| PowerShell Core (everywhere) | Alien on Linux/macOS, non-idiomatic |

### Configuration Formats

| Format | Why NOT |
|--------|---------|
| JSON | Requires jq parser |
| YAML | Requires yq parser |
| TOML | Requires toml parser |
| INI | Bash parsing is fragile |

**Verdict:** Shell arrays and plain text files are the only zero-dependency option.

---

## Installation / Bootstrap

### Unix (macOS / Linux)

```bash
# Clone and run - no pre-installation needed
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts
./setup.sh
```

**macOS Note:** If Bash 4+ not available:
```bash
./scripts/setup/upgrade-bash.sh  # Installs Homebrew + Bash 5
```

### Windows

```powershell
# PowerShell as Administrator
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts
.\setup.ps1
```

**Note:** winget is pre-installed on Windows 11 and Windows Server 2025. For Windows 10, may need App Installer from Microsoft Store.

---

## Development Setup

### Required for Contributors

```bash
# Install development tools (on your dev machine only)
# macOS
brew install shellcheck shfmt

# Linux (Debian/Ubuntu)
sudo apt install shellcheck
# shfmt via Go: go install mvdan.cc/sh/v3/cmd/shfmt@latest

# Run linting
shellcheck scripts/**/*.sh
shfmt -d scripts/
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck
  - repo: https://github.com/scop/pre-commit-shfmt
    rev: v3.7.0-4
    hooks:
      - id: shfmt
```

### VS Code Extensions

| Extension | Purpose |
|-----------|---------|
| shellcheck | Inline linting |
| shell-format | Auto-formatting (uses shfmt) |
| Bash IDE | Syntax highlighting, completion |

---

## Version Matrix

### Minimum Supported Versions

| Component | Minimum | Reason |
|-----------|---------|--------|
| Bash | 4.0 | Associative arrays, modern features |
| Zsh | 5.0 | Adequate for Oh-My-Zsh |
| PowerShell | 5.1 | Ships with Windows 10+ |
| Git | 2.25 | Modern defaults, init.defaultBranch |
| macOS | 10.15 (Catalina) | Zsh default, still supported |
| Ubuntu | 20.04 LTS | Bash 5.0, long-term support |
| Windows | 10 (1903+) | winget availability |

### Tested Configurations

| OS | Shell | Package Manager | Status |
|----|-------|-----------------|--------|
| Ubuntu 22.04/24.04 | Bash 5.1 | APT + Snap | 100% |
| Pop!_OS 22.04 | Bash 5.1 | APT + Flatpak | 100% |
| Fedora 39/40 | Bash 5.2 | DNF + Flatpak | 90% |
| Arch Linux | Bash 5.2 | Pacman + AUR | 80% |
| macOS 14 (Sonoma) | Zsh 5.9 / Bash 5.2 | Homebrew | 20% |
| Windows 11 | PowerShell 5.1 | winget | 80% |

---

## Anti-Patterns to Avoid

### 1. DO NOT use `curl | bash` as primary flow

**Why:** Security risk, no code inspection, network dependency during execution

**Instead:** `git clone` + explicit `./setup.sh`

### 2. DO NOT require jq for configuration

**Why:** Not pre-installed anywhere

**Instead:** Shell arrays in `.sh` files

### 3. DO NOT use Bash 3 syntax for macOS compatibility

**Why:** Severely limits code quality, associative arrays are essential

**Instead:** Require Bash 4+, provide upgrade script for macOS

### 4. DO NOT create monolithic scripts

**Why:** Unmaintainable, hard to test, hard to customize

**Instead:** Modular architecture with clear boundaries:
```
src/core/     # Shared utilities (logging, detection)
src/unix/     # macOS + Linux specific
src/windows/  # PowerShell specific
data/         # Package lists (separate from logic)
```

### 5. DO NOT hard-code paths

**Why:** Breaks across platforms, breaks when user changes install location

**Instead:** Use `$HOME`, `$XDG_CONFIG_HOME`, environment detection

---

## Sources

### Official Documentation
- [Homebrew Installation](https://docs.brew.sh/Installation) - NONINTERACTIVE mode for automation
- [ShellCheck](https://www.shellcheck.net/) - Static analysis documentation
- [Microsoft WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/) - Official winget guide

### Best Practices Guides
- [Microsoft Engineering Playbook - Bash Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/bash/) - shellcheck/shfmt CI integration
- [GitLab Shell Scripting Standards](https://docs.gitlab.com/development/shell_scripting_guide/) - Enterprise shell guidelines
- [Safer Bash Scripts with set -euxo pipefail](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/) - Error handling patterns

### Tool Comparisons
- [chezmoi - Why Use chezmoi](https://www.chezmoi.io/why-use-chezmoi/) - When dotfiles managers make sense
- [chezmoi Comparison Table](https://www.chezmoi.io/comparison-table/) - Feature comparison of dotfiles tools
- [dotfiles.github.io/utilities](https://dotfiles.github.io/utilities/) - Comprehensive dotfiles tool list

### Community Discussions
- [FreeBSD Forums - POSIX in 2025](https://forums.freebsd.org/threads/in-2025-do-you-still-need-to-follow-the-posix-standard-in-shell-scripts-what-is-your-shell-for-scripting.99220/) - POSIX vs Bash tradeoffs
- [Modular Bash Architecture Guide](https://medium.com/mkdir-awesome/the-ultimate-guide-to-modularizing-bash-script-code-f4a4d53000c2) - Project structure patterns

---

## Confidence Assessment

| Recommendation | Confidence | Reason |
|----------------|------------|--------|
| Bash 4+ for Unix | HIGH | Official docs, widespread adoption, project already uses |
| PowerShell 5.1+ for Windows | HIGH | Native, official Microsoft docs |
| No external parsers | HIGH | Verified jq not pre-installed on any target OS |
| shellcheck + shfmt | HIGH | Microsoft, GitLab, community consensus |
| No dotfiles managers | MEDIUM | Correct for "fresh machine" use case; would be wrong for personal dotfiles sync |
| Modular architecture | HIGH | Multiple guides, existing codebase direction |

---

*Last updated: 2026-02-04*
