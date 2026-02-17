# Phase 9: Terminal Blueprint - Research

**Researched:** 2026-02-17
**Domain:** Shell prompt migration (Powerlevel10k to Starship), TOML preset authoring, shell script modularization
**Confidence:** HIGH

## Summary

Phase 9 creates a standalone terminal replication subproduct under `examples/terminal/` that provides: (1) an automated migration script from Powerlevel10k to Starship, (2) curated Starship presets that approximate the most popular p10k styles, and (3) a modular one-command setup. The timing is excellent -- Powerlevel10k's maintainer has declared the project "on life support" with no new features and most bugs left unfixed, creating natural demand for migration tooling.

The existing `examples/terminal-setup.sh` (493 lines) and `examples/terminal-setup.ps1` (547 lines) already handle CLI tool installation, Starship config, aliases, and plugin setup. Phase 9 extends this with a new `examples/terminal/` directory containing the migration script, preset TOML files, and a dedicated README. The existing scripts become backward-compatible entry points that delegate to the new modular structure.

**Primary recommendation:** Create `examples/terminal/` as a self-contained directory with `setup.sh` (refactored from existing), `migrate-p10k.sh` (new), and `presets/` containing 3 curated TOML files (minimal, powerline, p10k-alike). The existing `examples/terminal-setup.sh` should remain as a thin wrapper that sources the new modular setup for backward compatibility.

## Standard Stack

### Core
| Component | Type | Purpose | Why Standard |
|-----------|------|---------|--------------|
| Starship | Binary (Rust) | Cross-shell prompt | Cross-shell, fast, actively maintained, replaces deprecated p10k |
| starship.toml | TOML config | Prompt configuration | Official Starship config format with schema validation |
| Pure Bash/Zsh | Shell scripts | Migration + setup | Project constraint: zero external deps, run on clean machine |

### Supporting
| Component | Type | Purpose | When to Use |
|-----------|------|---------|-------------|
| `starship preset` CLI | Subcommand | List/export built-in presets | Reference for creating custom presets |
| STARSHIP_CONFIG env var | Environment | Point to non-default config location | When user has custom config path |
| Nerd Fonts | Font family | Icon rendering in prompt | Required for powerline/p10k-alike presets |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom TOML presets | `starship preset <name> -o` | Built-in presets are generic; custom presets match p10k styles better |
| In-script TOML generation | Separate .toml files | Separate files are easier to maintain, preview, diff |
| oh-my-posh | Starship | oh-my-posh is also cross-shell but heavier; project already standardized on Starship |

## Architecture Patterns

### Recommended Directory Structure
```
examples/
  terminal-setup.sh          # EXISTING - backward compat wrapper (thin, delegates to terminal/setup.sh)
  terminal-setup.ps1         # EXISTING - Windows equivalent (unchanged)
  terminal/
    setup.sh                 # Main entry point (modular version of terminal-setup.sh)
    migrate-p10k.sh          # p10k detection, backup, removal, Starship replacement
    README.md                # Standalone migration guide + before/after comparison
    presets/
      minimal.toml           # Clean prompt (current project default style)
      powerline.toml         # Powerline arrows/segments (matches p10k Classic/Rainbow)
      p10k-alike.toml        # Closest approximation to p10k Lean style
```

### Pattern 1: Backward-Compatible Wrapper
**What:** Existing `examples/terminal-setup.sh` becomes a thin wrapper that detects if `examples/terminal/setup.sh` exists and delegates to it, falling back to its own logic if not.
**When to use:** When adding new modular structure without breaking existing entry points.
**Example:**
```bash
#!/usr/bin/env bash
# examples/terminal-setup.sh — backward-compatible entry point
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -f "${SCRIPT_DIR}/terminal/setup.sh" ]]; then
    exec bash "${SCRIPT_DIR}/terminal/setup.sh" "$@"
fi

# ... original code as fallback ...
```

