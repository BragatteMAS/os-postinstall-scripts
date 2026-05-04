# Quick Start

> The README has the 5-step install. This guide adds: **how to choose a profile**, **what runs under the hood**, and **what to do after install**.

## Two-step install (any OS)

```bash
git clone https://github.com/BragatteMAS/os-postinstall-scripts && cd os-postinstall-scripts
./bootstrap.sh                # macOS/Linux: prereqs (Homebrew, Bash 4+, build-essential)
./setup.sh --dry-run          # preview
./setup.sh                    # install (default: developer)
```

Windows uses `bootstrap.ps1` + `setup.ps1` — see [README §Quick Start](../README.md#quick-start).

## Choosing a profile

| If you... | Pick |
|-----------|------|
| Want only the modern Rust CLI baseline (`bat`, `eza`, `rg`, `fd`, `zoxide`, `delta` + 14 more) | `minimal` (~5 min, ~20 packages) |
| Want a neutral dev environment — VS Code, Sublime, Docker/OrbStack, browsers (Firefox/Chromium), Rust dev tools, GUI apps defensible to most devs | `developer` (~15 min, ~79 packages on macOS) |
| Want everything including the curator's personal pick — Chrome/Zen/Brave, Cursor, Claude Desktop, ChatGPT, Affinity, CapCut, AI/MCP tools | `full` (~30 min, ~181 packages on macOS) |

```bash
./setup.sh minimal
./setup.sh developer    # default if no arg
./setup.sh full
```

Per-package details: [`installation-profiles.md`](installation-profiles.md). The package count shown in your completion summary is computed from the actual lists in `data/packages/`.

## What `bootstrap` and `setup` actually do

**`bootstrap.{sh,ps1}`** — runs once per machine. Verifies and installs:

- macOS: Xcode CLT, Homebrew, Bash 4+ (system Bash is 3.2 — too old), git submodules
- Linux (Debian/Ubuntu/Pop!_OS/Mint): git, curl, build-essential, ca-certificates via apt
- Windows: winget verification, Git via winget

After bootstrap, all the tooling `setup` expects is present.

**`setup.{sh,ps1}`** — driven by `data/packages/profiles/<profile>.txt`, dispatches to:

1. Platform-specific installers (apt / brew / brew-cask / winget / flatpak / snap)
2. Cross-platform Rust CLI tools via `data/packages.csv` (`csv:rust-cli`, `csv:rust-dev`, etc.)
3. AI tools (only in `full`): Claude Code, Codex, Gemini CLI, Ollama
4. Dev environment: mise + fnm + uv (interactive: skip what you don't want)
5. macOS system defaults (only on macOS, only `developer`/`full`)
6. Post-install hooks in `data/hooks/`

Idempotent at every step — re-running skips already-installed packages.

## After install

```bash
exec zsh -l         # reload shell to pick up aliases/functions
h                   # show help reference (alias defined by dotfiles)
h rust-cli          # list installed Rust CLI tools
h ai                # list installed AI tools (full profile only)
mcpl list           # list configured MCP servers (full profile only)
```

The first `exec zsh -l` is required to load aliases configured by the dotfiles step.

## Common follow-ups

| Task | Command |
|------|---------|
| Re-run safely (idempotent) | `./setup.sh` (any profile) |
| Apply only the dotfiles | `./setup.sh dotfiles` |
| Roll back dotfile symlinks | `./setup.sh unlink` |
| Apply macOS system defaults only | `./setup.sh defaults` (macOS) |
| Restore macOS defaults from backup | `./setup.sh defaults-restore` (macOS) |
| Detect packages no longer in lists | `./setup.sh drift` |

## Need only a nice terminal (no full setup)?

**macOS / Linux:**
```bash
git clone https://github.com/BragatteMAS/os-postinstall-scripts
bash os-postinstall-scripts/terminal-setup.sh --interactive
```

**Windows:**
```powershell
git clone https://github.com/BragatteMAS/os-postinstall-scripts
powershell -ExecutionPolicy Bypass -File os-postinstall-scripts\examples\terminal-setup.ps1
```

Installs Nerd Font + modern CLI tools (bat/eza/fd/rg/zoxide/starship) + zsh plugins + aliases (Bash/zsh on macOS/Linux; PowerShell + WinGet on Windows). ~3 min. No system defaults, no GUI apps, no AI tools.

## Stuck?

- Common issues: [`troubleshooting.md`](troubleshooting.md)
- 35 cataloged pitfalls with workarounds: [`PITFALLS.md`](PITFALLS.md)
- Open an issue: [github.com/BragatteMAS/os-postinstall-scripts/issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
