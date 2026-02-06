# Phase 3: Dotfiles Management - Research

**Researched:** 2026-02-05
**Domain:** Shell configuration, symlink management, dotfiles
**Confidence:** HIGH

## Summary

This phase implements a topic-centric dotfiles system with safe symlink management. The approach is straightforward: create symlinks from `$HOME` to configs in `data/dotfiles/`, with automatic backup of existing files. Shell configuration prioritizes zsh with bash fallback, using modular sourcing patterns. Starship provides cross-shell prompt theming, and git uses the include pattern for local overrides.

The standard approach for this domain is well-established: symlink creation with backup, modular shell configs that source smaller files, and git's native include mechanism for local user settings. No complex frameworks are needed - simple shell patterns suffice.

**Primary recommendation:** Implement symlink manager as core utility in `src/core/dotfiles.sh`, create shell configs in `data/dotfiles/{zsh,bash,shared}/`, use Starship for prompt theming.

## Standard Stack

The established tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| ln | (system) | Create symlinks | POSIX standard, no deps |
| cp | (system) | Backup files | POSIX standard, -p preserves permissions |
| Starship | latest | Cross-shell prompt | Actively maintained, Rust-based, replaces p10k |
| zsh-autosuggestions | master | Fish-like suggestions | De facto standard zsh plugin |
| zsh-syntax-highlighting | master | Command highlighting | De facto standard, must source last |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| zinit | master | zsh plugin manager | Only if user opts in via menu |
| fzf | latest | Fuzzy finder | If already installed, source integration |
| git | (system) | Config management | Already installed, use include pattern |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Starship | p10k | p10k is on "life support" per maintainer |
| Manual symlinks | GNU Stow | Adds external dependency, overkill for this scope |
| zinit | oh-my-zsh | OMZ is heavier, slower startup |

**Installation:**
```bash
# Starship (via brew or cargo, not install.sh)
brew install starship
# OR
cargo install starship

# zsh plugins (git clone, no framework)
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```

## Architecture Patterns

### Recommended Directory Structure
```
data/dotfiles/
├── shared/           # Cross-shell compatible files
│   ├── aliases.sh    # Alias definitions (sourced by both shells)
│   ├── path.sh       # PATH management with dedup
│   └── env.sh        # Environment variables
├── zsh/
│   ├── zshrc         # Main zsh config (symlinked to ~/.zshrc)
│   ├── functions.sh  # zsh-specific functions
│   └── plugins.sh    # Plugin loading
├── bash/
│   ├── bashrc        # Main bash config (symlinked to ~/.bashrc)
│   └── functions.sh  # bash-specific functions
├── git/
│   ├── gitconfig     # Global git config (symlinked to ~/.gitconfig)
│   └── gitignore     # Global gitignore (symlinked to ~/.config/git/ignore)
└── starship/
    └── starship.toml # Prompt config (symlinked to ~/.config/starship.toml)
```

### Pattern 1: Symlink with Backup
**What:** Create symlink only after backing up existing non-symlink file
**When to use:** Always when replacing user config files
**Example:**
```bash
# Source: Established dotfiles pattern
create_dotfile_symlink() {
    local source="$1"    # Absolute path to source in data/dotfiles/
    local target="$2"    # Absolute path in $HOME
    local backup_dir="${HOME}/.dotfiles-backup"

    # Create backup directory if needed
    mkdir -p "$backup_dir"

    # If target exists and is NOT a symlink, back it up
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup_name
        backup_name=$(basename "$target" | tr '/' '-')
        backup_name="${backup_name}.bak.$(date +%Y-%m-%d)"

        if ! cp -p "$target" "${backup_dir}/${backup_name}"; then
            log_error "Failed to backup: $target"
            return 1
        fi
        log_info "Backed up: $target -> ${backup_dir}/${backup_name}"
    fi

    # Create/replace symlink
    ln -sfn "$source" "$target"
    log_ok "Linked: $target -> $source"
}
```

### Pattern 2: Modular Shell Config
**What:** Main rc file sources smaller topical files in fixed order
**When to use:** For zshrc/bashrc that need organization
**Example:**
```bash
# Source: zsh best practices
# ~/.zshrc sources files in this order:
# 1. path.sh   - PATH setup
# 2. env.sh    - Environment variables
# 3. aliases.sh - Alias definitions
# 4. functions.sh - Shell functions
# 5. plugins.sh - Plugin loading (zsh only)
# 6. prompt.sh - Prompt init (starship)

# Shared configs (cross-shell)
DOTFILES_SHARED="${HOME}/.config/os-postinstall/dotfiles/shared"
for config in path.sh env.sh aliases.sh; do
    [[ -f "${DOTFILES_SHARED}/${config}" ]] && source "${DOTFILES_SHARED}/${config}"
done

# Shell-specific
DOTFILES_ZSH="${HOME}/.config/os-postinstall/dotfiles/zsh"
for config in functions.sh plugins.sh; do
    [[ -f "${DOTFILES_ZSH}/${config}" ]] && source "${DOTFILES_ZSH}/${config}"
done

# Starship prompt (last)
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Local overrides
[[ -f "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
```

