# 🔧 Troubleshooting Guide

This guide helps you resolve common issues when using OS Post-Install Scripts. If your issue isn't covered here, please [open an issue](https://github.com/BragatteMAS/os-postinstall-scripts/issues) on GitHub.

## 📋 Table of Contents

- [Installation Issues](#installation-issues)
- [Shell Configuration Problems](#shell-configuration-problems)
- [Package Manager Errors](#package-manager-errors)
- [Profile Installation Problems](#profile-installation-problems)
- [Modern CLI Tools Issues](#modern-cli-tools-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Performance Problems](#performance-problems)
- [Getting Help](#getting-help)

## 🚫 Installation Issues

### "Permission denied" when running scripts

**Problem:** Script won't execute
```bash
bash: ./setup.sh: Permission denied
```

**Solution:**
```bash
# Make script executable
chmod +x setup.sh
./setup.sh

# Or run with bash directly
bash setup.sh
```

### "Command not found: git"

**Problem:** Git is required but not installed
```bash
./setup.sh: line 28: git: command not found
```

**Solution:**
```bash
# Install git first
# Ubuntu/Debian
sudo apt update && sudo apt install -y git

# Fedora
sudo dnf install -y git

# macOS
xcode-select --install
```

### Script hangs or appears frozen

**Problem:** Script seems stuck, no output for minutes

**Common causes:**
1. Waiting for package manager lock
2. Slow internet connection
3. Large package download

**Solution:**
```bash
# Check if package manager is running
ps aux | grep -E "apt|dpkg|yum|dnf"

# If APT is locked (Ubuntu/Debian)
# Our scripts wait safely, but you can check:
sudo lsof /var/lib/dpkg/lock-frontend

# Monitor download progress
# In another terminal:
watch -n 1 "du -sh ~/.cache/apt/archives/"
```

### Installation fails with "No space left on device"

**Problem:** Insufficient disk space

**Solution:**
```bash
# Check available space
df -h /

# Clean package cache
# Ubuntu/Debian
sudo apt clean

# Remove old kernels (Ubuntu)
sudo apt autoremove --purge

# Check large directories
du -sh /* 2>/dev/null | sort -h | tail -20
```

## 🐚 Shell Configuration Problems

### Shell didn't change to Zsh

**Problem:** Still in Bash after installation

**Solution:**
```bash
# Check current shell
echo $SHELL

# Change default shell
chsh -s $(which zsh)

# Logout and login again, or:
exec zsh
```

### Prompt looks broken/shows weird characters

**Problem:** Seeing characters like `⎈`, ``, or broken boxes

**Cause:** Missing Powerline/Nerd fonts

**Solution:**
```bash
# Install Powerline fonts
# Ubuntu/Debian
sudo apt install fonts-powerline

# Or install Nerd Fonts (recommended)
# Download from: https://www.nerdfonts.com/
# Recommended: "Hack Nerd Font" or "FiraCode Nerd Font"

# After installing fonts, restart terminal
```

### "Command not found" for aliases

**Problem:** Aliases not working after installation

**Solution:**
```bash
# Reload shell configuration
source ~/.zshrc

# Verify aliases are loaded
alias | grep ll

# If using bash instead
source ~/.bashrc

# Check if using correct file
ls -la ~/.*rc
```

### Zsh is very slow to start

**Problem:** Shell takes several seconds to start

**Solution:**
```bash
# Profile startup time
time zsh -i -c exit

# Check what's slow
zsh -xv 2>&1 | ts -i "%.s" > zsh_startup.log
tail -50 zsh_startup.log

# Common fixes:
# 1. Disable unused plugins in ~/.zshrc
# 2. Lazy load nvm:
echo 'export NVM_LAZY_LOAD=true' >> ~/.zshrc

# 3. Skip Oh My Zsh auto-update check
echo 'DISABLE_UPDATE_PROMPT=true' >> ~/.zshrc
```

## 📦 Package Manager Errors

### APT lock errors (Ubuntu/Debian)

**Problem:** "Could not get lock /var/lib/dpkg/lock-frontend"

**Note:** Our scripts handle this safely by waiting. If you see this error, another process is using APT.

**Solution:**
```bash
# Check what's using APT
sudo lsof /var/lib/dpkg/lock-frontend

# Wait for automatic updates to finish
# You can monitor with:
ps aux | grep -i apt

# If process is truly stuck (rare):
# 1. Try to stop it gracefully
sudo killall apt apt-get

# 2. Only if absolutely necessary:
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a
```

### Snap install failures

**Problem:** "error: cannot communicate with server"

**Solution:**
```bash
# Restart snapd
sudo systemctl restart snapd

# Check snapd status
systemctl status snapd

# If snapd is not installed
sudo apt install snapd

# Ensure snap bin is in PATH
echo 'export PATH="/snap/bin:$PATH"' >> ~/.zshrc
```

### Package not found errors

**Problem:** "E: Unable to locate package X"

**Solution:**
```bash
# Update package lists
sudo apt update

# Search for correct package name
apt search package-name

# Enable universe repository (Ubuntu)
sudo add-apt-repository universe
sudo apt update

# Check if package needs PPA
# Search for "Ubuntu PPA package-name"
```

## 👤 Profile Installation Problems

### Profile not found

**Problem:** "Profile not found: myprofile"

**Solution:**
```bash
# Available profiles: minimal, developer, full
./setup.sh minimal
./setup.sh developer
./setup.sh full

# Check profile files exist
ls data/packages/profiles/
```

### Profile installation incomplete

**Problem:** Some packages from profile didn't install

**Solution:**
```bash
# Run with verbose output and log
./setup.sh -v developer 2>&1 | tee install.log

# Look for errors
grep -i error install.log

# Retry specific package
sudo apt install package-name  # or appropriate package manager
```

## 🦀 Modern CLI Tools Issues

### Rust tools not in PATH

**Problem:** "command not found: bat" after installing Rust tools

**Solution:**
```bash
# Add Cargo to PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
ls ~/.cargo/bin/

# Reinstall if needed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Cargo install fails

**Problem:** "error: failed to compile"

**Solution:**
```bash
# Update Rust
rustup update

# Install build dependencies
# Ubuntu/Debian
sudo apt install build-essential pkg-config libssl-dev

# Clear cargo cache
rm -rf ~/.cargo/registry/cache

# Try installing one at a time
cargo install bat
cargo install eza
```

### Tools conflict with system commands

**Problem:** Wrong version of command runs

**Solution:**
```bash
# Check which command runs
which ls
type ls

# Adjust PATH order in ~/.zshrc
# Cargo bin should come before system paths
export PATH="$HOME/.cargo/bin:$PATH"

# Or use aliases instead
alias ls='eza'
alias cat='bat'
```

## 💻 Platform-Specific Issues

### macOS Issues

#### "xcrun: error: invalid active developer path"

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# If that fails:
sudo xcode-select --reset
```

#### Homebrew installation fails

**Solution:**
```bash
# Manual Homebrew install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc

# Add to PATH (Intel)
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
```

### WSL Issues

#### "System has not been booted with systemd"

**Solution:**
```bash
# Enable systemd in WSL2
# Add to /etc/wsl.conf:
[boot]
systemd=true

# Then in PowerShell:
wsl --shutdown
# Restart WSL
```

#### Can't access Windows files

**Solution:**
```bash
# Windows drives are mounted at /mnt/
cd /mnt/c/Users/YourUsername

# Fix permissions if needed
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata
```

### Linux Distribution Specific

#### Ubuntu: Held packages preventing upgrades

**Solution:**
```bash
# List held packages
apt-mark showhold

# Unhold packages
sudo apt-mark unhold package-name

# Then upgrade
sudo apt upgrade
```

#### Fedora: DNF is slow

**Solution:**
```bash
# Enable fastest mirror
echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf

# Clean cache
sudo dnf clean all
```

## 🐌 Performance Problems

### Scripts run slowly

**Problem:** Installation takes much longer than expected

**Solutions:**

1. **Check internet speed:**
```bash
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```

2. **Use local mirrors:**
```bash
# Ubuntu - use local mirror
sudo sed -i 's|http://archive.|http://us.archive.|g' /etc/apt/sources.list
```

3. **Parallel downloads:**
```bash
# For apt (Ubuntu 20.04+)
echo 'Acquire::Queue-Mode "host";' | sudo tee /etc/apt/apt.conf.d/99parallel
```

### High memory usage after installation

**Problem:** System feels sluggish

**Solution:**
```bash
# Check memory usage
free -h
htop

# Common culprits:
# - Docker Desktop (on Mac/Windows)
# - Language servers in VS Code
# - Unused Docker containers

# Clean Docker
docker system prune -a

# Limit VS Code extensions
# Disable unused extensions
```

## 🆘 Getting Help

### Gathering Debug Information

When reporting issues, include:

```bash
# System information
uname -a
cat /etc/os-release  # Linux only

# Shell version
$SHELL --version

# Script version
git log -1 --oneline

# Error messages
./setup.sh 2>&1 | tee debug.log
```

### Where to Get Help

1. **Check existing issues:**
   - [GitHub Issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)

2. **Discord community:**
   - Real-time help from users
   - Share your debug.log

3. **Create new issue:**
   - Use issue templates
   - Include system info
   - Describe what you expected vs what happened

### Emergency Recovery

If installation seriously breaks your system:

```bash
# Restore shell configuration
mv ~/.zshrc.pre-postinstall ~/.zshrc
mv ~/.bashrc.pre-postinstall ~/.bashrc

# Remove Oh My Zsh
rm -rf ~/.oh-my-zsh

# Reset shell to bash
chsh -s /bin/bash

# Remove installed packages (Ubuntu/Debian)
# Check installation log first!
grep "apt install" install.log
```

## 💡 Prevention Tips

1. **Always backup first:**
```bash
# Our scripts create backups, but extra safety:
cp ~/.zshrc ~/.zshrc.backup
cp ~/.bashrc ~/.bashrc.backup
```

2. **Test in VM/Container first:**
```bash
# Test in Docker
docker run -it ubuntu:22.04 bash
# Run scripts inside container
```

3. **Use dry-run when available:**
```bash
./setup.sh --dry-run minimal
```

4. **Read output carefully:**
   - Scripts explain what they're doing
   - Look for warnings or errors
   - Don't ignore error messages

---

Still having issues? We're here to help! Open an issue with your debug information. 🤝