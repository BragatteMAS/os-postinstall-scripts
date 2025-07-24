# 🎯 Product-Focused Git Configuration Guide

> Transform your Git workflow to maintain laser focus on product development while keeping tooling and methods properly organized but out of the way.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Commands Reference](#commands-reference)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

## Overview

The Product-Focused Git Configuration automatically structures every new Git repository to separate product code from tooling, AI agents, and project documentation. This ensures your commit history tells the story of your product, not your development process.

### Key Benefits

- **Clean Commit History**: Product commits are easily distinguishable
- **Automatic Organization**: Tooling goes to `.github/` automatically
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Zero Configuration**: Works with standard `git init`
- **Smart Hooks**: Auto-prefix tooling commits

## Quick Start

### One-Time Installation

```bash
# Clone os-postinstall-scripts
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

# Run the installer
./install_product_focused_git.sh

# Reload your shell
source ~/.zshrc  # or ~/.bashrc
```

### Create a New Project

```bash
# Option 1: Use the gnew function
gnew my-awesome-project

# Option 2: Standard git init (structure created automatically)
mkdir my-project && cd my-project
git init
```

### Check Project Health

```bash
# In any git repository
gcheck
```

## How It Works

### 1. Global Git Templates

When you run `git init`, Git copies files from a template directory. We configure this globally to include:

```
~/.config/git-templates/
├── .github/
│   ├── AI_TOOLKIT/
│   ├── PROJECT_DOCS/
│   └── METHODS/
├── .gitattributes      # Marks .github/ as generated
├── .gitignore          # Standard ignores
├── README.md           # Project template
└── hooks/              # Smart git hooks
    ├── prepare-commit-msg
    └── post-commit
```

### 2. Smart Git Hooks

#### prepare-commit-msg
- Detects commits that only touch `.github/`
- Auto-prefixes with `chore(.github):`
- Maintains conventional commit format

#### post-commit
- Shows commit statistics (product vs tooling)
- Helps maintain awareness of commit focus

### 3. Git Aliases

Product-focused aliases filter out `.github/`:

```bash
git logp      # Product commits only
git diffp     # Product changes only
git statusp   # Product files only
```

### 4. Shell Functions

Enhanced commands for project management:

```bash
gnew <name>   # Create new project with structure
ginit         # Initialize structure in existing project
gcheck        # Check project health and statistics
```

## Installation

### Automated Installation

The installer handles everything:

```bash
./install_product_focused_git.sh
```

What it does:
1. Detects your OS (Linux/macOS/Windows)
2. Installs git templates to `~/.config/git-templates`
3. Configures `git config --global init.templateDir`
4. Sets up git aliases
5. Adds shell functions to `.zshrc`/`.bashrc`

### Manual Installation

If you prefer manual setup:

```bash
# 1. Copy templates
cp -r global-git-templates ~/.config/git-templates

# 2. Configure git
git config --global init.templateDir ~/.config/git-templates

# 3. Add aliases
git config --global alias.logp "log --oneline -- ':!.github'"
git config --global alias.diffp "diff -- ':!.github'"
git config --global alias.statusp "status -- ':!.github'"

# 4. Source shell functions
cat >> ~/.zshrc << 'EOF'
# Add the shell functions from install_product_focused_git.sh
EOF
```

## Usage

### Creating Projects

#### New Project with gnew

```bash
gnew my-project
cd my-project
# Already has .github/ structure and initial commit
```

#### Standard Git Init

```bash
mkdir my-project
cd my-project
git init
# .github/ structure created automatically
```

#### Existing Project

```bash
cd existing-project
ginit
# Creates .github/ structure if missing
# Migrates old tooling (like .bmad-core)
```

### Daily Workflow

#### Commit Product Changes

```bash
# Make product changes
vim src/feature.js

# Stage and commit (normal flow)
git add src/feature.js
git commit -m "feat: add user authentication"
```

#### Commit Tooling Changes

```bash
# Update AI agents
vim .github/AI_TOOLKIT/agents/dev.md

# Stage and commit (auto-prefixed)
git add .github/
git commit -m "update development agent"
# Becomes: "chore(.github): update development agent"
```

#### View Product History

```bash
# See only product commits
git logp

# Or with more detail
git logpf

# With graph
git logpg
```

### Project Statistics

```bash
# Check project health
gcheck

# Output:
📁 Structure Check:
  ✅ AI Toolkit
  ✅ Project Docs
  ✅ Methods
  ✅ Git Attributes

📊 Commit Statistics:
  Total commits: 42
  Product commits: 38
  Tooling commits: 4
  Product focus: 90%
```

## Commands Reference

### Git Aliases

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `git logp` | `git log --oneline -- ':!.github'` | Product commits only |
| `git diffp` | `git diff -- ':!.github'` | Product changes only |
| `git statusp` | `git status -- ':!.github'` | Product files only |
| `git showp` | `git show -- ':!.github'` | Show product changes |
| `git addp` | `git add -- ':!.github'` | Stage product files |
| `git logpf` | `git log --pretty=format:...` | Formatted product log |
| `git logpg` | `git log --graph ...` | Product commit graph |
| `git countp` | `git rev-list --count HEAD -- ':!.github'` | Count product commits |
| `git contributorsp` | `git shortlog -sn -- ':!.github'` | Product contributors |

### Shell Functions

| Function | Description | Example |
|----------|-------------|---------|
| `gnew` | Create new project with structure | `gnew my-app` |
| `ginit` | Initialize structure in current directory | `ginit` |
| `gcheck` | Check project structure and stats | `gcheck` |

### Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git statusp` | Quick product status |
| `gl` | `git logp` | Quick product log |
| `gd` | `git diffp` | Quick product diff |

## Customization

### Modify Templates

Edit files in `~/.config/git-templates/`:

```bash
# Edit the README template
vim ~/.config/git-templates/README.md

# Add custom git hooks
vim ~/.config/git-templates/hooks/pre-push

# Modify .gitignore
vim ~/.config/git-templates/.gitignore
```

### Add Custom Aliases

```bash
# Add more product-focused aliases
git config --global alias.blamep "blame -- ':!.github'"
git config --global alias.greppr "grep --cached -- ':!.github'"
```

### Customize Shell Functions

Edit your `.zshrc` or `.bashrc` to modify the functions:

```bash
# Add custom project initialization
gnew() {
    # ... existing code ...
    
    # Add your customizations
    npm init -y
    echo "node_modules/" >> .gitignore
}
```

## Troubleshooting

### Templates Not Applied

```bash
# Check template directory is set
git config --global init.templateDir

# Should output: ~/.config/git-templates
```

### Hooks Not Running

```bash
# Check hooks are executable
ls -la ~/.config/git-templates/hooks/

# Fix permissions
chmod +x ~/.config/git-templates/hooks/*
```

### Functions Not Available

```bash
# Reload shell configuration
source ~/.zshrc  # or ~/.bashrc

# Check if functions exist
type gnew
```

### Windows-Specific Issues

On Windows (Git Bash):
- Ensure you're using Git Bash, not CMD
- Paths use forward slashes: `C:/Users/name/.config`
- Home directory is usually `/c/Users/YourName`

## Advanced Usage

### CI/CD Integration

Add to your GitHub Actions:

```yaml
- name: Check commit focus
  run: |
    # Ensure product commits don't touch .github/
    git log --oneline ${{ github.event.before }}..${{ github.sha }} --name-only | 
    grep -E "^[a-f0-9]+ (feat|fix|perf):" | 
    xargs -I {} sh -c 'git show --name-only {} | grep -q "^\.github/" && exit 1 || exit 0'
```

### Team Adoption

Share the configuration:

```bash
# Export your setup
tar -czf product-focused-git.tar.gz ~/.config/git-templates

# Team members import
tar -xzf product-focused-git.tar.gz -C ~/
git config --global init.templateDir ~/.config/git-templates
```

### Integration with BMAD/AI Tools

The structure is designed to work with:
- BMAD Method (goes to `.github/AI_TOOLKIT/`)
- Claude commands (in `.github/AI_TOOLKIT/commands/`)
- Any AI/tooling framework

## Best Practices

1. **Commit Atomically**: One logical change per commit
2. **Use Conventional Commits**: `feat:`, `fix:`, `docs:`, etc.
3. **Review Before Push**: Use `git logp` to review product commits
4. **Document in .github/**: Keep all tooling docs there
5. **Regular Health Checks**: Run `gcheck` weekly

---

> 💡 **Remember**: The goal is a commit history that reads like a changelog, focused entirely on what matters to your users - the product itself.
>
> **Built with ❤️ by Bragatte, M.A.S**