### Pattern 3: Git Include for Local Config
**What:** Main gitconfig includes a local file for user-specific values
**When to use:** For git configuration that needs user email/name
**Example:**
```ini
# Source: Git official documentation
# ~/.gitconfig
[include]
    path = ~/.gitconfig.local

[user]
    # Intentionally left blank - set in .gitconfig.local

[alias]
    st = status
    co = checkout
    br = branch
    cm = commit
    lg = log --oneline --graph --all
    last = log -1 HEAD

[init]
    defaultBranch = main

[pull]
    rebase = true

[push]
    autoSetupRemote = true

[fetch]
    prune = true
```

```ini
# ~/.gitconfig.local (created during setup, prompts user)
[user]
    name = Your Name
    email = your.email@example.com
```

### Anti-Patterns to Avoid
- **Hardcoded paths:** Use `$HOME` not `/home/username`
- **Relative symlinks:** Use absolute paths for reliability
- **Monolithic rc files:** Split into sourced modules
- **Overwriting without backup:** Always backup non-symlinks first
- **Complex plugin managers for simple needs:** git clone is sufficient for 2-3 plugins

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-shell prompt | Custom PS1/PROMPT | Starship | Handles git status, languages, async |
| PATH deduplication | Custom function | Use established pattern | Edge cases with special chars |
| zsh completions | Manual fpath setup | Tool's built-in setup | Each tool knows its completion |
| Plugin loading | Custom loader | Direct source or zinit | Tested, handles errors |
| Git user prompting | echo/read | git config --global | Handles quoting, encoding |

**Key insight:** Shell configuration has well-established patterns. The value is in organizing and applying them consistently, not in inventing new approaches.

## Common Pitfalls

### Pitfall 1: Source Order for zsh-syntax-highlighting
**What goes wrong:** Syntax highlighting doesn't work or causes errors
**Why it happens:** zsh-syntax-highlighting must be sourced LAST after all other plugins
**How to avoid:** Fixed source order in zshrc, document clearly
**Warning signs:** "widgets can only be called when ZLE is active" errors

### Pitfall 2: Backup Manifest Not Updated
**What goes wrong:** User can't restore original configs after multiple runs
**Why it happens:** Manifest not updated atomically or at all
**How to avoid:** Write to manifest immediately after successful backup, before symlink
**Warning signs:** Backup files exist but manifest is empty or outdated

### Pitfall 3: DRY_RUN Not Respected
**What goes wrong:** Files modified during dry-run
**Why it happens:** Not checking DRY_RUN before every file operation
**How to avoid:** Wrap all file operations in conditional, use helper function
**Warning signs:** Running with DRY_RUN=true still creates backups

### Pitfall 4: Symlink Target Directory Missing
**What goes wrong:** Symlink creation fails for ~/.config/starship.toml
**Why it happens:** ~/.config/ directory doesn't exist on fresh system
**How to avoid:** mkdir -p parent directory before ln -sfn
**Warning signs:** "No such file or directory" errors on clean systems

### Pitfall 5: Existing Symlink Points to Wrong Target
**What goes wrong:** Replacing symlink silently breaks another dotfiles setup
**Why it happens:** ln -sf replaces without checking where old symlink pointed
**How to avoid:** Check if existing symlink points to our data/dotfiles/, if not, warn
**Warning signs:** User loses track of which dotfiles repo is active

### Pitfall 6: Shell Not Detected Correctly
**What goes wrong:** Wrong shell configs applied
**Why it happens:** Checking $SHELL instead of current shell
**How to avoid:** Use $0 or check /proc/$$/comm for current shell
**Warning signs:** zsh config applied when user runs from bash

## Code Examples

Verified patterns from research:

### Starship Initialization
```bash
# Source: Starship official docs
# Add to end of shell config

# For Bash (~/.bashrc)
eval "$(starship init bash)"

# For Zsh (~/.zshrc)
eval "$(starship init zsh)"
```

### Minimal Starship Configuration
```toml
# Source: Starship presets documentation
# ~/.config/starship.toml

# Schema for editor completion
"$schema" = 'https://starship.rs/config-schema.json'

# Blank line between prompts
add_newline = true

# Disable modules we don't need
[package]
disabled = true

[nodejs]
disabled = true

[python]
disabled = true

# Keep these enabled (git info is valuable)
[git_branch]
format = "[$symbol$branch]($style) "

[git_status]
format = "[$all_status$ahead_behind]($style) "

[directory]
truncation_length = 3
truncate_to_repo = true
```