### Pattern 2: Safe Migration with Rollback
**What:** Detect existing installation, create timestamped backups, perform migration, verify success.
**When to use:** Any destructive operation on user's shell configuration.
**Example:**
```bash
backup_p10k() {
    local backup_dir="${HOME}/.p10k-backup.$(date +%Y-%m-%d)"
    mkdir -p "$backup_dir"

    # Backup all p10k files
    [[ -f "${HOME}/.p10k.zsh" ]] && cp "${HOME}/.p10k.zsh" "$backup_dir/"
    [[ -f "${HOME}/.zshrc" ]] && cp "${HOME}/.zshrc" "$backup_dir/"

    # Save p10k installation path for potential rollback
    local p10k_dir
    p10k_dir=$(find_p10k_installation)
    [[ -n "$p10k_dir" ]] && echo "$p10k_dir" > "$backup_dir/p10k_path.txt"

    log_ok "Backup saved to $backup_dir"
}
```

### Pattern 3: Preset Selection Menu
**What:** Interactive menu to choose Starship preset, with preview capability.
**When to use:** When user needs to choose between preset styles.
**Example:**
```bash
select_preset() {
    local preset_dir="${SCRIPT_DIR}/presets"
    echo ""
    echo "Available Starship presets:"
    echo "  1) minimal    - Clean, fast, essentials only (recommended)"
    echo "  2) powerline  - Colored segments with arrows (like p10k Classic)"
    echo "  3) p10k-alike - Closest match to p10k Lean style"
    echo ""
    read -rp "Choose preset [1-3, default=1]: " choice
    # ...
}
```

### Anti-Patterns to Avoid
- **Modifying .zshrc with sed without backup:** Always backup first, then use marker-based insertion/removal.
- **Assuming p10k installation method:** Users install via oh-my-zsh, zinit, manual git clone, brew, etc. -- must detect all methods.
- **Hardcoding paths:** p10k can be in `~/.oh-my-zsh/custom/themes/powerlevel10k/`, `~/powerlevel10k/`, or managed by plugin managers.
- **Removing oh-my-zsh itself:** Migration should only remove the p10k theme, not oh-my-zsh if the user has other plugins.
- **Using Unicode arrows in TOML without fallback:** Per project decision [08.1-01], use ASCII-safe characters for cross-terminal compat, at least in the minimal preset.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Starship preset TOML | Generate TOML programmatically | Static .toml files in presets/ | TOML is declarative; static files are reviewable, diffable, testable |
| p10k detection | Custom heuristics only | Check known paths + grep .zshrc | p10k has 15+ installation methods; must check both filesystem and config |
| Starship installation | Custom binary download logic | Reuse existing install_tools() from terminal-setup.sh | Already handles brew/apt/curl cross-platform |
| Color/style definitions | Inline hex codes everywhere | Starship palette feature | `palette = 'name'` + `[palettes.name]` keeps colors DRY in TOML |

**Key insight:** The migration script's value is in detection and safe removal, not in Starship installation (which already exists in terminal-setup.sh).

## Common Pitfalls

### Pitfall 1: Incomplete p10k Detection
**What goes wrong:** Script only checks one p10k installation path, misses users who installed differently.
**Why it happens:** p10k has 15+ installation methods, each placing files in different locations.
**How to avoid:** Check ALL known paths systematically:
- `${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/` (oh-my-zsh)
- `$HOME/powerlevel10k/` (manual git clone)
- `$HOME/.zinit/plugins/romkatv---powerlevel10k/` (zinit)
- `$HOME/.zplug/repos/romkatv/powerlevel10k/` (zplug)
- `$HOME/.antigen/bundles/romkatv/powerlevel10k/` (antigen)
- `$HOME/.zim/modules/powerlevel10k/` (zim)
- Homebrew: `$(brew --prefix)/opt/powerlevel10k/` (if brew available)
- Also grep `.zshrc` for `source.*powerlevel10k` lines
**Warning signs:** Migration script says "p10k not found" when user definitely has it.

### Pitfall 2: Breaking oh-my-zsh While Removing p10k
**What goes wrong:** Removing p10k theme directory or .zshrc lines breaks oh-my-zsh loading.
**Why it happens:** Oh-my-zsh uses `ZSH_THEME` variable; if set to "powerlevel10k/powerlevel10k" and the theme dir is removed, zsh startup fails.
**How to avoid:** When removing p10k from oh-my-zsh: (1) change `ZSH_THEME` to a safe default like `"robbyrussell"` BEFORE removing theme directory, (2) remove the `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh` line.
**Warning signs:** User's shell breaks after migration (errors on terminal open).

