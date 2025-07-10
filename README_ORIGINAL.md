# 🚀 Linux Post-Install Scripts & Enhanced Zsh Configuration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

> Comprehensive post-installation scripts and an advanced Zsh configuration optimized for developers, data scientists, and power users.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Zsh Configuration](#zsh-configuration)
- [Post-Install Scripts](#post-install-scripts)
- [Advanced Features](#advanced-features)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This repository contains:
- **Advanced Zsh Configuration**: A feature-rich `.zshrc` file with 1700+ lines of optimizations
- **Linux Post-Install Scripts**: Automated installation scripts for Ubuntu/Pop!_OS/Debian
- **Windows Setup**: PowerShell scripts for Windows 11 using winget
- **Cross-Platform Support**: Works on macOS, Linux, and WSL

## ✨ Features

### Zsh Configuration Highlights

#### 🦀 Rust-Powered Tools
- **bat** - Better `cat` with syntax highlighting
- **eza** - Modern `ls` replacement with icons
- **fd** - Fast and user-friendly `find`
- **ripgrep** - Lightning-fast grep
- **delta** - Beautiful git diffs
- **zoxide** - Smarter `cd` command
- **bottom** - System monitor
- **dust** - Intuitive disk usage
- **sd** - Intuitive find & replace
- **procs** - Modern `ps` replacement

#### 🎨 User Interface
- **Powerlevel10k** theme with instant prompt
- **Custom welcome message** with git branch info
- **Interactive quick menu** (`qm`) for common tasks
- **Comprehensive help system** (`h`, `halp`, `zdoc`)

#### 🔧 Advanced Features
- **Universal package installer** - Auto-detects package manager
- **Configuration backup system** - Automated with rotation
- **Git credential security** - Platform-specific secure storage
- **SSH agent management** - Auto-loads keys
- **Docker/Podman integration** - Simplified container management
- **Lazy loading** - Fast startup with nvm/rbenv
- **Command tracking** - Shows most used commands
- **Feature flags** - Customizable via `.zshrc.flags`

#### 📊 Data Science Tools
- **Conda/Mamba** integration with silent mode
- **Jupyter** shortcuts and notebook utilities
- **Nushell** integration for data analysis
- **CSV analysis** functions
- **Project templates** for scientific computing

## 🚀 Installation

### Quick Install (Zsh Configuration)

```bash
# Clone the repository
git clone https://github.com/BragatteMAS/os-postinstall-scripts.git
cd os-postinstall-scripts

# Backup existing configuration
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null

# Install the new configuration
cp zshrc ~/.zshrc

# Install Oh My Zsh (if not installed)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Reload shell
source ~/.zshrc
```

### Install Recommended Tools

#### macOS (Homebrew)
```bash
brew install fzf eza bat fd ripgrep git-delta nushell tokei zoxide sd dust procs bottom hyperfine lsd gitui
```

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install fzf bat fd-find ripgrep git-delta
cargo install eza nu tokei zoxide sd dust procs bottom
```

#### Arch Linux
```bash
sudo pacman -S fzf bat fd ripgrep git-delta nushell tokei zoxide sd dust procs bottom
```

## 📚 Zsh Configuration

### Directory Structure
```
~
├── .zshrc                 # Main configuration
├── .zshrc.flags          # Feature toggles (optional)
├── .env.local            # Sensitive variables (create from template)
├── .p10k.zsh            # Powerlevel10k config
└── .zshrc_checked       # Dependency check flag
```

### Key Commands

#### 🔍 Help & Discovery
- `h` or `hal` - Essential commands list
- `halp [category]` - Help by category (ls, git, data, search, rust)
- `hfun` - List all custom functions
- `zdoc` - Complete documentation
- `a <term>` - Search aliases
- `cmd <term>` - Search commands

#### 🚀 Quick Actions
- `qm` - Interactive quick menu
- `welcome` - Show welcome message
- `welcomec` - Compact welcome
- `checktools` - Check installed tools
- `bum` - Update system packages

#### 📊 Data Science
- `create_sci_env [name]` - Create conda environment
- `init_project [name]` - Initialize project structure
- `quick_csv <file>` - Quick CSV analysis
- `nu_open <file>` - Open in Nushell
- `explore` - Interactive data explorer

#### 🛠️ System Management
- `install_tool <package>` - Universal installer
- `backup_configs` - Backup configurations
- `shell_benchmark` - Measure startup time
- `setup_git_credentials` - Configure git auth

### Customization

#### Feature Flags
Create `~/.zshrc.flags` to customize:
```bash
ENABLE_WELCOME_MESSAGE=true
ENABLE_COMMAND_TRACKING=true
ENABLE_AUTO_SSH_AGENT=true
ENABLE_LAZY_LOADING=true
ENABLE_QUICK_MENU=true
```

#### Environment Variables
Copy the template and add your secrets:
```bash
cp ~/.env.local.template ~/.env.local
chmod 600 ~/.env.local
```

## 📦 Post-Install Scripts

### Linux Setup

#### Ubuntu/Pop!_OS/Debian
```bash
# Main post-install script
sudo chmod +x post_install.sh
sudo ./post_install.sh

# Individual package managers
sudo ./auto_apt.sh    # APT packages
sudo ./auto_snap.sh   # Snap packages
sudo ./auto_flat.sh   # Flatpak packages
```

### Windows 11 Setup

```powershell
# Run in PowerShell as Administrator
./win11.ps1

# Update all packages
winget upgrade --all
```

### Anaconda Installation

```bash
sudo chmod +x anaconda.sh
sudo ./anaconda.sh
```

## 🌟 Advanced Features

### Section 22 Enhancements

1. **Universal Package Manager** (`install_tool`)
   - Auto-detects: brew, apt, dnf, pacman, zypper, cargo

2. **Git Credential Security** (`setup_git_credentials`)
   - macOS: Keychain
   - Linux: Git Credential Manager
   - WSL: Windows integration

3. **Configuration Backup** (`backup_configs`)
   - Automated backups with timestamps
   - Keeps last 10 versions
   - Includes manifest

4. **WSL Support**
   - Clipboard integration
   - Windows path access
   - Browser integration

5. **Docker/Podman Aliases**
   - `dps` - Pretty container list
   - `dsh <name>` - Shell into container
   - `dclean` - Clean all resources

6. **Performance Optimizations**
   - Lazy loading for nvm/rbenv
   - Conditional Oh My Zsh plugins
   - Minimal startup overhead

## 📝 Documentation

- **[CHANGELOG.md](CHANGELOG.md)** - Version history (dynamically generated)
- **[MIGRATION.md](MIGRATION.md)** - Guide for upgrading from older versions
- **[AI_REPOSITORY_TEMPLATE.md](AI_REPOSITORY_TEMPLATE.md)** - AI-assisted development guide

### Dynamic Changelog

The CHANGELOG.md is generated from a template with proper dates:
```bash
# Method 1: Using make (recommended)
make changelog

# Method 2: Using the script
bash .ai/scripts/update-changelog-dates.sh

# Method 3: Using generate script (creates new CHANGELOG)
bash .ai/scripts/generate-changelog-date.sh

# Method 4: Direct sed command
sed "s/\${RELEASE_DATE}/$(date +%Y-%m-%d)/g; s/\${INITIAL_DATE}/$(git log --reverse --format='%Y-%m-%d' | head -1)/g" CHANGELOG.template.md > CHANGELOG.md
```

### Dependency and License Management

Automated tools for IP protection and compliance:
```bash
# Generate all dependency documentation
make all-docs

# Individual commands:
make requirements  # Generate requirements files
make licenses     # Analyze all licenses
make monitor-deps # Monitor for changes
make ip-docs      # Create IP documentation package
```

Features:
- 📦 Multi-language requirements detection
- ⚖️ License compatibility analysis
- 🔍 Security vulnerability scanning
- 📋 IP-ready documentation generation

See [.ai/DEPENDENCY-MANAGEMENT.md](.ai/DEPENDENCY-MANAGEMENT.md) for details.

## 📊 Documentation Flow

```
┌─────────────┐
│   START     │
└──────┬──────┘
       │
       ▼
┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│ First Time?  │ YES │   make setup    │     │ Choose Type  │
│              ├────▶│ (initial config)├────▶│              │
└──────┬───────┘     └─────────────────┘     └───────┬──────┘
       │ NO                                           │
       └──────────────────────────────────────────────┘
                                                      │
        ┌─────────────┬──────────────┬────────────────┼────────────────┬──────────────┐
        ▼             ▼              ▼                ▼                ▼              ▼
┌───────────┐ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐
│    AI     │ │ Dependencies │ │  Changelog  │ │  IP/Patent  │ │ Monitor     │ │    ALL     │
│ Context   │ │              │ │             │ │    Docs     │ │  Changes    │ │   DOCS     │
└─────┬─────┘ └──────┬───────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └─────┬──────┘
      │              │                 │               │               │               │
      ▼              ▼                 ▼               ▼               ▼               ▼
┌───────────┐ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐
│  Choose:  │ │    make      │ │    make     │ │    make     │ │    make     │ │   make     │
│ • Claude  │ │ requirements │ │  changelog  │ │   ip-docs   │ │monitor-deps │ │  all-docs  │
│ • Copilot │ └──────┬───────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └────────────┘
│ • Cursor  │        │                 │               │               │
│ • ChatGPT │        ▼                 ▼               ▼               ▼
│ • Gemini  │ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ • Generic │ │    make      │ │ CHANGELOG.md│ │ .ai/ip-docs │ │  Alerts &   │
└─────┬─────┘ │  licenses    │ │  generated  │ │  package    │ │  Reports    │
      │       └──────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
      ▼
┌───────────┐
│.ai/ files │
│ created   │
└───────────┘
```

### Quick Commands by Use Case

| Use Case | Command | Output |
|----------|---------|--------|
| 🤖 **AI Development** | `npx create-ai-context` | `.ai/` folder with context files |
| 📦 **Track Dependencies** | `make requirements` | `requirements/` with all deps |
| ⚖️ **Check Licenses** | `make licenses` | `licenses/` with analysis |
| 📝 **Update Changelog** | `make changelog` | `CHANGELOG.md` with dates |
| 🛡️ **IP Documentation** | `make ip-docs` | `.ai/ip-documentation-*.tar.gz` |
| 📊 **Everything** | `make all-docs` | All of the above |

### Supported Models & Languages

<details>
<summary><b>🤖 AI Assistants</b></summary>

- **Claude** → `.ai/CLAUDE.md`
- **GitHub Copilot** → `.github/copilot-instructions.md`
- **Cursor** → `.cursorrules`
- **ChatGPT** → `.ai/OPENAI_CODEX.md`
- **Gemini** → `.ai/GEMINI_CONTEXT.md`
- **Others** → `.ai/AI_ASSISTANT.md`

</details>

<details>
<summary><b>💻 Programming Languages</b></summary>

- **Python** → `requirements.txt`, `Pipfile`
- **Node.js** → `package.json`
- **Rust** → `Cargo.toml`
- **Go** → `go.mod`
- **Ruby** → `Gemfile`
- **PHP** → `composer.json`
- **Java** → `pom.xml`, `build.gradle`

</details>

See [.ai/DOCUMENTATION-FLOW.md](.ai/DOCUMENTATION-FLOW.md) for detailed workflow guide.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Diolinux](https://www.youtube.com/watch?v=vBfj5dNZOSA&t=8s) - Initial inspiration
- [Oh My Zsh](https://ohmyz.sh/) - Framework foundation
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Amazing prompt
- All the amazing Rust tool developers

## 📊 Stats

- **Lines of Code**: 1700+ in `.zshrc`
- **Custom Functions**: 30+
- **Aliases**: 100+
- **Supported Platforms**: macOS, Linux, WSL
- **Package Managers**: 6 (brew, apt, dnf, pacman, zypper, cargo)

---

Made with ❤️ by [@BragatteMAS](https://github.com/BragatteMAS)