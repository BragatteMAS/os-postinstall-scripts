# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.6.0] - 2026-06-07

Unified prompt contract: every default-bearing prompt now renders its
visible hint FROM the default value, so a prompt can no longer advertise a
default it does not use. This kills, by construction, the default-inversion
bug class that was patched piecemeal across v5.4.0 / v5.4.4 / v5.4.6 — the
same root cause, fixed four-plus times because each prompt was hand-coded.

This is a **MINOR** version bump: the interactive prompts change shape (hint
format, and the Windows profile menu now defaults to `developer` on Enter,
matching the bash wizard), which is user-visible behavior — but no flag or
`--unattended` API broke.

### Added
- **`prompt_default`** in `src/core/prompt.sh` (bash) and its PowerShell
  sibling **`Read-Default`** in `src/platforms/windows/core/prompt.psm1`.
  Shared cross-OS contract: the default is both displayed and returned (they
  cannot diverge); `NONINTERACTIVE` auto-picks the default and logs it to
  stderr; only the resolved value reaches stdout.
- **`tests/test-core-prompt.bats`** — 8 behavioral contract tests covering
  default resolution (empty / explicit / unattended / timeout) and the
  stdout-cleanliness guard.
- Windows prompt-contract tests in `tests/test-windows.ps1` (one behavioral
  via the `NONINTERACTIVE` path, plus call-site parity guards).

### Changed
- **Six bash prompt sites** migrated onto `prompt_default`:
  `show_category_menu`, `ask_tool` (`interactive.sh`),
  `detect_previous_install` (`progress.sh`), `offer_ollama_model`
  (`ai-tools.sh`), and `select_profile_interactive` + its confirm sub-step
  (`wizard.sh`).
- **Windows profile menu** (`main.ps1`) now defaults to **developer (2)** on
  Enter — previously Enter fell through to "Invalid choice". The three OSes
  now share the same Enter-selects-developer behavior.
- **`docs/REFACTOR-SELECTORS.md`** updated to record the shipped (narrower)
  approach versus the originally proposed `select_one`/`select_multi`.

### Removed
- **`read_with_timeout`** (`interactive.sh`) — superseded by `prompt_default`'s
  built-in timeout; it had no remaining callers.

## [5.5.0] - 2026-05-08

Skip granular: closes Deney's wishlist ("se ja fez partes anteriores
tem que ter algo para pular mais facil"). The `setup.sh` post-install
prompts (dotfiles, terminal blueprint) are now gated on per-section
state. Re-running `setup.sh` after a successful previous run silently
skips sections that already completed, instead of asking again.

This is a **MINOR** version bump because the menu shape of
`detect_previous_install` changed (3 options -> 4 options), which
is user-visible behavior even though no flag/API broke.

### Added
- **Section state helpers** in `src/core/progress.sh`:
  - `mark_section_done <name>` — idempotent append to state file
  - `is_section_done <name>` — 0/1 check
  - `list_sections_done` — echo space-separated list
  - `clear_sections_done` — reset sections line only

  State file gains a new optional line `sections_done=...`. Existing
  state files without the line continue to work; helpers create the
  line on first call.

- **`setup.sh` section gating**: dotfiles and terminal-blueprint
  prompts are skipped (with informative `log_info`) when the section
  is marked done. After a successful run of either, the section is
  marked. No behavior change in `--unattended` mode (which never ran
  these prompts to begin with).

- **`detect_previous_install` 4-option menu**:
  ```
  1) Continue (skip sections marked done: <list>)
  2) Reinstall everything (re-run all sections regardless of state)
  3) Fresh install (clear state, start over)
  4) Cancel
  ```
  Default = 1. Option 2 calls `clear_sections_done`, option 3 deletes
  the state file. The prompt always surfaces `[1-4, default=1]`,
  consistent with v5.4.0/v5.4.4/v5.4.6 default-surfacing convention.

### Fixed
- **`save_install_state` no longer clobbers `sections_done`**.
  Previous version emitted only the 4 metadata fields, so any
  `sections_done` line written by `mark_section_done` was wiped on
  the next save (the final save at end of `setup.sh`). Regression
  test added.

### Added (tests)
- 8 bats regression tests (`v5.5.0`) in `tests/test-regressions.bats`:
  helper behavior, idempotency, multi-section, clear/preserve,
  state file integrity across saves, menu shape, setup.sh wiring.

- 3 Pester behavior scaffolds (Skip gate) in `tests/pester/winget.Tests.ps1`:
  template tests for Windows CI runner. Documents the `winget.ps1`
  refactor required (extract to `.psm1` module + thin runner) before
  tests can flip from Skip to active.

### Docs
- `CONTRIBUTING.md`: admin policy section — PRs over branch-protection
  bypass. Default release flow now documented as PR-based.
- `docs/REFACTOR-SELECTORS.md`: planning document for unifying the
  three selection mechanisms (`wizard.sh`, `interactive.sh`,
  `group-selector.sh`) into `src/core/select.sh`. Marked v5.6.0+.

## [5.4.8] - 2026-05-08

Discovered via v5.4.7 dry-run audit on `setup.sh --dry-run --unattended -y full`.
macOS dispatcher emitted `WARN Unknown package file: winget-developer.txt`
and the same for `winget-full.txt`. Asymmetric with Linux (which handles
all brew-cask-* variants in one branch).

### Fixed
- **`macos/main.sh`: silence `winget-developer.txt` and `winget-full.txt`**
  as Windows-only, same as `winget.txt`. The case branch now matches
  all three files.

### Added (tests)
- 1 regression test (`v5.4.8`) in `tests/test-regressions.bats`:
  macos dispatcher pattern (all winget-*.txt covered). Suite: 24/24 OK.

## [5.4.7] - 2026-05-07

