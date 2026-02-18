# Phase 11: Flag & Boolean Fixes - Research

**Researched:** 2026-02-18
**Domain:** Bash boolean semantics, flag propagation, data file hygiene, documentation accuracy
**Confidence:** HIGH

## Summary

Phase 11 addresses four concrete bugs in the codebase where runtime behavior diverges from documented intent. All four issues are small, surgical fixes with well-defined before/after states. No new libraries, no architectural changes, no new patterns to learn.

The most impactful bug is FLAG-01 (VERBOSE boolean check). Currently, `logging.sh` uses `-n "${VERBOSE:-}"` to test VERBOSE mode, which means **any non-empty string** (including `"false"`) triggers verbose output. Since `config.sh` defaults VERBOSE to `"false"`, the system always produces timestamps and debug output unless VERBOSE is explicitly unset -- the exact opposite of documented behavior. FLAG-02 (NONINTERACTIVE/UNATTENDED split) is the second most impactful: `config.sh` and `setup.sh` only set/export `UNATTENDED`, but six downstream callsites check `NONINTERACTIVE` instead, creating a permanent disconnect where `-y` never suppresses apt confirmation or interactive menus.

FLAG-03 (remove kite.kite) and FLAG-04 (ARCHITECTURE.md correction) are trivial one-line fixes.

**Primary recommendation:** Fix FLAG-01 and FLAG-02 first (they affect runtime correctness), then FLAG-03 and FLAG-04 (data/docs cleanup). All four can be done in a single plan.

## Standard Stack

Not applicable -- this phase modifies existing Bash/PowerShell scripts and text files. No new dependencies.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `== "true"` string check | `[[ $VERBOSE ]]` (truthiness) | Simpler but `"false"` is truthy in Bash. String equality is explicit and safe. |
| Bridge variable in config.sh | Renaming all callsites to UNATTENDED | Larger diff, more risk. Bridge is DRYer (single source of truth). |
| Removing kite.kite line | Commenting it out | Dead comments rot. Clean removal is better. |

## Architecture Patterns

### Pattern 1: Boolean Flags as Strings

**What:** All boolean flags in this project use string comparison `== "true"` rather than Bash truthiness (`-n`/`-z`).

**When to use:** Always, for all boolean-like env vars in this codebase.

**Why:** In Bash, `-n "false"` returns true because `"false"` is a non-empty string. The project already uses `== "true"` correctly for `DRY_RUN` and `UNATTENDED` in `config.sh`, `setup.sh`, `progress.sh`, and `apt.sh`. The VERBOSE check in `logging.sh` is the only holdout using the wrong pattern.

**Existing correct examples (from codebase):**
```bash
# config.sh, apt.sh, progress.sh -- all use == "true" correctly
if [[ "${DRY_RUN:-}" == "true" ]]; then ...
if [[ "${NONINTERACTIVE:-}" == "true" ]]; then ...
if [[ "${DRY_RUN:-}" == "true" ]]; then ...
```

**Buggy pattern (logging.sh lines 99, 113, 127, 141, 153):**
```bash
# BUG: -n tests for non-empty, not for "true"
# "false" is non-empty, so VERBOSE=false triggers verbose output
if [[ -n "${VERBOSE:-}" ]]; then
```

**Fixed pattern:**
```bash
# CORRECT: explicit string comparison
if [[ "${VERBOSE:-}" == "true" ]]; then
```

### Pattern 2: Flag Bridge in config.sh

**What:** A bridge variable that derives `NONINTERACTIVE` from `UNATTENDED` so downstream scripts get the variable they expect.

**Why it's needed:** The codebase has two names for the same concept:
- **Entry layer** (config.sh, setup.sh): uses `UNATTENDED`
- **Downstream scripts** (interactive.sh, apt.sh, dev-env.sh, ai-tools.sh): checks `NONINTERACTIVE`

Neither layer is "wrong" -- they just use different names. A bridge in config.sh unifies them.

**Implementation:**
```bash
# config.sh -- after UNATTENDED definition (line 28)
# Bridge: downstream scripts check NONINTERACTIVE (apt.sh, interactive.sh, dev-env.sh, ai-tools.sh)
NONINTERACTIVE="${NONINTERACTIVE:-${UNATTENDED}}"
export NONINTERACTIVE
```

**Why bridge and not rename:** Renaming `NONINTERACTIVE` to `UNATTENDED` in all 6 downstream files is riskier (more files touched, more places to miss). The bridge is a single line in config.sh that makes both names work. `NONINTERACTIVE` can also be set directly by advanced users without going through the CLI flag.

