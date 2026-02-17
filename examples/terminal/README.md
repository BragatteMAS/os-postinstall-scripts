# Terminal Blueprint

One-command terminal transformation: modern CLI tools, Starship prompt, shell aliases, zsh plugins, and p10k migration.

Part of [os-postinstall-scripts](https://github.com/BragatteMAS/os-postinstall-scripts).

## Quick Start

```bash
# Full install (everything)
bash setup.sh

# Interactive wizard (choose components)
bash setup.sh --interactive

# Preview changes without modifying files
bash setup.sh --dry-run

# Include Powerlevel10k migration
bash setup.sh --migrate

# Standalone p10k migration
bash migrate-p10k.sh
```

## What's Included

| Component | Description |
|-----------|-------------|
| CLI tools | bat, eza, fd, ripgrep, delta, zoxide, starship |
| Starship prompt | Minimal config with 3 curated presets |
| Nerd Font | JetBrainsMono Nerd Font (optional) |
| Shell aliases | 40+ shortcuts for git, navigation, modern tools |
| Zsh plugins | autosuggestions, syntax-highlighting, completions |
| p10k migration | Detect, backup, clean, and replace Powerlevel10k |

## Starship Presets

Three curated presets in `presets/`:

| Preset | Style | Nerd Font | Best For |
|--------|-------|-----------|----------|
| minimal | Clean, essentials only | No | Speed, compatibility |
| powerline | Colored segments with arrows | Yes | Visual richness |
| p10k-alike | Two-line, lean | No (recommended: Yes) | p10k users migrating |

**Switch preset:**

```bash
cp presets/minimal.toml ~/.config/starship.toml
```

**Customize further:** [starship.rs/config](https://starship.rs/config/)

All presets use ASCII `>` for the prompt character (cross-terminal safe).

## Migrating from Powerlevel10k

**Why migrate:** Powerlevel10k is on life support -- no new features, most bugs unfixed, and the author has moved on. Starship is actively maintained, cross-shell, and fast.

### What the script does

1. Detects p10k across 7 installation methods (oh-my-zsh, manual clone, zinit, zplug, antigen, zim, Homebrew)
2. Creates timestamped backup at `~/.p10k-backup.YYYY-MM-DD`
3. Cleans .zshrc (removes p10k source lines, instant-prompt, theme references)
4. Resets ZSH_THEME to `robbyrussell` (oh-my-zsh default)
5. Optionally offers Starship preset selection

### What it does NOT do

- Install Starship (use `brew install starship` or `curl -sS https://starship.rs/install.sh | sh`)
- Remove oh-my-zsh (only removes the p10k theme reference)
- Delete p10k files by default (use `--remove` flag for full cleanup)

### Flags

| Flag | Effect |
|------|--------|
| `--dry-run` / `-n` | Preview all changes without modifying files |
| `--remove` | Delete p10k installation directory and config files |
| `--help` / `-h` | Show usage information |

### Rollback

Backups are saved to `~/.p10k-backup.YYYY-MM-DD/` containing:
- `.zshrc` (pre-migration copy)
- `.p10k.zsh` (if it existed)
- `p10k_path.txt` (original p10k directory path)

To restore:

```bash
cp ~/.p10k-backup.YYYY-MM-DD/.zshrc ~/
cp ~/.p10k-backup.YYYY-MM-DD/.p10k.zsh ~/
```

## Before/After Comparison

```
# Before (p10k lean):
~/projects/myapp main !1 ?2                          3s
>

# After (Starship p10k-alike preset):
~/projects/myapp main !?                             3s
>
```

Key differences: slightly different git status symbols, same overall feel. Both use two-line layout with `>` character prompt.

## p10k Features Not Replicated

| Feature | Why It's OK |
|---------|-------------|
| Instant prompt | Starship is fast enough (~5ms) that the visual difference is negligible |
| Transient prompt | Not available in Starship; prompt stays visible (some prefer this) |
| Show-on-command | Starship shows modules based on directory context automatically |
| p10k configure wizard | Use preset files instead -- simpler, version-controllable |

## Standalone Usage

These scripts work independently -- download just the `examples/terminal/` directory:

```bash
# No project dependencies required
curl -LO https://github.com/BragatteMAS/os-postinstall-scripts/archive/main.tar.gz
tar xzf main.tar.gz --strip-components=2 os-postinstall-scripts-main/examples/terminal
cd terminal && bash setup.sh
```

Works on macOS (Homebrew) and Linux (apt). No CI/CD dependencies.

## Directory Structure

```
examples/terminal/
  setup.sh           # One-command terminal setup (SSoT)
  migrate-p10k.sh    # p10k to Starship migration
  README.md          # This file
  presets/
    minimal.toml     # ASCII-safe, clean prompt
    powerline.toml   # Colored segments (Nerd Font)
    p10k-alike.toml  # p10k Lean approximation
```
