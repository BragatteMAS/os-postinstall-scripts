# External Integrations

**Analysis Date:** 2026-02-08

## APIs & External Services

**Package Installation:**
- Rustup - Rust installer via `https://sh.rustup.rs`
  - Files: `src/install/rust-cli.sh`
  - Purpose: Automated Rust language and cargo installation

- UV (Python package manager) - Astral installer via `https://astral.sh/uv/install.sh`
  - Files: `src/install/uv.sh`
  - Purpose: Python package management

- Cargo-binstall - Binary installer via GitHub
  - Files: `src/install/rust-cli.sh`
  - Purpose: Fast binary installation for Rust tools

- Homebrew - macOS package manager
  - Files: `src/platforms/macos/install/homebrew.sh`
  - Purpose: Package installation on macOS

**Repository Access:**
- GitHub API (implicit via Git and GitHub CLI)
  - Purpose: Repository management, cloning, authentication

## Data Storage

**Databases:**
- None - Installation state tracked via system state only

**File Storage:**
- Local filesystem only
  - Shell profiles: `$HOME/.zshrc`, `$HOME/.bashrc`
  - Dotfiles: Symlinked from `data/dotfiles/` to `$HOME`

**Caching:**
- None - Direct package manager access on each install

## Authentication & Identity

- Git credentials: Standard `~/.ssh/` or `~/.git-credentials`
- GitHub CLI token: `~/.config/gh/config.yml`
- No API keys or external auth providers

## CI/CD & Deployment

**Hosting:**
- GitHub: `https://github.com/BragatteMAS/os-postinstall-scripts`

**CI Pipeline:**
- Workflows removed; manual testing only
- ShellCheck linting via local execution

## Environment Configuration

**Required env vars:**
- `DRY_RUN` - Simulate operations without execution
- `VERBOSE` - Enable verbose logging

**Optional env vars:**
- `PROFILE` - Installation profile selection (minimal, developer, full)

---

*Integration audit: 2026-02-08*