### Pitfall 3: Instant Prompt Cache Left Behind
**What goes wrong:** p10k's instant prompt leaves a cache file that causes zsh warnings after removal.
**Why it happens:** p10k writes to `${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh` and the top of .zshrc has `source` lines for it.
**How to avoid:** (1) Remove the instant prompt source block from top of .zshrc (typically the first ~10 lines), (2) remove `$HOME/.cache/p10k-instant-prompt-*.zsh` files.
**Warning signs:** Zsh startup shows "source: no such file or directory" for p10k-instant-prompt after migration.

### Pitfall 4: Preset Uses Unicode Glyphs Without Nerd Font
**What goes wrong:** Prompt shows boxes/question marks instead of icons.
**Why it happens:** Powerline and p10k-alike presets use Nerd Font glyphs that require a Nerd Font to render.
**How to avoid:** (1) Minimal preset uses ASCII-safe characters only (per project decision), (2) powerline/p10k-alike presets clearly document Nerd Font requirement, (3) setup.sh offers font installation before preset selection.
**Warning signs:** Prompt looks broken with rectangles and `?` symbols.

### Pitfall 5: DRY_RUN Not Guarding Destructive Operations
**What goes wrong:** Migration script removes p10k files even in dry-run mode.
**Why it happens:** Per project decision [08.2-03], `run()` cannot guard pipe right sides or complex operations.
**How to avoid:** Every destructive operation (rm, sed -i, cp overwrite) must have explicit `[[ "$DRY_RUN" == "true" ]]` guard.
**Warning signs:** Dry-run mode still modifies user's .zshrc or removes p10k files.

### Pitfall 6: Backward Compatibility Regression
**What goes wrong:** Existing `examples/terminal-setup.sh` stops working when new directory structure is added.
**Why it happens:** Refactoring breaks the standalone nature of the original script.
**How to avoid:** Keep `examples/terminal-setup.sh` fully functional. It should detect and delegate to `examples/terminal/setup.sh` if present, but work on its own if `terminal/` directory doesn't exist (e.g., if someone downloads just the single script).
**Warning signs:** `bash terminal-setup.sh` fails with "file not found" errors.

## Code Examples

### p10k Detection Function
```bash
# Source: Research synthesis of p10k documentation + community patterns
detect_p10k() {
    local found=false
    local p10k_dir=""
    local install_method=""

    # Check .zshrc for p10k references
    if [[ -f "${HOME}/.zshrc" ]] && grep -qE 'powerlevel10k|p10k' "${HOME}/.zshrc"; then
        found=true
    fi

    # Check known installation directories
    local -a p10k_paths=(
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        "$HOME/powerlevel10k"
        "$HOME/.zinit/plugins/romkatv---powerlevel10k"
        "$HOME/.zplug/repos/romkatv/powerlevel10k"
        "$HOME/.antigen/bundles/romkatv/powerlevel10k"
        "$HOME/.zim/modules/powerlevel10k"
    )

    # Also check Homebrew if available
    if command -v brew &>/dev/null; then
        local brew_prefix
        brew_prefix="$(brew --prefix 2>/dev/null)"
        [[ -n "$brew_prefix" ]] && p10k_paths+=("${brew_prefix}/opt/powerlevel10k")
    fi

    for path in "${p10k_paths[@]}"; do
        if [[ -d "$path" ]]; then
            p10k_dir="$path"
            found=true
            break
        fi
    done

    # Check for .p10k.zsh config file
    local p10k_config=""
    [[ -f "${HOME}/.p10k.zsh" ]] && p10k_config="${HOME}/.p10k.zsh"

    if [[ "$found" == "true" ]]; then
        echo "P10K_FOUND=true"
        echo "P10K_DIR=${p10k_dir}"
        echo "P10K_CONFIG=${p10k_config}"
        return 0
    fi

    return 1
}
```

