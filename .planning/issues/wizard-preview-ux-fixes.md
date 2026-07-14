# Wizard preview (PP9) + dry-run UX — findings from real use (M5 cutover, 2026-07-13)

> Source: first wizard run on a genuinely fresh machine (M5, macOS 26.5.2).
> Items 1-2 live in `preview_profile_packages()` / `select_profile_interactive()`
> (`src/core/wizard.sh`); items 3-5 in the setup.sh summary / blueprint layers.
> Fix together + bats cases. All user-facing strings in ENGLISH (owner call,
> 2026-07-13: "deixe inglês").

## STATUS (fixed same day, 2026-07-13 evening — v5.6.1 batch)

| # | Verdict | Fix |
|---|---------|-----|
| 1 | FIXED | `_preview_entry_matches_platform()` filter + hidden-count note (wizard.sh) |
| 2 | FIXED | `✓ Preview of 'X' done — nothing was installed.` footer (wizard.sh) |
| 3 | FIXED | dry-run closing block "DRY-RUN complete — NOTHING was installed" (progress.sh) |
| 4 | FIXED | "What's next" suppressed in dry-run (progress.sh) |
| 5 | FIXED | optional layers gated off entirely under DRY_RUN (setup.sh) |
| 6 | RESOLVED-BY-EXPLANATION | Duration was honest wall-clock inflated by prompt idle (24m dry vs 5m real); with #5/#7 fixed, dry-run has no prompts left |
| 7 | FIXED | dev-env runs NONINTERACTIVE for the full profile (both main.sh) |
| 8 | FIXED | menu estimates → ranges 2-5 / 5-15 / 10-30 min (wizard.sh) |
| 9 | INVALID | starship IS in packages.csv (rust-shell,65); non-install was a #10 symptom |
| 10 | FIXED (root cause found) | dispatch loops fed the profile on STDIN and real `brew install` children drained it (loop died after brew-developer.txt — forensics: M5 package-state = brew.txt+brew-developer only, Caskroom empty). Fix: FD3 loops in both main.sh (csv.sh pattern) + `install_csv_category` fails loudly on 0 entries |

Verification: bats full suite green (incl. 10 new v5.6.1 cases), ShellCheck 36/36,
dry-run E2E traverses all 10 waves, M5 real re-run = the live E2E test.

**Live E2E result (M5 re-run, 2026-07-13/14):** FD3 fix confirmed in
production — full dispatch traversed everything; 42 casks landed (vs 2
before). Residuals for a follow-up:

- `zen-browser` renamed upstream to `zen` — update brew-cask list.
- `claude-code@latest` vs plain `claude-code` (bootstrap installs the
  unpinned cask; the wave then sees a conflict) — pick ONE canonical name.
- sudo-gated pkg casks fail (correctly) under unattended: docker-desktop,
  google-drive, karabiner-elements, logi-options+ — document that these
  need one interactive pass, or a `--sudo-casks` deferred wave.
