# OS Post-Installation Scripts

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/OS-Linux-yellow.svg)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/OS-Windows-blue.svg)](https://www.microsoft.com/windows)
[![macOS](https://img.shields.io/badge/OS-macOS-black.svg)](https://www.apple.com/macos/)

Comprehensive post-installation automation scripts for multiple operating systems. Streamline your system setup with automated software installation, configuration management, and development environment setup.

## 🎯 Purpose

Automate the tedious post-installation process across different operating systems:
- 🐧 **Linux**: Ubuntu, Pop!_OS, Linux Mint, and other Debian-based distributions
- 🪟 **Windows**: Windows 11 PowerShell automation
- 🍎 **macOS**: Coming soon

## ✨ Features

- **🚀 One-Command Setup**: Run a single script to configure your entire system
- **📦 Comprehensive Software Installation**: Development tools, productivity apps, multimedia software
- **🔧 System Configuration**: Shell customization (Bash/Zsh), development environments, system settings
- **🎨 Distribution-Specific Adaptations**: Optimized for each Linux distribution
- **🛡️ Security Tools**: Firewall, VPN, SSH configuration included
- **🔄 Modular Architecture**: Easy to customize and extend
- **🤖 AI-Assisted Development**: Enhanced with BMad Method for better documentation and development

## 📁 Project Structure

```
OS-postinstall-scripts/
├── .ai/                    # AI context (BMad Method)
├── linux/                  # Linux scripts
│   ├── auto/              # Modular installers
│   ├── bash/              # Shell configurations
│   ├── distros/           # Distribution-specific
│   └── post_install.sh    # Main script
├── windows/               # Windows scripts
├── mac/                   # macOS scripts (future)
├── zshrc*                 # Zsh configurations
└── docs/                  # Documentation
```

## 🚀 Quick Start

### Linux

```bash
# Clone the repository
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts/linux

# Make executable and run
chmod +x post_install.sh
sudo ./post_install.sh
```

### Windows

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\windows\win11.ps1
```

## 📋 What Gets Installed

### Development Tools
- **Version Control**: Git, Git LFS
- **Editors/IDEs**: VS Code with extensions
- **Containers**: Docker, Docker Compose
- **Languages**: Python, Node.js, Rust, Go (optional)
- **Databases**: MongoDB Compass, pgAdmin, DBeaver

### System Tools
- **Terminal**: Alacritty, Terminator, Zsh with Oh My Zsh
- **System Monitoring**: Stacer, htop, btop
- **Backup**: Timeshift
- **File Management**: Nemo, folder-color
- **Security**: gufw (firewall), OpenSSH, VPN clients

### Productivity
- **Communication**: Discord, Slack, Teams
- **Office**: LibreOffice, OnlyOffice
- **Notes**: Obsidian, Joplin, Simplenote
- **Media**: VLC, Spotify, OBS Studio

### Shell Enhancements
- **Bash**: Custom aliases, functions, and prompt
- **Zsh**: Oh My Zsh with plugins, themes, and Rust integration
- **Common**: Git aliases, development shortcuts

## 🛠️ Customization

### Adding/Removing Software

Edit the package arrays in the scripts:

```bash
# In linux/post_install.sh or linux/auto/auto_apt.sh
APT_INSTALL=(
    # Add your packages here
    "package-name"
    # Remove unwanted packages
)
```

### Shell Configuration

- **Bash**: Modify `linux/bash/bashrc.sh`
- **Zsh**: Edit `zshrc` and related files
- **VS Code**: Update extension list in `linux/bash/vscode_list_extensions.txt`

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### AI-Assisted Development

This project uses the BMad Method for AI-assisted development. Check `.ai/` directory for:
- Project context and conventions
- Common patterns and best practices
- AI-friendly documentation

## 📚 Documentation

- [User Guide](docs/user-guide.md) - Detailed usage instructions
- [Contributing Guide](CONTRIBUTING.md) - How to contribute
- [AI Context](.ai/README.md) - For AI assistants
- [Changelog](CHANGELOG.md) - Version history

## 🔄 Roadmap

- [ ] Complete macOS support
- [ ] GUI installation wizard
- [ ] Profile-based installations (minimal, developer, full)
- [ ] Ansible playbook alternative
- [ ] Automated testing framework
- [ ] Cloud sync for configurations

## 📝 License

This project is licensed under the GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.

## 👏 Acknowledgments

- Created and maintained by [Bragatte](https://github.com/BragatteMAS)
- Enhanced with [BMad Method](https://github.com/bmadcode/bmad-method) for AI-assisted development
- Community contributors (see [Contributors](https://github.com/BragatteMAS/os-postinstall-scripts/graphs/contributors))

## 🐛 Issues & Support

- [Report bugs](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- [Request features](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- [Discussions](https://github.com/BragatteMAS/os-postinstall-scripts/discussions)

---

<div align="center">
  
**⭐ Star this project if it helps you!**

Made with ❤️ for the open source community

</div>