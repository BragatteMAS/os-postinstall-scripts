# Architecture Patterns: v3.0 Quality & Parity Integration

**Domain:** Cross-platform post-install scripts -- quality fixes and Windows parity
**Researched:** 2026-02-18
**Confidence:** HIGH (derived from complete codebase analysis, no external dependencies)

## Executive Summary

Five architectural changes are needed for v3.0. Analysis of the entire codebase reveals clear dependency ordering: some changes are fully independent (can be done in parallel), while others have cascading effects that dictate sequence. The critical insight is that the DATA_DIR fix and the directory merge both touch `setup.sh` sourcing paths, so they should be coordinated but can still be done as separate commits.

---

## Current Architecture (As-Is)

```
os-postinstall-scripts/
├── setup.sh                 # Bash entry point (sources config.sh)
├── setup.ps1                # PowerShell entry point
├── config.sh                # User config + path constants (sets readonly DATA_DIR)
├── src/
│   ├── core/                # 8 Bash modules (logging, errors, packages, idempotent,
│   │                        #   platform, dotfiles, progress, interactive)
│   ├── install/             # 5 cross-platform installers (ai-tools, dev-env, fnm, uv, rust-cli)
│   ├── installers/          # 1 file: dotfiles-install.sh (confusing name collision)
│   └── platforms/
│       ├── linux/           # main.sh + install/{apt,cargo,flatpak,snap}.sh
│       ├── macos/           # main.sh + install/{homebrew,brew,brew-cask}.sh
│       └── windows/
│           ├── main.ps1     # Orchestrator
│           ├── core/        # PS modules: logging.psm1, packages.psm1, errors.psm1
│           └── install/     # winget.ps1, cargo.ps1, npm.ps1, ai-tools.ps1
├── data/
│   ├── packages/            # txt files + profiles/
│   └── dotfiles/            # topic-centric configs
└── tests/                   # test_harness.sh, test-{linux,macos,dotfiles}.sh, test-windows.ps1
```

### Source Dependencies (Bash)

```
setup.sh
  └─ config.sh              (sets readonly DATA_DIR, CORE_DIR, SRC_DIR)
  └─ core/logging.sh        (sets RED, GREEN, YELLOW, BLUE, GRAY, NC via setup_colors)
  └─ core/platform.sh       (sets _RED, _GREEN, _YELLOW, _BLUE, _NC -- DUPLICATES)
  └─ core/errors.sh         (sources logging.sh internally)
  └─ core/progress.sh       (sources logging.sh internally)
  └─ src/installers/dotfiles-install.sh  (for "dotfiles" action)
       └─ core/logging.sh
       └─ core/dotfiles.sh

core/packages.sh             (sets readonly DATA_DIR -- CONFLICTS with config.sh)
  └─ (no core deps, standalone)

install/*.sh                 (sourced by platform main.sh, also run standalone)
  └─ core/logging.sh
  └─ core/errors.sh
  └─ core/idempotent.sh
  └─ core/packages.sh       (brings in DATA_DIR)
  └─ core/interactive.sh
  └─ core/platform.sh
```

### Source Dependencies (PowerShell)

```
setup.ps1
  └─ windows/core/logging.psm1
  └─ windows/core/errors.psm1
  └─ windows/main.ps1
       └─ windows/core/logging.psm1
       └─ windows/core/packages.psm1
       └─ windows/core/errors.psm1
       └─ windows/install/winget.ps1   (separate process via &)
       └─ windows/install/cargo.ps1    (separate process via &)
       └─ windows/install/npm.ps1      (separate process via &)
       └─ windows/install/ai-tools.ps1 (separate process via &)

Each install/*.ps1 independently imports:
  └─ ../core/logging.psm1
  └─ ../core/packages.psm1
  └─ ../core/errors.psm1
  └─ PLUS defines local helper functions (Test-WinGetInstalled, Test-NpmInstalled, etc.)
```

---

## The Five Changes: Detailed Analysis

### Change 1: Merge src/install/ + src/installers/ into src/install/

