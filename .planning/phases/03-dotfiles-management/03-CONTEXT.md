# Phase 3: Dotfiles Management - Context

**Gathered:** 2026-02-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement topic-centric dotfiles system with safe symlink management. Creates symlinks in $HOME for configs in data/dotfiles/, backs up existing configs, configures shell (zsh/bash), and git configuration.

NOT in scope: package installation (Phase 4/5), advanced shell frameworks (oh-my-zsh), GPG signing.

</domain>

<decisions>
## Implementation Decisions

### Symlink Strategy
- Symlinks created directly in $HOME (not ~/.config/ subdirs)
- Paths are absolute (not relative)
- Existing non-symlink files: backup automatically, then replace
- Existing symlinks: replace without backup (assumed from previous setup)
- Include `setup.sh unlink` command that removes symlinks and restores backups

### Backup Behavior
- Location: ~/.dotfiles-backup/
- Structure: flat with path prefix (e.g., config-git-config.bak.2026-02-05)
- Multiple backups: keep all with timestamps (no auto-cleanup)
- Manifest file: backup-manifest.txt listing original -> backup mappings
- On backup failure: abort entire operation (don't create partial symlinks)
- Permissions: preserve original (cp -p)
- DRY_RUN=true respected for dotfiles operations
- Backup dir created automatically if missing
- No compression (files are small, easier to inspect)
- Summary shown at end: "Backed up: ~/.zshrc -> ~/.dotfiles-backup/zshrc.bak.2026-02-05"

### Shell Configuration
- Priority: zsh first, bash as fallback
- Structure: modular (zshrc sources: path.sh, aliases.sh, functions.sh, prompt.sh)
- Shared configs: data/dotfiles/shared/ for cross-shell compatible files (aliases, path)
- Shell-specific: data/dotfiles/zsh/, data/dotfiles/bash/
- Framework: none by default (KISS), but interactive menu offers:
  - "Do you want a shell framework?" -> zinit / none
  - Essencial plugins: zsh-autosuggestions + zsh-syntax-highlighting
  - Optional plugins available via menu
- Plugin installation: git clone to ~/.zsh/
- Prompt: Starship (cross-shell, actively maintained)
  - Install via package manager (brew/cargo)
  - Config: ~/.config/starship.toml (symlink from data/dotfiles/starship/)
  - Include minimal starship.toml preset
- History: separate per shell (.zsh_history, .bash_history)
  - HISTSIZE=50000, SAVEHIST=50000
  - Ignore consecutive duplicates
  - Share between zsh sessions (SHARE_HISTORY)
  - Extended history with timestamps
- PATH management: dedicated path.sh file, duplicate prevention
- Autocompletions: detect installed tools, load completions dynamically
- fzf integration: if installed, source fzf.zsh
- Source order: fixed (1.path 2.env 3.aliases 4.functions 5.plugins 6.prompt)
- Local overrides: source ~/.zshrc.local if exists

### Git Configuration
- Structure: gitconfig + gitconfig.local (include pattern)
- User-specific values: prompt during installation, store in gitconfig.local
- Aliases: essential only (st, co, br, cm, lg, last)
- Default branch: main
- Pull/push defaults: Claude decides sensible values

### Claude's Discretion
- Exact env vars (EDITOR, PAGER, LANG defaults)
- Key bindings (use zsh defaults)
- Pull/push git config values
- Loading skeleton for completions
- Starship.toml specific modules enabled

</decisions>

<specifics>
## Specific Ideas

- Starship chosen over p10k because p10k is on "life support" (maintainer stopped)
- Essential plugins only by default, but offer menu for more (zsh-completions, history-substring-search, fzf-tab)
- "Detectar + perguntar" flow for new users: detect installed shell, ask preferences
- Avoid over-engineering: simple patterns, Claude fills implementation details

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 03-dotfiles-management*
*Context gathered: 2026-02-05*
