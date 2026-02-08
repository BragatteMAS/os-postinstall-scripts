# Installation Profiles

Profiles control what gets installed. Each profile is a list of package files dispatched to platform-specific installers.

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
**For:** Full development environment
**What it installs:** Everything in minimal, plus dev tools, modern CLI, and AI tools

| Platform | Packages |
|----------|----------|
| Linux | `apt.txt`, `apt-post.txt`, `flatpak.txt`, `snap.txt` |
| macOS | `brew.txt`, `brew-cask.txt` |
| Windows | `winget.txt` |
| Cross-platform | `cargo.txt`, `npm.txt`, `ai-tools.txt` |

Also runs `src/install/dev-env.sh` (Node.js via fnm) and `src/install/rust-cli.sh` (bat, eza, ripgrep, etc.)

### full
**For:** Everything including post-install extras
**What it installs:** Everything in developer, plus additional Flatpak and Snap packages

| Platform | Packages |
|----------|----------|
| Linux | All from developer + `flatpak-post.txt`, `snap-post.txt` |
| macOS | Same as developer |
| Windows | Same as developer |
| Cross-platform | Same as developer |

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
apt-post.txt
brew.txt
brew-cask.txt
winget.txt
cargo.txt
npm.txt
ai-tools.txt
flatpak.txt
snap.txt
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
cargo.txt
```

Then run: `./setup.sh my-profile`

## Package Lists

All package lists live in `data/packages/`. Edit them to add or remove individual packages:

| File | Format | Contents |
|------|--------|----------|
| `apt.txt` | APT | System utilities, dev tools, desktop apps |
| `apt-post.txt` | APT | Additional system packages |
| `brew.txt` | Homebrew | macOS CLI tools |
| `brew-cask.txt` | Homebrew Cask | macOS GUI apps |
| `cargo.txt` | Cargo | Rust CLI tools (bat, eza, ripgrep, etc.) |
| `npm.txt` | npm | Node.js global packages |
| `ai-tools.txt` | Mixed | AI development tools |
| `flatpak.txt` | Flatpak | Linux sandboxed apps |
| `snap.txt` | Snap | Linux snap packages |
| `winget.txt` | Winget | Windows packages |