**Problem:** Two directories with confusingly similar names. `src/installers/` contains only `dotfiles-install.sh`. `src/install/` has 5 cross-platform installers. Users and contributors cannot predict which directory holds what.

**Solution:** Move `dotfiles-install.sh` from `src/installers/` to `src/install/`, then remove `src/installers/`.

**Files Modified:**
| File | Change |
|------|--------|
| `src/installers/dotfiles-install.sh` | **MOVE** to `src/install/dotfiles-install.sh` |
| `setup.sh` (lines 143, 148, 200) | Update path: `src/installers/` -> `src/install/` |
| `tests/test_harness.sh` (line 133) | Update or remove `src/installers` directory check |

**Files NOT modified (important):** No other file references `src/installers/` -- only `setup.sh` sources from it.

**Internal path update in moved file:**
```bash
# dotfiles-install.sh line 17 currently:
REPO_ROOT="$(cd "${_INSTALLER_DIR}/../.." && pwd -P)"
# After move to src/install/:
REPO_ROOT="$(cd "${_INSTALLER_DIR}/../.." && pwd -P)"
# Same! Both src/install/ and src/installers/ are at the same depth from project root.
```

**Risk:** LOW. The relative path from `src/install/` to project root is the same depth as from `src/installers/`. Only `setup.sh` needs updating.

**Dependencies:** NONE. Fully independent change.

---

### Change 2: Extract Shared PS Helpers to a Module

**Problem:** Three functions are duplicated across PowerShell installer scripts:

| Function | Defined In | Identical? |
|----------|-----------|------------|
| `Test-WinGetInstalled` | `winget.ps1` (line 24), `cargo.ps1` (line 66), `ai-tools.ps1` (line 49) | YES -- same implementation |
| `Test-NpmInstalled` | `npm.ps1` (line 24), `ai-tools.ps1` (line 28) | YES -- same implementation |
| `Test-CargoInstalled` | `cargo.ps1` (line 88) | Unique to cargo.ps1 |

**Constraint:** PowerShell scripts run as separate processes (invoked via `& "$WindowsDir/install/winget.ps1"`), NOT dot-sourced. Module state is NOT shared between caller and callee. Each script must independently import its needed modules.

**Solution:** Create `src/platforms/windows/core/idempotent.psm1` containing shared check functions.

**New File:**
```
src/platforms/windows/core/idempotent.psm1
```

**Contents:**
```powershell
#Requires -Version 5.1
# Module: idempotent.psm1
# Description: Shared idempotent check helpers for Windows installers

function Test-WinGetInstalled {
    param([Parameter(Mandatory)][string]$PackageId)
    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($PackageId)) {
        return $true
    }
    return $false
}

function Test-NpmInstalled {
    param([Parameter(Mandatory)][string]$PackageName)
    npm list -g $PackageName 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Test-CargoInstalled {
    param([Parameter(Mandatory)][string]$PackageName)
    $output = cargo install --list 2>$null
    if ($output -match "^$([regex]::Escape($PackageName)) ") {
        return $true
    }
    return $false
}

Export-ModuleMember -Function Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
```

**Files Modified:**

| File | Change |
|------|--------|
| `windows/install/winget.ps1` | Remove local `Test-WinGetInstalled`; add `Import-Module ../core/idempotent.psm1` |
| `windows/install/cargo.ps1` | Remove local `Test-WinGetInstalled` and `Test-CargoInstalled`; add import |
| `windows/install/npm.ps1` | Remove local `Test-NpmInstalled`; add import |
| `windows/install/ai-tools.ps1` | Remove local `Test-WinGetInstalled` and `Test-NpmInstalled`; add import |

**Why this works with separate processes:** Each `.ps1` script runs in its own process and does its own `Import-Module`. The module file is on disk, so each process imports it independently. This is the standard PowerShell pattern -- modules are designed for exactly this scenario.

**Import line for each script:**
```powershell
Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force
```

**Risk:** LOW. Module import is the standard PS pattern. Each script already imports 3 modules; this adds a 4th.

**Dependencies:** NONE. Fully independent change. Can be done in parallel with any other change.

---

### Change 3: Add Unit Tests for Core Bash Modules

