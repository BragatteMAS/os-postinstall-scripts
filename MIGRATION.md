# Migration Guide

## Upgrading from Previous Version

If you're already using an older version of this zshrc configuration, follow these steps to upgrade safely:

### 1. Backup Your Current Configuration

```bash
# Create a backup directory with timestamp
mkdir -p ~/.config_backups/manual_$(date +%Y%m%d_%H%M%S)

# Backup current files
cp ~/.zshrc ~/.config_backups/manual_$(date +%Y%m%d_%H%M%S)/
cp ~/.zshenv ~/.config_backups/manual_$(date +%Y%m%d_%H%M%S)/ 2>/dev/null
cp ~/.p10k.zsh ~/.config_backups/manual_$(date +%Y%m%d_%H%M%S)/ 2>/dev/null
```

### 2. Check for Custom Modifications

Review your current `.zshrc` for any custom additions:

```bash
# Create a diff to see your customizations
diff ~/.zshrc ~/os-postinstall-scripts/zshrc
```

### 3. Install New Configuration

```bash
# Copy new zshrc
cp ~/os-postinstall-scripts/zshrc ~/.zshrc

# Remove old check file to see dependency check again
rm ~/.zshrc_checked
```

### 4. Merge Your Customizations

Add your custom configurations to the appropriate sections:

- **Custom aliases**: Add after Section 11
- **Custom functions**: Add after Section 12
- **Environment variables**: Add to `.env.local`
- **Path modifications**: Add to Section 5 (OS-specific)

### 5. Configure New Features

```bash
# Create feature flags file (optional)
cat > ~/.zshrc.flags << 'EOF'
ENABLE_WELCOME_MESSAGE=true
ENABLE_COMMAND_TRACKING=true
ENABLE_AUTO_SSH_AGENT=true
ENABLE_LAZY_LOADING=true
ENABLE_QUICK_MENU=true
EOF

# Create secure environment file
cp ~/.env.local.template ~/.env.local
chmod 600 ~/.env.local
# Edit ~/.env.local with your secrets
```

### 6. Test New Configuration

```bash
# Test in a new shell instance
zsh

# Check for errors
echo $?

# Verify your aliases still work
alias | grep "your-custom-alias"

# Test new features
zdoc  # Show documentation
qm    # Try quick menu
```

## Breaking Changes

### Renamed Commands
- `sed` alias → `sdr` (if using sd Rust tool)

### Removed Features
- Automatic "Press Enter to continue" prompts
- Screen clearing on welcome message

### New Dependencies
These are optional but recommended:
- `sd` - Modern sed replacement
- `dust` - Disk usage analyzer
- `procs` - Modern ps
- `bottom` - System monitor
- `hyperfine` - Benchmarking tool
- `lsd` - Alternative to eza
- `gitui` - Terminal UI for git

## Troubleshooting

### Shell Startup is Slow
1. Enable lazy loading: Set `ENABLE_LAZY_LOADING=true` in `.zshrc.flags`
2. Run `shell_benchmark` to identify bottlenecks
3. Disable unused features in `.zshrc.flags`

### Commands Not Found
1. Run `checktools` to see missing dependencies
2. Install recommended tools for your OS (see README.md)
3. Some commands require specific tools (e.g., `nu_open` needs nushell)

### Git Branch Not Showing
- P10k might be overriding. Run `p10k configure` to reconfigure

### Welcome Message Issues
- To disable: Set `ENABLE_WELCOME_MESSAGE=false` in `.zshrc.flags`
- To show manually: Run `welcome` or `welcomec`

### Permission Errors with .env.local
```bash
chmod 600 ~/.env.local
```

## Rollback Procedure

If you encounter issues:

```bash
# Restore from automatic backup
cp ~/.config_backups/manual_*/zshrc ~/.zshrc

# Or restore from your original backup
cp ~/.zshrc.backup ~/.zshrc

# Reload shell
source ~/.zshrc
```