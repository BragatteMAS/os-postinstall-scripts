# Installation Profiles

Profiles control what gets installed. Each profile is a list of package files dispatched to platform-specific installers.

## File naming convention

| Suffix | Included in | Purpose |
|--------|-------------|---------|
| `<source>.txt` | minimal + developer + full | Base — universal essentials |
| `<source>-developer.txt` | developer + full | Dev defaults (not in minimal) |
| `<source>-full.txt` | full only | Bragatte's personal pick |

## Available Profiles

### minimal
**For:** Quick setup, essential tools only
**What it installs:** Core system packages for your platform

| Platform | Packages |
|----------|----------|
| Linux | `apt.txt` |
| macOS | `brew.txt` |
| Windows | `winget.txt` |

### developer (default)
**For:** Full development environment with curated dev defaults
**Editorial stance:** Opinionated but defensible to most devs (modern Rust CLI baseline, Firefox+Chromium, core tools)

| Platform | Packages |
|----------|----------|
| Linux | `apt.txt`, `apt-developer.txt`, `flatpak-developer.txt`, `snap-developer.txt` |
| macOS | `brew.txt`, `brew-cask-developer.txt` |
| Windows | `winget.txt` |
| Cross-platform | `npm-developer.txt`, `csv:rust-cli`, `csv:rust-dev`, `csv:rust-data` (from `data/packages.csv`) |

Also runs `src/install/dev-env.sh` (Node.js via fnm + Python via uv, mise preferred orchestrator). Rust tools resolve from `data/packages.csv` via `csv.sh`.

### full
**For:** Bragatte's personal stack — everything from developer + personal picks
**Editorial stance:** Bragatte's complete personal setup. **Don't run this if you want neutral dev defaults — use `developer` instead.** Includes specific browsers (Chrome, Zen, Brave, Opera), AI editors (Cursor, Claude, ChatGPT), and domain-specific tools.

| Platform | Packages |
|----------|----------|
| Linux | All developer + `flatpak-full.txt`, `snap-full.txt` |
| macOS | All developer + `brew-developer.txt`, `brew-full.txt`, `brew-cask-full.txt` |
| Windows | Same as developer |
| Cross-platform | All developer + `ai-tools-full.txt` |

## Usage

```bash
# Default profile (developer)
./setup.sh

# Specific profile
./setup.sh minimal
./setup.sh developer
./setup.sh full

# Preview without installing
./setup.sh --dry-run developer

# Skip prompts
./setup.sh --unattended minimal

# Verbose output
./setup.sh -v full
```

## How Profiles Work

Profiles are plain text files in `data/packages/profiles/`. Each line references a package file from `data/packages/`:

```
# data/packages/profiles/developer.txt
apt.txt
apt-developer.txt
brew.txt
brew-cask-developer.txt
winget.txt
npm-developer.txt
flatpak-developer.txt
snap-developer.txt
csv:rust-cli
csv:rust-dev
csv:rust-data
```

The platform handler (`src/platforms/linux/main.sh`, etc.) reads the profile and dispatches only the relevant package files for your OS. Linux ignores `brew.txt`, macOS ignores `apt.txt`, etc.

## Customization

Edit `config.sh` to:

- **Change default profile**: Set `DEFAULT_PROFILE`
- **Add extra packages**: Append to `EXTRA_PACKAGES=()`
- **Skip packages**: Add to `SKIP_PACKAGES=()`

### Creating a Custom Profile

Create a new `.txt` file in `data/packages/profiles/`:

```bash
# data/packages/profiles/my-profile.txt
apt.txt
csv:rust-cli
```

Then run: `./setup.sh my-profile`

## Package Lists

All package lists live in `data/packages/`. Suffix indicates profile membership:

| File | Profiles | Format | Contents |
|------|----------|--------|----------|
| `apt.txt` | min/dev/full | APT | Linux base — system utilities, core dev tools |
| `apt-developer.txt` | dev/full | APT | Linux dev extras |
| `brew.txt` | min/dev/full | Homebrew | macOS base CLI |
| `brew-developer.txt` | dev/full | Homebrew | macOS dev formulae |
| `brew-full.txt` | full only | Homebrew | macOS Bragatte personal formulae |
| `brew-cask-developer.txt` | dev/full | Homebrew Cask | macOS GUI apps (dev defaults) |
| `brew-cask-full.txt` | full only | Homebrew Cask | macOS GUI apps (Bragatte's pick) |
| `data/packages.csv` (rows with category=rust-*) | dev/full | Brew/Cargo | Rust CLI tools — installer chooses brew or cargo per `prefer` column |
| `npm-developer.txt` | dev/full | npm | Node.js global packages |
| `ai-tools-full.txt` | full only | Mixed | AI/MCP development tools |
| `flatpak-developer.txt` | dev/full | Flatpak | Linux sandboxed apps |
| `flatpak-full.txt` | full only | Flatpak | Linux flatpak full extras |
| `snap-developer.txt` | dev/full | Snap | Linux snap packages |
| `snap-full.txt` | full only | Snap | Linux snap full extras |
| `winget.txt` | min/dev/full | Winget | Windows packages |
