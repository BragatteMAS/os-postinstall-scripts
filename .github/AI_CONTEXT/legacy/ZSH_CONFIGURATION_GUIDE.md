# Advanced Zsh Configuration Guide

## Overview

This project includes a comprehensive Zsh configuration with 1700+ lines of optimizations, modern CLI tools integration, and developer-focused enhancements.

## Configuration Files

### Main Files

1. **`zshrc`** - The main configuration file
   - Complete Zsh setup with Powerlevel10k theme
   - Rust-powered CLI tools integration
   - Custom functions and aliases
   - Performance optimizations

2. **`zshrc-prd.md`** - Product Requirements Document
   - Detailed documentation of all features
   - Design decisions and rationale
   - Usage examples

3. **`zshrc_rust_integration.zsh`** - Rust tools specific configuration
   - Integration of modern CLI replacements
   - Performance benchmarks
   - Tool-specific configurations

## Key Features

### 1. Modern CLI Tools (Rust-Powered)

| Traditional | Rust Replacement | Command | Description |
|-------------|------------------|---------|-------------|
| `cat` | `bat` | `cat` (aliased) | Syntax highlighting, line numbers |
| `ls` | `eza` | `ls`, `ll`, `la` | Icons, tree view, git integration |
| `find` | `fd` | `fd` | Intuitive syntax, faster |
| `grep` | `ripgrep` | `rg` | Faster, respects .gitignore |
| `cd` | `zoxide` | `z` | Frecency-based navigation |
| `ps` | `procs` | `procs` | Tree view, more info |
| `du` | `dust` | `dust` | Intuitive visualization |
| `sed` | `sd` | `sdr` | Simpler syntax |
| `diff` | `delta` | (git integration) | Syntax highlighting for diffs |
| `top` | `bottom` | `btm` | Better UI, more features |

### 2. Oh My Zsh Integration

**Installed Plugins:**
- `git` - Git aliases and functions
- `zsh-autosuggestions` - Fish-like suggestions
- `zsh-syntax-highlighting` - Command highlighting
- `sudo` - ESC ESC to prepend sudo
- `command-not-found` - Suggest package installation
- `fzf` - Fuzzy finder integration
- `docker` - Docker completions
- `kubectl` - Kubernetes completions

**Theme:** Powerlevel10k with instant prompt

### 3. Custom Functions

#### System Management
```bash
qm              # Quick menu - interactive task selector
backup_configs  # Backup shell configurations with rotation
shell_benchmark # Test shell performance
system_update   # Update all package managers
```

#### Development
```bash
gi [template]        # Generate .gitignore files
setup_git_credentials # Configure git credential helper
dockerclean         # Clean Docker resources
k8s_debug [pod]     # Debug Kubernetes pods
```

#### Navigation
```bash
mkcd [dir]     # Make directory and cd into it
up [n]         # Go up n directories (default: 1)
extract [file] # Universal archive extractor
```

### 4. Advanced Features

#### Welcome Message
- Shows system info with neofetch
- Displays current git branch
- Lists available commands by category
- Shows active environments (conda, virtualenv)
- Indicates secure environment variables loaded

#### Environment Management
- **`.env.local`** - Secure environment variables (git-ignored)
- **`.zshrc.local`** - Local customizations
- **`.zshrc.flags`** - Feature flags for enabling/disabling features

#### Performance Optimizations
- Lazy loading for nvm, rbenv, and other tools
- Conditional loading based on tool availability
- Optimized PATH management
- Smart completion caching

### 5. Aliases

#### Git Aliases
```bash
gs   # git status
gco  # git checkout
gcm  # git commit -m
gp   # git push
gl   # git pull
glog # Pretty git log
```

#### System Aliases
```bash
update  # Update system packages
install # Install packages (auto-detects package manager)
search  # Search for packages
ports   # Show listening ports
myip    # Show public IP
```

#### Docker Aliases
```bash
dps    # docker ps with better format
dim    # docker images
dex    # docker exec -it
dlog   # docker logs -f
dstop  # Stop all containers
```

## Installation

### Quick Install
```bash
# Backup existing configuration
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)

# Copy new configuration
cp zshrc ~/.zshrc

# Install Oh My Zsh (if not installed)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Rust tools (optional but recommended)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
./install_rust_tools.sh

# Reload configuration
source ~/.zshrc
```

### Manual Installation Steps

1. **Install Zsh**
   ```bash
   sudo apt install zsh
   chsh -s $(which zsh)
   ```

2. **Install dependencies**
   ```bash
   sudo apt install git curl wget neofetch
   ```

3. **Follow quick install steps above**

## Customization

### Adding Personal Settings

Create `~/.zshrc.local`:
```bash
# Personal aliases
alias myproject="cd ~/projects/myproject"

# Personal functions
function my_custom_function() {
    echo "My custom function"
}

# Personal exports
export MY_API_KEY="secret"
```

### Enabling/Disabling Features

Create `~/.zshrc.flags`:
```bash
# Disable specific features
DISABLE_WELCOME_MESSAGE=true
DISABLE_AUTO_UPDATE=true
DISABLE_RUST_TOOLS=true
```

### Modifying Theme

Run `p10k configure` to reconfigure Powerlevel10k theme.

## Troubleshooting

### Common Issues

1. **Slow startup**
   - Run `shell_benchmark` to identify bottlenecks
   - Disable unused plugins in `.zshrc`
   - Use `.zshrc.flags` to disable features

2. **Command not found**
   - Ensure PATH is correctly set
   - Run `install_tool [toolname]` to install missing tools
   - Check if tool requires manual installation

3. **Theme issues**
   - Install required fonts (MesloLGS NF)
   - Run `p10k configure` to reconfigure
   - Check terminal emulator settings

### Performance Tips

1. **Use lazy loading** - Already implemented for heavy tools
2. **Limit plugins** - Only enable what you use
3. **Cache completions** - Automatic with Oh My Zsh
4. **Profile startup** - `zsh -xvs` to debug

## Integration with Post-Install Scripts

The Zsh configuration is automatically set up when running the Linux post-install scripts:

```bash
# The post_install.sh script will:
1. Install Zsh
2. Set as default shell
3. Copy configuration files
4. Install Oh My Zsh and plugins
5. Install Rust tools (if selected)
6. Configure Git integration
```

## Best Practices

1. **Keep `.zshrc.local` for personal settings**
2. **Use `.env.local` for sensitive data**
3. **Regular backups with `backup_configs`**
4. **Update tools periodically with `update_tools`**
5. **Document custom functions and aliases**

## Contributing

When contributing Zsh configurations:

1. Test on fresh installations
2. Document new functions/aliases
3. Consider performance impact
4. Maintain backward compatibility
5. Update this guide

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix)