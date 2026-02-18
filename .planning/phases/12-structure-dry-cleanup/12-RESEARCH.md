# Phase 12: Structure & DRY Cleanup - Research

**Researched:** 2026-02-18
**Domain:** Shell/PowerShell code deduplication, directory consolidation, readonly variable guards
**Confidence:** HIGH

## Summary

Phase 12 addresses four independent DRY violations across the codebase. Each requirement has a well-defined scope, exact file locations, and a proven fix pattern. No external dependencies, no library upgrades, no new tooling -- this is pure refactoring of existing code.

The four changes are:
1. **DRY-01**: Extract `Test-WinGetInstalled` (duplicated in 3 PS1 files) and `Test-NpmInstalled` (duplicated in 2 PS1 files) into a new shared `idempotent.psm1` module.
2. **DRY-02**: Merge `src/installers/` (1 file: `dotfiles-install.sh`) into `src/install/` (5 files), updating all path references.
3. **DRY-03**: Remove independent color definitions from `platform.sh` and have it use `logging.sh` colors instead.
4. **DRY-04**: Add a `-z` guard on `DATA_DIR` in `packages.sh` to prevent readonly collision when sourced twice (via `config.sh` and directly).

All four changes are mutually independent. They can be implemented and verified in any order. The prior research in `.planning/research/ARCHITECTURE.md` has already fully specified the exact implementation for DRY-01, and the `.planning/research/SUMMARY.md` confirms all four changes with file locations and patterns.

**Primary recommendation:** Implement all four requirements as a single plan with one task per requirement. Each task is self-contained and independently verifiable.

## Standard Stack

### Core

No new libraries or tools needed. This phase works entirely within the existing stack:

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PowerShell | 5.1+ | `idempotent.psm1` module system | Already in use for all PS modules; `Import-Module` + `Export-ModuleMember` is the standard PS sharing pattern |
| Bash | 4.0+ | Shell source guards | Already in use (`[[ -n "${_VAR_SOURCED:-}" ]] && return 0`) throughout `src/core/` |
| git mv | any | Directory consolidation | Preserves git history for moved files |

### Supporting

None required.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `idempotent.psm1` module | Dot-sourcing a `.ps1` helper file | Modules are the PS standard; dot-sourcing in separate process contexts does not propagate state; modules work because each process imports independently via `Import-Module` |
| `git mv` for directory merge | Manual copy + delete | Loses git blame/history for the moved file |
| Source guard (`-z` check) on DATA_DIR | Remove `readonly` from one site | Would weaken immutability guarantees; guard is strictly better |

## Architecture Patterns

### Recommended Project Structure (Post-Phase 12)

```
src/
  core/
    logging.sh         # SSoT for colors AND logging (DRY-03 makes this definitive)
    platform.sh        # Detection only; uses logging.sh colors (DRY-03 removes its own colors)
    packages.sh        # DATA_DIR with -z guard (DRY-04 prevents readonly collision)
    errors.sh
    idempotent.sh
    interactive.sh
    progress.sh
    dotfiles.sh
  install/             # ALL cross-platform installers (DRY-02 merges src/installers/ here)
    ai-tools.sh
    dev-env.sh
    dotfiles-install.sh  # Moved from src/installers/ (DRY-02)
    fnm.sh
    rust-cli.sh
    uv.sh
  platforms/
    linux/
      install/
        apt.sh
        cargo.sh
        flatpak.sh
        snap.sh
      main.sh
    macos/
      install/
        brew.sh
        brew-cask.sh
        homebrew.sh
      main.sh
    windows/
      core/
        errors.psm1
        idempotent.psm1  # NEW (DRY-01)
        logging.psm1
        packages.psm1
      install/
        ai-tools.ps1    # Imports idempotent.psm1 (DRY-01 removes local Test-* functions)
        cargo.ps1        # Imports idempotent.psm1 (DRY-01 removes local Test-* functions)
        npm.ps1          # Imports idempotent.psm1 (DRY-01 removes local Test-* functions)
        winget.ps1       # Imports idempotent.psm1 (DRY-01 removes local Test-* functions)
      main.ps1
```

### Pattern 1: PowerShell Module Import (DRY-01)

**What:** Each PS1 installer imports shared check functions from a `.psm1` module.
**When to use:** When functions are identical across multiple scripts that run as separate processes.
**Source:** `.planning/research/ARCHITECTURE.md` lines 131-189

```powershell
# In each installer .ps1 file, add this import alongside existing imports:
Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force

# The module exports: Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
```

**Critical constraint:** Scripts are invoked via `& "$WindowsDir/install/winget.ps1"` (separate process), NOT dot-sourced. Module state is NOT inherited. Each script MUST independently `Import-Module`.

### Pattern 2: Bash Source Guard for Readonly Variables (DRY-04)

**What:** Protect `readonly DATA_DIR` with a `-z` check so re-sourcing does not crash.
**When to use:** When a variable can be set by multiple source paths (config.sh sets DATA_DIR, packages.sh also sets DATA_DIR).
**Source:** Direct code inspection of `config.sh` (line 52) and `packages.sh` (lines 26-27)

The problem: `config.sh` declares `readonly DATA_DIR="${PROJECT_ROOT}/data"` at line 52 and exports it at line 56. When `packages.sh` is later sourced, it tries `DATA_DIR="..."` followed by `readonly DATA_DIR` at lines 26-27. If DATA_DIR is already set and readonly, bash throws: `bash: DATA_DIR: readonly variable`.

```bash
# Current packages.sh (BROKEN on re-source):
DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
readonly DATA_DIR

# Fixed packages.sh:
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
    readonly DATA_DIR
fi
```

### Pattern 3: Logging as Color SSoT (DRY-03)

**What:** `platform.sh` currently defines its own `_RED`, `_GREEN`, `_YELLOW`, `_BLUE`, `_NC` color variables (lines 33-45) AND its own `_platform_info/ok/warn/error` helper functions (lines 50-64). These duplicate what `logging.sh` provides. Replace them so `logging.sh` is the sole color SSoT.
**When to use:** When a utility module (platform.sh) has logging needs but is not the logging module.
**Source:** Direct code inspection of `platform.sh` and `logging.sh`

```bash
# Current platform.sh (DUPLICATE colors):
if [[ -t 1 ]]; then
    readonly _RED='\033[0;31m'
    readonly _GREEN='\033[0;32m'
    # ... 5 more readonly color vars
fi

_platform_info() { echo -e "${_BLUE}[INFO]${_NC} $*"; }
_platform_ok()   { echo -e "${_GREEN}[OK]${_NC} $*"; }
# ... 2 more functions

# Fixed platform.sh: use logging.sh functions directly
# Remove all _RED/_GREEN/_YELLOW/_BLUE/_NC definitions
# Remove all _platform_info/_platform_ok/_platform_warn/_platform_error functions
# Replace callsites with log_info/log_ok/log_warn/log_error
```

**Prerequisite:** `logging.sh` must be sourced before `platform.sh`. Currently, in all entry points:
- `setup.sh` line 37-38: sources `logging.sh` THEN `platform.sh` -- already correct order
- `linux/main.sh` lines 22-27: sources `logging.sh` THEN `platform.sh` -- already correct order
- `macos/main.sh` lines 22-27: sources `logging.sh` THEN `platform.sh` -- already correct order

No entry point sources `platform.sh` before `logging.sh`. This change is safe.

### Pattern 4: Directory Merge with git mv (DRY-02)

**What:** Move `src/installers/dotfiles-install.sh` to `src/install/dotfiles-install.sh`, update all references.
**When to use:** When two directories serve the same purpose.
**Source:** Direct inspection of `src/installers/` (1 file) and `src/install/` (5 files)

```bash
git mv src/installers/dotfiles-install.sh src/install/dotfiles-install.sh
# Then delete src/installers/ directory (will be empty except CLAUDE.md)
```

### Anti-Patterns to Avoid

- **Do NOT dot-source `.psm1` files in PowerShell.** Use `Import-Module`. Dot-sourcing works in the same process but breaks in the separate-process invocation model this project uses.
- **Do NOT remove `readonly` from `DATA_DIR`.** The readonly protection is valuable. Add a guard, not a removal.
- **Do NOT make `platform.sh` source `logging.sh` itself.** All entry points already source logging.sh first. Adding a source inside platform.sh creates a circular dependency risk and is unnecessary.
- **Do NOT rename the moved file.** Keep `dotfiles-install.sh` as-is to minimize reference changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PowerShell function sharing | Custom dot-source mechanism | `Import-Module` / `Export-ModuleMember` | Standard PS pattern; handles scope isolation automatically |
| File move with history | Manual copy + delete + add | `git mv` | Preserves git blame history |
| Readonly collision | Custom variable manager | `[[ -z "${VAR:-}" ]]` guard | One-line Bash idiom; zero overhead |

**Key insight:** Every fix in this phase uses standard language idioms. No custom abstractions needed.

## Common Pitfalls

### Pitfall 1: PowerShell Process Scope Isolation

**What goes wrong:** After creating `idempotent.psm1`, developers forget that each `.ps1` script runs as a SEPARATE process (invoked via `&`). The module import in `main.ps1` does NOT propagate to child scripts.
**Why it happens:** In Bash, `export -f` propagates functions to subshells. PowerShell has no equivalent for module functions.
**How to avoid:** Every `.ps1` file that calls `Test-WinGetInstalled`, `Test-NpmInstalled`, or `Test-CargoInstalled` MUST have its own `Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force` line.
**Warning signs:** "CommandNotFoundException: The term 'Test-WinGetInstalled' is not recognized" error at runtime.

### Pitfall 2: Path Reference Cascade After Directory Merge

**What goes wrong:** After `git mv src/installers/dotfiles-install.sh src/install/dotfiles-install.sh`, tests fail because hardcoded paths still reference `src/installers/`.
**Why it happens:** Multiple files reference `src/installers/` by path string.
**How to avoid:** Grep for ALL references before AND after the move. Known references:

| File | Line(s) | Reference |
|------|---------|-----------|
| `setup.sh` | 144, 149, 201 | `"${SCRIPT_DIR}/src/installers/dotfiles-install.sh"` |
| `tests/test_harness.sh` | 133 | `test_directory_exists "src/installers"` |

**Warning signs:** `test_harness.sh` failing on "Directory src/installers not found" (expected -- the test should be updated to check `src/install` instead, or removed since `src/install` already has a test at line 132).

### Pitfall 3: Readonly Collision Not Caught in Normal Flow

**What goes wrong:** The `DATA_DIR` readonly collision in `packages.sh` does NOT manifest in normal `./setup.sh` execution because `packages.sh` has a source guard (`[[ -n "${_PACKAGES_SOURCED:-}" ]] && return 0`). The collision only occurs when running unit tests that source `config.sh` AND THEN source `packages.sh` in the same shell, or when re-sourcing after `unset _PACKAGES_SOURCED`.
**Why it happens:** The source guard prevents re-sourcing, which hides the collision. But unit tests need to reset state.
**How to avoid:** The `-z` guard on DATA_DIR is the fix. Test it by: (1) sourcing `config.sh`, (2) unsetting `_PACKAGES_SOURCED`, (3) sourcing `packages.sh` -- it should not crash.
**Warning signs:** `bash: DATA_DIR: readonly variable` error in test output.

### Pitfall 4: platform.sh Readonly Color Variables

**What goes wrong:** `platform.sh` currently declares its color variables as `readonly`. Simply removing the color block is fine, but if any code OUTSIDE this project references `_RED`, `_GREEN`, etc., it will break.
**Why it happens:** The `readonly` keyword on those variables means they were expected to be stable.
**How to avoid:** Grep the entire project for `_RED`, `_GREEN`, `_YELLOW`, `_BLUE`, `_NC` (with underscore prefix). Only `platform.sh` itself uses these -- confirmed by searching. They are private internal variables.
**Warning signs:** "unbound variable" errors if anything references `_RED` etc. after removal.

### Pitfall 5: dotfiles-install.sh Internal Path

**What goes wrong:** `dotfiles-install.sh` line 17 computes `REPO_ROOT` as `"$(cd "${_INSTALLER_DIR}/../.." && pwd -P)"`. When the file is in `src/installers/`, `../..` resolves to the project root correctly. When moved to `src/install/`, `../..` STILL resolves to the project root because both directories are at the same depth under `src/`.
**Why it happens:** Both `src/installers/` and `src/install/` are direct children of `src/`.
**How to avoid:** Verify that `_INSTALLER_DIR/../..` still resolves correctly from the new location. It does, because the directory depth is identical.
**Warning signs:** None expected -- this is a non-issue, documented here to prevent unnecessary worry.

## Code Examples

### DRY-01: New idempotent.psm1

```powershell
# Source: .planning/research/ARCHITECTURE.md lines 139-168
#Requires -Version 5.1
#######################################
# Module: idempotent.psm1
# Description: Shared idempotent check helpers for Windows installers
# Author: Bragatte
# Date: 2026-02-18
#######################################
# PowerShell equivalent of src/core/idempotent.sh
# Provides Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
# Each .ps1 installer imports this module independently (separate process scope)

function Test-WinGetInstalled {
    <#
    .SYNOPSIS
        Check if a WinGet package is already installed.
    .PARAMETER PackageId
        The exact WinGet package ID to check.
    .OUTPUTS
        System.Boolean - $true if installed, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($PackageId)) {
        return $true
    }

    return $false
}

function Test-NpmInstalled {
    <#
    .SYNOPSIS
        Check if an npm package is installed globally.
    .PARAMETER PackageName
        The npm package name to check.
    .OUTPUTS
        System.Boolean - $true if installed globally, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    npm list -g $PackageName 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Test-CargoInstalled {
    <#
    .SYNOPSIS
        Check if a cargo package is already installed via cargo install --list.
    .PARAMETER PackageName
        The cargo package name to check.
    .OUTPUTS
        System.Boolean - $true if installed, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $output = cargo install --list 2>$null
    if ($output -match "^$([regex]::Escape($PackageName)) ") {
        return $true
    }

    return $false
}

Export-ModuleMember -Function Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
```

### DRY-02: setup.sh Path Update

```bash
# Before (3 occurrences):
source "${SCRIPT_DIR}/src/installers/dotfiles-install.sh"

# After:
source "${SCRIPT_DIR}/src/install/dotfiles-install.sh"
```

### DRY-03: platform.sh Color Removal

```bash
# REMOVE this entire block (lines 32-64 of platform.sh):
#######################################
# Colors (only if terminal)
#######################################
if [[ -t 1 ]]; then
    readonly _RED='\033[0;31m'
    ...
fi
_platform_info() { ... }
_platform_ok() { ... }
_platform_warn() { ... }
_platform_error() { ... }

# REPLACE callsites:
# _platform_info "..."  ->  log_info "..."
# _platform_ok "..."    ->  log_ok "..."
# _platform_warn "..."  ->  log_warn "..."
# _platform_error "..."  ->  log_error "..."
```

**Callsite inventory in platform.sh:**

| Old Call | Line(s) | New Call |
|----------|---------|---------|
| `_platform_info` | 316 (request_sudo) | `log_info` |
| `_platform_ok` | 339 (verify_all) | `log_ok` |
| `_platform_warn` | 155 (verify_bash_version), 195, 201, 262, 266, 301 | `log_warn` |
| `_platform_error` | 155, 226, 295, 313, 318 | `log_error` |

### DRY-04: packages.sh Guard

```bash
# Before (lines 26-27):
DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
readonly DATA_DIR

# After:
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
    readonly DATA_DIR
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Duplicate functions in each PS1 file | Shared module with Import-Module | Standard PS pattern since PS 2.0 | Eliminates maintenance burden of keeping copies in sync |
| Two install directories (install/ + installers/) | Single install/ directory | Phase 12 | One logical home for all cross-platform installers |
| Duplicate color definitions in logging.sh + platform.sh | logging.sh as sole color SSoT | Phase 12 | Single place to modify color behavior |
| Unguarded readonly variable | `-z` guard before readonly | Standard Bash defensive pattern | Enables safe re-sourcing in test contexts |

## Open Questions

1. **Should `Test-CargoInstalled` also be extracted even though it's only in cargo.ps1?**
   - What we know: Currently only `cargo.ps1` defines `Test-CargoInstalled`. It is NOT duplicated.
   - What's unclear: Whether Phase 13 (Windows Parity) might need it elsewhere.
   - Recommendation: YES, extract it into `idempotent.psm1` alongside the others. The `.planning/research/ARCHITECTURE.md` explicitly includes it in the module design. It costs nothing to include, and Phase 13 may use it. The success criteria says "Test-WinGetInstalled and Test-NpmInstalled exist in exactly one file" -- `Test-CargoInstalled` inclusion is bonus, not required.

2. **Should the `src/installers/CLAUDE.md` be moved or deleted?**
   - What we know: `src/installers/CLAUDE.md` exists with empty content. `src/install/CLAUDE.md` also exists with empty content.
   - Recommendation: Delete `src/installers/CLAUDE.md` when removing the directory. The `src/install/CLAUDE.md` already exists.

3. **Should `test_harness.sh` line 133 be updated or removed?**
   - What we know: Line 132 tests `test_directory_exists "src/install"` and line 133 tests `test_directory_exists "src/installers"`. After the merge, `src/installers/` will not exist.
   - Recommendation: Remove line 133. The directory no longer exists. Line 132 already validates `src/install/`.

4. **Should the `examples/terminal-setup.ps1` `Test-WinGetInstalled` also be refactored?**
   - What we know: `examples/terminal-setup.ps1` line 128 defines its own `Test-WinGetInstalled`. Examples are standalone demo scripts.
   - Recommendation: NO. Examples are intentionally self-contained and not part of the main installation flow. Refactoring them would reduce their standalone value.

## Sources

### Primary (HIGH confidence)

All findings are based on direct code inspection of the current codebase:

- `src/platforms/windows/install/winget.ps1` - `Test-WinGetInstalled` definition at line 24
- `src/platforms/windows/install/cargo.ps1` - `Test-WinGetInstalled` duplicate at line 66, `Test-CargoInstalled` at line 88
- `src/platforms/windows/install/ai-tools.ps1` - `Test-WinGetInstalled` duplicate at line 49, `Test-NpmInstalled` duplicate at line 28
- `src/platforms/windows/install/npm.ps1` - `Test-NpmInstalled` definition at line 24
- `src/core/platform.sh` lines 33-64 - Duplicate color definitions and logging helpers
- `src/core/logging.sh` lines 17-62 - Canonical color definitions
- `src/core/packages.sh` lines 26-27 - Unguarded `readonly DATA_DIR`
- `config.sh` line 52 - First `readonly DATA_DIR` declaration
- `setup.sh` lines 144, 149, 201 - References to `src/installers/`
- `tests/test_harness.sh` line 133 - Reference to `src/installers`
- `.planning/research/ARCHITECTURE.md` lines 120-189 - Prior research on DRY-01 implementation

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md` lines 58-107 - Phase 2 (now Phase 12) rationale and pitfalls
- `.planning/phases/11-flag-boolean-fixes/11-VERIFICATION.md` - Phase 11 completion confirmation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new tools, pure refactoring of existing patterns
- Architecture: HIGH - All changes are documented in prior research with exact line numbers
- Pitfalls: HIGH - All edge cases identified from direct code inspection
- Code examples: HIGH - Derived from existing codebase, not external sources

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (stable -- no external dependencies to drift)

