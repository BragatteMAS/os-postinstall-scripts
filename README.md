# OS Post-Install Scripts

**Two commands to turn a fresh OS into a fully configured development environment.**

<div align="center">

[![Version: 5.0.0](https://img.shields.io/badge/Version-5.0.0-orange?style=flat)](CHANGELOG.md)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat)](LICENSE)
[![Platforms: Linux | macOS | Windows](https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS%20%7C%20Windows-informational?style=flat)](README.md)
[![Shell: Bash 4.0+](https://img.shields.io/badge/Shell-Bash%204.0%2B-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![ShellCheck: compliant](https://img.shields.io/badge/ShellCheck-compliant-green?style=flat)](https://www.shellcheck.net/)

<img src="assets/terminal-screenshot.png" alt="Terminal with starship prompt, custom aliases, and modern CLI tools" width="700">

*A fully configured terminal: starship prompt, 100+ aliases, modern Rust CLI tools.*

</div>

## Why

Every fresh OS install means hours of manual setup: installing packages, configuring dotfiles, tweaking system preferences. This repo replaces that with two idempotent commands per OS. Pick a profile (`minimal`, `developer`, or `full`), run them, get back to building.

## Quick Start

### macOS / Linux

```bash
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

./bootstrap.sh         # prereqs: Homebrew + Bash 4+ on macOS, git/curl/build-essential on Linux
./setup.sh --dry-run   # preview what will be installed
./setup.sh             # install (default profile: developer)
```

### Windows

```powershell
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1   # prereqs: winget + Git
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Profile developer
```

> Don't have Git yet? `winget install Git.Git`, restart PowerShell, then clone.

> Just want a nice terminal (modern CLI tools, prompt, aliases) without the full setup? See `terminal-setup.sh` (macOS/Linux) or `examples/terminal-setup.ps1` (Windows).

## Profiles

| Feature | Minimal | Developer | Full |
|---------|:-------:|:---------:|:----:|
| System packages (apt / brew / winget) | ✓ | ✓ | ✓ |
| Dev tools + Rust CLI baseline | | ✓ | ✓ |
| GUI apps (cask / flatpak / snap) | | ✓ | ✓ |
| AI / MCP tools | | | ✓ |
| Personal preferences | | | ✓ |
| **Estimated time** | ~5 min | ~15 min | ~30 min |

```bash
./setup.sh minimal      # essentials only
./setup.sh developer    # neutral dev defaults (default)
./setup.sh full         # developer + extras (browsers, AI editors, design apps)
```

> **Note:** `full` adds opinionated personal extras (specific browsers, AI editors, design apps). If you want only neutral dev defaults without the curator's personal apps, use `developer`.

Profile details: [`docs/installation-profiles.md`](docs/installation-profiles.md).

## Modern CLI Tools

The `developer` and `full` profiles install Rust-based replacements for traditional Unix tools:

| Traditional | Modern | Why |
|-------------|--------|-----|
| `cat` | `bat` | syntax highlighting, line numbers |
| `ls` | `eza` | icons, git status, tree view |
| `find` | `fd` | intuitive syntax, respects `.gitignore` |
| `grep` | `ripgrep` (`rg`) | faster, respects `.gitignore` |
| `cd` | `zoxide` (`z`) | frequency-based smart jumping |
| `diff` | `delta` | syntax-highlighted side-by-side |

Aliases configured via `data/dotfiles/shared/aliases.sh`. Full reference: [`docs/modern-cli-tools.md`](docs/modern-cli-tools.md).

## Platform Support

| Platform | Package Managers | Architectures |
|----------|------------------|---------------|
| Ubuntu / Pop!_OS / Mint | APT, Snap, Flatpak, Cargo, npm | x86_64, arm64 |
| macOS | Homebrew, Brew Cask, Cargo, npm | Intel + Apple Silicon |
| Windows 10/11 | WinGet | x86_64 |

## Common Usage

```bash
./setup.sh --dry-run         # preview, no changes
./setup.sh -y full           # unattended full install
./setup.sh dotfiles          # symlink dotfiles only
./setup.sh unlink            # remove dotfile symlinks (restores backups)
./setup.sh defaults          # macOS system defaults (Dock, Finder, etc.)
./setup.sh drift             # report packages no longer in lists
```

| Flag | Short | Env Var | Description |
|------|-------|---------|-------------|
| `--dry-run` | `-n` | `DRY_RUN=true` | preview without installing |
| `--verbose` | `-v` | `VERBOSE=true` | debug output with timestamps |
| `--unattended` | `-y` | `UNATTENDED=true` | skip confirmation prompts |
| `--help` | `-h` | — | show help |

Customization (extra packages, custom profiles, dotfiles): [`docs/user-guide.md`](docs/user-guide.md).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `bash 3.2` too old on macOS | run `./bootstrap.sh` (or `brew install bash`) |
| `./setup.sh: Permission denied` | `chmod +x setup.sh` |
| APT lock on Linux | wait for unattended-upgrades / Software Center to finish |
| `winget: command not found` | update App Installer from Microsoft Store |
| PowerShell execution policy blocks script | use `-ExecutionPolicy Bypass` flag (shown in Quick Start) |

Full guide with 35 cataloged pitfalls: [`docs/troubleshooting.md`](docs/troubleshooting.md), [`docs/PITFALLS.md`](docs/PITFALLS.md).

## Safety

- Dry-run skips all sudo requests, network calls, and file mutations
- Existing dotfiles are backed up to `~/.dotfiles-backup/` before any symlink
- `./setup.sh unlink` restores original files from backups
- Script never deletes files outside its own backup paths

For vulnerability reports: [`SECURITY.md`](SECURITY.md).

## Documentation

| Topic | Where |
|-------|-------|
| Quick install guide | [`docs/quick-start.md`](docs/quick-start.md) |
| Complete usage | [`docs/user-guide.md`](docs/user-guide.md) |
| Troubleshooting | [`docs/troubleshooting.md`](docs/troubleshooting.md) |
| Profile details | [`docs/installation-profiles.md`](docs/installation-profiles.md) |
| Modern CLI tools | [`docs/modern-cli-tools.md`](docs/modern-cli-tools.md) |
| 35 cataloged pitfalls | [`docs/PITFALLS.md`](docs/PITFALLS.md) |
| Contributing | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Changelog | [`CHANGELOG.md`](CHANGELOG.md) |

## Credits

- Inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles), [thoughtbot/laptop](https://github.com/thoughtbot/laptop)
- Static analysis via [ShellCheck](https://www.shellcheck.net/)
- Diagrams via [Mermaid](https://mermaid.js.org/)
- Built with [Claude Code](https://claude.ai/) as co-pilot (430+ commits)

## License

Apache 2.0 — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

If this project helped you, a star helps others find it.