Closes the last orchestrator that was still under wave-level retry.
v5.4.5 dropped `retry_with_backoff` around snap/flatpak in
`linux/main.sh`; ai-tools (also an orchestrator) was missed. v5.4.7
fixes the asymmetry — same rationale as `dev-env.sh:138` which never
had retry.

### Fixed
- **`linux/main.sh`: ai-tools dispatcher no longer wrapped in
  `retry_with_backoff`.** Wrapping an orchestrator multiplies failures
  (each retry re-records the same failed sub-installer). The brew/apt
  formulae paths still keep retry where it belongs (atomic transient
  ops); the orchestrator boundary is now consistent across the dispatch
  loop.

### Added (tests)
- 1 regression test (`v5.4.7`) in `tests/test-regressions.bats`:
  ai-tools dispatcher pattern (no retry_with_backoff). Suite: 23/23 OK.

## [5.4.6] - 2026-05-07

Closes the remaining two interactive prompts that violated the v5.4.0
"surface default inline" convention. ai-tools ollama prompt and
group-selector bash fallback both treated Enter as a silent default
without showing the user what would happen.

### Fixed
- **ai-tools.sh ollama prompt: surface default=2 (Skip).**
  `Select [1-2]:` previously hid the default; Enter silently triggered
  the `*)` catch-all (skip). Now: `Select [1-2, default=2]:`. Skip path
  also upgraded from `log_debug` to `log_info` — v5.4.0 convention is
  to make non-actions visible, not hide them behind a debug flag.

- **group-selector.sh bash-fallback: surface default=none.**
  Prompt listed valid inputs (`'all'`, `'none'`, numbers) but didn't
  say what Enter does. Empty input was case-matched to `none`;
  behavior unchanged, prompt now shows `[default=none]`.

### Added (tests)
- 3 regression tests (`v5.4.6`) in `tests/test-regressions.bats`:
  ai-tools default=2 surfaced, skip log upgraded to log_info,
  group-selector default=none surfaced. Suite: 22/22 OK.

## [5.4.5] - 2026-05-07

Cross-OS classifier parity. Snap (Linux), Flatpak (Linux), and WinGet
(Windows) installers now emit the same actionable failure reasons +
hints that brew-cask gained in v5.4.2. `linux/main.sh` drops external
`retry_with_backoff` around snap/flatpak waves (mirrors `macos/main.sh:215`
NOTE from v5.4.2). apt dispatcher unchanged — `apt.sh` has its own
internal `apt-get` retry that handles repo timeouts at the right layer.

### Fixed
- **Snap installer (Linux): single-attempt + classifier**
  (`src/platforms/linux/install/snap.sh::snap_install`). Previously
  `retry_with_backoff sudo snap install` retried 3× on deterministic
  errors (snap missing, classic flag missing) wasting ~50s each. Now:
  single attempt, 4 classifier branches (not-found / classic / already
  installed / network), each with an actionable hint.

- **Flatpak installer (Linux): single-attempt + classifier**
  (`src/platforms/linux/install/flatpak.sh::flatpak_install`). Same
  retry pattern dropped, classifier added (Nothing matches / already
  installed / permission / network).

- **WinGet installer (Windows): classifier added**
  (`src/platforms/windows/install/winget.ps1::Install-WinGetPackage`).
  Previously generic "Failed to install" with no reason. Now: 4
  branches (No package found / already installed / hash mismatch /
  network) with hints. WinGet was already single-attempt — no retry to drop.

### Changed
- **`linux/main.sh`: snap/flatpak dispatchers no longer wrapped in
  `retry_with_backoff`.** Mirrors `macos/main.sh:215` decision from
  v5.4.2: per-package classifier surfaces the actionable reason; the
  wave-level retry was multiplying deterministic failures. apt
  dispatcher unchanged (apt.sh handles repo timeouts internally).

### Added (tests)
- 4 regression tests (`v5.4.5`) in `tests/test-regressions.bats`:
  snap not-found, snap classic-required, flatpak not-found, linux
  main.sh dispatcher pattern (no retry_with_backoff around snap/flatpak).
- 1 Pester contract test (`tests/pester/winget.Tests.ps1`) covering
  the WinGet classifier branches. Source-content fingerprint —
  Windows CI runner with winget should layer real behavior tests on top.

## [5.4.4] - 2026-05-07

Same class of bug as v5.4.0: another interactive prompt treated Enter as
silent acceptance of "Update" without showing the default. README also adds
a callout so `--unattended -y` is discoverable for users who want a
hands-off install on a fresh machine.

### Fixed
- **`detect_previous_install` prompt surfaces `default=1`.**
  `src/core/progress.sh:109` displayed `Select [1-3]:` and treated Enter as
  Update via the `*) return 0` catch-all. Same bug class fixed in
  `show_category_menu` at v5.4.0 — convention slipped past this prompt.
  One-line fix mirrors that pattern: `Select [1-3, default=1]:`.

### Changed
- **README highlights `./setup.sh -y full`** as the skip-everything path.
  Callout above the Common Usage code block + inline comment now reads
  "skips ALL prompts" so new users notice it without scanning the flag table.

## [5.4.3] - 2026-05-06

Fixes a silent skip in the terminal blueprint reported by Deney as
"pasta nao existente skippa o install".

### Fixed
- **`select_preset()` falls back to project config when chosen preset
  is missing.** Before: hit `return 1` and the entire starship install
  was silently skipped. Now: warns, falls back to
  `data/dotfiles/starship/starship.toml` (always present in repo), and
  only fails hard if THAT is also missing — with an actionable hint
  (`cd <repo> && git pull && bash terminal-setup.sh --interactive`).