**Problem:** Current tests are integration/validation only (syntax checks, pattern matching, file existence). No unit tests exercise the actual functions in `src/core/` modules.

**Existing test infrastructure:**

| File | Type | What It Tests |
|------|------|---------------|
| `test_harness.sh` | Structure | File existence, permissions, shebangs, URLs, directories |
| `test-linux.sh` | Validation | Syntax (`bash -n`), content patterns (grep), anti-patterns |
| `test-macos.sh` | Validation | Same pattern as test-linux.sh |
| `test-windows.ps1` | Validation | File existence, content patterns, anti-patterns |
| `test-dotfiles.sh` | **Unit** | Sources dotfiles.sh and tests functions with assertions |

**The dotfiles test is the model.** `test-dotfiles.sh` is the only actual unit test. It:
1. Creates a temp directory
2. Overrides `$HOME` for isolation
3. Sources the module under test
4. Tests individual functions with assertions
5. Cleans up on exit

**Solution:** Create unit test files following the `test-dotfiles.sh` pattern.

**New Files:**

| File | Module Under Test | Key Functions to Test |
|------|-------------------|----------------------|
| `tests/test-core-logging.sh` | `src/core/logging.sh` | `setup_colors`, `log_ok`, `log_error`, `log_warn`, `log_info`, `log_debug` (VERBOSE gating), `log_banner`, `_strip_colors` |
| `tests/test-core-errors.sh` | `src/core/errors.sh` | `record_failure`, `show_failure_summary`, `get_failure_count`, `clear_failures`, `retry_with_backoff`, `create_temp_dir`, `cleanup_temp_dir` |
| `tests/test-core-packages.sh` | `src/core/packages.sh` | `load_packages` (valid file, missing file, comments, blank lines), `load_profile`, `get_packages_for_manager` |
| `tests/test-core-idempotent.sh` | `src/core/idempotent.sh` | `ensure_line_in_file`, `ensure_dir`, `ensure_symlink`, `add_to_path`, `backup_if_exists` |
| `tests/test-core-platform.sh` | `src/core/platform.sh` | `detect_platform` (verify variables set), `verify_bash_version` |

**Test Pattern (reusable from test-dotfiles.sh):**
```bash
#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

TEST_DIR="/tmp/test-MODULE-$$"
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

cleanup() { [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"; }
trap cleanup EXIT INT TERM

assert_eq() { ... }  # Same as test-dotfiles.sh

# Source module under test
source "${PROJECT_ROOT}/src/core/MODULE.sh"

# Test functions
test_function_name() { ... }

# Run all tests
main() {
    setup_test_env
    test_function_name
    # ... more tests
    # Summary
}
main "$@"
```

**Special considerations per module:**

- **logging.sh**: Test `setup_colors` with `NO_COLOR=1` and non-TTY. Capture output with `$()` subshell. Test `_write_log` writes to `LOG_FILE`.
- **errors.sh**: Test `retry_with_backoff` with a command that fails N times then succeeds. Test `FAILURE_LOG` cross-process file.
- **packages.sh**: Create temp `.txt` files with comments, blank lines, valid entries. Test DATA_DIR resolution. **Caution:** `packages.sh` sets `readonly DATA_DIR` -- test must handle this (source in subshell or set up paths first).
- **platform.sh**: Just verify that `detect_platform` sets `DETECTED_OS` to a non-empty value. Cannot easily mock `uname`.
- **idempotent.sh**: Test file operations in temp directories. `is_installed` can be tested with known commands (`bash`, `ls`).

**Risk:** LOW. Tests are additive -- no existing files change. But `packages.sh` readonly DATA_DIR requires careful test setup.

**Dependencies:** Depends on Change 5 (DATA_DIR fix) if tests for `packages.sh` need to source it without hitting the readonly collision. Can start with other module tests immediately.

---

### Change 4: Remove Duplicate Color Definitions from platform.sh