### Anti-Patterns to Avoid

- **`-n` for boolean checks:** Never use `-n "${FLAG:-}"` for flags that can be `"false"`. Always use `== "true"`.
- **Silent variable mismatch:** When one layer sets `UNATTENDED` and another checks `NONINTERACTIVE`, the fix is a bridge, not hoping someone remembers to set both.
- **Keeping dead package entries:** Stale entries in data files cause silent install failures that waste user time and pollute failure summaries.

## Don't Hand-Roll

Not applicable -- all fixes are direct edits to existing files. No custom solutions needed.

## Common Pitfalls

### Pitfall 1: Bash Truthiness Trap

**What goes wrong:** Developer uses `-n "$FLAG"` thinking it tests "is the flag enabled". But `-n` tests "is the string non-empty", and `"false"` is non-empty.
**Why it happens:** In most languages, `false` is falsy. In Bash, only the empty string is falsy for `-n`/`-z`.
**How to avoid:** Always use `== "true"` for boolean flags. The codebase already does this everywhere except logging.sh.
**Warning signs:** Flags that seem to "always be on" regardless of the value set.

### Pitfall 2: Missing the log_debug Inversion

**What goes wrong:** When fixing `log_debug()`, the guard condition uses `-z` (the inverse of `-n`). The `-z` check at line 153 must also be changed to `!= "true"`.
**Why it happens:** `log_debug` uses the opposite test (`-z` instead of `-n`) to suppress output when VERBOSE is off. Both directions of the check need fixing.
**How to avoid:** Fix both patterns in the same commit: change `-n "${VERBOSE:-}"` to `"${VERBOSE:-}" == "true"` AND change `-z "${VERBOSE:-}"` to `"${VERBOSE:-}" != "true"`.

### Pitfall 3: Bridge Export Scope

**What goes wrong:** Adding `NONINTERACTIVE` to config.sh but forgetting to export it. Child processes (spawned via `bash script.sh`) won't see it.
**Why it happens:** `config.sh` already exports UNATTENDED on line 54, but the new NONINTERACTIVE must also be exported.
**How to avoid:** Add NONINTERACTIVE to the existing export statement on line 54.

### Pitfall 4: ARCHITECTURE.md `set -e` Claim

**What goes wrong:** ARCHITECTURE.md line 75 states: `set -euo pipefail` at top of every script. This directly contradicts ADR-001 which says "No `set -e` anywhere in the codebase."
**Why it happens:** ARCHITECTURE.md was generated by automated analysis that assumed standard Bash conventions without verifying against the project's actual strategy.
**How to avoid:** The fix is to update line 75 to accurately describe the real strategy: no `set -e`, failures tracked not fatal, per ADR-001.

## Code Examples

### FLAG-01: Fix VERBOSE boolean check in logging.sh

Six locations need changing:

```bash
# Lines 99, 113, 127, 141 — change from:
if [[ -n "${VERBOSE:-}" ]]; then
# change to:
if [[ "${VERBOSE:-}" == "true" ]]; then

# Line 153 (log_debug guard) — change from:
if [[ -z "${VERBOSE:-}" ]]; then
# change to:
if [[ "${VERBOSE:-}" != "true" ]]; then
```

**Files affected:** `src/core/logging.sh` (1 file, 5 locations)

### FLAG-02: Bridge NONINTERACTIVE from UNATTENDED in config.sh

```bash
# config.sh — add after line 28 (UNATTENDED definition):
# Bridge: downstream scripts (apt.sh, interactive.sh, dev-env.sh, ai-tools.sh)
# check NONINTERACTIVE; this derives it from UNATTENDED for consistency
NONINTERACTIVE="${NONINTERACTIVE:-${UNATTENDED}}"

# config.sh — update line 54 to include NONINTERACTIVE in exports:
export DEFAULT_PROFILE DRY_RUN VERBOSE UNATTENDED NONINTERACTIVE
```

**Files affected:** `config.sh` (1 file, 2 locations)

**Downstream consumers that already check NONINTERACTIVE (no changes needed):**
- `src/core/interactive.sh` lines 40, 70
- `src/platforms/linux/install/apt.sh` lines 80, 125
- `src/install/dev-env.sh` line 39
- `src/install/ai-tools.sh` line 147

### FLAG-03: Remove kite.kite from winget.txt

