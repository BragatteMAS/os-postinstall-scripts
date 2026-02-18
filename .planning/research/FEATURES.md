# Feature Landscape: v3.0 Quality & Parity

**Domain:** Quality fixes, Windows feature parity, code hygiene for shell-based post-install scripts
**Researched:** 2026-02-18
**Confidence:** HIGH (code analysis + official docs + established patterns)

## Executive Summary

v3.0 is a quality milestone, not a feature milestone. The codebase (v2.1) is functionally complete across three platforms but has accumulated technical debt: boolean flag bugs, naming inconsistencies, DRY violations in PowerShell, missing Windows UX features (step counters, DryRun flag, completion summary), and test coverage limited to static validators. The fix categories form a natural dependency chain where boolean/flag correctness must come first (other code depends on these flags), followed by DRY extraction (reduces surface area for Windows parity work), then Windows parity additions, and finally tests that validate all the above.

---

## Table Stakes

Fixes users and maintainers expect. Missing = codebase feels buggy or inconsistent.

| Feature | Why Expected | Complexity | Category | Notes |
|---------|--------------|------------|----------|-------|
| **Fix VERBOSE boolean bug** | `VERBOSE=false` triggers verbose mode because `-n` test treats any non-empty string as true | Low | Bug Fix | logging.sh lines 99/113/127/141/153 use `-n` instead of `== "true"` |
| **Unify NONINTERACTIVE/UNATTENDED** | Two names for the same concept; `interactive.sh` and `apt.sh` use NONINTERACTIVE while `setup.sh`/`config.sh` use UNATTENDED | Low | Consistency | Pick one name, alias the other for backward compat |
| **Remove stale winget.txt entries** | `kite.kite` is a dead product (Kite AI shut down 2022) | Low | Data Fix | Simple line removal |
| **Fix ARCHITECTURE.md drift** | References patterns that have evolved (e.g., `set -euo pipefail` mentioned but project uses `set -o pipefail` only) | Low | Docs Fix | Sync with actual codebase patterns |
| **Windows -DryRun flag** | Bash has `--dry-run` CLI flag, Windows only has `$env:DRY_RUN` env var | Medium | Windows Parity | Add `[switch]$DryRun` param to `setup.ps1` |
| **Windows step counters** | Linux/macOS show `[Step X/Y]` progress, Windows shows nothing | Medium | Windows Parity | Port `count_platform_steps` logic to PS |
| **Windows completion summary** | Linux/macOS show profile/platform/duration/failures at end, Windows shows bare "Setup Complete" | Medium | Windows Parity | Port `show_completion_summary` to PS |
| **CmdletBinding on PS scripts** | PowerShell best practice; enables -Verbose, -Debug, -ErrorAction propagation | Low | Code Quality | Add `[CmdletBinding()]` to all installer scripts |
| **Extract shared PS helpers** | `Test-WinGetInstalled` duplicated 3x (winget.ps1, cargo.ps1, ai-tools.ps1), `Test-NpmInstalled` duplicated 2x | Medium | DRY Violation | Create shared `helpers.psm1` module |
| **Consolidate install/installers directories** | `src/install/` (cross-platform) and `src/installers/` (dotfiles only) coexist confusingly | Low | Structure | Move dotfiles-install.sh into src/install/ or rename |

### Table Stakes Analysis

**Current state of bugs (confirmed via code analysis):**

1. **VERBOSE boolean (CRITICAL):** `config.sh` line 25 sets `VERBOSE="${VERBOSE:-false}"`. When user does NOT set VERBOSE, it defaults to `"false"`. In `logging.sh`, the check `[[ -n "${VERBOSE:-}" ]]` evaluates the string `"false"` as non-empty (truthy), enabling verbose mode for ALL users by default. The only reason this hasn't been reported is that `setup.sh` also exports VERBOSE, and `parse_flags` only sets `VERBOSE=true` on `--verbose` flag -- but if any script sources `config.sh` directly without going through `setup.sh`, the bug manifests.

   **Fix:** Change all `-n "${VERBOSE:-}"` checks to `"${VERBOSE:-}" == "true"` and all `-z "${VERBOSE:-}"` checks to `"${VERBOSE:-}" != "true"`.

2. **NONINTERACTIVE/UNATTENDED split (MODERATE):** `interactive.sh` and `apt.sh` check `NONINTERACTIVE`, while `config.sh` exports `UNATTENDED` and `setup.sh` uses `--unattended` flag. These are semantically identical but disconnected. Users setting `UNATTENDED=true` will not affect interactive menus in `ai-tools.sh` or `dev-env.sh` which check `NONINTERACTIVE`.

   **Fix:** Unify on UNATTENDED (matches CLI flag `--unattended`). Add `NONINTERACTIVE="${UNATTENDED}"` alias in config.sh for backward compatibility.

3. **Test-WinGetInstalled 3x duplication (MODERATE):** Identical function body in winget.ps1 (line 24-44), cargo.ps1 (line 66-86), ai-tools.ps1 (line 49-72). Each PS1 runs as a separate process so they cannot share in-memory state, but they CAN share a module imported at the top of each script.

**Confidence:** HIGH -- all bugs confirmed by direct code inspection.

**Sources:**
- [Baeldung: Boolean in Shell Scripts](https://www.baeldung.com/linux/shell-script-boolean-type-variable) -- `-n` tests string non-emptiness, not truthiness
- [Microsoft: ShouldProcess Deep Dive](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.5) -- CmdletBinding patterns
- [PowerShell Forums: Shared Helper Functions](https://forums.powershell.org/t/shared-helper-private-functions/11846) -- module-based sharing pattern

---

## Differentiators

Features that elevate the project beyond "it works." Not expected at this maturity, but raise quality score significantly.

| Feature | Value Proposition | Complexity | Priority | Notes |
|---------|-------------------|------------|----------|-------|
| **Unit tests for core modules** | Validate logging, errors, progress, platform detection in isolation | Medium | High | Current tests are static validators only (file existence, shebang checks) |
| **PS ShouldProcess/WhatIf** | Native PowerShell dry-run via `[CmdletBinding(SupportsShouldProcess)]` instead of `$env:DRY_RUN` string check | Medium | Medium | Would be idiomatic PS, but breaks consistency with Bash `DRY_RUN=true` pattern |
| **Profile validation** | Verify profile .txt files reference existing package files, catch typos early | Low | Medium | Currently no validation -- typo in profile silently skips packages |
| **Windows -Verbose flag** | Map PS -Verbose to `$env:VERBOSE=true` for parity with Bash `--verbose` | Low | Medium | Natural extension of CmdletBinding |
| **Colored output parity on Windows** | PS logging.psm1 uses Write-Host -ForegroundColor but platform.sh has duplicate color vars | Low | Low | Minor inconsistency, not user-facing |

### Differentiator Analysis

**Unit tests for core modules** is the highest-value differentiator because:
1. Core modules (logging.sh, errors.sh, progress.sh) are sourced by every script
2. Testing them validates the foundation everything else depends on
3. Test patterns already exist (test_harness.sh, test-linux.sh use assert_pass/assert_fail)
4. Does not require running actual installers -- pure function testing

**PS ShouldProcess/WhatIf -- recommendation: DO NOT adopt for v3.0.** While ShouldProcess is the idiomatic PowerShell pattern, this project's cross-platform design uses `$env:DRY_RUN` as the universal flag. Switching Windows to ShouldProcess would create asymmetry: Bash uses `DRY_RUN=true ./setup.sh`, Windows would use `.\setup.ps1 -WhatIf`. The `$env:DRY_RUN` pattern works, is consistent, and is already implemented in all PS installers. Instead, add a `-DryRun` switch that sets `$env:DRY_RUN = 'true'` internally -- best of both worlds.

**Sources:**
- [Microsoft: Write-Progress](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-progress?view=powershell-7.5) -- PS native progress bar
- [PowerShell Scripting Best Practices 2025](https://dstreefkerk.github.io/2025-06-powershell-scripting-best-practices/) -- CmdletBinding, ShouldProcess

---

## Anti-Features

Features to explicitly NOT build in v3.0.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **ShouldProcess migration** | Breaks cross-platform `DRY_RUN` consistency; would require different UX per platform | Add `-DryRun` switch that maps to `$env:DRY_RUN = 'true'` |
| **Pester test framework** | Out of scope per PROJECT.md; adds PS dependency; current test runner works | Extend existing test-windows.ps1 with more assertions |
| **bats-core migration** | Adds dependency on bats; current harness is zero-dep and functional | Extend test_harness.sh and platform test files |
| **PS Write-Progress bars** | Visual noise for a script that runs ~30 packages; text step counters are simpler | Port Bash `[Step X/Y]` text pattern to PS |
| **Shared PS module path manipulation** | Complex PS module loading ($env:PSModulePath changes) for dubious benefit | Use `Import-Module -Force` with relative paths (current pattern) |
| **CI/CD pipeline** | Explicit owner decision: no CI/CD automation | Keep manual test execution |
| **curl|sh checksum verification** | Reviewers suggested it but it adds complexity; these are well-known official installers | Document the curl|sh commands clearly; trust upstream |

### Anti-Feature Rationale

The v3.0 scope explicitly rejects adding new abstractions. The core principle is **fix what's broken, close parity gaps, don't introduce new patterns**. ShouldProcess, Pester, bats-core, and CI/CD are all valid engineering choices but each introduces a new pattern that increases maintenance burden without fixing the identified issues.

---

## Feature Dependencies

```
DEPENDENCY CHAIN (must follow this order):

Group 1: Flag/Boolean Fixes (no dependencies)
├── Fix VERBOSE boolean bug in logging.sh
├── Unify NONINTERACTIVE/UNATTENDED naming
└── Remove stale winget.txt entries

        |
        v  (flags must be correct before building on them)

Group 2: DRY Extraction + Structure (depends on Group 1)
├── Extract shared PS helpers (helpers.psm1)
├── Consolidate install/installers directories
├── Add CmdletBinding to PS scripts
└── Fix ARCHITECTURE.md drift

        |
        v  (clean modules needed before adding features to them)

Group 3: Windows Parity (depends on Group 2)
├── Add -DryRun switch to setup.ps1
├── Add step counters to Windows main.ps1
├── Add completion summary to Windows
└── Add -Verbose switch to setup.ps1

        |
        v  (features must exist before testing them)

Group 4: Testing + Docs (depends on Groups 1-3)
├── Unit tests for core Bash modules
├── Extend PS test coverage for new features
├── Profile validation tests
├── Document EXTRA_PACKAGES in README
└── Windows troubleshooting section in docs
```

### Why This Order

1. **Group 1 first** because VERBOSE and NONINTERACTIVE/UNATTENDED are checked by virtually every module. Testing anything that touches logging or interactivity while the boolean bug exists means tests would validate broken behavior.

2. **Group 2 before Group 3** because the DRY extraction of `Test-WinGetInstalled` into `helpers.psm1` creates the shared module that Windows parity features (step counters, summary) will also use. Adding step counters to main.ps1 before extracting helpers would mean touching main.ps1 twice.

3. **Group 3 before Group 4** because tests should validate the correct final behavior, not intermediate states. Writing tests for step counters before they exist would require test rewrites.

4. **Group 4 last** because it validates all prior work and documents the final state.

---

## Detailed Feature Specifications

### Group 1: Flag/Boolean Fixes

#### 1.1 Fix VERBOSE Boolean Bug

**What:** Change 5 occurrences in `logging.sh` from `-n`/`-z` tests to `== "true"` comparisons.

**Before:**
```bash
if [[ -n "${VERBOSE:-}" ]]; then      # BUG: "false" is non-empty
```

**After:**
```bash
if [[ "${VERBOSE:-}" == "true" ]]; then  # CORRECT: only "true" triggers
```

**Files:** `src/core/logging.sh` (lines 99, 113, 127, 141, 153)
**Risk:** Low. Pattern `== "true"` is already used for `DRY_RUN` checks everywhere.
**Complexity:** Low

#### 1.2 Unify NONINTERACTIVE/UNATTENDED

**What:** Standardize on `UNATTENDED` (matches `--unattended` CLI flag). Add alias in `config.sh`.

**Files to update:**
- `config.sh` -- add `export NONINTERACTIVE="${UNATTENDED}"` after UNATTENDED export
- `src/core/interactive.sh` -- change `NONINTERACTIVE` to `UNATTENDED` (2 occurrences)
- `src/install/ai-tools.sh` -- change `NONINTERACTIVE` to `UNATTENDED` (1 occurrence)
- `src/install/dev-env.sh` -- change `NONINTERACTIVE` to `UNATTENDED` (1 occurrence)
- `src/platforms/linux/install/apt.sh` -- change `NONINTERACTIVE` to `UNATTENDED` (2 occurrences)

**Note:** `NONINTERACTIVE=1` in `homebrew.sh` line 95 is a different thing -- it is the Homebrew installer's own env var, NOT our project flag. Do NOT change it.

**Risk:** Low. Straightforward rename with alias for safety.
**Complexity:** Low

#### 1.3 Remove Stale winget.txt Entries

**What:** Remove `kite.kite` from `data/packages/winget.txt`. Kite (AI code completions) shut down in November 2022.

**Risk:** None.
**Complexity:** Low

### Group 2: DRY Extraction + Structure

#### 2.1 Extract Shared PS Helpers Module

**What:** Create `src/platforms/windows/core/helpers.psm1` with shared functions.

**Functions to extract:**
- `Test-WinGetInstalled` -- from winget.ps1, cargo.ps1, ai-tools.ps1 (3 copies)
- `Test-NpmInstalled` -- from npm.ps1, ai-tools.ps1 (2 copies)
- `Test-CargoInstalled` -- from cargo.ps1 (1 copy, but belongs with other idempotency checks)

**Pattern:**
```powershell
# helpers.psm1
function Test-WinGetInstalled { ... }  # Single source of truth
function Test-NpmInstalled { ... }
function Test-CargoInstalled { ... }
Export-ModuleMember -Function Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
```

Each installer script replaces its local definition with:
```powershell
Import-Module "$PSScriptRoot/../core/helpers.psm1" -Force
```

**Why module instead of dot-source:** Modules are the project's established pattern (logging.psm1, packages.psm1, errors.psm1 are all .psm1). PS scripts run in separate processes so they already re-import modules; adding one more import is negligible.

**Risk:** Low. Existing test-windows.ps1 validates these functions exist; update tests to check new module path.
**Complexity:** Medium (touches 4 files, creates 1 new file)

#### 2.2 Consolidate install/installers Directories

**What:** `src/installers/` contains only `dotfiles-install.sh`. Move it to `src/install/dotfiles.sh` and update references.

**References to update:**
- `setup.sh` lines 143, 148, 200 -- source path change
- `test_harness.sh` line 133 -- directory existence check

**Risk:** Low. Single file move with grep-verified references.
**Complexity:** Low

#### 2.3 Add CmdletBinding to PS Scripts

**What:** Add `[CmdletBinding()]` attribute to all PowerShell installer scripts. This enables native -Verbose, -Debug, -ErrorAction parameter propagation.

**Files:**
- `src/platforms/windows/install/winget.ps1` -- no param block, needs wrapping
- `src/platforms/windows/install/cargo.ps1` -- no param block, needs wrapping
- `src/platforms/windows/install/npm.ps1` -- no param block, needs wrapping
- `src/platforms/windows/install/ai-tools.ps1` -- no param block, needs wrapping

**Note:** These scripts are called via `&` operator from main.ps1, not dot-sourced. CmdletBinding works with `&` invocation. No changes to callers needed.

**Risk:** Low. CmdletBinding is additive; existing behavior unchanged.
**Complexity:** Low

#### 2.4 Fix ARCHITECTURE.md Drift

**What:** Update `.planning/codebase/ARCHITECTURE.md` to match actual codebase patterns.

**Known drifts:**
- References `set -euo pipefail` but project uses only `set -o pipefail` (no -e, no -u by design)
- Does not mention `FAILURE_LOG` cross-process tracking
- Missing `src/install/` cross-platform installers layer
- References `detect_os()` but function is `detect_platform()`
- Lists `needs_update()` but function does not exist

**Risk:** None (documentation only).
**Complexity:** Low

### Group 3: Windows Parity

#### 3.1 Add -DryRun Switch to setup.ps1

**What:** Add `-DryRun` switch parameter that maps to `$env:DRY_RUN = 'true'`.

**Implementation:**
```powershell
param(
    [string]$Profile = 'developer',
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Help
)

if ($DryRun) { $env:DRY_RUN = 'true' }
if ($Verbose -and $Verbose -ne [System.Management.Automation.SwitchParameter]::Present) {
    $env:VERBOSE = 'true'
}
```

**Why not ShouldProcess:** Cross-platform consistency. Bash uses `DRY_RUN=true ./setup.sh --dry-run`. Windows should mirror: `.\setup.ps1 -DryRun`. Both set the same env var that all installer scripts already check.

**Risk:** Low. Non-breaking addition.
**Complexity:** Low

#### 3.2 Add Step Counters to Windows main.ps1

**What:** Port the `[Step X/Y]` progress pattern from Linux/macOS main.sh to Windows main.ps1.

**Implementation approach:**
```powershell
function Get-PlatformStepCount {
    param([string[]]$Entries)
    $count = 0
    foreach ($entry in $Entries) {
        if ($entry -in @('winget.txt','cargo.txt','npm.txt','ai-tools.txt')) {
            $count++
        }
    }
    return $count
}
```

Then in Install-Profile, add `$currentStep` tracking:
```powershell
$totalSteps = Get-PlatformStepCount -Entries $entries
$currentStep = 0

# In each case:
$currentStep++
Write-Log -Level INFO -Message "[Step $currentStep/$totalSteps] Installing WinGet packages..."
```

**Risk:** Low. Text-based progress, no UI complexity.
**Complexity:** Medium

#### 3.3 Add Completion Summary to Windows

**What:** Port `show_completion_summary()` logic to PowerShell.

**Implementation approach:** Add to `setup.ps1` or as a function in a module:
```powershell
function Show-CompletionSummary {
    param(
        [string]$ProfileName,
        [TimeSpan]$Duration
    )
    $failCount = 0
    if ($env:FAILURE_LOG -and (Test-Path $env:FAILURE_LOG)) {
        $failCount = (Get-Content $env:FAILURE_LOG -ErrorAction SilentlyContinue | Measure-Object).Count
    }

    Write-Log -Level BANNER -Message $(if ($env:DRY_RUN -eq 'true') { 'Dry Run Complete' } else { 'Setup Complete' })
    Write-Log -Level INFO -Message "Profile:  $ProfileName"
    Write-Log -Level INFO -Message "Platform: Windows"
    Write-Log -Level INFO -Message "Duration: $($Duration.Minutes)m $($Duration.Seconds)s"
    # ... failure reporting
}
```

**Risk:** Low. Mirrors existing Bash pattern exactly.
**Complexity:** Medium

#### 3.4 Add DryRun Banner to Windows

**What:** Show prominent DRY_RUN warning banner at start of Windows install, matching Bash `show_dry_run_banner()`.

**Implementation:** Add to `Install-Profile` in main.ps1:
```powershell
if ($env:DRY_RUN -eq 'true') {
    Write-Log -Level WARN -Message '========================================='
    Write-Log -Level WARN -Message '  DRY RUN MODE - No changes will be made'
    Write-Log -Level WARN -Message '========================================='
}
```

**Risk:** None.
**Complexity:** Low

### Group 4: Testing + Documentation

#### 4.1 Unit Tests for Core Bash Modules

**What:** Add tests for `logging.sh`, `errors.sh`, `progress.sh` that validate function behavior (not just file existence).

**Test cases for logging.sh:**
- VERBOSE=false does NOT show timestamps (validates bug fix)
- VERBOSE=true shows timestamps
- NO_COLOR=1 suppresses color codes
- log_debug hidden when VERBOSE is not "true"
- log_error writes to stderr

**Test cases for errors.sh:**
- record_failure adds to FAILED_ITEMS array
- get_failure_count returns correct count
- show_failure_summary shows all items
- clear_failures resets the list

**Test cases for progress.sh:**
- show_dry_run_banner shows banner when DRY_RUN=true
- show_dry_run_banner silent when DRY_RUN=false
- count_platform_steps returns correct count for linux/macos

**Pattern:** Use existing `assert_pass`/`assert_fail` from test-linux.sh.

**Risk:** Low. Read-only tests, no system changes.
**Complexity:** Medium

#### 4.2 Profile Validation

**What:** Test that each profile .txt file only references package files that actually exist in `data/packages/`.

**Implementation:**
```bash
# For each profile in data/packages/profiles/*.txt:
#   For each non-comment line:
#     Assert data/packages/$line exists
```

**Why this matters:** A typo in `developer.txt` (e.g., `carg.txt` instead of `cargo.txt`) would silently skip all cargo packages with only a `log_warn "Unknown package file"` message. Catching this in tests prevents user confusion.

**Risk:** None.
**Complexity:** Low

#### 4.3 Documentation Fixes

**What:**
- Document `EXTRA_PACKAGES` and `SKIP_PACKAGES` in README (currently only in config.sh)
- Add Windows troubleshooting section to README or docs/
- Update ARCHITECTURE.md (see Group 2.4)

**Risk:** None.
**Complexity:** Low

---

## Fix Priority Matrix

| Fix | Essential vs Nice-to-Have | Effort | Impact | Priority |
|-----|---------------------------|--------|--------|----------|
| VERBOSE boolean bug | **Essential** -- wrong behavior in production | 15 min | High | P0 |
| NONINTERACTIVE/UNATTENDED | **Essential** -- broken feature path | 30 min | High | P0 |
| Stale winget.txt | **Essential** -- install failure on Windows | 5 min | Medium | P0 |
| Extract PS helpers (DRY) | **Essential** -- reduces maintenance burden before adding features | 45 min | Medium | P1 |
| CmdletBinding on PS | Nice-to-have -- enables future -Verbose propagation | 20 min | Low | P2 |
| Consolidate install/installers | Nice-to-have -- cosmetic improvement | 15 min | Low | P2 |
| ARCHITECTURE.md drift | Nice-to-have -- only affects contributors | 20 min | Low | P2 |
| Windows -DryRun flag | **Essential** -- parity gap identified by reviewer | 20 min | High | P1 |
| Windows step counters | **Essential** -- parity gap (UX consistency) | 40 min | Medium | P1 |
| Windows completion summary | **Essential** -- parity gap (UX consistency) | 40 min | Medium | P1 |
| Windows DryRun banner | **Essential** -- parity gap | 10 min | Medium | P1 |
| Unit tests for core modules | **Essential** -- validates all fixes above | 60 min | High | P1 |
| Profile validation tests | Nice-to-have -- prevents silent typo failures | 15 min | Low | P2 |
| Document EXTRA_PACKAGES | Nice-to-have -- helps users customize | 15 min | Low | P2 |
| Windows troubleshooting docs | Nice-to-have -- helps Windows users | 20 min | Low | P2 |

---

## MVP Recommendation

**Must fix (blocks everything else):**
1. VERBOSE boolean bug -- 5 lines, 15 minutes, fixes broken flag logic
2. NONINTERACTIVE/UNATTENDED unification -- 7 files, 30 minutes, fixes broken interactivity
3. Stale winget.txt removal -- 1 line, prevents install failures

**Must do (core v3.0 value):**
4. Extract shared PS helpers -- enables DRY maintenance of Windows code
5. Windows -DryRun flag + banner -- closes highest-visibility parity gap
6. Windows step counters + completion summary -- closes UX parity gap
7. Unit tests for core Bash modules -- validates fixes, prevents regression

**Defer to v3.1 or later:**
- CmdletBinding (low impact, can be added anytime)
- Directory consolidation (cosmetic)
- Profile validation (low risk of typo issues)
- ARCHITECTURE.md drift (contributor-only impact)
- Full Windows troubleshooting documentation

---

## Sources

### HIGH Confidence (Official docs, direct code analysis)
- [Microsoft: Everything about ShouldProcess](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.5) -- CmdletBinding, WhatIf, DryRun patterns
- [Microsoft: Write-Progress](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-progress?view=powershell-7.5) -- PS native progress (rejected in favor of text counters)
- Direct code inspection: logging.sh, config.sh, interactive.sh, apt.sh, setup.sh, setup.ps1, all PS installers

### MEDIUM Confidence (Community best practices)
- [Baeldung: Boolean in Shell Scripts](https://www.baeldung.com/linux/shell-script-boolean-type-variable) -- `-n` vs `== "true"` pitfall
- [PowerShell Forums: Shared Helper Functions](https://forums.powershell.org/t/shared-helper-private-functions/11846) -- Module-based DRY pattern
- [PowerShell Scripting Best Practices 2025](https://dstreefkerk.github.io/2025-06-powershell-scripting-best-practices/) -- CmdletBinding, ShouldProcess
- [Adam the Automator: PowerShell CmdletBinding](https://adamtheautomator.com/powershell-cmdletbinding/) -- CmdletBinding tutorial
- [Adam the Automator: Write-Progress](https://adamtheautomator.com/write-progress/) -- Progress bar patterns

---

*Research completed: 2026-02-18*
*Confidence: HIGH -- all findings verified against actual codebase*
