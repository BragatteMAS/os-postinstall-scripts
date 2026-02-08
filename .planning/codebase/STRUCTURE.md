# Codebase Structure

**Analysis Date:** 2026-02-08

## Directory Layout

```
os-postinstall-scripts/
├── src/                       # Core source code
│   ├── core/                  # Shared modules (platform-agnostic)
│   │   ├── platform.sh       # OS/distro/arch detection
│   │   ├── logging.sh        # Colored output with auto-detection
│   │   ├── errors.sh         # Failure tracking and cleanup traps
│   │   ├── idempotent.sh     # Guard functions (is_installed, needs_update)
│   │   ├── packages.sh       # Data-driven package loading from txt files
│   │   ├── progress.sh       # Step counter and DRY_RUN banner
│   │   ├── interactive.sh    # User prompts and menu helpers
│   │   └── dotfiles.sh       # Symlink manager with backup system
│   ├── install/               # Tool-specific installers (cross-platform)
│   │   ├── ai-tools.sh       # AI CLI tools (Claude, Gemini, Codex, Ollama)
│   │   ├── rust-cli.sh       # Rust CLI tools via cargo-binstall
│   │   ├── dev-env.sh        # Development environment setup
│   │   ├── fnm.sh            # Fast Node Manager
│   │   └── uv.sh             # Python UV package manager
│   ├── installers/            # Orchestration installers
│   │   └── dotfiles-install.sh  # Dotfiles deployment orchestrator
│   └── platforms/             # Platform-specific implementations
│       ├── linux/
│       │   ├── main.sh       # Linux orchestrator
│       │   ├── post_install.sh  # Post-install configuration
│       │   └── install/      # Package manager handlers
│       │       ├── apt.sh    # APT packages (data-driven)
│       │       ├── cargo.sh  # Cargo packages
│       │       ├── flatpak.sh # Flatpak packages
│       │       └── snap.sh   # Snap packages
│       ├── macos/
│       │   ├── main.sh       # macOS orchestrator
│       │   └── install/      # macOS installers
│       │       ├── homebrew.sh  # Homebrew bootstrap
│       │       ├── brew.sh     # Brew formulae
│       │       └── brew-cask.sh # Brew casks
│       └── windows/
│           ├── main.ps1      # Windows orchestrator (PowerShell)
│           ├── core/         # Windows core modules
│           │   ├── errors.psm1
│           │   ├── logging.psm1
│           │   └── packages.psm1
│           └── install/
│               └── winget.ps1  # WinGet installer
│
├── data/                      # Data files (no logic)
│   ├── packages/              # Package lists (one per line)
│   │   ├── apt.txt, cargo.txt, brew.txt, snap.txt, flatpak.txt
│   │   ├── npm.txt, winget.txt, ai-tools.txt
│   │   ├── apt-post.txt, snap-post.txt, flatpak-post.txt, brew-cask.txt
│   │   └── profiles/         # Profile composition files
│   │       ├── minimal.txt   # References: apt
│   │       ├── developer.txt # References: apt, cargo, npm, brew
│   │       └── full.txt      # References: all package lists
│   └── dotfiles/              # Dotfiles source (symlinked to $HOME)
│       ├── zsh/              # zshrc, plugins.sh, functions.sh
│       ├── bash/             # bashrc
│       ├── git/              # gitconfig, gitignore, gitconfig.local.template
│       ├── shared/           # aliases.sh, env.sh, path.sh (cross-shell)
│       └── starship/         # starship.toml
│
├── examples/                  # Reference configs (snapshots)
│   ├── terminal-setup.sh      # One-script terminal transformation
│   ├── claude-md-example.md   # CLAUDE.md for AI-assisted dev
│   └── starship-example.toml  # Starship prompt config
│
├── docs/                      # User documentation
│   ├── quick-start.md
│   ├── user-guide.md
│   ├── installation-profiles.md
│   ├── modern-cli-tools.md
│   └── troubleshooting.md
│
├── tests/                     # Test scripts
│   ├── test_harness.sh        # Main test runner
│   ├── test-dotfiles.sh       # Dotfiles integration tests
│   └── test-linux.sh          # Linux platform tests
│
├── .planning/                 # GSD planning documents
│   ├── PROJECT.md, ROADMAP.md, STATE.md, REQUIREMENTS.md
│   ├── config.json
│   ├── adrs/                  # Architecture Decision Records (current)
│   ├── codebase/              # Codebase analysis docs
│   ├── research/              # Domain research
│   └── phases/                # Phase plans and summaries (01-08)
│
├── .github/                   # GitHub configuration
│   ├── ISSUE_TEMPLATE/        # Bug report, feature request, config
│   └── pull_request_template.md
│
├── setup.sh                   # Main entry point (Bash)
├── setup.ps1                  # Windows entry point (PowerShell)
├── config.sh                  # User configuration options
├── README.md                  # Project overview
├── CONTRIBUTING.md            # Contribution guidelines
├── CHANGELOG.md               # Version history
├── REQUIREMENTS.md            # System requirements
├── LICENSE                    # MIT License
├── .gitignore
└── .gitattributes
```

## Directory Purposes

**src/core/:**
- Purpose: Platform-agnostic shared modules sourced by all scripts
- Pattern: Each module exports functions; no side effects on source

**src/install/:**
- Purpose: Cross-platform tool installers (not tied to any OS)
- Pattern: Self-contained scripts that source core modules

**src/platforms/:**
- Purpose: OS-specific orchestrators and package manager handlers
- Pattern: Each OS has main.sh orchestrator + install/ subdirectory

**data/packages/:**
- Purpose: Plain text package lists (one package per line, # comments)
- Pattern: Scripts load these via `load_packages()` from packages.sh

**data/dotfiles/:**
- Purpose: Source files symlinked to $HOME by dotfiles.sh
- Pattern: Organized by tool (zsh/, git/, shared/, starship/)

## Key File Locations

**Entry Points:**
- `setup.sh`: Root entry point with --dry-run, --verbose, --unattended flags and positional profile argument
- `setup.ps1`: Windows entry point (PowerShell)
- `src/platforms/<os>/main.sh`: Platform orchestrators

**Core Logic:**
- `src/core/packages.sh`: Data-driven package loading
- `src/core/platform.sh`: OS detection (detect_os, detect_distro, detect_arch)
- `src/core/dotfiles.sh`: Symlink manager with backup

**Configuration:**
- `config.sh`: User-facing configuration options
- `data/packages/profiles/*.txt`: Profile composition (which package lists to use)

## Naming Conventions

**Files:**
- Shell modules: lowercase with hyphens (e.g., `rust-cli.sh`, `brew-cask.sh`)
- Package lists: lowercase with hyphens (e.g., `apt-post.txt`, `ai-tools.txt`)
- Core modules: lowercase single word (e.g., `logging.sh`, `errors.sh`)

**Functions:**
- Core: `detect_os()`, `log_info()`, `is_installed()`, `load_packages()`
- Platform: `install_apt_packages()`, `install_brew_packages()`

## Where to Add New Code

**New package manager:** `src/platforms/<os>/install/newmanager.sh` + `data/packages/newmanager.txt`
**New cross-platform tool:** `src/install/newtool.sh`
**New core utility:** `src/core/newutil.sh`
**New platform:** `src/platforms/<os>/main.sh` + `src/platforms/<os>/install/`

---

*Structure analysis: 2026-02-08*