### Clean p10k References from .zshrc
```bash
# Source: Research synthesis of p10k uninstall docs
clean_zshrc_p10k() {
    local zshrc="${HOME}/.zshrc"
    [[ -f "$zshrc" ]] || return 0

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Remove p10k references from $zshrc"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"

    # Remove instant prompt block (top of file, multi-line)
    # Remove: source lines for p10k-instant-prompt
    # Remove: [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    # Change: ZSH_THEME="powerlevel10k/powerlevel10k" -> ZSH_THEME="robbyrussell"
    # Remove: source ~/powerlevel10k/powerlevel10k.zsh-theme (manual installs)
    # Remove: zinit/zplug p10k lines

    grep -v 'p10k-instant-prompt' "$zshrc" \
        | grep -v 'source.*\.p10k\.zsh' \
        | grep -v 'source.*powerlevel10k\.zsh-theme' \
        | grep -v 'zinit.*powerlevel10k' \
        | grep -v 'zplug.*powerlevel10k' \
        | sed 's/ZSH_THEME="powerlevel10k\/powerlevel10k"/ZSH_THEME="robbyrussell"/' \
        > "$tmp"

    mv "$tmp" "$zshrc"
    log_ok "Cleaned p10k references from .zshrc"
}
```

### Minimal Preset (ASCII-safe)
```toml
# Source: Project existing starship.toml + ASCII-safe decision [08.1-01]
"$schema" = "https://starship.rs/config-schema.json"

format = """
$directory\
$git_branch\
$git_status\
$cmd_duration\
$line_break\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold purple"

[git_status]
format = "[$all_status$ahead_behind]($style) "
style = "bold red"

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "
style = "bold yellow"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

# Disabled noisy modules
[package]
disabled = true
[nodejs]
disabled = true
[python]
disabled = true
[rust]
disabled = true
[golang]
disabled = true
[java]
disabled = true
[ruby]
disabled = true
[php]
disabled = true
[docker_context]
disabled = true
[kubernetes]
disabled = true
[aws]
disabled = true
[gcloud]
disabled = true
[azure]
disabled = true
```

### Powerline Preset (Nerd Font required)
```toml
# Source: Adapted from Starship official pastel-powerline + gruvbox-rainbow presets
# Reference: https://starship.rs/presets/pastel-powerline
"$schema" = "https://starship.rs/config-schema.json"

palette = "powerline"

format = """
[](fg:color_blue)\
$directory\
[](fg:color_blue bg:color_purple)\
$git_branch\
$git_status\
[](fg:color_purple bg:color_yellow)\
$cmd_duration\
[](fg:color_yellow)\
$line_break\
$character"""

[palettes.powerline]
color_blue = "#3465A4"
color_purple = "#75507B"
color_yellow = "#C4A000"
color_fg = "#EEEEEC"
color_green = "#4E9A06"
color_red = "#CC0000"

[directory]
format = "[ $path ]($style)"
style = "fg:color_fg bg:color_blue"
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[ $symbol$branch ]($style)"
symbol = " "
style = "fg:color_fg bg:color_purple"

[git_status]
format = "[$all_status$ahead_behind]($style)"
style = "fg:color_fg bg:color_purple"

[cmd_duration]
format = "[ $duration ]($style)"
min_time = 2000
style = "fg:color_fg bg:color_yellow"

[character]
success_symbol = "[>](bold color_green)"
error_symbol = "[>](bold color_red)"

# Keep clean
[package]
disabled = true
[nodejs]
disabled = true
[python]
disabled = true
[rust]
disabled = true
[docker_context]
disabled = true
```

