# Refactor: Unified Selection Mechanism

> **Status**: ✅ Implemented in v5.6.0 — revised approach (see "What shipped" below)
> **Created**: 2026-05-08 (during ultrathink audit pre-v5.5.0)
> **Shipped**: 2026-06-07

## What shipped (v5.6.0)

The original proposal below was a unified **selection** abstraction
(`select_one` / `select_multi`). On implementation it was deliberately
narrowed: the recurring bug was never about *menu rendering* — it was about
the *default* (the visible hint disagreeing with the value actually used).
A single multi-renderer abstraction would have grown parameters for timeout,
return-mode, value-mapping and a confirm-callback — a god-function at odds
with the project's KISS principle.

**What was built instead** — a small default-surfacing primitive that renders
the hint FROM the default, so the two cannot diverge:

- **bash** — `prompt_default` in `src/core/prompt.sh`. Six sites migrated
  (`show_category_menu`, `ask_tool`, `detect_previous_install`,
  `offer_ollama_model`, `select_profile_interactive` + its confirm step).
  `read_with_timeout` removed (superseded).
- **PowerShell** — `Read-Default` in `src/platforms/windows/core/prompt.psm1`.
  The profile menu in `main.ps1` now defaults to developer on Enter, matching
  the bash wizard across all three OSes.
- **The three renderers were kept distinct** — they are three interaction
  *types* (rich 1-of-N picker, binary confirm, dynamic N-of-M multi-select),
  not duplication. They shared a *theme*, not a bug.

Coverage ended up wider than this doc's original 3-site inventory: the default
bug also lived in `detect_previous_install` and the ollama prompt, both fixed.
The cross-OS contract lives in the two prompt files' headers (no separate ADR
needed for a solo project). The original analysis is preserved below as the
decision record.

## Problem

Three independent selection mechanisms exist in the codebase, each with
its own UX conventions and bug surface area:

| Mechanism | File | Used for |
|-----------|------|----------|
| `select_profile_interactive` | `src/core/wizard.sh` | First-run profile picker (minimal/developer/full) |
| `show_category_menu` + `ask_tool` | `src/core/interactive.sh` | Per-category dev-env opt-in (Node/Python/mise) |
| `select_groups` (gum + bash fallback) | `src/core/group-selector.sh` | Cask groups multi-select |

### Pain caused by fragmentation

1. **Bug fixes don't propagate.** v5.4.0 fixed a default-inversion in
   `show_category_menu`, v5.4.4 fixed the same class in
   `detect_previous_install`, v5.4.6 fixed it in `ai-tools` and
   `group-selector`. Same bug, four fixes, because each prompt was
   coded independently.
2. **UX inconsistency.** Some prompts say `[default=N]`, others put
   default in case fallthrough silently, others use timeout-based
   defaults (`interactive.sh:40`). User has no muscle memory.
3. **Adding new selection requires choice.** "Where should this new
   prompt live?" — every contributor has to re-derive the answer.
4. **Testing duplication.** Each mechanism gets its own set of
   regression tests (see test-regressions.bats v5.4.0 / v5.4.4 /
   v5.4.6 entries).

## Proposed shape

Single abstraction in `src/core/select.sh`:

```bash
# select_one - prompt user to choose one of N labeled options
# Args: $1 = prompt, $2 = default_index (1-based), rest = labels
# Returns: 0, echoes selected label name to stdout
# Honours: NONINTERACTIVE=true → echoes default and returns 0
# UX contract: prompt always shows "[1-N, default=K]" inline
select_one() { ... }

# select_multi - prompt user to multi-select from N labeled options
# Args: $1 = prompt, rest = labels
# Returns: 0, echoes one label per line on stdout
# Renders: gum choose --no-limit if available, bash numbered menu otherwise
# UX contract: empty input → no selection, prompt shows "[Enter=none]"
select_multi() { ... }
```

### UX contracts the abstraction enforces

- **Default surfacing**: if defaultable, prompt always reads
  `... [N, default=K]:` (current convention from v5.4.0/v5.4.4/v5.4.6).
- **Skip visibility**: skip path always logs via `log_info`, not
  `log_debug` (v5.4.6 convention).
- **Cancel path**: `Cancel` choice returns non-zero exit; caller
  decides how to react.
- **NONINTERACTIVE compliance**: when `NONINTERACTIVE=true`, picks
  default + emits `log_info "Auto-selected: <label>"`.

## Migration plan

1. Build `select_one` + `select_multi` in `src/core/select.sh`. Source
   from `setup.sh`. Add full bats coverage of contracts above.
2. Migrate **group-selector.sh** (smallest, ~30 lines call site).
3. Migrate **interactive.sh::show_category_menu + ask_tool**
   (medium complexity — has timeout-based default).
4. Migrate **wizard.sh::select_profile_interactive** last
   (most behavior, profile-specific phrasing — port carefully).
5. Delete old code, mark commits with `Closes #N` for the architectural
   issue tracking this refactor.

Each migration is its own atomic commit. The bats regression tests
written for v5.4.0/v5.4.4/v5.4.6 stay green throughout — they're the
guardrail. New tests cover the unified abstraction.

## Why this is NOT v5.5.0

- v5.5.0 scope is **skip granular** (Deney's wishlist) — that's a
  user-visible feature with a specific request. Scoping creep would
  delay both.
- This refactor is **invisible to users** when correct, but user-
  visible noise if it goes wrong (every prompt looks slightly
  different mid-migration).
- 2-3 days dedicated > sprinkled across releases. Refactors degrade
  when commits are interleaved with unrelated bugfixes.

## Acceptance criteria for the refactor PR

- [ ] All three call sites migrated, old code deleted
- [ ] All v5.4.0–v5.4.6 regression tests still pass
- [ ] New contract tests for `select_one`, `select_multi` (≥10 cases)
- [ ] `--unattended` mode never prompts (verified by integration test)
- [ ] Docs updated: `CONTRIBUTING.md` references `select.sh` as the
      canonical place for new prompts
- [ ] No regression in shellcheck warnings
- [ ] Manual validation on macOS + Linux
