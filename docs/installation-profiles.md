# 📦 Installation Profiles Guide

Installation profiles let you quickly set up your development environment based on your specific needs. Instead of manually selecting individual packages, choose a profile that matches your role or use case.

## 🎯 Available Profiles

### developer-standard
**Perfect for:** Full-stack developers, general software development  
**Install time:** ~15 minutes  
**Disk space:** ~5GB

<details>
<summary><b>What's included</b></summary>

#### Development Tools
- **Version Control**: Git, Git LFS
- **Containers**: Docker, Docker Compose  
- **Languages**: Python 3, Node.js, Rust, Go
- **Package Managers**: pip, npm, cargo
- **Build Tools**: make, cmake, gcc, g++

#### Modern CLI
- All Rust-powered tools (bat, eza, ripgrep, etc.)
- Shell enhancements (zsh, oh-my-zsh, starship)
- Terminal multiplexer (tmux)

#### Editors & IDEs
- Visual Studio Code
- Vim/Neovim with plugins
- Sublime Text

#### Productivity
- htop, btop (system monitoring)
- jq (JSON processing)
- httpie (API testing)
- tree, ncdu (file management)

</details>

**Use when:** You want a complete, modern development setup with all the bells and whistles.

---

### developer-minimal
**Perfect for:** Quick setup, containers, cloud development  
**Install time:** ~5 minutes  
**Disk space:** ~2GB

<details>
<summary><b>What's included</b></summary>

#### Essentials Only
- **Version Control**: Git
- **Containers**: Docker
- **Editor**: VS Code
- **Languages**: Python, Node.js
- **Shell**: Improved with modern tools
- **Utilities**: curl, wget, jq

</details>

**Use when:** You need to get coding quickly, use cloud IDEs, or prefer installing additional tools as needed.

---

### devops
**Perfect for:** Infrastructure engineers, SREs, Cloud architects  
**Install time:** ~20 minutes  
**Disk space:** ~8GB

<details>
<summary><b>What's included</b></summary>

#### Infrastructure as Code
- Terraform
- Ansible
- Packer
- CloudFormation tools

#### Container Orchestration
- Docker & Docker Compose
- kubectl
- Helm
- k9s (Kubernetes CLI UI)
- Podman

#### Cloud Provider CLIs
- AWS CLI v2
- Azure CLI
- Google Cloud SDK
- DigitalOcean CLI

#### Monitoring & Debugging
- htop, btop, iotop
- netstat, ss, dig, nmap
- tcpdump, wireshark
- prometheus, grafana (optional)

#### CI/CD Tools
- Jenkins CLI
- GitHub CLI
- GitLab CLI

</details>

**Use when:** You're managing infrastructure, working with Kubernetes, or doing cloud architecture.

---

### data-scientist
**Perfect for:** ML engineers, Data analysts, Researchers  
**Install time:** ~25 minutes  
**Disk space:** ~10GB

<details>
<summary><b>What's included</b></summary>

#### Programming Languages
- Python 3 with scientific stack
- R with tidyverse
- Julia

#### Python Data Stack
- Jupyter Lab & Notebook
- NumPy, Pandas, Matplotlib
- Scikit-learn, TensorFlow, PyTorch
- Seaborn, Plotly
- XGBoost, LightGBM

#### Data Tools
- PostgreSQL client
- SQLite
- Redis
- Apache Spark (optional)

#### Visualization
- Gnuplot
- Graphviz
- RStudio

#### Development
- VS Code with Python/R extensions
- Git & Git LFS (for large datasets)
- Docker (for reproducible environments)

</details>

**Use when:** You're doing data analysis, machine learning, or scientific computing.

---

### student
**Perfect for:** CS students, learners, educational environments  
**Install time:** ~15 minutes  
**Disk space:** ~6GB

<details>
<summary><b>What's included</b></summary>

#### Multiple Languages
- Python 3 (with IDLE and Thonny)
- C/C++ (with GCC)
- Java (OpenJDK)
- JavaScript (Node.js)
- Go

#### Educational IDEs
- VS Code (beginner-friendly)
- Code::Blocks (for C/C++)
- Thonny (Python learning)
- Scratch (visual programming)

#### Learning Tools
- Git with GUI (GitKraken/gitg)
- Vim with tutorial
- Educational shell prompt

#### CS Fundamentals
- GDB debugger
- Valgrind (memory analysis)
- Make (build automation)
- SQLite

#### Documentation
- Pandoc
- LaTeX (for papers)
- Markdown editors

</details>

**Use when:** You're learning to code, taking CS courses, or need a variety of languages for assignments.

## 🚀 Using Profiles

### Interactive Selection (Recommended)
```bash
./setup.sh
```
You'll see a menu like:
```
Please select a profile:

  1) developer-standard    - Complete development environment
  2) developer-minimal     - Essential tools only
  3) devops               - Infrastructure and cloud tools
  4) data-scientist       - ML/AI and data analysis tools
  5) student              - Educational programming environment

Enter number (1-5):
```