---

## Appendix: Complete Reference List for DRY-02 Path Updates

Files that reference `src/installers/` and must be updated:

| File | Line(s) | Current Reference | New Reference |
|------|---------|-------------------|---------------|
| `setup.sh` | 144 | `"${SCRIPT_DIR}/src/installers/dotfiles-install.sh"` | `"${SCRIPT_DIR}/src/install/dotfiles-install.sh"` |
| `setup.sh` | 149 | `"${SCRIPT_DIR}/src/installers/dotfiles-install.sh"` | `"${SCRIPT_DIR}/src/install/dotfiles-install.sh"` |
| `setup.sh` | 201 | `"${SCRIPT_DIR}/src/installers/dotfiles-install.sh"` | `"${SCRIPT_DIR}/src/install/dotfiles-install.sh"` |
| `tests/test_harness.sh` | 133 | `test_directory_exists "src/installers"` | DELETE this line |

## Appendix: Complete Reference List for DRY-03 Callsite Updates in platform.sh

Functions to replace (remove definitions, use logging.sh exports):

| Old Function | Logging.sh Equivalent | Callsites in platform.sh |
|-------------|----------------------|--------------------------|
| `_platform_info` | `log_info` | Lines 51, 290, 316 |
| `_platform_ok` | `log_ok` | Lines 54, 339, 344, 347 |
| `_platform_warn` | `log_warn` | Lines 57, 195, 201, 262, 266, 301, 306 |
| `_platform_error` | `log_error` | Lines 60, 155, 226, 295, 313, 318 |

**Source guard change required:** `platform.sh` currently has `[[ -n "${_PLATFORM_SOURCED:-}" ]] && return 0` at line 10. This guard must remain. However, platform.sh does NOT source logging.sh itself -- it relies on the caller having already sourced it. This is confirmed by checking all three entry points: `setup.sh`, `linux/main.sh`, and `macos/main.sh` all source `logging.sh` before `platform.sh`. No change needed to source order.

## Appendix: DRY-01 File Modification Details

### winget.ps1 Changes
- **REMOVE**: Lines 24-44 (`Test-WinGetInstalled` function definition)
- **ADD**: `Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force` after line 18

### cargo.ps1 Changes
- **REMOVE**: Lines 66-86 (`Test-WinGetInstalled` function definition)
- **REMOVE**: Lines 88-108 (`Test-CargoInstalled` function definition)
- **ADD**: `Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force` after line 19

### npm.ps1 Changes
- **REMOVE**: Lines 24-43 (`Test-NpmInstalled` function definition)
- **ADD**: `Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force` after line 18

### ai-tools.ps1 Changes
- **REMOVE**: Lines 28-47 (`Test-NpmInstalled` function definition)
- **REMOVE**: Lines 49-72 (`Test-WinGetInstalled` function definition)
- **ADD**: `Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force` after line 22
