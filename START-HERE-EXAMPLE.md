# 🚀 Start Here!

<div align="center">

### Transform your fresh OS into a development powerhouse in minutes!

[![Quick Install](https://img.shields.io/badge/Quick%20Install-5%20minutes-success?style=for-the-badge)](install/quick-start.sh)
[![Supported OS](https://img.shields.io/badge/Linux%20|%20Windows%20|%20macOS-blue?style=for-the-badge)](docs/getting-started/supported-systems.md)
[![Profile Based](https://img.shields.io/badge/Profile%20Based-Customizable-orange?style=for-the-badge)](profiles/)

</div>

---

## 🎯 Choose Your Path

### 🏃 "Just Do It!" (Recommended)
```bash
curl -sSL https://github.com/BragatteMAS/os-postinstall-scripts/raw/main/install/quick-start.sh | bash
```
> 🎨 Installs the **developer-standard** profile with all the essentials

### 🔍 "Show Me First"
```bash
# See what would be installed
curl -sSL https://github.com/BragatteMAS/os-postinstall-scripts/raw/main/install/quick-start.sh | bash -s -- --preview

# Like what you see? Run it for real:
curl -sSL https://github.com/BragatteMAS/os-postinstall-scripts/raw/main/install/quick-start.sh | bash
```

### 🎨 "I Know What I Want"
```bash
# Choose a profile
curl -sSL https://github.com/BragatteMAS/os-postinstall-scripts/raw/main/install/quick-start.sh | bash -s -- --profile devops

# Available profiles:
# • developer-minimal - Just the essentials (Git, Docker, VS Code)
# • developer-standard - Full dev setup (default)
# • devops - Infrastructure tools (Terraform, K8s, Cloud CLIs)  
# • data-scientist - Python, R, Jupyter, data tools
# • student - Learning-focused setup
```

### 🔧 "Full Control Please"
```bash
# Clone and customize
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

# Interactive mode
./install/menu.sh

# Or manual selection
./install/linux/ubuntu.sh --only docker,python,vscode
```

---

## 📦 What Gets Installed?

<details>
<summary><b>🖥️ Developer Standard Profile</b> (click to expand)</summary>

### Development Tools
- 🐙 Git + GitHub CLI
- 🐳 Docker + Docker Compose  
- 📝 VS Code + Extensions
- 🦀 Rust toolchain + modern CLI tools
- 🐍 Python 3 + pip + poetry
- 📦 Node.js + npm + yarn
- ☕ Java (OpenJDK)

### Shell Enhancement  
- 🚀 Zsh + Oh My Zsh
- ⭐ Starship prompt
- 🔧 Modern CLI replacements (eza, bat, ripgrep, etc.)

### Productivity
- 🔥 Flameshot (screenshots)
- ⏰ Timeshift (backups)
- 📊 Htop, Btop (monitoring)

[See full list →](docs/getting-started/what-gets-installed.md)

</details>

<details>
<summary><b>🚀 Other Profiles</b></summary>

| Profile | Best For | Key Tools |
|---------|----------|-----------|
| `minimal` | Quick setups | Git, Docker, VS Code |
| `devops` | Infrastructure | Terraform, Ansible, K8s tools |
| `data-scientist` | ML/Data | Python, R, Jupyter, GPU tools |
| `student` | Learning | Multiple languages, educational tools |

[Create custom profile →](docs/guides/create-your-profile.md)

</details>

---

## 🎓 New to Command Line?

No worries! We've got you covered:

📖 **[First Time User Guide](docs/getting-started/first-time-users.md)** - Step-by-step with screenshots  
🎥 **[Video Walkthrough](https://youtube.com/...)** - Watch it in action  
❓ **[FAQ](docs/getting-started/faq.md)** - Common questions answered  

---

## 🚨 System Requirements

- **OS**: Ubuntu 20.04+, Fedora 35+, Windows 11, macOS 12+
- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 10GB free space
- **Access**: sudo/admin privileges
- **Network**: Internet connection

---

## 🤝 Contributing

Want to add your favorite tool? It's easy!

1. 📋 Check if it's [already requested](https://github.com/BragatteMAS/os-postinstall-scripts/issues?q=is%3Aissue+label%3Atool-request)
2. 🧩 [Add a module](docs/guides/add-new-tool.md) - 10 minute guide
3. 🎨 [Create a profile](docs/guides/create-your-profile.md) - Share your setup

---

## 🆘 Need Help?

<div align="center">

[📚 **Documentation**](docs/) • [🐛 **Report Issue**](https://github.com/BragatteMAS/os-postinstall-scripts/issues) • [💬 **Discussions**](https://github.com/BragatteMAS/os-postinstall-scripts/discussions) • [🔒 **Security**](SECURITY.md)

</div>

---

<div align="center">
<sub>Built with ❤️ by developers, for developers</sub>
</div>