### Direct Profile Installation
```bash
# Install specific profile
./setup.sh --profile developer-minimal

# See what would be installed first
./setup.sh --profile devops --dry-run
```

### Command Line Options
```bash
# List all available profiles
./setup.sh --list

# Show detailed information about a profile
./setup.sh --details data-scientist

# Help
./setup.sh --help
```

## 📝 Creating Custom Profiles

### Basic Structure

Create a new YAML file in `profiles/`:

```yaml
# profiles/my-custom-profile.yaml
name: my-custom-profile
description: My personalized development setup
author: Your Name
version: 1.0.0

packages:
  # Group packages by category
  version_control:
    - git
    - git-flow
    
  languages:
    - python3
    - rust
    - golang
    
  editors:
    - vscode
    - neovim
    
  tools:
    - docker
    - terraform
    - kubectl
```

### Advanced Profile Features

```yaml
# Conditional packages (coming soon)
packages:
  base:
    - git
    - docker
  
  optional:
    gpu_tools:
      condition: has_nvidia_gpu
      packages:
        - cuda
        - nvidia-docker

# Post-install configuration
config:
  shell:
    default: zsh
    theme: powerlevel10k
    
  git:
    setup_credentials: true
    default_branch: main
    
  vscode:
    install_extensions: true
    extensions:
      - ms-python.python
      - hashicorp.terraform

# Post-install actions
post_install:
  - message: "🎉 Setup complete! Run 'source ~/.zshrc' to reload."
  - create_directories:
    - ~/projects
    - ~/documents/code
  - run_commands:
    - "git config --global init.defaultBranch main"
```

### Platform-Specific Packages

```yaml
packages:
  common:
    - git
    - curl
    
  linux:
    apt:
      - build-essential
      - libssl-dev
    snap:
      - code --classic
      - discord
      
  macos:
    brew:
      - mas  # Mac App Store CLI
      - rectangle  # Window management
    cask:
      - visual-studio-code
      - iterm2
```

## 🔍 Profile Comparison

| Feature | Standard | Minimal | DevOps | Data Science | Student |
|---------|----------|---------|---------|--------------|---------|
| **Languages** | 5+ | 2 | 3 | 3 | 6+ |
| **Install Time** | 15 min | 5 min | 20 min | 25 min | 15 min |
| **Disk Space** | 5GB | 2GB | 8GB | 10GB | 6GB |
| **IDE/Editors** | 3 | 1 | 2 | 2 | 4 |
| **Cloud Tools** | Basic | None | Full | Basic | None |
| **Containers** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Modern CLI** | ✅ | Partial | ✅ | Partial | Basic |
| **Best For** | General dev | Quick start | Infrastructure | ML/Analytics | Learning |

## 💡 Choosing the Right Profile

### Decision Tree

1. **How much time do you have?**
   - < 10 minutes → `developer-minimal`
   - No rush → Consider other profiles

2. **What's your primary focus?**
   - Web/App Development → `developer-standard`
   - Infrastructure/Cloud → `devops`
   - Data/ML → `data-scientist`
   - Learning → `student`
   - Just essentials → `developer-minimal`

3. **System resources?**
   - Limited (< 4GB RAM) → `developer-minimal` or `student`
   - Good (8GB+ RAM) → Any profile
   - Powerful (16GB+ RAM) → `data-scientist` or `devops`

### Mix and Match

You can install multiple profiles or start minimal and add more:

```bash
# Start with minimal
./setup.sh --profile developer-minimal

# Later add specific tools
./src/install/rust-cli.sh  # Add modern CLI tools
```

## 🛠️ Profile Maintenance

### Updating Profiles

Profiles are versioned and can be updated:

```bash
# Check for profile updates
git pull

# Reinstall profile to get new packages
./setup.sh --profile developer-standard --update
```

### Contributing Profiles

We welcome new profiles! Consider creating profiles for:
- Mobile development (iOS/Android)
- Game development
- Security researcher
- Content creator
- Specific language ecosystems (Ruby, PHP, etc.)

See [Contributing Guide](../CONTRIBUTING.md) for details.

## ❓ FAQ

**Q: Can I modify a profile before installing?**  
A: Yes! Copy the profile, modify it, and use your custom version:
```bash
cp profiles/developer-standard.yaml profiles/my-standard.yaml
# Edit my-standard.yaml
./setup.sh --profile my-standard
```

**Q: What if I need packages from multiple profiles?**  
A: Create a custom profile combining what you need, or install profiles sequentially.

**Q: Do profiles work on all operating systems?**  
A: Profiles define what to install; the installer adapts to your OS. Some packages may not be available on all platforms.

**Q: Can I uninstall a profile?**  
A: Not automatically yet. Package managers handle this differently. Track what you install for manual removal if needed.

**Q: How often are profiles updated?**  
A: We review profiles monthly and update for new tools, security fixes, and community feedback.

---

Profiles make it easy to get the perfect development environment. Choose one that fits, or create your own! 🚀