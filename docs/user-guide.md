# User Guide

Complete reference for daily use after the first install. For getting started, see [`quick-start.md`](quick-start.md).

## Contents

1. [Overview](#overview)
2. [Install methods](#install-methods)
3. [Profiles](#profiles)
4. [macOS system defaults](#macos-system-defaults)
5. [Dotfiles](#dotfiles)
6. [Drift detection](#drift-detection)
7. [Post-install hooks](#post-install-hooks)
8. [Customization](#customization)
9. [Maintenance](#maintenance)
10. [Troubleshooting](#troubleshooting)

## Overview

A cross-platform post-install toolkit that turns a fresh OS into a development environment. Two-step flow: `bootstrap.{sh,ps1}` installs prereqs, `setup.{sh,ps1}` runs the chosen profile.

### Key features

- **Two-command setup**: `./bootstrap.sh && ./setup.sh` (mirrored on Windows with `.ps1`)
- **Profile-based**: `minimal` / `developer` / `full` driven by plain text package lists
- **Cross-platform**: Linux (apt + flatpak + snap), macOS (Homebrew + Cask), Windows 10/11 (WinGet)
- **Modern CLI baseline**: Rust replacements for `cat`/`ls`/`find`/`grep`/`cd`/`diff` via `data/packages.csv`
- **Idempotent**: safe to re-run; skips already-installed packages
- **Dry-run**: `--dry-run` previews everything without changes
- **Backup-aware**: dotfiles backed up before any symlink

### Supported platforms

| OS | Package managers | Architectures |
|----|------------------|---------------|
| Ubuntu / Pop!_OS / Linux Mint (Debian-based) | APT, Snap, Flatpak, Cargo, npm | x86_64, arm64 |
| macOS 12+ | Homebrew, Brew Cask, Cargo, npm | Intel + Apple Silicon |
| Windows 10/11 | WinGet | x86_64 |

WSL2 is supported via the Linux path; native Windows via `setup.ps1`.

## Install methods

### Profile-based (recommended)

```bash
./bootstrap.sh           # one time per machine
./setup.sh --dry-run     # preview
./setup.sh developer     # install
```

The profile arg is positional. Without it, the default `developer` runs.

### Single sub-action (no full profile)

`setup.sh` accepts named actions for partial workflows:

```bash
./setup.sh dotfiles            # only symlink dotfiles
./setup.sh unlink              # remove dotfile symlinks (restore backups)
./setup.sh defaults            # apply macOS system defaults (macOS only)
./setup.sh defaults-restore    # restore macOS defaults from backup
./setup.sh drift               # detect installed-but-not-listed packages
```

### Direct installer (advanced)

For surgical use, sub-installers can be invoked directly. They source `config.sh` themselves:

```bash
bash src/install/dev-env.sh    # mise + fnm + uv (interactive: skip what you don't want)
bash src/install/ai-tools.sh   # Claude Code, Codex, Gemini CLI, Ollama (full profile only)
bash src/install/uv.sh         # Just Python via uv
```

## Profiles

| Profile | Time | Packages (macOS) | Use when |
|---------|------|------------------|----------|
| `minimal` | ~5 min | ~20 | want only the Rust CLI baseline |
| `developer` (default) | ~15 min | ~79 | want a neutral dev env defensible to most devs |
| `full` | ~30 min | ~181 | want everything including curator's personal pick (browsers, AI editors, design apps) |

Per-package details: [`installation-profiles.md`](installation-profiles.md).

## macOS system defaults

Declarative system preferences (Dock, Finder, keyboard, trackpad, screenshots, security) — 34 settings defined in `data/defaults/macos-defaults.txt`.

```bash
./setup.sh --dry-run defaults    # preview
./setup.sh defaults              # apply
./setup.sh defaults-restore      # restore from backup
```

File format is pipe-delimited:
```
domain|key|type|value
NSGlobalDomain|AppleShowAllExtensions|bool|true
```

Backups are saved to `~/.config/os-postinstall/defaults-backup-*.txt` before applying. Restore reads the most recent.

## Dotfiles

Symlink-based with automatic backup before overwriting:

```bash
./setup.sh dotfiles    # install symlinks (backups go to ~/.dotfiles-backup/)
./setup.sh unlink      # restore originals from backups
```

Managed paths:

| Source | Target |
|--------|--------|
| `data/dotfiles/zsh/zshrc` | `~/.zshrc` |
| `data/dotfiles/bash/bashrc` | `~/.bashrc` |
| `data/dotfiles/git/gitconfig` | `~/.gitconfig` |
| `data/dotfiles/git/gitignore` | `~/.config/git/ignore` |
| `data/dotfiles/starship/starship.toml` | `~/.config/starship.toml` |

Git user identity (`user.name`, `user.email`) is collected interactively and stored in `~/.gitconfig.local` (sourced by the repo-managed `~/.gitconfig`), so the shared config stays generic.

## Drift detection

Compare currently installed packages against `data/packages/*.txt` lists:

```bash
./setup.sh drift
```

Reads state from `~/.config/os-postinstall/package-state.txt`. **Warn-only** — never auto-removes anything.

## Post-install hooks

Custom shell scripts in `data/hooks/` run after `setup.sh` completes. Filenames control ordering and platform:

- `90-macos-restart-dock.sh` — `90-` orders execution; `-macos-` filters to macOS only
- `91-macos-restart-finder.sh` — runs after `90-` on macOS

Naming pattern: `<NN>-<os>?-<name>.sh`. Linux markers: `-linux-`. No marker = all platforms.

## Customization

### Add packages without forking

Edit `data/packages/<source>.txt` (one package per line, `#` for comments):

```bash
# data/packages/apt.txt
my-custom-package
```

Then re-run `./setup.sh` (idempotent — skips already-installed).

### Custom profile

```bash
# data/packages/profiles/myprofile.txt
apt.txt
brew.txt
csv:rust-cli
```

Run `./setup.sh myprofile`.

### EXTRA_PACKAGES / SKIP_PACKAGES (config.sh)

Two arrays in `config.sh` for per-run overrides without editing package files:

```bash
EXTRA_PACKAGES=(neovim tmux) ./setup.sh
SKIP_PACKAGES=(snapd kite) ./setup.sh
EXTRA_PACKAGES=(neovim) SKIP_PACKAGES=(snapd) ./setup.sh
```

### Add a new dotfile to manage

1. Place file in `data/dotfiles/<topic>/`
2. Add mapping in `src/install/dotfiles-install.sh` (see `symlink_map` array)
3. Run `./setup.sh dotfiles`

## Maintenance

### Update the toolkit

```bash
git pull
git describe --tags    # current version
cat CHANGELOG.md       # what changed
```

### Re-run after package list changes

After editing `data/packages/*.txt` upstream:

```bash
./setup.sh             # idempotent — installs additions, skips existing
./setup.sh drift       # see what's now in your system that isn't listed
```

## Troubleshooting

- Top 5 issues: [`README.md` §Troubleshooting](../README.md#troubleshooting)
- Full guide: [`troubleshooting.md`](troubleshooting.md)
- 35 cataloged pitfalls: [`PITFALLS.md`](PITFALLS.md)

## Resources

- GitHub: [github.com/BragatteMAS/os-postinstall-scripts](https://github.com/BragatteMAS/os-postinstall-scripts)
- Issues / feature requests: [github.com/BragatteMAS/os-postinstall-scripts/issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- License: Apache 2.0 — [`LICENSE`](../LICENSE)
- Changelog: [`CHANGELOG.md`](../CHANGELOG.md)
