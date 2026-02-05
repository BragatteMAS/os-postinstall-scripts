# Architecture Patterns

**Domain:** Cross-platform post-install scripts / dotfiles management
**Researched:** 2026-02-04
**Confidence:** HIGH (patterns verified with multiple authoritative sources)

## Recommended Architecture

The target architecture separates **code** (src/), **data** (data/), and **documentation** (docs/) following industry-standard patterns from dotfiles managers and shell script best practices.

```
os-postinstall-scripts/
├── src/
│   ├── core/           # Platform-agnostic shared code
│   │   ├── bootstrap.sh      # Single entry point
│   │   ├── config-loader.sh  # YAML parsing + config management
│   │   ├── logging.sh        # Logging utilities
│   │   ├── platform.sh       # Platform detection
│   │   └── utils.sh          # Common utilities
│   ├── unix/           # macOS + Linux shared code
│   │   ├── brew.sh           # Homebrew operations
│   │   ├── shell-setup.sh    # Shell configuration
│   │   └── packages.sh       # Package installation abstraction
│   ├── linux/          # Linux-specific code
│   │   ├── apt.sh            # APT package manager
│   │   ├── dnf.sh            # DNF/YUM package manager
│   │   ├── pacman.sh         # Pacman/AUR
│   │   ├── flatpak.sh        # Flatpak operations
│   │   └── snap.sh           # Snap operations
│   ├── macos/          # macOS-specific code
│   │   ├── defaults.sh       # System preferences
│   │   └── cask.sh           # Homebrew Cask apps
│   └── windows/        # Windows-specific code
│       └── winget.ps1        # WinGet/Chocolatey
├── data/
│   ├── packages/       # Package lists (declarative)
│   │   ├── core.yaml         # Essential packages
│   │   ├── dev-tools.yaml    # Development tools
│   │   ├── rust-cli.yaml     # Rust CLI replacements
│   │   └── ai-tools.yaml     # AI development tools
│   ├── dotfiles/       # Configuration files
│   │   ├── zsh/              # Zsh configuration
│   │   ├── git/              # Git configuration
│   │   └── shell/            # Shell aliases/functions
│   └── profiles/       # Installation profiles
│       ├── minimal.yaml
│       ├── standard.yaml
│       └── full.yaml
├── docs/               # Documentation
│   ├── USAGE.md
│   ├── PROFILES.md
│   └── CONTRIBUTING.md
└── install.sh          # One-liner entry point
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `src/core/bootstrap.sh` | Entry point, orchestration | All src/ modules |
| `src/core/config-loader.sh` | Parse YAML configs, validate | bootstrap.sh, all installers |
| `src/core/platform.sh` | OS/distro detection | bootstrap.sh |
| `src/core/logging.sh` | Consistent output formatting | All modules |
| `src/unix/packages.sh` | Abstract package operations | Platform-specific installers |
| `src/linux/*.sh` | Linux package managers | packages.sh |
| `src/macos/*.sh` | macOS-specific operations | packages.sh, brew.sh |
| `src/windows/*.ps1` | Windows operations | N/A (separate entry point) |
| `data/packages/*.yaml` | Declarative package lists | config-loader.sh |
| `data/profiles/*.yaml` | Installation presets | config-loader.sh |
| `data/dotfiles/*` | Configuration templates | shell-setup.sh |

### Data Flow

```
User runs: ./install.sh [--profile=standard]
                │
                ▼
        ┌───────────────────┐
        │  src/core/        │
        │  bootstrap.sh     │
        └─────────┬─────────┘
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
platform.sh  config-loader.sh  logging.sh
    │             │
    │    ┌────────┴────────┐
    │    ▼                 ▼
    │  data/profiles/    data/packages/
    │  standard.yaml     *.yaml
    │             │
    └──────┬──────┘
           │
           ▼
  ┌─────────────────────────────┐
  │  Platform Router            │
  │  (detects: macos/linux/win) │
  └────────────┬────────────────┘
               │
   ┌───────────┼───────────┐
   ▼           ▼           ▼
src/macos/  src/linux/  src/windows/
   │           │           │
   ▼           ▼           ▼
brew.sh    apt.sh      winget.ps1
           dnf.sh
           pacman.sh
               │
               ▼
        ┌─────────────────┐
        │  src/unix/      │
        │  shell-setup.sh │
        └────────┬────────┘
                 │
                 ▼
           data/dotfiles/
```

## Patterns to Follow

### Pattern 1: Topic-Centric Organization (Holman Style)

**What:** Group related functionality by topic (git, shell, rust-tools) rather than by file type.

**When:** For dotfiles in `data/dotfiles/` directory.

**Example:**
```
data/dotfiles/
├── git/
│   ├── gitconfig.symlink     # Symlinked to ~/.gitconfig
│   ├── gitignore.symlink     # Symlinked to ~/.gitignore
│   └── install.sh            # Git-specific setup
├── zsh/
│   ├── zshrc.symlink
│   ├── path.zsh              # Loaded first ($PATH setup)
│   ├── aliases.zsh           # Loaded automatically
│   └── completion.zsh        # Loaded last
└── rust/
    └── aliases.zsh           # bat, eza aliases
```

**File Extension Convention:**

| Extension | Behavior |
|-----------|----------|
| `.symlink` | Symlinked to `$HOME` without extension |
| `.zsh` | Auto-sourced by shell setup |
| `path.zsh` | Loaded first (PATH modifications) |
| `completion.zsh` | Loaded last (completions) |
| `install.sh` | Run during bootstrap |

**Source:** [Holman Dotfiles](https://github.com/holman/dotfiles)

### Pattern 2: Data-Driven Package Lists

**What:** Separate package declarations (YAML) from installation logic (shell scripts).

**When:** Always. This is the core architectural principle.

**Example:**
```yaml
# data/packages/rust-cli.yaml
name: rust-cli-tools
description: Modern Rust-based CLI replacements
install_via:
  cargo: true
  brew: true  # Fallback on macOS

packages:
  - name: bat
    cargo: bat
    brew: bat
    description: Better cat with syntax highlighting

  - name: eza
    cargo: eza
    brew: eza
    description: Better ls with colors and icons

  - name: fd
    cargo: fd-find
    brew: fd
    description: Better find, user-friendly

  - name: ripgrep
    cargo: ripgrep
    brew: ripgrep
    aliases:
      - rg
    description: Better grep, blazingly fast
```

**Benefits:**
- Package lists are human-readable and editable
- Logic for installation is separate and reusable
- Easy to add/remove packages without touching code
- Profiles can reference package files

### Pattern 3: Platform Abstraction Layer

**What:** Abstract package operations behind a common interface, with platform-specific implementations.

**When:** For any cross-platform package installation.

**Example:**
```bash
# src/unix/packages.sh

# Detect and set package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        source "$SRC_DIR/linux/apt.sh"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        source "$SRC_DIR/linux/dnf.sh"
    elif command -v brew &>/dev/null; then
        PKG_MANAGER="brew"
        source "$SRC_DIR/unix/brew.sh"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        source "$SRC_DIR/linux/pacman.sh"
    fi
}

# Common interface
pkg_install() {
    local package="$1"
    case "$PKG_MANAGER" in
        apt) apt_install "$package" ;;
        dnf) dnf_install "$package" ;;
        brew) brew_install "$package" ;;
        pacman) pacman_install "$package" ;;
    esac
}

pkg_update() {
    case "$PKG_MANAGER" in
        apt) apt_update ;;
        dnf) dnf_update ;;
        brew) brew_update ;;
        pacman) pacman_update ;;
    esac
}
```

### Pattern 4: Main Function Pattern (Google Shell Style)

**What:** Wrap executable logic in a `main()` function, declare variables as local.

**When:** For any script > 50 lines.

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/install.log"

# Source dependencies
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/platform.sh"

# Functions
install_packages() {
    local profile="$1"
    local packages
    packages=$(get_packages_for_profile "$profile")
    # ...
}

# Main function
main() {
    local profile="${1:-standard}"

    log "Starting installation with profile: $profile"
    detect_platform
    install_packages "$profile"
    log_success "Installation complete"
}

# Entry point
main "$@"
```

**Source:** [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Pattern 5: Graceful Degradation

**What:** Configuration should work even when optional tools are missing.

**When:** Always for dotfiles and optional feature detection.

**Example:**
```bash
# data/dotfiles/zsh/aliases.zsh

# Use modern tools if available, fallback to defaults
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -la --icons'
    alias tree='eza --tree'
else
    alias ll='ls -la'
fi

if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hardcoded Package Lists in Scripts

**What:** Embedding package names directly in installation scripts.

**Why bad:**
- Changes require code edits
- Difficult to maintain multiple profiles
- No separation of concerns

**Instead:** Use YAML package lists in `data/packages/`, reference from scripts.

**Current project has this issue in:** `platforms/linux/install/apt.sh` with `APT_INSTALL` array.

### Anti-Pattern 2: Duplicated Platform Detection

**What:** Each script implementing its own OS detection.

**Why bad:**
- Inconsistent detection logic
- Maintenance burden
- Bugs in one place don't get fixed everywhere

**Instead:** Single `src/core/platform.sh` module sourced by all scripts.

**Current project has this issue in:** `scripts/setup/main.sh` has inline `detect_system()`.

### Anti-Pattern 3: Relative Path Gymnastics

**What:** Using complex relative paths like `../../../scripts/utils/`.

**Why bad:**
- Breaks when scripts are moved
- Hard to understand
- Error-prone

**Instead:**
```bash
# At script start, establish absolute paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SRC_DIR="$ROOT_DIR/src"
readonly DATA_DIR="$ROOT_DIR/data"
```

### Anti-Pattern 4: Scripts > 100 Lines Without Functions

**What:** Long procedural scripts without modularization.

**Why bad:**
- Hard to test individual parts
- Difficult to maintain
- No code reuse

**Instead:**
- Extract functions
- Source shared utilities
- Consider splitting into multiple files

**Reference:** Google Shell Style Guide recommends rewriting scripts > 100 lines in a structured language.

### Anti-Pattern 5: Platform-Specific Code in Core

**What:** Putting macOS-only or Linux-only logic in shared scripts.

**Why bad:**
- Core becomes platform-aware (coupling)
- Harder to add new platforms
- Testing becomes complex

**Instead:** Platform router pattern:
```bash
# src/core/bootstrap.sh
source "$SRC_DIR/core/platform.sh"

case "$PLATFORM" in
    macos)  source "$SRC_DIR/macos/setup.sh" ;;
    linux)  source "$SRC_DIR/linux/setup.sh" ;;
    windows)
        log_error "Run windows/install.ps1 for Windows"
        exit 1
        ;;
esac
```

## Scalability Considerations

| Concern | Current (brownfield) | Target (greenfield) | Rationale |
|---------|---------------------|---------------------|-----------|
| Adding packages | Edit shell arrays | Add to YAML | Data-driven is maintainable |
| New platform | Copy scripts, modify | Add new `src/platform/` dir | Modular, isolated |
| New profile | Duplicate and modify | Reference package files | Composition over duplication |
| Testing | Manual | Automated with shellcheck, bats | Scripts in functions = testable |
| Dotfile sync | Copy/paste | Symlink manager | Consistent, traceable |

## Suggested Build Order (Dependencies)

Based on component dependencies, migration should follow this order:

### Phase 1: Core Foundation
1. `src/core/logging.sh` - No dependencies, used everywhere
2. `src/core/platform.sh` - Depends only on logging
3. `src/core/config-loader.sh` - Depends on logging

**Rationale:** These are leaf nodes with no dependencies but everything depends on them.

### Phase 2: Data Layer
1. `data/packages/core.yaml` - Package declarations
2. `data/packages/rust-cli.yaml` - Rust tools list
3. `data/profiles/` - Reference package files

**Rationale:** Data can be defined before code that consumes it.

### Phase 3: Platform-Specific Code
1. `src/unix/packages.sh` - Abstraction layer
2. `src/linux/apt.sh` - APT-specific (most common)
3. `src/macos/brew.sh` - Homebrew-specific
4. Other package managers as needed

**Rationale:** Depends on core + data, but independent of each other.

### Phase 4: Dotfiles System
1. `data/dotfiles/` structure with `.symlink` convention
2. `src/unix/shell-setup.sh` - Symlink manager
3. Topic directories (git, zsh, rust)

**Rationale:** Optional enhancement, depends on shell being configured.

### Phase 5: Bootstrap & Integration
1. `src/core/bootstrap.sh` - Ties everything together
2. `install.sh` - One-liner entry point
3. Profile integration

**Rationale:** Orchestration layer that depends on all components.

## Comparison: Current vs Target

| Aspect | Current Structure | Target Structure |
|--------|------------------|------------------|
| Entry points | Multiple (main.sh, post_install.sh) | Single (install.sh -> bootstrap.sh) |
| Package lists | In shell arrays | YAML in data/packages/ |
| Platform code | scripts/ + platforms/ (overlap) | src/{core,unix,linux,macos,windows}/ |
| Dotfiles | Scattered, copy-based | data/dotfiles/ with symlinks |
| Profiles | configs/profiles/ (good) | data/profiles/ (consolidate) |
| Utils | scripts/utils/ | src/core/ |

## Sources

- [Holman Dotfiles - Topic Organization](https://github.com/holman/dotfiles)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [chezmoi Comparison Table](https://www.chezmoi.io/comparison-table/)
- [Atlassian Bare Git Dotfiles](https://www.atlassian.com/git/tutorials/dotfiles)
- [GitHub Dotfiles Guide](https://dotfiles.github.io/)
- [Effective Shell - Managing Dotfiles](https://effective-shell.com/part-5-building-your-toolkit/managing-your-dotfiles/)
- [YADM Architecture](https://yadm.io/)
- [Arch Wiki - Dotfiles](https://wiki.archlinux.org/title/Dotfiles)
