# ADR-008: Standalone Terminal Setup as Self-Contained Product

**Status:** Amended
**Date:** 2026-02-08 (amended 2026-02-23)
**Phases:** Post-Phase 8, amended post-v4.1

## Context

Users frequently want to replicate a modern terminal experience (CLI tools, prompt, aliases, plugins) on a colleague's machine or a fresh system without running the full `setup.sh` with profile selection, dotfiles symlinks, and platform orchestration. The main setup flow is designed for full system provisioning — it's overkill for "just give me a nice terminal."

## Decision

Create `examples/terminal-setup.sh` as a **self-contained, zero-dependency script** that delivers the terminal experience independently of the main setup flow.

Key design choices:

1. **SSoT over self-contained** *(amended 2026-02-23)* — aliases and starship config are sourced from `data/dotfiles/` (single source of truth). The script copies these to user's home at install time. If the repo is missing (standalone download), the script gracefully degrades with warnings.

2. **Nerd Font selective install** *(amended 2026-02-23)* — Downloads only 4 font variants (Regular, Bold, Italic, BoldItalic ~10 MB) via GitHub releases on both macOS and Linux, instead of the full brew cask (~222 MB / 96 files).

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
- Script requires full repo clone for best experience (aliases + starship config from `data/dotfiles/`). Standalone download works but with degraded functionality.
- Script grows with each feature (currently ~540 lines). May need splitting if it exceeds ~600 lines.

**Trade-offs:**
- *(Amended 2026-02-23)* SSoT > self-contained. The previous approach duplicated aliases/config inline, causing drift. Now `data/dotfiles/` is the single source, copied to user's home at install time. Graceful degradation preserves standalone usability.

## Alternatives Considered

1. **Wrapper around setup.sh** — `setup.sh --terminal-only`. Rejected: couples the quick path to the full orchestration system, requires the full repo.
2. **Separate dotfiles repo** — chezmoi/yadm style. Rejected: over-engineering for "send files to colleague" use case.
3. **Just send dotfiles** — Share zshrc + starship.toml. Rejected: doesn't install tools, colleague gets broken experience.