**Problem:** `platform.sh` defines its own internal color variables (`_RED`, `_GREEN`, `_YELLOW`, `_BLUE`, `_NC`) on lines 33-45, AND defines internal logging helpers (`_platform_info`, `_platform_ok`, `_platform_warn`, `_platform_error`) on lines 50-64. These duplicate the functionality of `logging.sh`.

However, `platform.sh` uses its own colors ONLY in its internal `_platform_*` helper functions. These helpers are called by `verify_all()`, `verify_bash_version()`, `verify_supported_distro()`, etc.

**Root cause:** `platform.sh` was designed to be self-contained (no dependency on logging.sh), so it defines its own colors. But in practice, `logging.sh` is always sourced first (setup.sh sources logging.sh before platform.sh, and platform main scripts do the same).

**Solution:** Remove `_RED/_GREEN/_YELLOW/_BLUE/_NC` color definitions from `platform.sh`. Replace `_platform_*` internal helpers with calls to `logging.sh` functions.

**Files Modified:**

| File | Change |
|------|--------|
| `src/core/platform.sh` | Remove lines 33-64 (color vars + helper functions). Add conditional source of logging.sh (same pattern as errors.sh). Replace all `_platform_info` with `log_info`, `_platform_ok` with `log_ok`, `_platform_warn` with `log_warn`, `_platform_error` with `log_error`. |

**Detailed changes in platform.sh:**

```bash
# REMOVE: lines 33-64 (color block + helper functions)

# ADD at top (after source guard):
# Source logging module for output
if [[ -z "${_LOGGING_SOURCED:-}" ]]; then
    _PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${_PLATFORM_DIR}/logging.sh" ]]; then
        source "${_PLATFORM_DIR}/logging.sh"
    fi
fi

# REPLACE throughout:
# _platform_info  -> log_info   (5 occurrences)
# _platform_ok    -> log_ok     (1 occurrence: verify_all line 339)
# _platform_warn  -> log_warn   (3 occurrences)
# _platform_error -> log_error  (3 occurrences)
```

**What if logging.sh is NOT available?** Add fallback (same pattern as errors.sh and packages.sh):

```bash
# Internal fallback if logging not loaded
if ! type log_info &>/dev/null; then
    log_info() { echo "[INFO] $*"; }
    log_ok() { echo "[OK] $*"; }
    log_warn() { echo "[WARN] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
fi
```

**Callers affected:** NONE. The `_platform_*` functions are internal (not exported, not called from other files). The public API (`detect_platform`, `verify_all`, etc.) is unchanged.

**Risk:** LOW. Internal refactor only. No external API changes. The fallback ensures it works even if logging.sh fails to load.

**Dependencies:** NONE. Fully independent.

---

### Change 5: Resolve DATA_DIR Dual Readonly Definition

**Problem:** `DATA_DIR` is set as `readonly` in two places:

1. **`config.sh` line 49:** `readonly DATA_DIR="${PROJECT_ROOT}/data"`
2. **`packages.sh` line 26-27:** `DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" ... && pwd -P)"` then `readonly DATA_DIR`