### Added (tests)
- 1 regression test (`v5.4.3`): builds a fake repo with project_config
  but missing `presets/minimal.toml`, picks preset 2, asserts the
  fallback to project_config kicks in instead of silent return 1.

## [5.4.2] - 2026-05-06

Three concrete failures from Deney's run, three concrete fixes.

### Removed
- **`uv:fastapi-mcp`** from `data/packages/ai-tools-full.txt`. fastapi-mcp
  is a Python *library* (no CLI executable), and `uv tool install` only
  works for packages with entry points. brew said `No executables are
  provided by package fastapi-mcp; removing tool` — accurate. Library-only
  packages belong in per-project venvs, not global tool installs.

### Added
- **Cask classifier handles `conflicts with cask X`** (commit `5.4.2`).
  Previously `Failed: github (exit 1)` — generic. Now:
  `Failed to install: github (conflicts with another cask (github@beta))`
  followed by `→ Fix: brew uninstall --cask github@beta && brew install --cask github`.
- **Actionable hints** on every cask classification branch — `app exists`,
  `cask not found`, `network error`, and the new `conflicts with` all
  print the exact recovery command immediately after the failure.

### Changed
- **`retry_with_backoff` removed from the brew-cask wave wrappers** in
  `src/platforms/macos/main.sh`. Cask failures are mostly deterministic
  (app exists, cask renamed, conflicts) — retrying wastes ~50s and gets
  the same error. Per-package classifier + hint tells the user what to
  fix; transient network errors recover by re-running setup.sh
  (idempotent). Same rationale that removed retry around dev-env in v5.1.0.

### Added (tests)
- 2 new regression tests cover the conflict classifier and the `--force`
  hint on `app exists`.

## [5.4.1] - 2026-05-06

Critical fix from Deney's M5: terminal-setup was writing config blocks
INTO the repo file when ~/.zshrc was a symlink (the typical state after
running `dotfiles-install.sh`).