### zsh Plugin Loading (No Framework)
```bash
# Source: zsh-users official repos
# ~/.zsh/plugins.sh

# zsh-autosuggestions
ZSH_AUTOSUGGEST_DIR="${HOME}/.zsh/zsh-autosuggestions"
if [[ -f "${ZSH_AUTOSUGGEST_DIR}/zsh-autosuggestions.zsh" ]]; then
    source "${ZSH_AUTOSUGGEST_DIR}/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# zsh-syntax-highlighting (MUST be last)
ZSH_SYNTAX_DIR="${HOME}/.zsh/zsh-syntax-highlighting"
if [[ -f "${ZSH_SYNTAX_DIR}/zsh-syntax-highlighting.zsh" ]]; then
    source "${ZSH_SYNTAX_DIR}/zsh-syntax-highlighting.zsh"
fi
```

### zsh History Configuration
```bash
# Source: zsh documentation, community best practices
# Shared history settings

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY       # Write timestamp to history
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first
setopt HIST_IGNORE_DUPS       # Ignore consecutive duplicates
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS     # Remove extra blanks
setopt SHARE_HISTORY          # Share history between sessions
setopt INC_APPEND_HISTORY     # Add commands immediately
```

### PATH Deduplication
```bash
# Source: Established shell pattern
# data/dotfiles/shared/path.sh

add_to_path() {
    local new_path="$1"
    case ":$PATH:" in
        *":$new_path:"*)
            # Already present
            return 0
            ;;
    esac
    export PATH="$new_path:$PATH"
}

# Add common paths
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.cargo/bin"
[[ -d "$HOME/go/bin" ]] && add_to_path "$HOME/go/bin"
```

### Backup Manifest Format
```bash
# Source: Project decision (CONTEXT.md)
# ~/.dotfiles-backup/backup-manifest.txt
# Format: YYYY-MM-DD HH:MM:SS | original -> backup

2026-02-05 14:30:00 | ~/.zshrc -> ~/.dotfiles-backup/zshrc.bak.2026-02-05
2026-02-05 14:30:01 | ~/.gitconfig -> ~/.dotfiles-backup/gitconfig.bak.2026-02-05
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| oh-my-zsh | zinit or no framework | 2022+ | Faster startup, less bloat |
| p10k prompt | Starship | 2024 | p10k maintainer stepped back |
| ~/.bash_profile + ~/.bashrc split | Single ~/.bashrc | Modern practice | Less confusion |
| git aliases in shell | git config aliases | Always better | Works across shells |

**Deprecated/outdated:**
- **p10k**: Maintainer announced "life support" mode - use Starship instead
- **antigen**: Abandoned - use zinit if framework needed
- **oh-my-zsh for plugins only**: Too heavy - git clone individual plugins

## Open Questions

Things that couldn't be fully resolved:

1. **fzf Integration Scope**
   - What we know: fzf provides keybindings and completion
   - What's unclear: Should Phase 3 install fzf or just detect and configure if present?
   - Recommendation: Detect and configure only - installation is Phase 4/5 territory

2. **unlink Command Edge Cases**
   - What we know: Should restore backups when unlinking
   - What's unclear: If multiple backups exist, which one to restore?
   - Recommendation: Restore most recent backup, keep others, warn user

3. **Interactive Menu Implementation**
   - What we know: CONTEXT.md mentions optional zinit/plugin menu
   - What's unclear: Best UX pattern for shell menus without external deps
   - Recommendation: Simple select/case pattern, defer to Phase 7 if complex

## Sources

### Primary (HIGH confidence)
- Starship official docs - Installation, configuration, presets
- zsh-users/zsh-autosuggestions INSTALL.md - Manual installation without framework
- zsh-users/zsh-syntax-highlighting INSTALL.md - Must source last requirement
- Git official docs (git-scm.com) - include.path configuration

### Secondary (MEDIUM confidence)
- [Starship GitHub](https://github.com/starship/starship) - Version info, presets
- [zsh-autosuggestions GitHub](https://github.com/zsh-users/zsh-autosuggestions) - Configuration options
- [Git config best practices](https://www.brandonpugh.com/blog/git-config-settings-i-always-recommend/) - pull.rebase, push.autoSetupRemote
- [zsh history configuration](https://jdhao.github.io/2021/03/24/zsh_history_setup/) - HISTSIZE recommendations

### Tertiary (LOW confidence)
- Community gists for oh-my-zsh alternatives - General patterns only

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Well-established tools, official docs verified
- Architecture: HIGH - Patterns from official documentation and project CONTEXT.md
- Pitfalls: MEDIUM - Based on common issues in dotfiles repos, some from experience

**Research date:** 2026-02-05
**Valid until:** 2026-03-05 (30 days - stable domain)

---

*Phase: 03-dotfiles-management*
*Research complete: 2026-02-05*
