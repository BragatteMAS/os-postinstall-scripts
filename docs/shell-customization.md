# 🎨 Shell Customization Guide

This guide will help you customize your shell environment after running the OS Post-Install Scripts. We provide a powerful 1700+ line `.zshrc` configuration that supercharges your terminal experience.

## 📋 Table of Contents

- [Overview](#overview)
- [Zsh Configuration](#zsh-configuration)
- [Starship Prompt](#starship-prompt)
- [Aliases & Functions](#aliases--functions)
- [Plugins & Extensions](#plugins--extensions)
- [Themes & Colors](#themes--colors)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

## 🌟 Overview

Our shell configuration includes:
- **Oh My Zsh** framework
- **Starship** prompt for beautiful, informative prompts
- **1700+ lines** of optimizations and utilities
- **100+ aliases** for common tasks
- **Smart completions** for commands and paths
- **Git integration** with status in prompt
- **Directory jumping** with zoxide
- **Syntax highlighting** as you type

## 🐚 Zsh Configuration

### Installation Status

After running our scripts, check your setup:

```bash
# Check current shell
echo $SHELL  # Should show /usr/bin/zsh or /bin/zsh

# Check Oh My Zsh installation
ls -la ~/.oh-my-zsh

# Check if using our config
grep "OS Post-Install Scripts" ~/.zshrc
```

### Key Features in Our .zshrc

#### 1. Smart Directory Navigation
```bash
# Jump to any directory you've visited
z project    # Jumps to ~/Documents/GitHub/project
z dow        # Jumps to ~/Downloads

# Create and enter directory
mkcd new-project  # Creates and enters ./new-project

# Go up multiple directories
...    # Same as cd ../..
....   # Same as cd ../../..
```

#### 2. Enhanced Git Commands
```bash
# Quick git operations
gs     # git status
ga     # git add
gc     # git commit
gp     # git push
gl     # git log --oneline --graph
gd     # git diff

# Advanced git aliases
gclean # Remove merged branches
gundo  # Undo last commit (keep changes)
gstash # Interactive stash manager
```

#### 3. File Operations
```bash
# Safe file operations
cp -i  # Always ask before overwriting
mv -i  # Always ask before overwriting
rm -I  # Ask before removing multiple files

# Quick extraction
extract file.tar.gz  # Automatically detects format
extract file.zip
extract file.7z
```

#### 4. Development Shortcuts
```bash
# Python virtual environments
mkvenv          # Create venv in current directory
activate        # Activate venv in current directory

# Node.js helpers
nrs             # npm run start
nrb             # npm run build
nrt             # npm run test

# Docker shortcuts
dps             # docker ps with nice formatting
dex <container> # Execute bash in container
dlog <container> # Follow container logs
```

## ⭐ Starship Prompt

### Default Configuration

Our Starship configuration shows:
- Current directory with smart truncation
- Git branch and status
- Programming language versions when in project
- Command duration for long operations
- Exit code when commands fail

### Customizing Starship

Edit `~/.config/starship.toml`:

```toml
# Minimal prompt
format = """
$directory$git_branch$git_status$character
"""

# Or highly detailed
format = """
$username$hostname$kubernetes$directory
$git_branch$git_status$git_metrics
$python$rust$nodejs$golang
$cmd_duration$status$character
"""
```

Popular customizations:

```toml
# Show command duration for commands over 3 seconds
[cmd_duration]
min_time = 3000
format = "took [$duration]($style) "

# Customize directory display
[directory]
truncation_length = 3
truncate_to_repo = true

# Show Python virtual env
[python]
format = 'via [${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

# Custom symbols
[git_branch]
symbol = "🌱 "

[rust]
symbol = "🦀 "
```

## 🚀 Aliases & Functions

### Most Useful Aliases

#### System Management
```bash
# Update system
update     # Update package lists
upgrade    # Upgrade all packages
cleanup    # Clean package cache

# System info
sysinfo    # Display system information
ports      # Show listening ports
myip       # Show public IP
localip    # Show local IP
```

#### File Management
```bash
# Enhanced ls
ll         # Detailed list with icons
la         # Include hidden files
lt         # Sort by modification time
lsize      # Sort by size

# Quick navigation
..         # Go up one directory
...        # Go up two directories
~          # Go to home
-          # Go to previous directory
```

#### Development
```bash
# Quick edits
zshrc      # Edit ~/.zshrc
bashrc     # Edit ~/.bashrc
hosts      # Edit /etc/hosts (with sudo)

# Project templates
mkproject <type>  # Create project structure
# Types: python, node, rust, go
```

### Custom Functions

Add your own functions to `~/.zshrc_custom`:

```bash
# Weather in terminal
weather() {
    curl "wttr.in/${1:-YourCity}"
}

# Cheat sheet
cheat() {
    curl "cheat.sh/$1"
}

# Create backup
backup() {
    cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

# Find and replace in directory
replace_all() {
    fd -t f -e "$3" -x sd "$1" "$2" {}
}
```

## 🔌 Plugins & Extensions

### Enabled Oh My Zsh Plugins

Our configuration includes:
- `git` - Git aliases and functions
- `docker` - Docker completions
- `docker-compose` - Docker Compose completions
- `pip` - Python pip completions
- `npm` - npm completions
- `sudo` - Press ESC twice to add sudo
- `history` - Better history management
- `fzf` - Fuzzy finder integration

### Recommended Additional Plugins

```bash
# Edit ~/.zshrc and add to plugins=()
plugins=(
    git
    docker
    zsh-autosuggestions    # Fish-like suggestions
    zsh-syntax-highlighting # Syntax highlighting
    autojump               # Another j command
    kubectl                # Kubernetes shortcuts
    terraform              # Terraform completions
)
```

Install additional plugins:
```bash
# Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## 🎨 Themes & Colors

### Terminal Colors

Our scripts configure:
- 256 color support
- True color (24-bit) when available
- Optimized color schemes for readability

### Customizing Colors

#### For ls/eza
```bash
# Edit ~/.config/eza/theme.yml
# Or use dircolors
eval "$(dircolors -b ~/.dircolors)"
```

#### For terminal emulator
Popular color schemes:
- Dracula
- Nord
- Solarized
- Tokyo Night
- Catppuccin

Apply in your terminal preferences, not shell config.

## ⚡ Performance Tips

### Speed Up Shell Startup

1. **Profile your startup**
```bash
# See what's slow
zsh -xv 2>&1 | ts -i "%.s" > zsh_startup.log

# Or use built-in profiling
zprof  # Add 'zmodload zsh/zprof' at start of .zshrc
```

2. **Common optimizations**
```bash
# Lazy load nvm
export NVM_LAZY_LOAD=true

# Skip Oh My Zsh auto-update prompt
DISABLE_UPDATE_PROMPT=true

# Use faster git status checking
DISABLE_UNTRACKED_FILES_DIRTY=true
```

3. **Conditional loading**
```bash
# Only load work stuff on work machine
if [[ "$(hostname)" == *"work"* ]]; then
    source ~/.work_config
fi
```

### Optimize Heavy Commands

```bash
# Cache expensive commands
if [[ ! -f ~/.cache/aws_completion ]]; then
    aws_completer > ~/.cache/aws_completion
fi
source ~/.cache/aws_completion
```

## 🔧 Troubleshooting

### Common Issues

#### "Command not found" after installation
```bash
# Reload configuration
source ~/.zshrc

# Or start new shell
exec zsh
```

#### Slow shell startup
```bash
# Disable problematic plugins temporarily
# Comment out in ~/.zshrc:
# plugins=(... slow-plugin ...)

# Or skip Oh My Zsh
zsh --no-rcs  # Start without RC files
```

#### Broken prompt/characters
```bash
# Install powerline fonts
sudo apt install fonts-powerline  # Ubuntu/Debian

# Or use Nerd Fonts
# Download from: https://www.nerdfonts.com/
```

#### Conflicts with existing configuration
```bash
# Our installer creates backups
ls -la ~/.*.pre-postinstall

# Restore if needed
mv ~/.zshrc.pre-postinstall ~/.zshrc
```

### Reset to Defaults

```bash
# Complete reset
rm -rf ~/.oh-my-zsh
rm ~/.zshrc
# Run installer again
```

## 💡 Advanced Customization

### Per-Project Shell Configuration

Create `.envrc` in project roots:
```bash
# Python project
source venv/bin/activate
export PYTHONPATH="${PWD}/src:${PYTHONPATH}"

# Node project  
export PATH="${PWD}/node_modules/.bin:${PATH}"

# Use direnv to auto-load
# Install: sudo apt install direnv
# Add to ~/.zshrc: eval "$(direnv hook zsh)"
```

### Custom Prompt Segments

Add to `~/.config/starship.toml`:
```toml
# Show terraform workspace
[terraform]
format = "[🏗️ $workspace]($style) "

# Custom command
[custom.vpn]
command = "echo 🔒"
when = "pgrep -x openvpn"

# Show TODO count
[custom.todos]
command = "rg -c TODO | wc -l"
when = "rg -q TODO"
format = "[📝 $output]($style) "
```

### Integration with Tools

#### fzf (Fuzzy Finder)
```bash
# Keybindings (already configured)
# Ctrl+R - Search history
# Ctrl+T - Search files
# Alt+C  - Search directories

# Custom fzf commands
# Find and edit
fe() {
    local file
    file=$(fzf --preview 'bat --color=always {}')
    [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}
```

#### tmux Integration
```bash
# Auto-attach to session
if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
    tmux attach-session -t main || tmux new-session -s main
fi
```

## 📚 Resources

- [Oh My Zsh Documentation](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Starship Documentation](https://starship.rs/config/)
- [Zsh User Guide](https://zsh.sourceforge.io/Guide/)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)

---

Remember: Your shell is your home. Make it comfortable! 🏠