### Fixed
- **`terminal/setup.sh::setup_shell()` detects symlinked SHELL_RC and
  diverts the appended block to `~/.zshrc.local`** (already sourced by
  the repo's `data/dotfiles/zsh/zshrc` as the user-overrides hook).
  Without this, every user with the dotfiles symlink ended up with an
  uncommitted "Update zshrc" diff in their local clone after running
  the terminal blueprint — config from one user contaminating the repo
  artifact intended for everyone.
- **`-s "$SHELL_RC"` guard before backup**: if the divert lands on a
  brand-new empty `.zshrc.local`, we skip the backup step (nothing to
  back up).

### Added
- **Regression test** `[v5.4.1] terminal-setup diverts to .zshrc.local
  when target is symlink` — sets up a temp symlink rc, runs setup_shell
  in dry-run, asserts SHELL_RC was rewritten to `.zshrc.local`.

## [5.4.0] - 2026-05-06

UX repair driven by Deney's testimony: dev-env sub-prompts were
defaulting against the user's intent, and the install flow visually
"ended" mid-way at the terminal blueprint step.

### Changed
- **`show_category_menu` default is now 1 (All), not 3 (Skip).**
  When the user picks `developer` or `full`, the wizard would ask
  "Install Node? / Python? / mise?" with a 30s timeout — and silently
  default to **Skip** if the user took longer to read the menu than the
  timeout. Net effect: dev-env got installed only for users who clicked
  fast. New default matches the profile they explicitly chose.
- **`ask_tool` default is now "y", matching the `[Y/n]` prompt convention.**
  Previously the prompt said `[Y/n]` (capital Y suggests default=yes),
  but the actual timeout default was `"n"`. Pure UX trap — Enter now
  installs as the prompt implies.
- **Optional config layers section in `setup.sh`** now has a clear visual
  separator and a `[1/2]` / `[2/2]` counter on the dotfiles + terminal
  blueprint prompts, plus an explicit "installer is finishing up" line
  after the terminal blueprint returns. The blueprint's own "Done!"
  message no longer makes the main installer feel like it crashed mid-flow.

### Added
- **2 regression tests** (`test-regressions.bats`) guard against the
  defaults silently flipping back to the broken values.

### Notes
- Numbering convention is now consistent in spirit: in every menu, the
  default option is the one matching the user's apparent intent. No
  source-code-level renumbering — the change is in defaults, not order.
- Dotfiles + terminal-blueprint prompts keep `[y/N]` defaults because
  they MUTATE files in $HOME (.zshrc, .gitconfig). Backups exist
  (`~/.dotfiles-backup/`), but silent overwrite on timeout would be
  worse UX than the current explicit opt-in.

## [5.3.3] - 2026-05-06

### Fixed
- **README version badge synced with tag** (was lagging at 5.3.1 since
  the v5.3.2 commit didn't bump it). Cosmetic — no behaviour change.

## [5.3.2] - 2026-05-06

### Changed
- **`positron` and `rstudio` moved from `creative` → `code-editors` group.**
  Both are IDEs (Positron is Posit's multi-language successor to RStudio,
  covering R + Python). They belong with code editors, not with design
  software (Inkscape / GIMP / Affinity). README group table updated to
  match.

## [5.3.1] - 2026-05-06

Cleanup pass + refreshed demo recording.

### Removed
- **Nerd fonts** (`font-jetbrains-mono-nerd-font`, `font-symbols-only-nerd-font`,
  `font-sketchybar-app-font`) from `brew-cask-developer.txt`,
  `brew-cask-full.txt`, and `groups/essentials.txt`. The Nerd font is
  installed by `terminal-setup.sh` — keeping it in the cask lists triplicated
  the same artefact. The Sketchybar font is too niche for default install.
- **`meetingbar`** and **`hiddenbar`** from `brew-cask-full.txt` and
  `groups/productivity.txt`. Cosmetic / niche apps; user can `brew install`
  manually if wanted.
- **`claude-code`** (plain) from `groups/ai-editors.txt`. Only
  `claude-code@latest` (rolling channel CLI) ships now — the plain cask
  was creating an ambiguous duplicate.

### Changed
- **`assets/demo.gif`** re-recorded with current `setup.sh --dry-run -y minimal`.
  16 frames, 12.78 s, 418 KB (was a 51 KB placeholder from Feb 2026 with stale
  output). Source `assets/demo.cast` regenerated alongside.

## [5.3.0] - 2026-05-06

Interactive cask group selector. `setup.sh --groups` replaces the
all-or-nothing cask install with a multi-select prompt over 10 curated
groups (browsers, ai-editors, code-editors, dev-infra, productivity,
communication, knowledge, media, creative, essentials).

### Added
- **`--groups` / `-g` flag** in `setup.sh`. When set, brew-cask-* dispatch
  is deferred to a single interactive selector after the rest of install
  completes. Pick groups by name; only chosen groups install.
- **`src/core/group-selector.sh`**: implementation with two backends —
  `gum choose --no-limit` if installed (Charm's TUI), bash fallback with
  numbered comma-separated input otherwise. The selector auto-installs
  `gum` via brew if missing (skipped in DRY_RUN).
- **`data/packages/groups/*.txt`** (10 files): one per cask group, format
  matches existing brew-cask-*.txt with a leading `# <Group Name> — <desc>`
  comment used as the menu label.
- **`gum`** added to `brew-developer.txt` so the selector backend is
  available for any developer/full install.

### Changed
- `src/platforms/macos/main.sh`: brew-cask-developer.txt and
  brew-cask-full.txt cases now check `GROUPS_MODE` and skip when set;
  group-selector runs once at the end of the dispatch loop.

### Notes
- `--groups` is additive over the chosen profile: developer/full keeps
  installing all formulae + Rust CSV + AI tools as before. Only the
  cask install changes from "all" to "user-picked groups".
- Bash fallback works on any host; gum is the polished UX.

## [5.2.0] - 2026-05-06

Doc consolidation + preflight performance. Driven by user feedback that
separate runbook files (`tools/M5-RUNBOOK.md`, `tools/ATUIN-RUNBOOK.md`)
were getting lost — out-of-sight, out-of-mind. README is the single
entry point now.

### Added
- **README.md `Workflows` section** with two collapsed `<details>`
  blocks: full M5 migration runbook and Atuin shell-history sync guide.
  Recovery cookbook for codex/claude-code/gemini-cli npm-tool failures
  is embedded inside the migration block.
- Preflight tool now reports `total registry checks` and `parallelism`
  in the header.

### Changed
- **`tools/preflight-brew-names.sh` parallelized** with `xargs -P 10`.
  Sequential 35s → 6.6s end-to-end (5.3× speedup). Worker function
  `classify_one` handles formula/cask/npm/bun/uv/curl in one place;
  `PREFLIGHT_PARALLELISM=N` env var tunes concurrency.
- README version badge bumped to 5.2.0.

### Removed
- **`tools/M5-RUNBOOK.md`** and **`tools/ATUIN-RUNBOOK.md`** — content
  folded into README's `Workflows` section. Single source of truth so
  ops docs are visible from the front page.

### Notes
- Group selector with `gum` (`setup.sh --groups`) was scoped out of this
  release — needs design iteration in v5.3.0.

## [5.1.4] - 2026-05-06

UX gap closure + ai-tools tag pinning. Driven by a second-pass review
of the M5-bound flow: the terminal blueprint is a separate script users
were not discovering after `setup.sh`, and ai CLIs were not pinned to
their rolling channel.

### Added
- **`setup.sh` now offers terminal blueprint at the end** (interactive
  only). Same prompt pattern as the dotfiles offer right above it. Skip
  prints the standalone command for later use:
  `bash terminal-setup.sh --interactive`.
- **README.md restored "Just Want the Terminal?" section** with full
  usage examples (`--interactive`, `--dry-run`, full install), component
  table, and the demo asciinema gif. The section had been removed in the
  v5.0.0 README streamline; surfaced from real user feedback that the
  command "had disappeared".
- **`tools/M5-RUNBOOK.md` §4** is now an explicit "Terminal blueprint"
  step between install and verification.

### Changed
- **`@openai/codex` pinned to `@latest`** in `data/packages/ai-tools-full.txt`
  for symmetry with the brew cask `claude-code@latest`. npm install
  semantics are equivalent (latest is the default tag) — change is for
  explicitness so users see the channel intent in the package list.

### Notes
- `claude` (Claude Desktop), `claude-code` and `claude-code@latest`
  (CLI rolling channel) are intentionally distinct casks. We keep
  `claude-code@latest` in `brew-cask-full.txt`.

## [5.1.3] - 2026-05-05

Pre-flight breadth release. Closes the last gaps in pre-install validation
so a fresh install on a new machine can be gated upfront instead of
discovering registry/disk problems mid-run.

### Added
- **`check_disk_space()`** in `src/core/platform.sh`, plugged into
  `verify_all()`. Aborts (interactive) or warns (non-interactive) when
  free space on `/` is below 10 GiB. Full profile installs ~5 GiB; running
  out mid-install leaves a partial state.
- **AI-tools registry validation** in `tools/preflight-brew-names.sh`.
  For every entry in `data/packages/ai-tools-full.txt`, hits the
  appropriate registry (`registry.npmjs.org` for `npm:` and `bun:`,
  `pypi.org` for `uv:`/`pipx:`, the official URL for `curl:ollama`) and
  flags missing/renamed packages before they fail at install time.

## [5.1.2] - 2026-05-05

UX visibility release. Idempotent skips were already happening but
hidden behind `log_debug` (only visible with `VERBOSE=true`), so users
running `setup.sh full` on a machine with most packages already installed
saw only progress bars and no per-package confirmation.

### Changed
- **Per-package skip is now visible by default** in `brew.sh`,
  `brew-cask.sh`, `csv.sh`, `dev-env.sh`, `fnm.sh`, `uv.sh`. Format:
  `[skip] <name> (already installed)`.
- **Per-wave summary line** prints at the end of each formula/cask/csv
  wave: `Summary (brew-developer.txt): N installed, M skipped, K failed`.
  CSV pipeline now distinguishes `installed` (newly installed this run)
  from `skipped` (already in PATH) — previously they were merged under
  one counter.

No behavior change to install logic — strictly observability.

## [5.1.1] - 2026-05-05

Pre-flight tooling so the `full` profile can be validated against an
inventory snapshot before running `setup.sh` on a fresh machine.

### Added
- **`tools/preflight-brew-names.sh`** — read-only validator that diffs the
  macOS `full` profile against the M1 inventory snapshot in
  `.migration/MacBook-Pro-de-Fundacao-4-snapshot/`, computes the exact set
  of formulae/casks that will actually install on a fresh machine, and
  runs `brew info` on each name to classify the result as ok / not-found /
  third-party-tap / tap-not-added. Exits non-zero on any name that won't
  resolve, so it's usable as a pre-flight gate. Also covers hardcoded
  brew references inside install scripts (fnm, uv, pnpm, mise,
  oven-sh/bun/bun) that aren't listed in any `.txt` profile.
- **E2E regression test for `BREW_LOG`** (`tests/test-regressions.bats`):
  stubs `brew`, runs `_brew_cask_install` through it, and asserts the log
  file contains both the `=== brew install --cask <name> (rc=N) ===`
  header and the captured stderr verbatim. Closes the observability loop
  that the prior classification tests left open.

## [5.1.0] - 2026-05-05

Diagnostic + brew-centralization release driven by a real-world full
install on macOS (Deney) where ~56 dev/full formulae and most casks
silently never installed. Root causes traced, fixed, and pinned by tests.

### Added
- **`BREW_LOG="${TEMP_DIR}/brew-install.log"`** — captures stderr of every
  `brew install [--cask]` per package. The completion summary now points to
  this file when failures exist, ending the era of "Failed to install: X"
  with no reason.
- **Failure classification for cask installs** in `brew-cask.sh`. Errors are
  matched into a human-readable reason and surfaced inline:
  `(app exists at /Applications)`, `(cask name not found in any tap)`,
  `(network error)`. Same treatment lighter on `brew.sh` for formulae.
- **Trophy-style regression suite** (`tests/test-regressions.bats` +
  additions to `test-integration.bats` and `test-core-errors.bats`):
  15 tests, each named with the commit it guards. Integration tests share
  one cached dry-run via `setup_file` to keep the suite fast.

### Changed
- **fnm/uv/pnpm/bun installers prefer `brew install`** before falling back
  to curl/npm. Centralizes package management on Homebrew (single source of
  truth, idempotency, upgrade/uninstall via the same toolchain). Linux
  runners without brew transparently use the existing curl/npm fallback.
- **`brew tap oven-sh/bun` runs explicitly before `brew install bun`** to
  avoid silent failures when brew's auto-tap can't reach the third-party
  source (proxies, restricted networks).
- **`record_failure` deduplicates within a process**. When a retried
  orchestrator re-recorded the same name on each attempt, the failure
  appeared N times in the summary; now it appears once.
- **`dev-env.sh` is no longer wrapped in `retry_with_backoff`** by the
  platform main scripts. Retrying an orchestrator with side effects
  multiplied failures and re-prompted interactive questions; atomic curl
  / brew calls inside the orchestrator handle their own retry where it
  matters.

### Fixed
- **`brew.sh` respects `--developer` and `--full` flags** (`fa03a06`).
  Used to hardcode `load_packages "brew.txt"` and so loaded the same 5
  base formulae three times — the developer/full waves (mise, jq, gh,
  postgresql@17, ...) silently never installed.
- **`parse_flags` accepts flags in any position** (`c44301d`). Previously
  `setup.sh developer --dry-run` silently dropped `--dry-run` and ran a
  real install, because parsing broke at the first non-flag.
- **CSV row reader uses FD 3** (`e24dc9a`). `while read; done < <(awk ...)`
  was being drained by brew/cargo subprocesses inside the loop, which
  consumed CSV rows that should have been the next iteration. Visible as
  CSV pipe fragments interleaved with brew output, plus silently skipped
  packages.
- **fnm install no longer passes a stray `--`** to the official installer
  (`b4c2d10`). The fnm script rejected it as `Unrecognized argument --`
  and aborted before processing real flags — fnm never installed on
  fresh machines.
- **Wizard menu is visible to users** (`02a73b2`). `select_profile_interactive`
  printed the menu via `echo` to stdout, but the caller used
  `profile=$(select_profile_interactive ...)` — command substitution
  swallowed the entire menu. All UI now goes to stderr; only the chosen
  profile remains on stdout as the function's return value.

## [5.0.0] - 2026-05-04

### Notes for existing forks
This release rewrites `main` history (force push). Forks must run:
    git fetch origin && git reset --hard origin/main
to sync. Profile.txt files reference new package file names — see naming
convention below.

### Added
- **`data/packages.csv` — CSV-driven Rust tool catalog (Onda 5)**: 52 Rust tools
  in 5 categories (`rust-cli`, `rust-dev`, `rust-data`, `rust-tui`, `rust-shell`).
  Schema: `category,name,brew,cargo,binary,prefer,description`. Resolves the
  brew↔cargo duplication via per-row `prefer` column with fallback. Idempotent
  via binary-in-PATH check.
- **`src/core/csv.sh`**: `install_csv_category()` reads CSV and installs each
  entry respecting `prefer` (brew or cargo) with cross-source fallback.
- **`h rust-cli` / `h rust-dev` / `h rust-data` / `h rust-tui` / `h rust-shell`**:
  shell helpers in `data/dotfiles/shared/functions.sh` that read the CSV via
  symlink (`~/.config/os-postinstall/packages.csv`) and list tools with
  descriptions. Plus `h <toolname>` does direct lookup in the CSV (e.g.
  `h ast-grep` shows category, brew/cargo source, binary, prefer, description).
- **`h ai`** topic in shell helpers: lists AI CLI tools (claude, codex, gemini,
  copilot, opencode, ollama, etc.) and documents MCP management via `mcpl`.
- **`mise`** in `brew-developer.txt` as preferred tool version orchestrator.
  `dev-env.sh` now offers mise install as first step (fnm/uv kept as fallback).
- **Profile file `apt-full.txt`** for Linux personal pick (Bragatte). Linux now
  has tri-level structure matching macOS.
- **Three new package files** for macOS tri-level: `brew-developer.txt`,
  `brew-full.txt`, `brew-cask-full.txt`.

### Changed
- **AI tools migrate from pipx to uv** (`markitdown`, `fastapi-mcp`). pipx
  remains in `brew-developer.txt` as documented fallback only if uv ever fails.
- **`ai-tools.sh` extended with `bun:`, `uv:`, `pipx:` prefix cases** (was
  npm/curl only). Loads from `ai-tools-full.txt` (was `ai-tools.txt`).
- **`apt.sh`, `flatpak.sh`, `snap.sh`, `brew-cask.sh` accept `--developer` /
  `--full` flags** (`-post` kept as backwards-compat alias).
- **Profile naming convention** updated globally — see breaking change below.

### Removed (Onda 5 cleanup)
- **`src/install/rust-cli.sh`** — Rust tools moved to `data/packages.csv`.
- **`src/install/cargo.sh`** — replaced by `src/core/csv.sh::install_csv_category`.
- **`data/packages/cargo-developer.txt`** — replaced by `csv:rust-*` entries.
- Refs to `rust-cli.sh` and `cargo-developer.txt` cleaned up across:
  `linux/main.sh`, `macos/main.sh`, `state.sh`, `progress.sh`, `validate-profiles.sh`,
  `macos-inventory.sh`, `tests/test-core-progress.bats`, `tests/test-linux.sh`,
  `tests/test_harness.sh`, `tests/pester/progress.Tests.ps1`, README, CONTRIBUTING,
  `docs/installation-profiles.md`.

### Changed (refactor — Onda 1 of curation cycle)
- **Package file naming reflects profile membership** (breaking, internal):
  Renamed all package files so the suffix indicates which profiles include the file.
  `<source>.txt` = base (all profiles), `<source>-developer.txt` = dev + full,
  `<source>-full.txt` = full only (Bragatte's personal pick).
  - `apt-post.txt` → `apt-developer.txt`
  - `brew-cask.txt` → `brew-cask-developer.txt`
  - `cargo.txt` → `cargo-developer.txt`
  - `npm.txt` → `npm-developer.txt`
  - `flatpak.txt` → `flatpak-developer.txt`
  - `flatpak-post.txt` → `flatpak-full.txt`
  - `snap.txt` → `snap-developer.txt`
  - `snap-post.txt` → `snap-full.txt`
  - `ai-tools.txt` → `ai-tools-full.txt`
  - New files (full-only): `brew-developer.txt`, `brew-full.txt`, `brew-cask-full.txt`
- Installer scripts (`apt.sh`, `flatpak.sh`, `snap.sh`, `brew-cask.sh`) accept
  new flag `--developer`/`--full`. Old flag `--post` kept as backwards-compat alias.
- Dispatchers in `src/platforms/{linux,macos}/main.sh` and `src/core/progress.sh`
  updated to recognize the new naming.
- `tools/validate-profiles.sh` rewritten to validate the new naming convention.
- `docs/installation-profiles.md`, `README.md`, `CONTRIBUTING.md` updated.

### Migration note for forks
If you forked before this commit, update your `profile.txt` files to use the
new names. The file rename was performed via `git mv` so history is preserved.

## [4.2.2] - 2026-04-18

### Fixed
- `developer` profile no longer ships AI/MCP tooling — removed `ai-tools.txt`
  from `data/packages/profiles/developer.txt`. Restores the contract declared
  in `config.sh:12` ("developer: System + development tools (cargo, npm)").
  Regression introduced by commit `b1af359` (Feb 2026).

### Added
- `tools/validate-profiles.sh` — manual validator that catches profile
  contamination regressions. Manual only per project policy (no CI/CD).

### Changed
- **History sanitization** (2026-04-18): absolute personal paths
  (`~/...`) removed from historical commits via
  `git filter-repo`. Paths replaced with `$PROJECT_ROOT` for the repo root
  and `~/` for other home references. The personal email
  `marcelobragatte@gmail.com` is public (GitHub profile) and was
  intentionally kept.
- **`.planning/` no longer tracked**: internal GSD workflow state moved to
  `.gitignore`. Previously-tracked files removed from the index.

### Notes for existing clones
If you cloned before 2026-04-18, run:

    git fetch origin && git reset --hard origin/main

to sync with the rewritten history. Forks are unaffected — fork owners must
rebase independently.

## [4.1.0] - 2026-02-22

### Added
- 105 new tests: 83 bats (platform, progress, dotfiles, interactive, profile validation, integration, contract parity) + 22 Pester (logging, errors, packages, progress modules)
- `safe_curl_sh()` download-then-execute helper for all curl|sh sites (5 call sites migrated)
- Semantic exit codes (0/1/2) via `errors.sh` and `errors.psm1` with `compute_exit_code()`
- Exit code propagation through full parent-child orchestrator chain
- `verify_bash_version()` warn-not-block for macOS Bash 3.2 compatibility
- SECURITY.md with responsible disclosure policy and private vulnerability reporting
- NOTICE file for Apache 2.0 attribution
- `tests/contracts/bash-ps-parity.md` mapping 16 Bash↔PowerShell function pairs
- Fork-ready documentation: submodule init instructions, Pester prerequisites, test commands

### Changed
- License migrated from MIT to Apache 2.0 (attribution requirement)
- 36 broken Flatpak IDs corrected to valid reverse-DNS format across flatpak.txt and flatpak-post.txt
- `pipefail` added to all 12 subshell scripts
- README clone command now includes `--recurse-submodules`
- ADR-001 amended to document semantic exit code strategy
- ADR-009 added documenting curl|sh trust model

### Removed
- 3 discontinued apps archived (Skype, TogglDesktop, Workflow)

### Fixed
- EXIT trap bug: `cleanup()` now preserves non-zero exit codes
- Pester v5 module-scoped mocking: added `-ModuleName` to all Write-Host mocks
- SECURITY.md vs README vulnerability reporting contradiction resolved
- Version badge updated from 3.3.0 to 4.1.0
- `cargo.txt` duplicate entry removed
- `brew.txt` trailing whitespace cleaned

## [4.0.0] - 2026-02-18

### Added
- 37 bats-core unit tests covering logging.sh, errors.sh, packages.sh, idempotent.sh
- Lint runners: `tools/lint.sh` (ShellCheck for 30+ files) and `tools/lint.ps1` (PSScriptAnalyzer)
- Windows CLI switches: `-DryRun`, `-Verbose`, `-Unattended` matching Bash flag behavior
- Windows `[Step X/Y]` progress counters and completion summary (profile, platform, duration, failures)
- `[CmdletBinding()]` on all 12 exported PowerShell functions for native `-Verbose`/`-Debug` support
- Shared `idempotent.psm1` module with `Test-WinGetInstalled`, `Test-NpmInstalled`, `Test-CargoInstalled`
- README sections: EXTRA_PACKAGES/SKIP_PACKAGES customization, Windows Troubleshooting
- GitHub Release v4.0.0

### Changed
- VERBOSE check uses `== "true"` instead of `-n` (boolean correctness in 5 locations)
- NONINTERACTIVE/UNATTENDED unified via bridge in config.sh (6 downstream consumers)
- Merged `src/installers/` into `src/install/` (single directory)
- Color/format variables consolidated in logging.sh as SSoT (removed from platform.sh)
- DATA_DIR readonly guard prevents re-source collision

### Removed
- `kite.kite` from winget.txt (discontinued 2022)
- Duplicate `src/installers/` directory

### Fixed
- ARCHITECTURE.md corrected to reflect actual error handling strategy (no set -e, per ADR-001)
- PowerShell duplicate idempotent check functions consolidated

## [3.3.0] - 2026-02-08

### Added
- Cross-platform setup framework (Linux, macOS, Windows)
- Data-driven package management with `data/packages/*.txt`
- Profile composition system (minimal, developer, full)
- Core modules: platform detection, idempotency, logging, error handling
- Progress feedback with step counting and DRY_RUN banners
- Completion summary with timing and failure tracking
- Windows foundation with WinGet installer and orchestrator
- Modular dotfiles system with symlink manager
- Zsh installation script with profile selection
- Professional README with 23 sections
- CONTRIBUTING.md rewrite
- GitHub issue/PR templates with ShellCheck requirements
- 7 Architecture Decision Records for current codebase

### Changed
- Complete repository restructure to `src/`, `data/`, `platforms/` layout
- Package lists extracted from scripts to `data/packages/*.txt`
- Platform orchestrators migrated to `src/platforms/`
- Dotfiles translated to English, Claude-specific config moved to `.zshrc.local`
- Setup entry point with `--dry-run`, `--verbose`, `--unattended` CLI flags and positional profile argument

### Removed
- Legacy BMAD framework and agent-os artifacts
- 300+ obsolete files (backup dirs, legacy docs, empty stubs)
- CI/CD workflows (manual execution only going forward)
- Outdated ADRs, test guides, and manual test scripts
- Dead symlinks and migration tools

### Fixed
- All internal paths updated to match new structure
- Cross-process failure tracking via shared log file
- Broken cargo.txt path reference
- Dead `setup-with-profile.sh` references replaced

---

> **Nota:** As versões abaixo são registro histórico. Alguns diretórios e ferramentas
> referenciados (`.agent-os/`, `tools/`, `scripts/`, `platforms/`, `configs/`,
> symlinks de compatibilidade, migration tools) foram removidos ou reestruturados na v3.3.0.

## [3.2.2] - 2025-08-03

### Fixed
- Standardized documentation references and file extensions
- Fixed inconsistencies between symlinks and actual file locations
- Translated remaining Portuguese sections to English

## [3.2.1] - 2025-08-03

### Added
- Documentation symlinks for backward compatibility
- Global documentation structure

## [3.2.0] - 2025-08-03

### Added
- Lightweight agent orchestration system (`.agent-os/`)
- Documentation agent for automated doc maintenance

### Changed
- Updated dependencies and integration tooling

### Fixed
- Trailing whitespace cleanup in configuration files

## [3.1.5] - 2025-07-01

### Added
- MCP configuration with 7 essential MCPs (Context7, fetch, sequential-thinking, serena, FastAPI, A2A, system-prompts)

### Changed
- CLAUDE.md updated to v2.3.1

## [3.1.4] - 2025-07-28

### Added
- CLAUDE.md v2.3.0 with Context Engineering documentation
- CLAUDE-EXTENDED.md for detailed implementation guidance

### Changed
- Synchronized .zshrc configuration with latest shell setup

## [3.1.3] - 2025-07-27

### Fixed
- Translated remaining Portuguese sections to English across documentation

## [3.1.2] - 2025-07-27

### Fixed
- Corrected timeline dates in ROADMAP.md, PRD.md, and STORIES.md

## [3.1.1] - 2025-07-27

### Added
- Comprehensive PRD v2.0.0 with brownfield analysis
- STORIES.md aligned with PRD (user stories for recommendations, platform parity)
- PO validation deliverables (gap analysis, story tasks)

### Changed
- Testing philosophy shifted to manual-only approach
- Profile system deprecation in favor of intelligent recommendations

## [3.1.0] - 2025-07-27

### Added
- YAML/JSON/TOML configuration templates system
- Template manager (`tools/templates/manager.sh`)
- Unattended installation mode with `--unattended` flag
- CI/CD pipeline support via environment variables

### Changed
- Documentation structure aligned with CLAUDE.md requirements
- Critical docs (STATUS.md, PRD.md, STORIES.md) moved to root

### Fixed
- Documentation discovery issues
- Version consistency across project files

## [3.0.0] - 2025-01-27

### Changed - BREAKING
- Complete repository restructure following Agile Repository Structure Guide
- Scripts organized into `scripts/` directory by function
- Platform-specific code consolidated in `platforms/`
- Configuration files centralized in `configs/`

### Added
- New directory layout: `scripts/install/`, `scripts/setup/`, `scripts/utils/`, `platforms/`, `configs/`, `tools/`, `share/`
- Compatibility symlinks for backward compatibility
- Migration tools (`migrate-structure.sh`, `verify-migration.sh`)

## [2.7.0] - 2025-01-27

### Added
- Complete internationalization (English translation)
  - All user-facing content, code comments, and documentation translated
  - 4-phase structured translation approach

### Changed
- All shell scripts translated (setup.sh, install_rust_tools.sh, etc.)
- Consistent English terminology throughout codebase

## [2.6.0] - 2025-07-26

### Added
- Automated installation and update scripts for development tools
- Automatic version checking and backup creation before updates

## [2.5.1] - 2025-07-25

### Changed
- **BREAKING**: CI/CD workflows converted to manual execution only (`workflow_dispatch`)
- All workflows now require explicit `reason` input for audit trail

### Added
- Testing guidelines documentation

### Security
- Reduced attack surface by eliminating automatic workflow execution

## [2.5.0] - 2025-07-24

### Added
- AI development tools integration (MCPs configuration support)
- Cross-platform installer for AI tools (`install_ai_tools.sh`)
- Diagnostic script for installation verification
- Product-focused git configuration system (templates, hooks, aliases)
- Context Engineering documentation (CLAUDE.md v2.3.0)

### Changed
- Updated LICENSE copyright to "Bragatte, M.A.S"

### Fixed
- Corrected `claude.json` filename references

## [2.4.0-alpha.1] - 2025-07-23

### Added
- Profile-based installation system with 5 pre-configured profiles
- Interactive profile selection via `setup-with-profile.sh`
- Comprehensive user documentation (quick-start, modern-cli-tools, shell-customization, troubleshooting)

## [2.3.1] - 2025-07-23

### Security
- Fixed critical APT lock vulnerability (removed dangerous force-removal commands)
- Implemented safe wait mechanisms for package managers
- Added `package-manager-safety.sh` module

### Added
- Security test suite (10 validations, 5 integration scenarios)

### Changed
- Made `logging.sh` compatible with Bash 3.2 (macOS support)
- Repository reorganized for user-focused navigation

## [2.3.0] - 2025-07-23

### Added
- CLAUDE.md v2.3.0 for Context Engineering
- PRD.md, STORIES.md, STATUS.md, TESTING.md
- 8 Architecture Decision Records

### Changed
- Project follows Context Engineering principles
- Transparent communication about test coverage

## [2.2.0] - 2025-07-10

### Added
- Modular directory structure (install/, utils/, verify/)
- Central orchestrator script with interactive menu
- Comprehensive verification system
- Interactive desktop environment installer

### Changed
- Standardized naming convention (hyphens over underscores)
- All scripts with proper shebangs and error handling

### Fixed
- All 50 tests passing
- Script permission issues resolved

## [2.1.0] - 2025-07-10

### Added
- Test harness for validating script functionality
- Logging system and safe APT lock handling
- Security improvements across all scripts

### Changed
- All scripts use `set -euo pipefail`
- Fixed placeholder URLs (SEU_USUARIO to BragatteMAS)

### Security
- Safe APT lock waiting instead of force removal
- Logging for audit trails

## [2.0.0] - 2024-12-15

### Added
- Advanced shell enhancements (13 features):
  - Universal package manager function
  - Git credential security setup
  - Configuration backup system with rotation
  - WSL support, Docker/Podman integration
  - Adaptive themes, performance monitoring
  - Lazy loading for nvm/rbenv
  - Built-in documentation system (`zdoc`)
  - Interactive quick menu (`qm`)
  - SSH agent management, feature flags (`.zshrc.flags`)

### Changed
- Fixed sed alias conflict (renamed to `sdr`)
- Optimized xargs usage to prevent quote errors
- Removed terminal clearing from welcome message

### Fixed
- Conda access syntax errors
- Help system category navigation
- Terminal clearing issues

## [1.0.0] - Initial Release

### Features
- Basic post-install scripts for Linux
- Windows 11 setup with winget
- Anaconda installation script
- Basic zshrc configuration
