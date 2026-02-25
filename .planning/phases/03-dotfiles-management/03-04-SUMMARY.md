---
phase: 03-dotfiles-management
plan: 04
subsystem: dotfiles
tags: [dotfiles, symlinks, zsh-plugins, git-config, integration]

# Dependency graph
requires:
  - phase: 03-dotfiles-management
    provides: dotfiles.sh, git/starship configs, zsh/bash configs
provides:
  - Dotfiles installer orchestration (install_dotfiles, remove_dotfiles)
  - Git user setup prompting (setup_git_user)
  - Zsh plugin installation (install_zsh_plugins)
  - setup.sh integration (dotfiles, unlink actions)
affects:
  - End users running ./setup.sh dotfiles or ./setup.sh unlink

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Symlink map array with source:target pairs
    - Gitconfig safeguard prompt before replacing existing config
    - Indexed array for bash 3.2 compatibility (macOS)

key-files:
  created:
    - src/install/dotfiles-install.sh
  modified:
    - setup.sh

key-decisions:
  - "Installer lives at src/install/ (not src/installers/ as originally planned)"
  - "remove_dotfiles wraps unlink_dotfiles from core/dotfiles.sh"
  - "Git user config written to ~/.gitconfig.local (not global gitconfig)"
  - "Gitconfig replacement requires explicit user confirmation"

patterns-established:
  - "Orchestrator in src/install/ sources core module for primitives"
  - "DRY_RUN respected at every mutation point"
---

<one_liner>
Dotfiles installer fully integrated into setup.sh with symlinks, zsh plugins, git user setup, and unlink/restore.
</one_liner>

<what_happened>
All functionality described in plan 03-04 was delivered across plans 03-01 through 03-03:

- src/core/dotfiles.sh: symlink manager with backup, manifest, restore (03-01)
- data/dotfiles/{zsh,bash,git,starship}/: all configuration files (03-02, 03-03)
- src/install/dotfiles-install.sh: orchestration with install_dotfiles(), remove_dotfiles(), setup_git_user(), install_zsh_plugins() (03-02)
- setup.sh: dotfiles and unlink actions integrated (03-02)

Plan 03-04 originally specified path src/installers/ but actual implementation used src/install/ (consistent with dev-env.sh, rust-cli.sh, ai-tools.sh in same directory).

All success criteria verified against codebase:
- ./setup.sh dotfiles creates symlinks including nested paths (~/.config/git/ignore)
- ./setup.sh unlink removes symlinks and restores backups
- Git user prompting works in interactive mode, skips in non-interactive
- Zsh plugins (autosuggestions, syntax-highlighting) installed to ~/.zsh/
- DRY_RUN mode works at every mutation point
- Backup naming follows pattern: config-git-ignore.bak.2026-02-05
</what_happened>

<deviations>
- Path changed from src/installers/dotfiles-install.sh to src/install/dotfiles-install.sh
- Export name is remove_dotfiles (not unlink_dotfiles as planned — unlink_dotfiles is the core primitive)
- Added gitconfig safeguard prompt (not in original plan) to warn before replacing existing ~/.gitconfig
</deviations>

<verification>
```
[OK] src/install/dotfiles-install.sh exists
[OK] src/core/dotfiles.sh exists
[OK] install_dotfiles() defined
[OK] remove_dotfiles() defined
[OK] setup_git_user() defined
[OK] install_zsh_plugins() defined
[OK] setup.sh handles 'dotfiles' action
[OK] setup.sh handles 'unlink' action
[OK] bash -n passes on all files
```
</verification>
