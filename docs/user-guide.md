# 📚 OS Post-Install Scripts User Guide

Complete guide for using OS Post-Install Scripts to set up your development environment quickly and efficiently.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Installation Methods](#installation-methods)
4. [Using Profiles](#using-profiles)
5. [Script Components](#script-components)
6. [Customization](#customization)
7. [Advanced Usage](#advanced-usage)
8. [Maintenance](#maintenance)

## Overview

### What is OS Post-Install Scripts?

A comprehensive collection of scripts that automatically configure a fresh operating system installation with development tools, modern CLI utilities, and optimized shell configurations. Save hours of manual setup with our battle-tested installation scripts.

### Key Features

1. **One-Command Setup**: Get a complete dev environment in minutes
2. **Profile-Based Installation**: Choose pre-configured setups for your role
3. **Cross-Platform**: Works on Linux, macOS, and Windows (WSL)
4. **Modern Tools**: Includes Rust-powered CLI tools that replace traditional Unix utilities
5. **Safe Operations**: Never forces package manager locks, validates inputs
6. **Customizable**: Modular design lets you install only what you need

### What Gets Installed

- **Development Tools**: Git, Docker, VS Code, multiple programming languages
- **Modern CLI**: bat (cat), eza (ls), ripgrep (grep), fd (find), and more
- **Shell Enhancement**: Zsh with Oh My Zsh, Starship prompt, 1700+ lines of optimizations
- **Productivity Apps**: Browsers, communication tools, media players
- **System Utilities**: Package managers, system monitors, backup tools

## Quick Start

### Fastest Installation

```bash
# One-line install (uses developer-standard profile)
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/setup.sh | bash
```

### Recommended: Profile-Based Install

```bash
# Clone and choose your profile
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts
./setup-with-profile.sh
```

### Manual Control

```bash
# Interactive menu-driven installation
./setup.sh
```

### System Requirements

- **OS**: Ubuntu 20.04+, Fedora 36+, macOS 12+, or Windows 11 (WSL2)
- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 10GB free space
- **Network**: Internet connection required
- **Permissions**: sudo/admin access

## Installation Methods

### Method 1: Profile-Based Installation (Recommended)

Profiles are pre-configured sets of tools for specific use cases:

```bash
./setup-with-profile.sh
```

Available profiles:
- **developer-standard**: Full development environment (15 min)
- **developer-minimal**: Just essentials (5 min)
- **devops**: Infrastructure and cloud tools (20 min)
- **data-scientist**: Python, R, ML tools (25 min)
- **student**: Multiple languages for learning (15 min)

### Method 2: Interactive Menu

```bash
./setup.sh
```

Presents an interactive menu:
1. 🦀 Install Rust tools only
2. 📦 Install system packages
3. 🔧 Complete setup (recommended)
4. 🐍 Python with UV
5. 🐳 Docker/Podman
6. 📁 Sync dotfiles
7. 🏃 Quick essentials
8. 🔍 Check installed tools

### Method 3: Individual Scripts

For granular control:

```bash
# Just modern CLI tools
./src/install/rust-cli.sh

# Just Python with UV
./src/install/uv.sh

# Just development environment
./src/install/dev-env.sh
```

## Using Profiles

For detailed information about each installation profile, see the [Installation Profiles Guide](installation-profiles.md).

## Maintenance

### Keeping Scripts Updated

```bash
# Pull latest changes
git pull

# Check current version
git describe --tags

# See what's new
cat CHANGELOG.md
```

### Version Management

We use semantic versioning (MAJOR.MINOR.PATCH). See our [Versioning Guide](versioning-guide.md) for:
- When to bump version numbers
- Pre-release versioning (alpha, beta)
- How versions relate to features and fixes
- Integration with roadmap planning

### Contributing Updates

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:
- Creating pull requests
- Testing your changes
- Following code standards
- Updating documentation

## Troubleshooting

See our comprehensive [Troubleshooting Guide](troubleshooting.md) for solutions to common issues:
- Installation problems
- Shell configuration issues
- Package manager errors
- Platform-specific problems

## Additional Resources

### Documentation
- [Quick Start Guide](quick-start.md) - Get started fast
- [Installation Profiles](installation-profiles.md) - Choose your setup
- [Modern CLI Tools](modern-cli-tools.md) - Master new tools
- [Shell Customization](shell-customization.md) - Personalize your environment
- [Troubleshooting](troubleshooting.md) - Fix common issues

### Project Information
- **GitHub**: [github.com/BragatteMAS/os-postinstall-scripts](https://github.com/BragatteMAS/os-postinstall-scripts)
- **Issues**: [Report bugs or request features](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- **License**: MIT
- **Changelog**: See [CHANGELOG.md](../CHANGELOG.md)

## Getting Help

1. **Check Documentation First**
   - This guide and linked documentation
   - README.md for quick overview
   - Troubleshooting guide for issues

2. **Search Existing Issues**
   - [GitHub Issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
   - Someone may have already solved your problem

3. **Create New Issue**
   - Use issue templates
   - Include system information
   - Provide error messages
   - Describe what you expected vs what happened

4. **Community**
   - Star the repo if you find it useful
   - Share with others who might benefit
   - Contribute improvements back

## Conclusion

OS Post-Install Scripts transforms the tedious task of setting up a new development environment into a simple, automated process. Whether you're:

- Setting up a new machine
- Standardizing team environments
- Learning modern CLI tools
- Exploring different development stacks

These scripts save you hours of manual configuration while ensuring consistency and following best practices.

**Remember**: Start with a profile that fits your needs, and customize from there. The scripts are modular and safe to run multiple times.

Happy coding! 🚀
