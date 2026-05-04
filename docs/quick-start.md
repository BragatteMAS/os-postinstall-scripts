# 🚀 Quick Start Guide

Welcome to OS Post-Install Scripts! This guide will get you up and running in minutes.

## 🎯 Choose Your Path

### Option 1: Profile-Based Installation (NEW! ⭐)

Perfect if you want a customized setup based on your role:

```bash
# Clone the repository
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

# Run profile-based setup
./setup.sh
```

Available profiles:
- **minimal** - Essential system packages only
- **developer** - Full development environment (default)
- **full** - Everything including extra packages

### Option 2: Traditional Interactive Setup

For maximum control over what gets installed:

```bash
# Clone and run interactive setup
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts
./setup.sh
```

You'll see a menu like this:
```
Sistema Detectado:
  OS: linux
  Distro: ubuntu 22.04
  Arch: x86_64

Opções de Instalação:
  1) 🦀 Instalar apenas ferramentas Rust
  2) 📦 Instalar ferramentas do sistema (apt/brew/etc)
  3) 🔧 Configuração completa (Rust + Sistema + Configs)
  4) 🐍 Instalar Python com UV
  5) 🐳 Instalar Docker/Podman
  6) 📁 Sincronizar dotfiles
  7) 🏃 Setup rápido (essenciais)
  8) 🔍 Verificar ferramentas instaladas
  9) ❌ Sair
```

### Option 3: One-Line Install

The fastest way if you trust us:

```bash
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/setup.sh | bash
```

## 📋 System Requirements

### Supported Operating Systems
- ✅ **Ubuntu** 20.04, 22.04, 24.04
- ✅ **Pop!_OS** 20.04+
- ✅ **Linux Mint** 20+
- ✅ **Fedora** 36+
- ✅ **Arch Linux** (latest)
- ✅ **macOS** 12+ (Monterey and newer)
- ✅ **Windows 11** (via PowerShell)
- ✅ **WSL2** (Windows Subsystem for Linux)

### Minimum Requirements
- **RAM**: 4GB (8GB recommended)
- **Disk Space**: 10GB free
- **Internet**: Required for downloads
- **Permissions**: sudo/admin access

## 🎯 Common Use Cases

### "I just want modern CLI tools"
```bash
./setup.sh minimal
```

The `minimal` profile ships the Rust CLI baseline (`csv:rust-cli` in
`data/packages.csv`):
- `bat` (better cat)
- `eza` (better ls)
- `fd` (better find)
- `ripgrep` (better grep)
- `zoxide` (better cd)
- 14 more (run `h rust-cli` after install for the full list)

Need more categories? `./setup.sh developer` adds `rust-dev` and `rust-data`;
`./setup.sh full` adds `rust-tui` and `rust-shell` on top.

### "I need a full dev environment ASAP"
```bash
./setup.sh minimal
```

### "I'm setting up multiple machines"
```bash
# Use the same profile on all machines
./setup.sh --dry-run developer  # Preview first
./setup.sh developer            # Then install
```

### "I want everything"
```bash
./setup.sh full
```

## ⚡ What Happens During Installation?

1. **System Detection** - We identify your OS and architecture
2. **Package Updates** - System packages are updated (safely!)
3. **Tool Installation** - Selected tools are installed
4. **Configuration** - Shell and tool configs are applied
5. **Verification** - Installation is tested

## 🛡️ Safety Features

- **No forced operations** - We wait for package managers, never force
- **Backup creation** - Your existing configs are backed up
- **Idempotent** - Safe to run multiple times
- **Validation** - All inputs are sanitized
- **Dry run mode** - Preview changes before applying

## 🆘 Troubleshooting

### "Installation seems stuck"
The script might be waiting for a package manager lock. This is normal - we wait safely instead of forcing.

### "Permission denied"
Make sure to run with proper permissions:
```bash
chmod +x setup.sh
./setup.sh
```

### "Command not found after installation"
Reload your shell configuration:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### "I want to undo changes"
Check for backup files:
```bash
ls ~/.*.bak  # Your original configs
```

## 📖 Next Steps

- 📚 Read the full [User Guide](user-guide.md)
- 🛠️ Learn about [Modern CLI Tools](modern-cli-tools.md)
- 🤝 [Contribute](../CONTRIBUTING.md) to the project

## 💡 Pro Tips

1. **Start minimal** - You can always add more tools later
2. **Use profiles** - They're tested configurations that work well together
3. **Read the output** - The script explains what it's doing
4. **Check versions** - Run with `--help` to see all options

---

Need help? Open an issue on [GitHub](https://github.com/BragatteMAS/os-postinstall-scripts/issues)!