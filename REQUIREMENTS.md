# 📋 System Requirements

> ⚠️ **IMPORTANT**: These are **MANDATORY** requirements. The installation will not proceed without them.

This document outlines the requirements for using the OS Post-Install Scripts. We believe in using modern, secure tools and encourage best practices.

## 🔧 Minimum Requirements

### Operating Systems
- **macOS**: 10.15 (Catalina) or later
- **Linux**: Ubuntu 20.04+, Fedora 34+, Arch (current), Debian 11+
- **Windows**: Windows 10/11 with WSL2 or Git Bash

### Shell Requirements
- **Bash**: 4.0+ (required for associative arrays and modern features)
  - macOS ships with Bash 3.2 by default - upgrade required
  - Most modern Linux distributions include Bash 4.0+
- **Zsh**: 5.0+ (for shell configuration features)

### Core Dependencies
- **Git**: 2.25+ (for repository management)
- **curl** or **wget**: For downloading tools
- **jq**: 1.6+ (for JSON processing)

### Package Managers
- **macOS**: Homebrew (will be installed if missing)
- **Linux**: apt, dnf, pacman, or zypper
- **npm**: For Node.js packages

## 💡 Recommended Setup

### Development Tools
- **Python**: 3.8+ (for uv and other tools)
- **Node.js**: 16+ LTS (for MCPs and modern tooling)
- **Rust**: Latest stable (for modern CLI tools)

### Shell Tools
- **Oh My Zsh**: For enhanced shell experience
- **Starship**: Cross-shell prompt (optional)

## 🚀 Quick Setup for Requirements

### macOS - Update Bash
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Update Bash to latest version
brew install bash

# Add new bash to allowed shells
echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells  # M1/M2 Macs
# or
echo /usr/local/bin/bash | sudo tee -a /etc/shells     # Intel Macs

# Set as default shell (optional)
chsh -s /opt/homebrew/bin/bash  # or /usr/local/bin/bash for Intel

# Install other requirements
brew install git curl jq zsh
```

### Linux - Install Requirements
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y bash git curl jq zsh build-essential

# Fedora
sudo dnf install -y bash git curl jq zsh gcc make

# Arch
sudo pacman -Syu --noconfirm bash git curl jq zsh base-devel
```

## ✅ Verification Script

Run this to check if your system meets the requirements:

```bash
#!/usr/bin/env bash

echo "Checking system requirements..."

# Check Bash version
bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [[ "${bash_version%%.*}" -ge 4 ]]; then
    echo "✓ Bash $bash_version (OK)"
else
    echo "✗ Bash $bash_version (Requires 4.0+)"
fi

# Check other tools
for tool in git curl jq zsh; do
    if command -v $tool &> /dev/null; then
        echo "✓ $tool installed"
    else
        echo "✗ $tool missing"
    fi
done
```

## 🔍 Why These Requirements?

### Bash 4.0+
- **Associative arrays**: Essential for configuration management
- **Better parameter expansion**: Cleaner code
- **Improved debugging**: Better error handling
- **Modern features**: Makes scripts more maintainable

### Modern Tools
- **jq**: Reliable JSON/YAML processing
- **Git 2.25+**: Supports all modern features we use
- **Zsh 5.0+**: Better completion and plugin system

## 📚 Additional Resources

- [Bash Changelog](https://www.gnu.org/software/bash/manual/html_node/Bash-History.html)
- [Homebrew Installation](https://brew.sh)
- [Oh My Zsh](https://ohmyz.sh)

---

**Note**: Using modern versions ensures better security, performance, and access to features that make the installation process more reliable and user-friendly.