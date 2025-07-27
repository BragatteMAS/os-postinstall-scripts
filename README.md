# 🚀 OS Post-Install Scripts

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Shell-Bash%20%26%20Zsh-4EAA25.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)

**Transform your fresh OS installation into a fully configured development environment in minutes!**

[**Quick Start**](#-quick-start) • [**What Gets Installed**](#-what-gets-installed) • [**Documentation**](#-documentation) • [**Contributing**](#-contributing)

</div>

---

## 🎯 Quick Start

### One Command Install (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/setup.sh | bash
```

### Manual Install
```bash
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts
./setup.sh
```

### Interactive Mode
```bash
./linux/main.sh  # Menu-driven installation
```

---

## 📦 What Gets Installed

<details>
<summary><b>🛠️ Development Tools</b></summary>

- **Version Control**: Git, Git LFS, GitHub CLI
- **Containers**: Docker, Docker Compose, Podman
- **Languages**: Python, Node.js, Rust, Go, Java
- **Editors**: VS Code, Vim, Neovim
- **Build Tools**: Make, CMake, GCC

</details>

<details>
<summary><b>🦀 Modern CLI Tools</b></summary>

| Traditional | Modern | Description |
|-------------|--------|-------------|
| `cat` | `bat` | Syntax highlighting |
| `ls` | `eza` | Icons & Git status |
| `find` | `fd` | Intuitive & fast |
| `grep` | `ripgrep` | Blazing fast |
| `cd` | `zoxide` | Smart navigation |

Install all Rust tools: `./install_rust_tools.sh`

</details>

<details>
<summary><b>🎨 Shell Configuration</b></summary>

- **Zsh** with Oh My Zsh
- **Starship** prompt
- **1700+ lines** of optimizations
- **100+ aliases** and functions
- **Auto-completions** and suggestions

</details>

<details>
<summary><b>📱 Applications</b></summary>

- **Browsers**: Firefox, Chrome, Brave
- **Communication**: Discord, Slack, Telegram
- **Productivity**: Obsidian, LibreOffice, Flameshot
- **Media**: VLC, Spotify, OBS Studio
- **Utilities**: Timeshift, Stacer, Htop

</details>

<details>
<summary><b>🤖 AI Development Tools</b></summary>

- **MCPs (Model Context Protocol)**:
  - context7 - Always up-to-date documentation
  - fetch - Intelligent web requests
  - sequential-thinking - Structured reasoning
  - serena - Semantic code search
- **BMAD Method v4.31.0** - Complete project management
  - Easy installation with `./install_bmad.sh`
  - Easy updates with `./update_bmad.sh`
  - Automatic backup before updates
  - Version checking and comparison
- **Auto-configuration** for Claude Desktop
- **Slash commands** in Claude (/generate-prp, /execute-prp)

Install: `./install_ai_tools.sh` or choose option 9 in menu

</details>

---

## 🖥️ Supported Systems

- ✅ **Linux**: Ubuntu 20.04+, Pop!_OS, Mint, Fedora, Arch
- ✅ **Windows**: Windows 11 (PowerShell)
- 🚧 **macOS**: Basic support (expanding)

---

## ⚡ Features

- 🎯 **One-command setup** - Get running in minutes
- 📦 **Smart package management** - APT, Snap, Flatpak, Winget
- 🔒 **Security first** - Safe APT lock handling, no forced removals
- 🧪 **Tested** - CI/CD with GitHub Actions
- 📝 **Well documented** - Clear guides and examples
- 🛠️ **Modular** - Install only what you need
- 🔄 **Idempotent** - Safe to run multiple times
- 🤖 **AI-Powered Development** - MCPs + BMAD Method integration

---

## 📚 Documentation

- 📖 [**User Guide**](docs/user-guide.md) - Detailed instructions
- 🏗️ [**Architecture**](docs/core-architecture.md) - How it works
- 🤖 [**AI Tools Setup**](docs/ai-tools-setup.md) - MCPs + BMAD configuration
- 🤝 [**Contributing**](CONTRIBUTING.md) - Help us improve
- 📋 [**Changelog**](CHANGELOG.md) - What's new
- 🗺️ [**Roadmap**](ROADMAP.md) - Where we're going

### For Developers
- 🏛️ [Architecture Decisions](.github/PROJECT_DOCS/adrs/) - Why we built it this way
- 📋 [Project Status](.github/PROJECT_DOCS/STATUS.md) - Current development status
- 🤖 [AI Context](.github/AI_CONTEXT/CLAUDE.md) - For AI-assisted development

---

## 🤝 Contributing

We love contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Guide
1. 🍴 Fork the repository
2. 🌿 Create a feature branch
3. 📝 Make your changes
4. ✅ Run tests: `./tests/test_harness.sh`
5. 📤 Submit a pull request

### Priority Areas
- 🍎 **macOS scripts** - Expand platform support
- 🧪 **Tests** - Increase coverage
- 📚 **Documentation** - Improve guides
- 🌍 **Translations** - Make it global

---

## 🛡️ Security

- ✅ **No forced lock removal** - Safe APT operations
- ✅ **Input validation** - Protected against injection
- ✅ **Audit logging** - Track all operations
- 🐛 Found a vulnerability? See [SECURITY.md](SECURITY.md)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">
<sub>Built with ❤️ by Bragatte, M.A.S</sub>
</div>