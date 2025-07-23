# 🚀 OS Post-Install Scripts & Enhanced Shell Configuration

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Shell-Bash/Zsh-green.svg)](https://www.zsh.org/)
[![Linux](https://img.shields.io/badge/OS-Linux-yellow.svg)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/OS-Windows-blue.svg)](https://www.microsoft.com/windows)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![BMad Method Enhanced](https://img.shields.io/badge/AI--Assisted-BMad%20Method-purple.svg)](.ai/README.md)

> Comprehensive post-installation automation scripts with advanced shell configurations for developers, data scientists, and power users across multiple operating systems.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Zsh Configuration](#zsh-configuration)
- [Post-Install Scripts](#post-install-scripts)
- [Advanced Features](#advanced-features)
- [Project Structure](#project-structure)
- [Customization](#customization)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [License](#license)

## 🎯 Overview

This repository provides a complete solution for system setup automation:

- **🐧 Linux Post-Install Scripts**: Automated installation for Ubuntu, Pop!_OS, Linux Mint, and Debian-based distributions
- **🎨 Advanced Zsh Configuration**: Feature-rich `.zshrc` with 1700+ lines of optimizations and Rust-powered tools
- **🪟 Windows Setup**: PowerShell scripts for Windows 11 using winget
- **🤖 AI-Assisted Development**: Enhanced with BMad Method for better documentation and contributions
- **🔧 Cross-Platform Support**: Works on macOS, Linux, WSL, and Windows

## ✨ Features

### Shell Configuration Highlights

#### 🦀 Rust-Powered Modern CLI Tools
- **bat** - Better `cat` with syntax highlighting
- **eza** - Modern `ls` replacement with icons
- **fd** - Fast and user-friendly `find`
- **ripgrep** - Lightning-fast grep
- **delta** - Beautiful git diffs
- **zoxide** - Smarter `cd` command
- **bottom** - System monitor
- **dust** - Intuitive disk usage
- **sd** - Intuitive find & replace (aliased as `sdr`)
- **procs** - Modern `ps` replacement

#### 🎨 User Interface
- **Powerlevel10k** theme with instant prompt
- **Custom welcome message** with git branch info
- **Interactive quick menu** (`qm`) for common tasks
- **Comprehensive help system** (`h`, `halp`, `zdoc`)
- **Adaptive themes** based on system preferences

#### 🔧 Advanced Shell Features
- **Universal package manager** function (`install_tool`)
- **Git credential security** setup
- **Configuration backup system** with rotation
- **WSL (Windows Subsystem for Linux)** full support
- **Docker/Podman integration** with custom aliases
- **Performance monitoring** (`shell_benchmark`)
- **Secure environment variables** from `.env.local`
- **Lazy loading** for nvm and rbenv
- **Automatic SSH agent** management
- **Feature flags** support via `.zshrc.flags`

### Post-Installation Automation

#### 📦 Software Categories
- **Development Tools**: Git, VS Code, Docker, multiple programming languages
- **System Tools**: Synaptic, Neofetch, Stacer, Timeshift, VirtualBox
- **Terminal Emulators**: Alacritty (GPU-enhanced), Terminator
- **Productivity**: Office suites, note-taking apps, communication tools
- **Multimedia**: Video/audio editors, screen recorders, media players
- **Security**: Firewall (gufw), VPN tools, SSH server
- **Gaming**: Lutris, Wine, Steam, gaming peripherals support

#### 🚀 Installation Methods
- **APT**: Native Debian/Ubuntu packages
- **Flatpak**: Sandboxed applications from Flathub
- **Snap**: Universal Linux packages
- **Direct Downloads**: .deb files from vendors
- **Winget**: Windows Package Manager for Windows 11

## 🚀 Quick Start

### Linux Installation

```bash
# Clone the repository
git clone https://github.com/BragatteMAS/Linux_posintall_script
cd Linux_posintall_script

# For post-installation script
cd linux
chmod +x post_install.sh
sudo ./post_install.sh

# For Zsh configuration only
cp zshrc ~/.zshrc
source ~/.zshrc
```

### Windows Installation

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\windows\win11.ps1
```

### Zsh Configuration Only

```bash
# Quick install (backs up existing .zshrc)
curl -fsSL https://raw.githubusercontent.com/BragatteMAS/Linux_posintall_script/main/zshrc > ~/.zshrc.new
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup
mv ~/.zshrc.new ~/.zshrc
source ~/.zshrc
```

## 🐚 Zsh Configuration

### Key Commands

| Command | Description |
|---------|-------------|
| `qm` | Interactive quick menu for common tasks |
| `h` or `halp` | Show categorized help |
| `zdoc` | Complete function documentation |
| `ac rust` | List all Rust-powered tools |
| `backup_configs` | Backup shell configurations |
| `shell_benchmark` | Test shell performance |
| `welcomec` | Compact welcome message |

### Configuration Files

- `.zshrc` - Main configuration (1700+ lines)
- `.zshrc.local` - Local customizations (git-ignored)
- `.env.local` - Secure environment variables
- `.zshrc.flags` - Feature flags

## 📁 Project Structure

```
Linux_posintall_script/
├── .ai/                    # AI context (BMad Method)
│   ├── README.md          # Project overview for AI
│   ├── conventions/       # Coding standards
│   ├── patterns/         # Implementation patterns
│   └── context/          # Technical details
├── linux/                 # Linux scripts
│   ├── auto/             # Modular installers
│   │   ├── auto_apt.sh   # APT packages
│   │   ├── auto_flat.sh  # Flatpak apps
│   │   └── auto_snap.sh  # Snap packages
│   ├── bash/             # Bash configs
│   ├── distros/          # Distribution-specific
│   └── post_install.sh   # Main script
├── windows/              # Windows scripts
│   └── win11.ps1        # Windows 11 setup
├── mac/                  # macOS (future)
├── zshrc                 # Advanced Zsh config
├── zshrc-prd.md         # Zsh documentation
└── zshrc_rust_integration.zsh # Rust tools config
```

## 🛠️ Customization

### Adding Software

Edit package arrays in the respective files:

```bash
# Linux: linux/auto/auto_apt.sh
APT_INSTALL=(
    "your-package"
    # ... more packages
)

# Windows: windows/win11.ps1
$packages = @(
    "Your.Package"
    # ... more packages
)
```

### Shell Customization

Create `.zshrc.local` for personal settings:

```bash
# ~/.zshrc.local
export MY_CUSTOM_VAR="value"
alias myalias="my command"
```

## 🤝 Contributing

We welcome contributions! This project uses the BMad Method for AI-assisted development.

1. Check `.ai/conventions/CONVENTIONS.md` for coding standards
2. Review `.ai/patterns/PATTERNS.md` for common patterns
3. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
4. Join discussions in [Issues](https://github.com/BragatteMAS/Linux_posintall_script/issues)

## 🔄 Roadmap

- [ ] Complete macOS support
- [ ] GUI installation wizard
- [ ] Profile-based installations (minimal, developer, full)
- [ ] Ansible/Terraform alternatives
- [ ] Automated testing framework
- [ ] Cloud sync for configurations
- [ ] Package verification system
- [ ] Rollback capabilities

## 📝 Recent Updates

See [CHANGELOG1.md](CHANGELOG1.md) for the original project changelog.

### Version 2.0.0 Highlights
- Added 13 major new features to Zsh configuration
- Enhanced welcome message with git branch info
- Fixed sed alias conflict (now `sdr`)
- Added WSL support
- Improved help system with `zdoc`
- Added interactive quick menu (`qm`)

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.

## 👏 Acknowledgments

- Created and maintained by [Bragatte](https://github.com/BragatteMAS)
- Enhanced with [BMad Method](https://github.com/bmadcode/bmad-method) for AI-assisted development
- Rust tools ecosystem for modern CLI replacements
- Community contributors

## 🐛 Support

- [Report bugs](https://github.com/BragatteMAS/Linux_posintall_script/issues)
- [Request features](https://github.com/BragatteMAS/Linux_posintall_script/issues)
- [Discussions](https://github.com/BragatteMAS/Linux_posintall_script/discussions)

---

<div align="center">
  
**⭐ Star this project if it helps you!**

Made with ❤️ for the open source community

[Installation](#quick-start) • [Documentation](.ai/README.md) • [Contributing](CONTRIBUTING.md)

</div>