- ai-tools npm entry `@anthropic-ai/claude-code` conflicts (EEXIST on
  /opt/homebrew/bin/claude) with the brew cask installed earlier — two
  channels own the same binary; pick one (owner's rule: brew is canonical).
- ollama official script installs Ollama.app fine but its PATH step needs
  sudo → CLI symlink fails unattended; first `open -a Ollama` completes it.
- atuin is still in packages.csv (rust-shell) and got installed, though the
  owner discarded atuin in May/2026 — decide keep-in-catalog vs remove.

## 1. Preview lists package groups from other OSes (cosmetic, confusing)

`p` → profile 3 on macOS listed `apt.txt`, `winget*.txt`, `flatpak-*`,
`snap-*` alongside brew/csv groups. The title says "~176 packages on macos"
(count is filtered, correct), but the group list is not platform-filtered —
the real installer filters correctly; only the preview leaks.

**Fix:** filter displayed groups by the platform argument, same logic as the
count.

## 2. No success notice when returning from preview (owner feedback)

After the preview, `No changes made — preview only.` is immediately followed
by the full menu re-render — visually the user cannot tell whether the
preview "worked or not" (owner: "não soube se tinha rodado certo").

**Fix:** explicit, visible closing line before returning to the menu, e.g.:
`✓ Preview of 'full' done (176 packages listed) — nothing was installed.`
— with a blank line separating it from the menu.

## 3. Dry-run final summary does not state it was a simulation (owner feedback)

At the end of `--dry-run` full: `=== Dry Run Complete ===` + `[OK] All
sections completed successfully` — owner was unsure whether anything got
installed ("tem que ter um aviso no final... avisos ruins").

**Fix:** explicit final block, e.g.:
`✓ DRY-RUN complete — NOTHING was installed. 176 packages verified, 0
expected failures. To install for real: ./setup.sh (same profile).`

## 4. "What's next: h / h tools / welcome" shown after dry-run

That is POST-INSTALL guidance (the commands do not even exist on a clean
system yet). In dry-run, suppress it or replace with the call-to-action from
item 3.

## 5. Blueprint prints "Done! Restart your terminal to apply" in dry-run

Mutations ARE correctly gated (verified on the M5: no files written), but the
blueprint completion messages are not — they announce an application that
did not happen. Gate the messages too.

## 6. Investigate: `Duration: 24m 20s` for a dry-run — PARTLY RESOLVED

Real full run on the M5 finished in **5m 01s**, so the dry-run's "24m 20s"
was the ESTIMATE being printed under a wall-clock label. Fix: label it
`Duration (estimated)` in dry-run, keep real wall-clock in real runs.

## 8. Time estimates are ~5x off on modern hardware (owner feedback)

Menu promises "~30 min" for full and the dry-run said 24m; the real install
took 5m on an M5 with fast network ("a estimativa está nos derrubando
bastante"). Stale per-package timings inflate expectations. Recalibrate
(or present a range, e.g. "5-30 min depending on hardware/network").

## 7. dev-env layer prompts mid-install (breaks walk-away promise)

During the real `full` run the owner had to interact 3 times mid-install —
Mise, Node and Python choices (`src/install/dev-env.sh:~147,~169`, each
answered "1/ALL", one Y, one sudo password) — plus there is a
"Generate SSH key for GitHub?" prompt at `dev-env.sh:52`. This sits in the
middle of a ~25-min run, violating the project's own prompt contract
(choices at the start, optional layers at the end, unattended-safe middle —
same rationale that removed orchestrator retry prompts in v5.4.7).

**Fix direction:** collect ALL choices upfront (right after the profile
confirmation) or derive them from the profile (full ⇒ all, non-interactive);
announce the single sudo requirement at the start; everything between
"install begins" and the optional layers must be prompt-free and
`--unattended`-safe.

## 9. starship missing from every package list (blueprint-only dependency)

`rg -i "^starship" data/packages/*.txt data/packages.csv` → no match. Yet the
terminal blueprint layer and the owner's real `.zshrc` (guarded
`$+commands[starship]`) depend on it. Users who answer N to the blueprint
(e.g., chezmoi/dotfile users — exactly the M5 cutover case) silently get a
bare zsh prompt. Found live: M5 had no starship until installed manually.

**Fix:** add `starship` to `brew.txt` (base or developer tier) so the binary
ships with every profile; the blueprint keeps only the CONFIG role.

## 10. csv:rust-* categories silently no-op on macOS full install (CRITICAL)

Fresh M5 full install reported "All sections completed successfully /
Packages: 176", but ZERO of the ~50 CSV Rust tools were installed (no eza,
bat, rg, fd…; `/tmp/os-postinstall-failures.log` empty; nothing in brew).
Confirmed live 2026-07-13. Same failure class as the winget.ps1 tier bug:
a whole layer skipped with a success summary.

Evidence & hypotheses (root cause TBD post-cutover):
- `install_csv_category` (src/core/csv.sh:80) resolves
  `${DATA_DIR:-${PROJECT_ROOT}/data}/packages.csv`; `PROJECT_ROOT` is defined
  NOWHERE in setup.sh/main.sh — if `DATA_DIR` (macos/main.sh:63, cd with
  `2>/dev/null`) comes up empty, path resolves to `/data/packages.csv` →
  "CSV not found" → return 1; yet failures.log is empty, so either
  record_failure had no FAILURE_LOG in that context, or the 0-rows path
  (`total 0` → return 0 → success) ran instead.
- CSV parsing itself is fine (awk emits 19 rust-cli rows on the same file).
- Workaround applied on the M5: run `install_csv_category` for the 5
  categories with explicit `DATA_DIR=$PWD/data` — works.

**Fix directions:** fail LOUDLY when a dispatched section installs 0 items
(`total 0` must be a warning, not silent success); resolve DATA_DIR without
silent fallback chain; add a bats case asserting csv:rust-cli resolves the
CSV from a main.sh-like context; final summary must reconcile "packages
planned vs actually present" (e.g., spot-check binaries).

## Tests

- bats: preview on macos must NOT contain `apt.txt`/`winget`/`snap`/`flatpak`.
- bats: preview output must contain the `✓ Preview` success line.
- bats: dry-run summary must contain `NOTHING was installed` and must NOT
  contain the post-install "What's next" block.
- bats: blueprint under DRY_RUN must not print `Done! Restart`.
