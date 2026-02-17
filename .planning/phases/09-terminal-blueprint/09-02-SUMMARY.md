---
phase: 09-terminal-blueprint
plan: 02
subsystem: terminal-setup-wrapper
tags: [starship, terminal, setup, wrapper, migration, ssot]
dependency_graph:
  requires: [09-01]
  provides: [canonical-terminal-setup, terminal-wrapper, terminal-readme]
  affects: [examples/terminal/, examples/terminal-setup.sh]
tech_stack:
  added: []
  patterns: [ssot-wrapper-delegation, subprocess-migration, inline-toml-fallback, exec-delegation]
key_files:
  created:
    - examples/terminal/setup.sh
    - examples/terminal/README.md
  modified:
    - examples/terminal-setup.sh
decisions:
  - "terminal/setup.sh is SSoT -- all logic moved from terminal-setup.sh"
  - "terminal-setup.sh is pure wrapper (24 lines, exec delegation)"
  - "offer_migration() uses bash subprocess, never source"
  - "setup_starship() has inline TOML fallback when presets/ missing"
  - "--migrate flag for explicit non-interactive migration"
metrics:
  duration: 4 min
  completed: 2026-02-17
---

# Phase 9 Plan 02: Terminal Setup + Wrapper + README Summary

**One-liner:** Canonical setup.sh with preset selection and subprocess migration, 24-line pure wrapper replacing 493-line terminal-setup.sh, and standalone README with migration guide.

## What Was Done

### Task 1: Create canonical examples/terminal/setup.sh
**Commit:** 24b3c0f

Created `examples/terminal/setup.sh` (408 lines) as the single source of truth for terminal setup. All logic MOVED from the original `terminal-setup.sh` (not copied), plus new features:

- **select_preset()**: Interactive numbered menu for 3 Starship presets with .bak.YYYY-MM-DD backup before overwrite
- **offer_migration()**: Runs `migrate-p10k.sh` as subprocess (`bash "${SCRIPT_DIR}/migrate-p10k.sh"`), never sources it. Checks .zshrc for p10k references before offering
- **--migrate flag**: Non-interactive mode skips migration by default; `--migrate` enables it. Interactive mode asks via wizard regardless
- **setup_starship()**: Three paths -- interactive preset selection, non-interactive copies minimal.toml, inline TOML fallback when presets/ directory missing
- **wizard()**: Extended with p10k detection -- if .zshrc contains powerlevel10k/p10k references, asks "Migrate from Powerlevel10k?"
- All original functions preserved: detect_platform, detect_shell, ensure_deps, install_tools, install_nerd_font, install_zsh_plugins, setup_shell
- Main guard: `if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi`
- 13 DRY_RUN guards on all destructive operations

### Task 2: Convert terminal-setup.sh to pure wrapper
**Commit:** f9e40e6

Replaced 493-line `examples/terminal-setup.sh` with 24-line pure wrapper:

- `exec bash "${SCRIPT_DIR}/terminal/setup.sh" "$@"` -- replaces process, passes all flags
- Clear error message with git clone hint when `terminal/setup.sh` not found
- Error output to stderr (`>&2`)
- Zero code duplication. Zero fallback code. SSoT is `terminal/setup.sh`

### Task 3: Create standalone README.md
**Commit:** 9e3af8f

Created `examples/terminal/README.md` (144 lines) with:

- Quick start section covering all CLI flags
- Component table (CLI tools, Starship, Nerd Font, aliases, plugins, migration)
- Preset comparison table with Nerd Font requirements
- Migration guide: what it does (5 steps), what it does NOT do, flags, rollback instructions
- Before/after text comparison showing p10k vs Starship prompt
- p10k feature gap table (instant prompt, transient prompt, show-on-command, configure wizard)
- Standalone usage instructions (works without full project clone)
- Directory structure reference

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **SSoT enforcement**: terminal/setup.sh owns ALL terminal setup logic. terminal-setup.sh is a pure exec wrapper.
2. **Subprocess migration**: offer_migration() uses `bash "${SCRIPT_DIR}/migrate-p10k.sh"` -- zero coupling, separate process.
3. **Inline TOML fallback**: When presets/ directory is missing, setup_starship() writes a minimal inline config with ASCII `>` character.
4. **--migrate flag semantics**: Non-interactive defaults to NO migration (predictable for automation). Interactive wizard asks when p10k detected.
5. **exec delegation**: Wrapper uses `exec` to replace the process entirely -- no return after delegation.

## Verification Results

| Check | Result |
|-------|--------|
| setup.sh exists | PASS |
| setup.sh syntax (bash -n) | PASS |
| select_preset() function | PASS |
| bash..migrate-p10k subprocess | PASS |
| NO source migrate-p10k | PASS (0 occurrences) |
| --migrate flag (2+ refs) | PASS |
| Inline TOML fallback (schema) | PASS |
| 4 original functions | PASS |
| BASH_SOURCE main guard | PASS |
| DRY_RUN support (13 refs) | PASS |
| Wrapper delegation (exec) | PASS |
| Wrapper NO fallback code | PASS (0 occurrences) |
| Wrapper error message | PASS |
| Wrapper git clone hint | PASS |
| Wrapper syntax (bash -n) | PASS |
| Wrapper under 25 lines | PASS (24 lines) |
| README preset comparison | PASS (8 refs) |
| README migration section | PASS (10 refs) |
| README before/after | PASS (3 refs) |
| README directory structure | PASS (11 refs) |
| README under 200 lines | PASS (144 lines) |
| Complete directory listing | PASS (setup.sh, migrate-p10k.sh, README.md, presets/) |

## Self-Check: PASSED

- FOUND: examples/terminal/setup.sh
- FOUND: examples/terminal/README.md
- FOUND: examples/terminal-setup.sh (24 lines, wrapper)
- FOUND: 24b3c0f (Task 1 commit)
- FOUND: f9e40e6 (Task 2 commit)
- FOUND: 9e3af8f (Task 3 commit)