When `setup.sh` sources `config.sh` first, `DATA_DIR` becomes readonly. Later, when any installer sources `packages.sh`, the `DATA_DIR=` assignment on line 26 **fails with a readonly error** (bash will print a warning but continue since there's no `set -e`). The `readonly DATA_DIR` on line 27 also triggers an error but since the value doesn't change, it's a no-op warning.

Additionally, `linux/main.sh` (line 51-52) and `macos/main.sh` (line 51-52) both have:
```bash
if [[ -z "${DATA_DIR:-}" || ! -d "${DATA_DIR}" ]]; then
    DATA_DIR="$(cd "${LINUX_DIR}/../../data" 2>/dev/null && pwd -P)"
fi
```
These are guarded by the `-z` check, so they only fire when DATA_DIR is unset, but they would also hit the readonly wall.

**Why it hasn't broken yet:** When `packages.sh` is sourced from a child `bash` process (via `bash "${INSTALL_DIR}/dev-env.sh"`), the child doesn't inherit the readonly attribute -- only the exported value. So the readonly collision only happens in the SAME process.

But the collision DOES happen when `setup.sh` does `source "${SCRIPT_DIR}/src/installers/dotfiles-install.sh"` (line 143), which then sources `core/dotfiles.sh`, which sources `core/logging.sh`. If `packages.sh` is ever sourced in the same shell session as `config.sh`, the collision fires.

**Solution:** Make `packages.sh` respect an existing `DATA_DIR` (SSoT principle: whoever sets it first wins).

**Files Modified:**

| File | Change |
|------|--------|
| `src/core/packages.sh` (lines 26-27) | Guard the assignment |

**New code for packages.sh:**
```bash
# Data directory: respect existing value (config.sh may set it),
# otherwise resolve relative to this script's location
if [[ -z "${DATA_DIR:-}" ]]; then
    DATA_DIR="$(cd "${_PACKAGES_DIR}/../../data" 2>/dev/null && pwd -P)"
    readonly DATA_DIR
fi
```

**Also update the main.sh fallbacks** (linux/main.sh line 51-52 and macos/main.sh line 51-52): These already have the guard (`if [[ -z "${DATA_DIR:-}" ...`), but they try to reassign without checking readonly. Since DATA_DIR will always be set (by either config.sh or packages.sh) before these scripts run, these guards will never fire. But for safety, wrap them:

```bash
if [[ -z "${DATA_DIR:-}" || ! -d "${DATA_DIR}" ]]; then
    # Only set if not already readonly
    DATA_DIR="$(cd "${LINUX_DIR}/../../data" 2>/dev/null && pwd -P)" 2>/dev/null || true
fi
```

Actually, the simplest fix: since `config.sh` already exports `DATA_DIR`, and platform main.sh scripts are always invoked as child processes (`bash "$linux_main"`), they inherit the exported value. The guard in main.sh is for when main.sh runs directly (interactive mode, not via setup.sh). In that case, `packages.sh` will have already set DATA_DIR. So these guards are dead code in practice.

**Recommended approach:** Fix only `packages.sh`. The main.sh guards are harmless (they only fire when DATA_DIR is unset, which means readonly was never called).

**Risk:** LOW. Single line change. Respects existing pattern.

**Dependencies:** Change 3 (unit tests for packages.sh) benefits from this fix being done first.

---

## Component Boundaries (Post-v3.0)

```
os-postinstall-scripts/
├── setup.sh / setup.ps1         # Entry points
├── config.sh                    # SSoT for path constants
├── src/
│   ├── core/                    # Bash modules (8 files, unchanged count)
│   │   ├── logging.sh           # SSoT for colors + logging
│   │   ├── platform.sh          # Uses logging.sh (no own colors)
│   │   ├── errors.sh
│   │   ├── packages.sh          # Respects pre-set DATA_DIR
│   │   ├── idempotent.sh
│   │   ├── dotfiles.sh
│   │   ├── progress.sh
│   │   └── interactive.sh
│   ├── install/                  # ALL cross-platform installers (merged)
│   │   ├── ai-tools.sh
│   │   ├── dev-env.sh
│   │   ├── dotfiles-install.sh  # MOVED from src/installers/
│   │   ├── fnm.sh
│   │   ├── rust-cli.sh
│   │   └── uv.sh
│   └── platforms/
│       ├── linux/
│       ├── macos/
│       └── windows/
│           ├── core/
│           │   ├── logging.psm1
│           │   ├── packages.psm1
│           │   ├── errors.psm1
│           │   └── idempotent.psm1  # NEW: shared check helpers
│           └── install/             # Thinner scripts, use idempotent.psm1
├── data/                            # Unchanged
└── tests/
    ├── test_harness.sh              # Updated (no src/installers/ check)
    ├── test-linux.sh
    ├── test-macos.sh
    ├── test-windows.ps1
    ├── test-dotfiles.sh             # Existing unit test
    ├── test-core-logging.sh         # NEW
    ├── test-core-errors.sh          # NEW
    ├── test-core-packages.sh        # NEW
    ├── test-core-idempotent.sh      # NEW
    └── test-core-platform.sh        # NEW
```

### Data Flow (Post-v3.0)

No data flow changes. All 5 changes are structural/quality -- they reorganize code and remove duplication without changing runtime behavior.

```
User runs setup.sh
  -> config.sh sets DATA_DIR (SSoT)
  -> platform.sh detects OS (uses logging.sh for output)
  -> platform main.sh dispatches to:
     -> src/install/*.sh (cross-platform, includes dotfiles-install.sh)
     -> src/platforms/{os}/install/*.sh (platform-specific)

User runs setup.ps1
  -> windows/main.ps1 dispatches via & (separate processes):
     -> install/*.ps1 (each imports core/*.psm1 including idempotent.psm1)
```

---

## Dependency Graph Between Changes

```
Change 1 (Merge dirs)    -----> Independent
Change 2 (PS module)     -----> Independent
Change 3 (Unit tests)    -----> Depends on Change 5 (for packages.sh tests)
Change 4 (Color cleanup) -----> Independent
Change 5 (DATA_DIR fix)  -----> Independent

Notation:
  Independent = no prerequisites, can start immediately
  Depends on  = should be done after prerequisite
```

**Parallel-safe groups:**
- Group A (do anytime): Change 1, Change 2, Change 4, Change 5
- Group B (after Change 5): Change 3 (specifically the packages.sh unit tests)

In practice, most of Change 3 (logging, errors, idempotent, platform unit tests) can start immediately. Only `test-core-packages.sh` needs Change 5 first.

---

## Recommended Build Order

### Step 1: DATA_DIR Fix (Change 5)
**Why first:** Smallest change, highest hidden impact. Fixes a latent bug that could manifest during any development. One line in packages.sh.

### Step 2: Color Cleanup (Change 4)
**Why second:** Removes dead code and establishes logging.sh as the SSoT for output formatting. Makes the module boundaries clearer for anyone writing tests.

### Step 3: Directory Merge (Change 1)
**Why third:** Structural cleanup. Updates 2 references in setup.sh and 1 in test_harness.sh. Small blast radius.

### Step 4: PS Module Extraction (Change 2)
**Why fourth:** Creates new file, modifies 4 existing files. More touchpoints but zero risk to Bash-side code.

### Step 5: Unit Tests (Change 3)
**Why last:** Tests validate the cleaned-up state. Writing tests against the final architecture avoids rework. The test for packages.sh specifically benefits from Change 5 being in place.

### Alternative: Parallel Execution

If speed matters more than sequential safety, the true dependency graph allows:

```
Batch 1 (parallel): Change 5 + Change 4 + Change 1 + Change 2
Batch 2 (after Batch 1): Change 3
```

---

## Anti-Patterns to Avoid During Implementation

### Anti-Pattern 1: Breaking the Source Guard Convention
**What:** Removing or modifying the `[[ -n "${_MODULE_SOURCED:-}" ]] && return 0` pattern.
**Why bad:** Every core module uses this for safe re-sourcing. Breaking it causes double-execution.
**Instead:** Preserve all source guards. The DATA_DIR fix respects this by checking the existing value.

### Anti-Pattern 2: Making platform.sh Depend on logging.sh Being Pre-Sourced
**What:** Removing platform.sh's ability to work standalone.
**Why bad:** Some scripts source platform.sh before logging.sh (e.g., rust-cli.sh sources platform.sh on line 42, logging.sh on line 22 -- logging first, but the pattern isn't universal).
**Instead:** Add conditional source + fallback functions (as specified in Change 4).

### Anti-Pattern 3: Dot-Sourcing PS Installer Scripts
**What:** Changing `& "$WindowsDir/install/winget.ps1"` to `. "$WindowsDir/install/winget.ps1"` to share module state.
**Why bad:** Dot-sourcing would share scope, making failure tracking, cleanup, and variable isolation unreliable. The separate-process model is intentional.
**Instead:** Use `Import-Module` in each script (as specified in Change 2). Modules are designed for cross-process reuse.

### Anti-Pattern 4: Putting Test Assertions in test_harness.sh
**What:** Adding unit test assertions to the existing structural test harness.
**Why bad:** test_harness.sh tests project structure, not function behavior. Mixing concerns makes both harder to maintain.
**Instead:** Create separate test-core-*.sh files (as specified in Change 3).

---

## Verification Strategy

Since there is no CI/CD (project decision), each change should be verified manually:

### Per-Change Verification

| Change | Verification Command | What to Check |
|--------|---------------------|---------------|
| 1 (Merge dirs) | `bash tests/test_harness.sh` | All tests pass, no reference to src/installers/ |
| 1 (Merge dirs) | `bash setup.sh dotfiles` (DRY_RUN=true) | Dotfiles action still works |
| 2 (PS module) | `pwsh tests/test-windows.ps1` | All existing tests pass |
| 3 (Unit tests) | `bash tests/test-core-logging.sh` | New tests pass |
| 3 (Unit tests) | `bash tests/test-core-errors.sh` | New tests pass |
| 3 (Unit tests) | `bash tests/test-core-packages.sh` | New tests pass (no readonly error) |
| 3 (Unit tests) | `bash tests/test-core-idempotent.sh` | New tests pass |
| 3 (Unit tests) | `bash tests/test-core-platform.sh` | New tests pass |
| 4 (Color cleanup) | `bash tests/test-linux.sh` | Existing tests pass |
| 4 (Color cleanup) | `DRY_RUN=true bash setup.sh developer` | Output still has colors |
| 5 (DATA_DIR fix) | `bash -c 'source config.sh; source src/core/packages.sh; echo $DATA_DIR'` | No readonly error, correct path |

### Regression Verification (After All Changes)

```bash
# Full test suite
bash tests/test_harness.sh
bash tests/test-linux.sh
bash tests/test-macos.sh
bash tests/test-dotfiles.sh
# New unit tests
bash tests/test-core-logging.sh
bash tests/test-core-errors.sh
bash tests/test-core-packages.sh
bash tests/test-core-idempotent.sh
bash tests/test-core-platform.sh
# Windows (on Windows machine)
pwsh tests/test-windows.ps1
```

---

## New vs Modified Files Summary

### New Files (3)

| File | Purpose |
|------|---------|
| `src/platforms/windows/core/idempotent.psm1` | Shared PS check helpers (Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled) |
| `tests/test-core-{logging,errors,packages,idempotent,platform}.sh` | 5 unit test files for core Bash modules |

### Moved Files (1)

| From | To |
|------|-----|
| `src/installers/dotfiles-install.sh` | `src/install/dotfiles-install.sh` |

### Modified Files (9)

| File | Change Description |
|------|-------------------|
| `src/core/packages.sh` | Guard DATA_DIR assignment with `-z` check |
| `src/core/platform.sh` | Remove color vars, use logging.sh functions with fallback |
| `setup.sh` | Update 3 path references from `src/installers/` to `src/install/` |
| `tests/test_harness.sh` | Update or remove `src/installers` directory existence check |
| `src/platforms/windows/install/winget.ps1` | Remove local `Test-WinGetInstalled`, add idempotent.psm1 import |
| `src/platforms/windows/install/cargo.ps1` | Remove local `Test-WinGetInstalled` + `Test-CargoInstalled`, add import |
| `src/platforms/windows/install/npm.ps1` | Remove local `Test-NpmInstalled`, add import |
| `src/platforms/windows/install/ai-tools.ps1` | Remove local `Test-WinGetInstalled` + `Test-NpmInstalled`, add import |
| (none -- `test-windows.ps1` may need a new assertion for idempotent.psm1 existence) | |

### Deleted Directories (1)

| Directory | Reason |
|-----------|--------|
| `src/installers/` | Emptied by move, directory removed |

---

## Sources

- **Codebase analysis:** All findings derived from reading every file in `src/`, `tests/`, `setup.sh`, `setup.ps1`, `config.sh`
- **PowerShell module pattern:** [PowerShell Import-Module documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/import-module) -- modules imported via `Import-Module` work in separate processes independently
- **Bash readonly behavior:** Bash manual -- readonly variables in parent process are exported as regular variables to child processes created via `bash script.sh`
- **No external library dependencies** -- all changes are internal refactoring