### p10k-alike Preset (approximates p10k Lean)
```toml
# Source: Adapted from Starship pure-preset + p10k lean template research
# Reference: https://starship.rs/presets/pure-preset
"$schema" = "https://starship.rs/config-schema.json"

# Two-line prompt similar to p10k lean style
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$cmd_duration\
$line_break\
$character"""

[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
vimcmd_symbol = "[<](bold green)"

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold purple"

[git_status]
format = "([$all_status$ahead_behind]($style) )"
style = "bold red"
conflicted = "="
untracked = "?"
modified = "!"
staged = "+"
renamed = "~"
deleted = "-"
stashed = "*"

[git_state]
format = '\([$state( $progress_current/$progress_total)]($style)\) '
style = "bright-black"

[cmd_duration]
format = "[$duration]($style) "
min_time = 2000
style = "bold yellow"

[username]
show_always = false
format = "[$user]($style)@"
style_user = "bold blue"

[hostname]
ssh_only = true
format = "[$hostname]($style) "
style = "bold blue"

# Disabled (keep lean)
[package]
disabled = true
[nodejs]
disabled = true
[python]
disabled = true
[rust]
disabled = true
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Powerlevel10k (zsh-only) | Starship (cross-shell, Rust) | 2024-2025 (p10k maintenance mode) | Migration demand growing |
| p10k configure wizard | starship.toml + presets | Ongoing | Declarative config vs interactive wizard |
| Per-shell prompt themes | Cross-shell Starship | Starship v1.0+ (2022) | Same config for bash/zsh/fish/powershell |
| Unicode glyphs assumed | ASCII-safe with Nerd Font opt-in | Project decision [08.1-01] | Better cross-terminal compatibility |

**Deprecated/outdated:**
- **Powerlevel10k:** Officially "very limited support" -- no new features, most bugs unfixed, help requests ignored. Still functional but no longer actively developed.
- **p10k instant prompt:** Unique p10k feature with no Starship equivalent. Users migrating from p10k lose this (but Starship is fast enough that it's rarely missed).
- **p10k transient prompt:** No native Starship equivalent (can be approximated with manual zsh hooks, but not worth the complexity for this project).

## Powerlevel10k Deep Dive (Migration Target)

### Files Created by p10k
| File | Purpose | Always Present |
|------|---------|---------------|
| `~/.p10k.zsh` | Main config (generated by wizard) | Yes (if configured) |
| `~/.zshrc` modifications | Theme sourcing + instant prompt | Yes |
| `~/.cache/p10k-instant-prompt-*.zsh` | Instant prompt cache | If instant prompt enabled |
| Theme directory (varies by install method) | p10k source code | Yes |

### .zshrc Modifications by p10k
p10k adds up to 3 blocks to `.zshrc`:
1. **Instant prompt block** (top of file): `if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then source ...; fi`
2. **Theme activation** (middle): `ZSH_THEME="powerlevel10k/powerlevel10k"` (oh-my-zsh) or `source ~/powerlevel10k/powerlevel10k.zsh-theme` (manual)
3. **Config sourcing** (bottom): `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh`

### p10k Installation Paths by Method
| Method | Directory |
|--------|-----------|
| Oh My Zsh | `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k/` |
| Manual | `~/powerlevel10k/` |
| Zinit | `~/.zinit/plugins/romkatv---powerlevel10k/` |
| Zplug | `~/.zplug/repos/romkatv/powerlevel10k/` |
| Antigen | `~/.antigen/bundles/romkatv/powerlevel10k/` |
| Zim | `~/.zim/modules/powerlevel10k/` |
| Homebrew | `$(brew --prefix)/opt/powerlevel10k/` |

### p10k Features Without Starship Equivalents
| Feature | p10k | Starship | Impact |
|---------|------|----------|--------|
| Instant prompt | Native (cache-based) | None | p10k shows prompt before plugins load; Starship is fast enough to not need this |
| Transient prompt | Native | Manual zsh hooks only | Previous commands show minimal prompt; achievable but complex |
| Configuration wizard | `p10k configure` interactive TUI | Edit TOML file manually | Presets + README compensate for lack of wizard |
| Show on command | Native | None | Show segment only when relevant command typed |
| 50+ prompt segments | Built-in | 50+ modules (different set) | Roughly equivalent coverage |

## Starship Preset CLI Reference

| Command | Purpose |
|---------|---------|
| `starship preset --list` | List all available built-in presets |
| `starship preset <NAME>` | Print preset TOML to stdout |
| `starship preset <NAME> -o <FILE>` | Write preset TOML to file |

### Built-in Preset Names (as of 2025)
bracketed-segments, catppuccin-powerline, gruvbox-rainbow, jetpack, nerd-font-symbols, no-empty-icons, no-nerd-font, no-runtime-versions, pastel-powerline, plain-text-symbols, pure-preset, tokyo-night

## Cross-Platform Considerations

| Concern | macOS | Linux | Windows |
|---------|-------|-------|---------|
| Shell | zsh (default) | bash/zsh | PowerShell |
| p10k presence | Common (zsh default) | Common (zsh users) | N/A (p10k is zsh-only) |
| Starship install | `brew install starship` | `brew`/`curl\|sh` | `winget install Starship.Starship` |
| .zshrc location | `~/.zshrc` | `~/.zshrc` | N/A (uses $PROFILE) |
| Nerd Font install | `brew install --cask font-*` | curl + fc-cache | Per-user LOCALAPPDATA |

**Key decision:** The migration script (`migrate-p10k.sh`) targets macOS and Linux only (p10k is zsh-only). Windows users on PowerShell have no p10k to migrate from. The preset system and setup.sh should remain cross-platform where possible.

## Open Questions

1. **Should examples/terminal/setup.sh be a full rewrite or extract from existing terminal-setup.sh?**
   - What we know: Existing script is 493 lines, well-structured, battle-tested.
   - What's unclear: How much to extract vs duplicate.
   - Recommendation: Extract shared functions to a common lib, keep setup.sh as orchestrator. The existing terminal-setup.sh becomes a wrapper that delegates.

2. **Should the migration script remove p10k source files or just deactivate?**
   - What we know: Full removal is cleaner; leaving files wastes disk but enables rollback.
   - What's unclear: User preference for clean vs safe.
   - Recommendation: Deactivate in .zshrc, backup configs, but offer `--remove` flag for full cleanup. Default to safe (deactivate + backup).

3. **Should we offer more than 3 presets?**
   - What we know: Starship has 12 built-in presets. 3 covers the main p10k styles.
   - What's unclear: Whether users want more variety.
   - Recommendation: Start with 3 (minimal, powerline, p10k-alike). The README can reference `starship preset --list` for built-in alternatives.

## Sources

### Primary (HIGH confidence)
- [Starship Official Presets](https://starship.rs/presets/) - All preset names, descriptions, TOML configs
- [Starship Configuration](https://starship.rs/config/) - STARSHIP_CONFIG, palettes, format strings, modules
- [Starship Advanced Config](https://starship.rs/advanced-config/) - Transient prompt, continuation_prompt, pre-prompt hooks
- [Powerlevel10k GitHub](https://github.com/romkatv/powerlevel10k) - Installation methods, features, maintenance status
- [Starship Preset CLI](https://deepwiki.com/starship/starship/4.4-configuration-presets) - `starship preset` subcommand syntax and behavior

### Secondary (MEDIUM confidence)
- [Moving from p10k to Starship](https://bulimov.me/post/2025/05/11/powerlevel10k-to-starship/) - Migration experience report, performance comparison
- [p10k is on Life Support](https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship/) - p10k deprecation context, migration guidance
- [p10k Configuration Templates (DeepWiki)](https://deepwiki.com/romkatv/powerlevel10k/4.2-configuration-templates) - Lean/Classic/Rainbow/Pure template details
- [Starship Pure Preset](https://starship.rs/presets/pure-preset) - Full TOML for Pure prompt emulation
- [Starship Pastel Powerline](https://starship.rs/presets/pastel-powerline) - Full TOML for powerline-style prompt
- [Starship Gruvbox Rainbow](https://starship.rs/presets/gruvbox-rainbow) - Full TOML with palette feature example

### Tertiary (LOW confidence)
- [p10k uninstall steps](https://sleepycalculator.com/how-to-uninstall-powerlevel10k/) - Community-sourced uninstall guide (cross-verified with official README)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Starship is the clear successor, project already uses it
- Architecture: HIGH - Directory structure follows existing project patterns
- Pitfalls: HIGH - p10k installation paths verified from official docs + multiple sources
- Presets: MEDIUM - Custom TOML presets are author-created; based on official preset patterns
- Migration script: MEDIUM - p10k uninstall docs are sparse; detection logic synthesized from multiple sources

**Research date:** 2026-02-17
**Valid until:** 2026-04-17 (stable domain -- Starship config format and p10k status unlikely to change)
