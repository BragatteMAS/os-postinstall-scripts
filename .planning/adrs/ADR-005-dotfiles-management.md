# ADR-005: Symlink-Based Dotfiles Management

**Status:** Accepted
**Date:** 2026-02-05
**Phases:** 03

## Context

Dotfiles (`.zshrc`, `.gitconfig`, `.bashrc`, etc.) need to be managed across machines and updates. The project stores canonical versions in `data/dotfiles/` and must deploy them to `$HOME`. The deployment strategy must handle existing user configurations (don't destroy customizations), support updates (changes in repo reflected immediately), and allow rollback.

## Decision

Symlink-based management with automatic backup:

- Dotfile sources organized by topic: `data/dotfiles/{zsh,bash,git,starship,shared}/`
- `symlink_map` array in `dotfiles-install.sh` defines source-to-target mappings
- Before creating a symlink, existing files (non-symlinks) are backed up
- Flat backup naming: `~/.config/git/ignore` becomes `config-git-ignore.bak.2026-02-05` in `~/.dotfiles-backup/`
- Manifest file (`backup-manifest.txt`) tracks every backup with timestamps
- `./setup.sh unlink` removes symlinks and restores from backups
- Local overrides via `~/.zshrc.local` and `~/.bashrc.local` (sourced last, never managed)
- Git user identity separated into `~/.gitconfig.local` (created interactively, never committed)

## Alternatives Considered

### GNU Stow
- **Pros:** Battle-tested, handles nested directory structures, automatic conflict detection
- **Cons:** External dependency (not available on fresh OS without package manager). Stow's directory-mirroring model doesn't match the topic-centric layout. Backup/restore not built in. One more tool to explain to contributors

### chezmoi
- **Pros:** Templates, secrets management, cross-machine sync, encryption support
- **Cons:** Go binary dependency. Significant learning curve (templates, `.chezmoiignore`, state database). Overkill for 5 dotfiles. Violates KISS principle

### Git bare repo (`$HOME` as work tree)
- **Pros:** No symlinks, files are "real" in $HOME. Pure git operations for sync
- **Cons:** Dangerous (entire $HOME is a git repo, accidental `git clean` destroys files). Complex setup (`--bare`, `--work-tree=$HOME`, custom alias). Confusing for contributors. No backup/restore story

### Direct copy
- **Pros:** Simplest possible approach, no symlink knowledge needed
- **Cons:** Updates require re-running the copy. Changes in repo are not reflected until next run. Two copies of each file exist (repo + $HOME), violating SSoT. No way to distinguish user edits from managed content

## Recommendation

Symlinks are the sweet spot: changes in the repo are immediately reflected (SSoT), the backup system protects user customizations, and `unlink` provides clean rollback. The local override pattern (`~/.zshrc.local`) lets users extend without touching managed files.

## Consequences

- **Positive:** True SSoT -- edit in repo, see in shell immediately. Backup protects user data. Unlink provides clean removal. Local overrides allow customization without conflicts. Manifest enables auditing.
- **Negative:** Symlinks confuse some editors (follow-symlink behavior varies). Some tools don't handle symlinked configs well. Flat backup naming loses directory hierarchy (mitigated by manifest). Backup accumulates over time (no auto-cleanup).
