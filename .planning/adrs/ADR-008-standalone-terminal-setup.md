# ADR-008: Standalone Terminal Setup as Self-Contained Product

**Status:** Accepted
**Date:** 2026-02-08
**Phases:** Post-Phase 8

## Context

Users frequently want to replicate a modern terminal experience (CLI tools, prompt, aliases, plugins) on a colleague's machine or a fresh system without running the full `setup.sh` with profile selection, dotfiles symlinks, and platform orchestration. The main setup flow is designed for full system provisioning — it's overkill for "just give me a nice terminal."

## Decision

Create `examples/terminal-setup.sh` as a **self-contained, zero-dependency script** that delivers the terminal experience independently of the main setup flow.

Key design choices:

1. **Self-contained** — all config (aliases, starship.toml, plugin URLs) embedded inline. No imports from `src/` or `data/`. Script works if downloaded alone.

2. **Nerd Font auto-install** — JetBrainsMono Nerd Font installed via `brew install --cask` (macOS) or GitHub releases download (Linux), closing the most common "broken glyphs" issue.

3. **Hybrid execution model** — default installs everything silently (good for automation, piping); `--interactive` flag opens a p10k-style wizard for component selection.

4. **Feature flags** — `DO_FONT`, `DO_TOOLS`, `DO_STARSHIP`, `DO_ALIASES`, `DO_PLUGINS` control what gets installed, set by wizard or left as `true` defaults.

5. **Dependency guarantee** — `ensure_deps()` installs `curl`, `git`, `unzip`, `fontconfig` on Linux before any operation that needs them.

6. **Split heredoc pattern** — static aliases use quoted `'EOF'` (no interpolation), dynamic init lines (zoxide, starship) use unquoted `DYNAMIC` heredoc for `${SHELL_NAME}` injection. Avoids cross-platform `sed -i` incompatibility.

## Consequences

**Positive:**
- Most accessible entry point to the project (2 commands to a working terminal)
- SSoT for terminal config within examples/ (aliases.sh removed as redundant)
- Promotes the repo as a "terminal transformation" product, not just a setup script collection

**Negative:**
- Aliases and starship config are duplicated between `examples/terminal-setup.sh` and `data/dotfiles/`. Changes to one don't propagate to the other. This is intentional — terminal-setup.sh is a snapshot, data/dotfiles/ is the operational source.
- Script grows with each feature (currently ~470 lines). May need splitting if it exceeds ~600 lines.

**Trade-offs:**
- Self-contained > DRY for this use case. The value of "download one file, run it" outweighs the cost of maintaining duplicate alias definitions.

## Alternatives Considered

1. **Wrapper around setup.sh** — `setup.sh --terminal-only`. Rejected: couples the quick path to the full orchestration system, requires the full repo.
2. **Separate dotfiles repo** — chezmoi/yadm style. Rejected: over-engineering for "send files to colleague" use case.
3. **Just send dotfiles** — Share zshrc + starship.toml. Rejected: doesn't install tools, colleague gets broken experience.
