---
phase: 09-terminal-blueprint
plan: 01
subsystem: terminal-presets-migration
tags: [starship, p10k, migration, presets, toml]
dependency_graph:
  requires: []
  provides: [starship-presets, p10k-migration-script]
  affects: [examples/terminal/]
tech_stack:
  added: [starship-toml-presets, palette-feature]
  patterns: [safe-migration-backup, dry-run-guards, temp-file-sed-replacement]
key_files:
  created:
    - examples/terminal/presets/minimal.toml
    - examples/terminal/presets/powerline.toml
    - examples/terminal/presets/p10k-alike.toml
    - examples/terminal/migrate-p10k.sh
  modified: []
decisions:
  - "ASCII > character for all presets (per project decision 08.1-01)"
  - "Temp file + mv for .zshrc editing (portable, no sed -i)"
  - "Default deactivate + backup (safe); --remove flag for full cleanup"
  - "Preset selection only in interactive terminal ([[ -t 0 ]])"
metrics:
  duration: 2 min
  completed: 2026-02-17
---

# Phase 9 Plan 01: Starship Presets + p10k Migration Summary

**One-liner:** 3 curated Starship TOML presets (minimal/powerline/p10k-alike) and standalone p10k migration script with 7-method detection, timestamped backup, and DRY_RUN guards.

## What Was Done

### Task 1: Create 3 Starship preset TOML files
**Commit:** b77e856

Created `examples/terminal/presets/` with 3 curated presets:

- **minimal.toml** (67 lines): ASCII-safe prompt matching project default `data/dotfiles/starship/starship.toml`. Uses `>` character, disables 13 noisy modules. No Nerd Font required.
- **powerline.toml** (72 lines): Colored segments with Nerd Font glyph separators (U+E0B0). Uses `palette` feature for DRY color definitions. Documents Nerd Font prerequisite.
- **p10k-alike.toml** (79 lines): Two-line prompt approximating p10k Lean style. Includes username, hostname (SSH only), explicit git_status symbols (?!+~-*=), git_state (rebase/merge), vimcmd_symbol.

All 3 include `$schema` for editor validation.

### Task 2: Create p10k migration script
**Commit:** cf3db9d

Created `examples/terminal/migrate-p10k.sh` (274 lines) as standalone script:

- **detect_p10k()**: Checks .zshrc + 7 installation paths (oh-my-zsh, manual, zinit, zplug, antigen, zim, Homebrew) + .p10k.zsh config
- **backup_p10k()**: Timestamped backup directory (`~/.p10k-backup.YYYY-MM-DD`) with .p10k.zsh, .zshrc, and p10k_path.txt
- **clean_zshrc_p10k()**: Removes instant-prompt, source lines, zinit/zplug lines; replaces ZSH_THEME with robbyrussell. Uses mktemp (portable, no sed -i)
- **remove_p10k_files()**: Optional `--remove` flag for full cleanup (p10k dir, .p10k.zsh, cache files)
- **select_preset()**: Interactive menu offering 3 presets with backup of existing starship.toml
- **check_starship()**: Warns if Starship not installed, suggests install methods
- 9 DRY_RUN guards on all destructive operations
- Main guard pattern for sourceable + executable usage
- Argument parsing with `--dry-run`, `--remove`, `--help`

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **ASCII `>` for all presets**: Even the powerline preset uses `>` for the character prompt (only segment separators use Nerd Font glyphs). This matches project decision [08.1-01].
2. **mktemp for .zshrc editing**: Temp file approach instead of sed -i for cross-platform portability (BSD sed vs GNU sed).
3. **Default: deactivate only**: Safe default preserves p10k files. `--remove` flag required for full cleanup.
4. **Interactive preset selection gated by `[[ -t 0 ]]`**: Prevents hanging when piped or run non-interactively.

## Verification Results

| Check | Result |
|-------|--------|
| 3 TOML files in presets/ | PASS |
| minimal.toml has `[>]` (ASCII-safe) | PASS |
| powerline.toml has palette + palettes section | PASS |
| p10k-alike.toml has username + hostname | PASS |
| All 3 have $schema | PASS |
| No Unicode prompt chars in minimal | PASS |
| migrate-p10k.sh syntax check | PASS |
| detect_p10k() function exists | PASS |
| 18 powerlevel10k references (7+ paths) | PASS |
| 9 DRY_RUN guards | PASS |
| --remove flag support (5 refs) | PASS |
| BASH_SOURCE main guard | PASS |

## Self-Check: PASSED

- FOUND: examples/terminal/presets/minimal.toml
- FOUND: examples/terminal/presets/powerline.toml
- FOUND: examples/terminal/presets/p10k-alike.toml
- FOUND: examples/terminal/migrate-p10k.sh
- FOUND: b77e856 (Task 1 commit)
- FOUND: cf3db9d (Task 2 commit)
