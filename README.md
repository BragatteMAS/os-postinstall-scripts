# <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Desktop%20Computer.png" alt="Desktop Computer" width="30" height="30" /> OS Post-Install Scripts

<div align="center">

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Shell-Bash%20%26%20Zsh-4EAA25.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)

[![ShellCheck](https://github.com/BragatteMAS/os-postinstall-scripts/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/BragatteMAS/os-postinstall-scripts/actions/workflows/shellcheck.yml)
[![Test Scripts](https://github.com/BragatteMAS/os-postinstall-scripts/actions/workflows/test-scripts.yml/badge.svg)](https://github.com/BragatteMAS/os-postinstall-scripts/actions/workflows/test-scripts.yml)
[![Documentation](https://github.com/BragatteMAS/os-postinstall-scripts/actions/workflows/documentation.yml/badge.svg)](https://github.com/BragatteMAS/os-postinstall-scripts/actions/workflows/documentation.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Transform your fresh OS installation into a fully configured development powerhouse**  
*Automated • Customizable • Cross-Platform*

[<kbd> <br> 🚀 Quick Start <br> </kbd>](#-quick-start)
[<kbd> <br> 📚 Documentation <br> </kbd>](#-documentation)
[<kbd> <br> 🎯 Features <br> </kbd>](#-key-features)
[<kbd> <br> 💝 Contributing <br> </kbd>](#-contributing)

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="rainbow line" width="100%" height="3px" />

</div>

## 📖 About

**OS Post-Install Scripts** is a comprehensive automation toolkit that transforms hours of manual setup into minutes of automated configuration. Whether you're setting up a new development machine, deploying multiple workstations, or just love having a perfectly configured system, this project has you covered.

### 🎯 Who Is This For?

- **👩‍💻 Developers** who want consistent development environments
- **🚀 DevOps Engineers** managing multiple systems
- **🎓 Students** setting up for courses or projects
- **🏢 IT Professionals** deploying standardized workstations
- **🐧 Linux Enthusiasts** who frequently distro-hop
- **⚡ Anyone** who values their time and wants a perfect setup

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## ✨ Key Features

<table>
<tr>
<td width="50%">

### 🔧 **System Configuration**
- ✅ Automated software installation
- ✅ Development environment setup
- ✅ System optimizations
- ✅ Security configurations
- ✅ Backup solutions

</td>
<td width="50%">

### 🎨 **Shell Enhancement**
- ✅ 1700+ lines of Zsh optimizations
- ✅ Rust-powered modern CLI tools
- ✅ Custom themes and prompts
- ✅ Intelligent auto-completions
- ✅ Performance monitoring

</td>
</tr>
<tr>
<td width="50%">

### 📦 **Package Management**
- ✅ APT (Debian/Ubuntu)
- ✅ Flatpak (Universal)
- ✅ Snap (Universal)
- ✅ Winget (Windows)
- ✅ Direct downloads

</td>
<td width="50%">

### 🌐 **Cross-Platform**
- ✅ Ubuntu (20.04, 22.04, 24.04)
- ✅ Pop!_OS
- ✅ Linux Mint
- ✅ Windows 11
- ✅ macOS (coming soon)

</td>
</tr>
</table>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🚀 Quick Start

### 🐧 Linux Installation

<details open>
<summary><b>Option 1: Full Installation (Recommended)</b></summary>

```bash
# Clone the repository
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

# Run the installer
cd linux
chmod +x post_install.sh
sudo ./post_install.sh
```

</details>

<details>
<summary><b>Option 2: Zsh Configuration Only</b></summary>

```bash
# Quick install (backs up existing config)
curl -fsSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/zshrc > ~/.zshrc.new
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup
mv ~/.zshrc.new ~/.zshrc

# Install Oh My Zsh and required plugins
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

source ~/.zshrc
```

</details>

<details>
<summary><b>Option 3: Selective Installation</b></summary>

```bash
# Install only specific components
cd linux/auto

# Choose what to install:
./auto_apt.sh      # APT packages only
./auto_flat.sh     # Flatpak apps only
./auto_snap.sh     # Snap packages only
```

</details>

### 🪟 Windows Installation

<details>
<summary><b>Windows 11 Setup</b></summary>

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force

# Clone and run
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts\windows
.\win11.ps1
```

</details>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 📋 What Gets Installed?

<details>
<summary><b>🛠️ Development Tools</b></summary>

| Category | Tools |
|----------|-------|
| **Version Control** | Git, Git LFS, GitHub CLI |
| **Editors & IDEs** | VS Code, Vim, Neovim |
| **Containers** | Docker, Docker Compose, Podman |
| **Languages** | Python, Node.js, Rust, Go, Java |
| **Databases** | PostgreSQL, MySQL, MongoDB tools |
| **Build Tools** | Make, CMake, GCC, Clang |

</details>

<details>
<summary><b>🎯 Productivity Software</b></summary>

| Category | Applications |
|----------|-------------|
| **Communication** | Discord, Slack, Teams, Telegram |
| **Office** | LibreOffice, OnlyOffice |
| **Notes** | Obsidian, Joplin, Simplenote |
| **Browsers** | Firefox, Chrome, Brave |
| **Media** | VLC, Spotify, OBS Studio |
| **Utilities** | Flameshot, Timeshift, Stacer |

</details>

<details>
<summary><b>🦀 Modern CLI Tools (Rust-Powered)</b></summary>

### Core Replacements

| Traditional | Modern | Description |
|-------------|---------|-------------|
| `cat` | `bat` | Syntax highlighting, Git integration |
| `ls` | `eza` | Icons, tree view, Git status |
| `find` | `fd` | Intuitive syntax, faster |
| `grep` | `ripgrep` | Faster, respects .gitignore |
| `cd` | `zoxide` | Smarter navigation with learning |
| `sed` | `sd` | Intuitive find & replace |
| `du` | `dust` | Visual disk usage in tree format |
| `top` | `bottom` | Better resource monitor |
| `diff` | `delta` | Beautiful Git diffs |

### Development Tools

| Tool | Description |
|------|-------------|
| `cargo-watch` | Auto-reload for Rust projects |
| `cargo-edit` | Add dependencies via CLI |
| `cargo-audit` | Check for security vulnerabilities |
| `bacon` | Background Rust task runner |
| `tokei` | Code statistics and metrics |

### Additional Productivity Tools

| Tool | Description |
|------|-------------|
| `starship` | Customizable cross-shell prompt |
| `helix` | Modern modal text editor |
| `gitui` | Terminal UI for Git |
| `xsv` | CSV data manipulation |
| `httpie` | Modern HTTP client |

### Quick Installation

```bash
# Install all Rust tools at once
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install_rust_tools.sh | bash
```

The system includes intelligent fallbacks - if Rust tools aren't installed, it automatically uses traditional commands.

</details>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🎨 Zsh Configuration

Our advanced Zsh setup transforms your terminal into a productivity powerhouse:

### ⚡ Quick Commands

| Command | Description |
|---------|-------------|
| `qm` | **Quick Menu** - Interactive command palette |
| `update` | Update all packages across package managers |
| `backup_configs` | Backup your configurations |
| `gi [type]` | Generate .gitignore files |
| `extract [file]` | Extract any archive format |
| `weather` | Check weather in terminal |

### 🎯 Smart Aliases

```bash
# Navigation
z project    # Jump to project directory (frecency-based)
up 3         # Go up 3 directories
mkcd folder  # Create and enter directory

# Git
gs           # Git status with summary
gco feature  # Checkout branch
gcm "msg"    # Commit with message
gp           # Push with upstream tracking
glog         # Beautiful git log

# Docker
dps          # Better docker ps
dex nginx    # Execute into container
dlog app     # Follow container logs
dclean       # Clean unused resources
```

### 🚀 Performance Features

- **Instant Prompt** with Powerlevel10k
- **Lazy Loading** for heavy tools (nvm, rbenv)
- **Smart Caching** for completions
- **Async Git** status updates
- **Optimized PATH** management

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🛡️ Security & Best Practices

- 🔒 **No Hardcoded Secrets** - Uses `.env.local` for sensitive data
- 🔑 **SSH Key Management** - Automated SSH agent setup
- 🛡️ **Firewall Configuration** - UFW setup included
- 📝 **Backup System** - Configuration backup with rotation
- ✅ **Verified Sources** - Only official repositories and packages

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 📚 Documentation

<div align="center">

| 📖 Resource | 📝 Description |
|------------|---------------|
| [**User Guide**](docs/user-guide.md) | Complete usage instructions |
| [**Zsh Guide**](.ai/ZSH_CONFIGURATION_GUIDE.md) | Advanced shell configuration |
| [**Contributing**](CONTRIBUTING.md) | How to contribute |
| [**Conventions**](.ai/conventions/CONVENTIONS.md) | Coding standards |
| [**Patterns**](.ai/patterns/PATTERNS.md) | Common implementation patterns |
| [**Changelog**](CHANGELOG1.md) | Version history |

</div>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🚦 Requirements

### Minimum System Requirements

- **OS**: Ubuntu 20.04+, Pop!_OS 20.04+, Linux Mint 19+, Windows 11
- **RAM**: 4GB (8GB recommended)
- **Storage**: 20GB free space
- **Internet**: Required for package downloads
- **Privileges**: sudo/admin access

### Pre-Installation Checklist

- [ ] Backup your important data
- [ ] Note your current configurations
- [ ] Have sudo/admin password ready
- [ ] Stable internet connection
- [ ] At least 1 hour of time (full installation)

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🎯 Customization

### Adding Your Own Packages

<details>
<summary><b>Linux Packages</b></summary>

Edit the arrays in `linux/auto/auto_apt.sh`:

```bash
APT_INSTALL=(
    # Add your packages here
    "your-package"
    "another-package"
)
```

</details>

<details>
<summary><b>Windows Packages</b></summary>

Edit the array in `windows/win11.ps1`:

```powershell
$packages = @(
    # Add your packages here
    "Company.Package"
    "Another.Package"
)
```

</details>

### Personal Configuration

Create `.zshrc.local` for your personal settings:

```bash
# ~/.zshrc.local
export MY_API_KEY="your-key"
alias myproject="cd ~/projects/myproject"

# Your custom functions
function my_function() {
    echo "My custom function"
}
```

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 📊 Installation Process Flow

```
┌─────────────┐
│   START     │
└──────┬──────┘
       │
       ▼
┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│ First Time?  │ YES │   Clone Repo    │     │ Choose Type  │
│              ├────▶│ & Initial Setup ├────▶│              │
└──────┬───────┘     └─────────────────┘     └───────┬──────┘
       │ NO                                           │
       └──────────────────────────────────────────────┘
                                                      │
        ┌─────────────┬──────────────┬────────────────┼────────────────┬──────────────┐
        ▼             ▼              ▼                ▼                ▼              ▼
┌───────────┐ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐
│   Full    │ │     Zsh      │ │  Selective  │ │   Windows   │ │    Rust     │ │   Custom   │
│  Install  │ │     Only     │ │   Install   │ │   Install   │ │    Tools    │ │   Config   │
└─────┬─────┘ └──────┬───────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └─────┬──────┘
      │              │                 │               │               │               │
      ▼              ▼                 ▼               ▼               ▼               ▼
┌───────────┐ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐
│   Run:    │ │  Copy zshrc  │ │   Choose:   │ │     Run     │ │   Install   │ │   Create   │
│post_install│ │  Install     │ │ • auto_apt  │ │  win11.ps1  │ │  Rust CLI   │ │ .zshrc.local│
│    .sh     │ │  Oh My Zsh   │ │ • auto_flat │ │  (as Admin) │ │    Tools    │ │   files    │
└─────┬─────┘ └──────┬───────┘ │ • auto_snap │ └──────┬──────┘ └──────┬──────┘ └─────┬──────┘
      │              │          └──────┬──────┘        │               │               │
      ▼              ▼                 ▼               ▼               ▼               ▼
┌───────────┐ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐
│ Complete  │ │   Source     │ │     Run     │ │   Restart   │ │   Verify    │ │   Ready!   │
│   Setup   │ │   ~/.zshrc   │ │  Selected   │ │   Terminal  │ │   Tools     │ │            │
└───────────┘ └──────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └────────────┘
```

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🤝 Contributing

We love contributions! This project uses the **[BMad Method](.ai/README.md)** for AI-assisted development.

### How to Contribute

1. 🍴 Fork the repository
2. 🌿 Create your feature branch (`git checkout -b feature/amazing-feature`)
3. 📝 Follow our [conventions](.ai/conventions/CONVENTIONS.md)
4. ✅ Test your changes
5. 📊 Commit with meaningful messages
6. 🚀 Push and create a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/os-postinstall-scripts
cd os-postinstall-scripts

# Install development tools
./setup.sh --dev

# Run tests
make test

# Check code quality
make lint
```

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🗺️ Roadmap

<div align="center">

| Status | Feature | Target |
|--------|---------|--------|
| ✅ | Linux support (Ubuntu, Pop!_OS, Mint) | Done |
| ✅ | Windows 11 support | Done |
| ✅ | Advanced Zsh configuration | Done |
| ✅ | CI/CD with GitHub Actions | Done |
| 🚧 | macOS support | Q1 2024 |
| 📋 | GUI installer | Q2 2024 |
| 📋 | Ansible playbooks | Q2 2024 |
| 📋 | Profile-based installations | Q3 2024 |
| 📋 | Cloud backup sync | Q4 2024 |

</div>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 📊 Project Stats

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/BragatteMAS/os-postinstall-scripts?style=social)
![GitHub forks](https://img.shields.io/github/forks/BragatteMAS/os-postinstall-scripts?style=social)
![GitHub issues](https://img.shields.io/github/issues/BragatteMAS/os-postinstall-scripts)
![GitHub pull requests](https://img.shields.io/github/issues-pr/BragatteMAS/os-postinstall-scripts)

</div>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/aqua.png" alt="aqua line" width="100%" height="3px" />
</div>

## 🌟 Acknowledgments

<div align="center">

Special thanks to all contributors and projects that make this possible:

**Created and maintained by** [**@BragatteMAS**](https://github.com/BragatteMAS)

Enhanced with [**BMad Method**](https://github.com/bmadcode/bmad-method) • Powered by [**Modern Unix**](https://github.com/ibraheemdev/modern-unix) tools

</div>

<div align="center">
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="rainbow line" width="100%" height="3px" />

<h3>⭐ Star this project if it helps you!</h3>

<p>Made with ❤️ for the open source community</p>

[Report Bug](https://github.com/BragatteMAS/os-postinstall-scripts/issues) • 
[Request Feature](https://github.com/BragatteMAS/os-postinstall-scripts/issues) • 
[Join Discussions](https://github.com/BragatteMAS/os-postinstall-scripts/discussions)

</div>