```
# data/packages/winget.txt — remove line 44:
kite.kite
```

Kite (AI code completions) shut down in late 2022. The winget package `kite.kite` was removed from the winget-pkgs repository after URLs became permanently unavailable. Attempting to install it fails silently (winget error + Add-FailedItem).

**Files affected:** `data/packages/winget.txt` (1 file, 1 line removal)

### FLAG-04: Fix ARCHITECTURE.md error handling description

```markdown
# .planning/codebase/ARCHITECTURE.md — replace lines 72-78:

## Error Handling

**Strategy:** Continue on failure with structured tracking (per ADR-001).

**Patterns:**
- No `set -e` anywhere in the codebase (per ADR-001 — conflicts with "continue on failure" strategy)
- `set -o pipefail` in entry point `setup.sh` only (catches pipe failures without aborting)
- `src/core/errors.sh`: failure array tracking, cross-process shared log file, summary at end
- `src/core/idempotent.sh`: skip already-installed packages
- `DRY_RUN` mode: preview all operations without execution
- All scripts exit 0 regardless of individual package failures
```

**Files affected:** `.planning/codebase/ARCHITECTURE.md` (1 file, ~6 lines replaced)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `-n "$VERBOSE"` (Bash truthiness) | `"$VERBOSE" == "true"` (explicit string) | Phase 11 (this fix) | VERBOSE=false no longer triggers verbose output |
| UNATTENDED/NONINTERACTIVE split | Bridge variable in config.sh | Phase 11 (this fix) | `-y` flag propagates to apt, interactive menus |
| kite.kite in winget.txt | Removed | Phase 11 (this fix) | No more silent install failure on Windows |

**Deprecated/outdated:**
- Kite AI: Shut down November 2022, winget package URLs dead, removed from winget-pkgs repository

## Open Questions

None. All four requirements have clear, verifiable fixes with no ambiguity.

## Sources

### Primary (HIGH confidence)

- **Codebase inspection** (direct Read of all affected files):
  - `src/core/logging.sh` -- 5 instances of `-n`/`-z` VERBOSE check confirmed
  - `config.sh` -- UNATTENDED exported, NONINTERACTIVE absent confirmed
  - `setup.sh` -- `-y` flag sets UNATTENDED only, confirmed
  - `src/core/interactive.sh` -- checks NONINTERACTIVE, confirmed
  - `src/platforms/linux/install/apt.sh` -- checks NONINTERACTIVE for DEBIAN_FRONTEND, confirmed
  - `src/install/dev-env.sh` -- checks NONINTERACTIVE for SSH skip, confirmed
  - `src/install/ai-tools.sh` -- checks NONINTERACTIVE for ollama menu, confirmed
  - `data/packages/winget.txt` -- `kite.kite` on line 44, confirmed
  - `.planning/codebase/ARCHITECTURE.md` -- claims `set -euo pipefail` at top of every script (line 75), confirmed incorrect
  - `.planning/adrs/ADR-001-error-resilience.md` -- "No `set -e` anywhere in the codebase", confirmed
  - All 20+ `.sh` files contain `# NOTE: No set -e` comment, confirmed via grep
  - Only `setup.sh` uses `set -o pipefail` (without `-e`), confirmed via grep

### Secondary (MEDIUM confidence)

- [Kite farewell page](https://kite.com/) -- Kite officially shut down, site shows farewell message
- [winget-pkgs issue #55272](https://github.com/microsoft/winget-pkgs/issues/55272) -- Kite.Kite marked unavailable, URLs dead
- [winget-pkgs issue #45161](https://github.com/microsoft/winget-pkgs/issues/45161) -- Could not download kite.kite, package broken

## Metadata

**Confidence breakdown:**
- FLAG-01 (VERBOSE boolean fix): HIGH -- bug confirmed by direct code inspection, fix pattern already established in codebase (DRY_RUN, UNATTENDED both use `== "true"`)
- FLAG-02 (NONINTERACTIVE bridge): HIGH -- variable mismatch confirmed by grep across all .sh files, bridge pattern is straightforward
- FLAG-03 (kite.kite removal): HIGH -- package discontinuation confirmed by official sources and winget-pkgs issues
- FLAG-04 (ARCHITECTURE.md fix): HIGH -- contradiction between ARCHITECTURE.md and ADR-001 confirmed by direct comparison, every script file has explicit "No set -e" comment

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (stable -- these are codebase-specific bugs, not ecosystem-dependent)
