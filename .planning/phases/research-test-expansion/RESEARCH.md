# Test Coverage Expansion - Research

**Researched:** 2026-02-19
**Domain:** Bash unit testing (bats-core), PowerShell testing (Pester), cross-platform test parity, profile validation
**Confidence:** HIGH

## Summary

The project has 37 bats-core unit tests covering 4 of 8 core Bash modules (logging, errors, idempotent, packages). Four modules remain untested: platform.sh, progress.sh, dotfiles.sh, and interactive.sh. Additionally, 5 PowerShell modules (.psm1) have zero unit tests -- only static smoke tests in test-windows.ps1. Profile validation (verifying .txt files referenced in profiles actually exist) has no coverage at all.

This research investigates practical strategies for each gap: mocking `uname`/`/etc/os-release` for platform.sh, temp-directory isolation for dotfiles.sh, output capture for progress.sh, stdin simulation for interactive.sh, Pester setup for PowerShell modules, Bash/PowerShell API parity contracts, and profile file-reference validation.

**Primary recommendation:** Expand bats coverage for the 4 missing Bash modules first (highest value-per-effort). Add profile validation tests second. Pester for PowerShell modules is worthwhile but lower priority -- the 5 modules are thin wrappers and the existing smoke tests catch structural regressions.

---

## Research Question 1: Testing platform.sh (OS Detection) Without Each OS

### The Problem

`detect_platform()` calls `uname -s`, `uname -m`, reads `/etc/os-release`, calls `sw_vers`, and probes `command -v apt-get/brew/winget`. These are all external commands or system files. Testing on macOS cannot exercise the Linux or Windows paths without mocking.

### Mock Strategy: Function Override (Recommended)

**Confidence: HIGH** -- This is the same pattern already used in test-core-errors.bats (line 18: `sleep() { :; }`).

In Bash, a function definition shadows an external command of the same name. Bats runs each `@test` in a subshell, so overrides are automatically cleaned up.

```bash
setup() {
    export NO_COLOR=1
    unset _PLATFORM_SOURCED
    unset _LOGGING_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"

    # Override uname to return controlled values
    # Default: pretend we are Linux x86_64
    uname() {
        case "$1" in
            -s) echo "Linux" ;;
            -m) echo "x86_64" ;;
            *)  echo "Linux" ;;
        esac
    }
    export -f uname

    # Override command to control package manager detection
    # By default, simulate apt-get available
    _MOCK_COMMANDS=("apt-get")
    command() {
        if [[ "$1" == "-v" ]]; then
            for cmd in "${_MOCK_COMMANDS[@]}"; do
                [[ "$2" == "$cmd" ]] && return 0
            done
            return 1
        fi
        builtin command "$@"
    }
    export -f command

    source "${BATS_TEST_DIRNAME}/../src/core/platform.sh"
}
```

### Mocking /etc/os-release

For `detect_platform()` Linux distro detection, the function does `source /etc/os-release`. Two approaches:

**Approach A -- Create a fake file and redirect (complex, fragile):**
Not recommended. Would require modifying the source code to accept a configurable path.

**Approach B -- Test what we can control, skip what we cannot (recommended):**
On macOS, the `[[ -f /etc/os-release ]]` check returns false, so the Linux distro path sets `DETECTED_DISTRO="unknown"`. This is testable. For the Linux-specific detection (reading os-release), create a fixture file and temporarily set it:

```bash
@test "detect_platform sets DETECTED_DISTRO from os-release on Linux" {
    # Create a mock os-release
    local mock_osrelease="${BATS_TEST_TMPDIR}/os-release"
    echo 'ID=ubuntu' > "$mock_osrelease"
    echo 'VERSION_ID="22.04"' >> "$mock_osrelease"

    # This test will only pass on Linux or needs source code modification
    # to accept OS_RELEASE_PATH. Mark as skip on macOS:
    if [[ "$(builtin command uname -s)" != "Linux" ]]; then
        skip "Linux-only: /etc/os-release detection"
    fi

    run detect_platform
    assert_success
    [[ "$DETECTED_DISTRO" == "ubuntu" ]]
}
```

**Practical recommendation:** Test these aspects of platform.sh that DO NOT depend on the real OS:
- `uname -s` mapping (mock uname, test all branches: Darwin/Linux/MINGW/unknown)
- `uname -m` mapping (mock uname -m, test x86_64/arm64/unknown)
- `verify_bash_version()` (uses BASH_VERSINFO, which is testable)
- `verify_package_manager()` (mock command -v, test empty DETECTED_PKG)
- `verify_supported_distro()` (set DETECTED_DISTRO directly, test matching/non-matching)
- `request_sudo()` (test DRY_RUN=true skip, test root skip via id mock)

**Skip on non-matching platforms:** `/etc/os-release` parsing, `sw_vers`, actual `command -v brew`. Use `bats skip` for these.

### Testable Functions in platform.sh (7 exported)

| Function | Mockable? | Strategy | Tests Needed |
|----------|-----------|----------|--------------|
| `detect_platform` | Partial | Mock uname, mock command -v | 6-8 tests (OS mapping, arch mapping, pkg detection) |
| `verify_bash_version` | Yes | Set BASH_VERSINFO directly | 2 tests (pass >= 4, fail < 4) |
| `verify_supported_distro` | Yes | Set DETECTED_OS, DETECTED_DISTRO | 3 tests (macos=skip, supported, unsupported) |
| `verify_package_manager` | Yes | Set DETECTED_PKG | 2 tests (empty=fail, present=pass) |
| `check_internet` | Partial | Mock curl, or test non-interactive path | 1-2 tests |
| `request_sudo` | Yes | DRY_RUN=true path, mock id | 2-3 tests |
| `verify_all` | Complex | Integration of above | 1 test (happy path) |

**Estimated: ~15-18 new tests for test-core-platform.bats**

---

## Research Question 2: Testing dotfiles.sh Safely (Symlinks, Backups)

### The Problem

dotfiles.sh operates on `$HOME` -- creating symlinks, backing up files, writing manifests. Tests must not touch the real HOME.

### Solution: Override HOME and BACKUP_DIR in setup() (Recommended)

**Confidence: HIGH** -- This is exactly what test-dotfiles.sh already does (line 48-50). The existing integration test is the template.

```bash
setup() {
    export NO_COLOR=1
    unset _DOTFILES_SOURCED
    unset _LOGGING_SOURCED

    # Create isolated test environment
    TEST_DIR="$(mktemp -d)"
    export HOME="${TEST_DIR}/home"
    mkdir -p "$HOME"
    export BACKUP_DIR="${HOME}/.dotfiles-backup"
    export MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"

    # Reset session tracking
    SESSION_BACKUPS=()

    # Create test source files
    mkdir -p "${TEST_DIR}/source"
    echo "source content" > "${TEST_DIR}/source/testfile"

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/dotfiles.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}
```

### Key Difference from Existing test-dotfiles.sh

The existing `test-dotfiles.sh` is a standalone integration test using a custom test harness. The new `test-core-dotfiles.bats` would use bats-core with `assert_success`, `assert_output`, proper setup/teardown, and test isolation (each test gets its own subshell + temp dir).

### Testable Functions in dotfiles.sh (6 exported)

| Function | Strategy | Tests Needed |
|----------|----------|--------------|
| `path_to_backup_name` | Pure function, no side effects | 3-4 tests (simple, nested, empty) |
| `backup_with_manifest` | Temp dir with files | 3-4 tests (success, dry-run, empty arg, collision) |
| `create_dotfile_symlink` | Temp dir, verify symlinks | 5-6 tests (new, replace existing, backup trigger, dry-run, missing source, parent dir creation) |
| `unlink_dotfiles` | Temp dir, verify restore | 3-4 tests (unlink+restore, no backup, not-a-symlink) |
| `show_backup_summary` | Output capture | 2 tests (empty session, with backups) |
| `list_backups` | Temp dir with .bak files | 2 tests (empty, with backups) |

**Estimated: ~18-22 new tests for test-core-dotfiles.bats**

### Note: Overlap with test-dotfiles.sh

The existing `test-dotfiles.sh` (379 lines, 8 test functions) covers the most important integration scenarios. The new bats tests would add:
- Finer-grained function-level coverage
- Edge cases (empty args, collision handling, manifest format)
- DRY_RUN path testing
- Proper assert_output verification

**Recommendation:** Keep test-dotfiles.sh as-is (integration test). New bats tests focus on individual function behavior.

---

## Research Question 3: Testing progress.sh (Step Counters, Banners)

### The Problem

progress.sh has 3 functions: `show_dry_run_banner()`, `count_platform_steps()`, `show_completion_summary()`. The first and third produce console output. The second reads a profile file and returns a count.

### Solution: bats `run` Captures Output

**Confidence: HIGH** -- This is the standard bats pattern already used in test-core-logging.bats.

```bash
@test "show_dry_run_banner outputs banner when DRY_RUN=true" {
    export DRY_RUN=true
    run show_dry_run_banner
    assert_success
    assert_output --partial "DRY RUN MODE"
}

@test "show_dry_run_banner outputs nothing when DRY_RUN is unset" {
    unset DRY_RUN
    run show_dry_run_banner
    assert_success
    assert_output ""
}
```

### count_platform_steps Needs a Fixture

```bash
@test "count_platform_steps counts linux-relevant files" {
    # Create fixture profile
    local profile="${BATS_TEST_TMPDIR}/test-profile.txt"
    cat > "$profile" <<'EOF'
# Test profile
apt.txt
brew.txt
cargo.txt
winget.txt
flatpak.txt
EOF
    run count_platform_steps "$profile" "linux"
    assert_output "3"  # apt.txt + cargo.txt + flatpak.txt
}
```

### show_completion_summary Dependencies

`show_completion_summary()` calls `get_failure_count()` and `show_failure_summary()` from errors.sh. It also reads `$FAILURE_LOG` and uses `$SECONDS`. These need setup:

```bash
setup() {
    export NO_COLOR=1
    unset _LOGGING_SOURCED _PROGRESS_SOURCED _ERRORS_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/errors.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/progress.sh"
    clear_failures
    SECONDS=90  # Simulate 1m30s elapsed
    FAILURE_LOG="$(mktemp)"
    export FAILURE_LOG
}

teardown() {
    rm -f "$FAILURE_LOG"
}
```

### Testable Functions in progress.sh (3 exported)

| Function | Strategy | Tests Needed |
|----------|----------|--------------|
| `show_dry_run_banner` | Output capture | 2 tests (DRY_RUN=true, unset) |
| `count_platform_steps` | Fixture profile file | 4-5 tests (linux count, macos count, missing file, empty profile, comments-only) |
| `show_completion_summary` | Output capture + FAILURE_LOG setup | 3-4 tests (no failures, with failures, dry-run banner text) |

**Estimated: ~10-12 new tests for test-core-progress.bats**

---

## Research Question 4: Minimal Integration Test

### What Is the Goal?

Verify that `./setup.sh --dry-run developer` completes without error and produces expected output. This is a smoke test that exercises the full pipeline: config loading, platform detection, profile dispatch.

### Recommended Approach

```bash
@test "setup.sh --dry-run developer completes successfully" {
    cd "${BATS_TEST_DIRNAME}/.."
    run bash setup.sh --dry-run developer
    assert_success
    assert_output --partial "DRY RUN MODE"
    assert_output --partial "Profile: developer"
    assert_output --partial "Detected:"
}

@test "setup.sh --help shows usage" {
    cd "${BATS_TEST_DIRNAME}/.."
    run bash setup.sh --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "minimal"
    assert_output --partial "developer"
    assert_output --partial "full"
}

@test "setup.sh with unknown flag fails" {
    cd "${BATS_TEST_DIRNAME}/.."
    run bash setup.sh --invalid-flag
    assert_failure
    assert_output --partial "Unknown option"
}
```

### Constraints

- **No real installations.** Always use `--dry-run`.
- **Platform-dependent output.** On macOS, output includes "macOS". On Linux, output includes the distro name. Tests should use `--partial` matching.
- **Internet dependency.** `check_internet()` pings google.com. In dry-run mode, `verify_all()` still runs this check. Tests on air-gapped machines will get a warning but continue (non-interactive mode returns 0).
- **Sudo prompt.** In dry-run mode, `request_sudo()` skips. This is safe.

### Recommended File

Create `tests/test-integration.bats` with 5-8 tests covering:
1. `--dry-run developer` succeeds
2. `--dry-run minimal` succeeds
3. `--dry-run full` succeeds
4. `--help` shows usage
5. Unknown flag fails
6. `--verbose` adds timestamps
7. `dotfiles` action sources dotfiles-install.sh (dry-run)

**Estimated: ~5-8 tests for test-integration.bats**

---

## Research Question 5: Pester for PowerShell Modules

### Is It Worth It?

**The case for Pester:**
- 5 PowerShell modules (logging, errors, packages, idempotent, progress) with 0 unit tests
- These modules are the PowerShell equivalents of the 8 Bash core modules
- Pester is THE standard -- Microsoft-maintained, 10k+ stars, ships with Windows
- Mock support lets you test `Test-WinGetInstalled` without real winget

**The case against (for now):**
- The 5 modules total ~350 lines of code (thin wrappers)
- test-windows.ps1 already catches structural regressions (46 assertions)
- Pester tests only run on Windows/PowerShell, limiting who can run them
- The project has no CI/CD (explicit owner decision) -- tests are manual only

### Minimal Viable Pester Setup

**Confidence: HIGH** -- Official Pester docs and Microsoft Learn.

**Installation (one-time, Windows only):**
```powershell
Install-Module Pester -Force -SkipPublisherCheck
```

**File structure:**
```
tests/
  pester/
    logging.Tests.ps1
    errors.Tests.ps1
    packages.Tests.ps1
    idempotent.Tests.ps1
    progress.Tests.ps1
```

**Minimal test example for logging.psm1:**
```powershell
#Requires -Module Pester

BeforeAll {
    Import-Module "$PSScriptRoot/../../src/platforms/windows/core/logging.psm1" -Force
}

Describe 'Write-Log' {
    BeforeEach {
        $env:NO_COLOR = '1'
        $env:VERBOSE = ''
    }

    It 'outputs [INFO] prefix for INFO level' {
        $output = Write-Log -Level INFO -Message 'test' 6>&1
        $output | Should -Match '\[INFO\]'
        $output | Should -Match 'test'
    }

    It 'suppresses DEBUG when VERBOSE is not true' {
        $env:VERBOSE = ''
        $output = Write-Log -Level DEBUG -Message 'hidden' 6>&1
        $output | Should -BeNullOrEmpty
    }

    It 'shows DEBUG when VERBOSE is true' {
        $env:VERBOSE = 'true'
        $output = Write-Log -Level DEBUG -Message 'visible' 6>&1
        $output | Should -Match '\[DEBUG\]'
    }

    It 'outputs BANNER format' {
        $output = Write-Log -Level BANNER -Message 'MyBanner' 6>&1
        $output | Should -Match '=== MyBanner ==='
    }
}
```

**Running:**
```powershell
Invoke-Pester tests/pester/*.Tests.ps1 -Output Detailed
```

### Write-Host Capture Gotcha

**Confidence: HIGH** -- This is a well-documented Pester limitation.

`Write-Host` output is NOT captured by default assignment. In Pester 5+, use the `6>&1` redirection (Information stream) to capture it:

```powershell
$output = Write-Log -Level INFO -Message 'test' 6>&1
```

Or use `Should -Invoke` with mocking to verify Write-Host was called:

```powershell
Mock Write-Host {}
Write-Log -Level INFO -Message 'test'
Should -Invoke Write-Host -Times 1
```

### InModuleScope for Testing Internal State

For errors.psm1, `$script:FailedItems` is module-scoped. Testing requires `InModuleScope`:

```powershell
Describe 'Add-FailedItem' {
    BeforeEach {
        Import-Module "$PSScriptRoot/../../src/platforms/windows/core/errors.psm1" -Force
        Clear-Failures
    }

    It 'increments failure count' {
        Add-FailedItem -Item 'test-pkg'
        Get-FailureCount | Should -Be 1
    }
}
```

### Recommendation

**Add Pester tests as a separate phase item (TEVO-02), lower priority than bats expansion.** Start with logging.psm1 and errors.psm1 (highest value -- these mirror the Bash modules). Skip idempotent.psm1 initially (calls real winget/npm/cargo -- requires mocking that is harder to set up).

**Estimated: ~15-20 Pester tests across 3-4 modules (logging, errors, packages, progress)**

---

## Research Question 6: Contract Tests for Bash/PowerShell API Parity

### The Problem

5 modules exist as Bash/PowerShell pairs. The pairs should export matching APIs (same function count, same semantics). Currently no automated verification.

| Bash Module | PowerShell Module | Bash Functions | PS Functions |
|-------------|-------------------|----------------|--------------|
| logging.sh | logging.psm1 | 12 (incl. aliases) | 1 (Write-Log) |
| errors.sh | errors.psm1 | 8 | 4 |
| packages.sh | packages.psm1 | 3 | 1 |
| idempotent.sh | idempotent.psm1 | 10 | 3 |
| progress.sh | progress.psm1 | 3 | 3 |

**Note:** The PS modules deliberately consolidate multiple Bash functions into fewer functions with parameters. For example, Bash has `log_ok`, `log_error`, `log_warn`, `log_info`, `log_debug` -- PS has `Write-Log -Level OK|ERROR|WARN|INFO|DEBUG`. This is by design (ADR-006 cross-platform strategy), not a bug.

### Contract Test Approach

A contract test verifies that both implementations handle the same scenarios identically. Since the APIs differ by design, the contracts should focus on **behavioral equivalence**, not function-name matching.

**Option A: Declarative contract file (Recommended)**

Create `tests/contracts/api-parity.txt`:
```
# Bash function -> PS function -> Contract
# Format: bash_fn | ps_fn | behavior
log_ok "msg"         | Write-Log -Level OK -Message "msg"    | outputs [OK] prefix
log_error "msg"      | Write-Log -Level ERROR -Message "msg"  | outputs [ERROR] prefix
record_failure "pkg"  | Add-FailedItem -Item "pkg"             | increments count to 1
get_failure_count     | Get-FailureCount                       | returns 0 when empty
clear_failures        | Clear-Failures                         | resets to 0
load_packages "f.txt" | Read-PackageFile -FileName "f.txt"     | reads package list
```

Then a meta-test verifies this contract file stays in sync:

```bash
@test "contract: all Bash exported functions have PS equivalent" {
    # Extract export -f lines from Bash modules
    local bash_exports=$(grep -h "export -f" src/core/{logging,errors,packages,progress}.sh | \
        sed 's/export -f //' | tr ' ' '\n' | sort)

    # Verify each has an entry in the contract file
    while IFS= read -r fn; do
        grep -q "^${fn}" tests/contracts/api-parity.txt || \
            fail "Bash function '$fn' missing from contract file"
    done <<< "$bash_exports"
}
```

**Option B: Output comparison tests**

Run the same logical operation in both languages and compare output:

```bash
@test "contract: logging output format matches" {
    # Bash output
    export NO_COLOR=1
    local bash_out=$(source src/core/logging.sh && log_ok "test" 2>&1)

    # PS output (if pwsh available)
    if command -v pwsh &>/dev/null; then
        local ps_out=$(pwsh -NoProfile -Command "
            Import-Module src/platforms/windows/core/logging.psm1
            \$env:NO_COLOR='1'
            Write-Log -Level OK -Message 'test' 6>&1
        " 2>&1)

        # Both should contain [OK] and 'test'
        [[ "$bash_out" == *"[OK]"* ]]
        [[ "$ps_out" == *"[OK]"* ]]
    else
        skip "pwsh not available"
    fi
}
```

### Recommendation

**Option A is more practical.** Option B requires `pwsh` installed on the test machine, which is unlikely on Linux. The contract file serves as living documentation of the API mapping and can be validated by the bats tests (checking Bash side) and Pester tests (checking PS side) independently.

**Estimated: 1 contract file + 5-8 validation tests in test-contracts.bats**

---

## Research Question 7: Profile Validation Tests

### The Problem

Profile files (developer.txt, full.txt, minimal.txt) reference package files (apt.txt, brew.txt, cargo.txt, etc.). If someone adds a reference to a non-existent file, the error only appears at runtime.

### Solution: File-Reference Validation Test

```bash
@test "all profile files reference existing package files" {
    local profiles_dir="${BATS_TEST_DIRNAME}/../data/packages/profiles"
    local packages_dir="${BATS_TEST_DIRNAME}/../data/packages"

    for profile in "$profiles_dir"/*.txt; do
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Trim whitespace
            line="${line#"${line%%[![:space:]]*}"}"
            # Skip comments and empty lines
            [[ -z "$line" || "$line" == \#* ]] && continue

            # Verify the referenced file exists
            assert [ -f "${packages_dir}/${line}" ] \
                "Profile $(basename "$profile") references '${line}' but file does not exist"
        done < "$profile"
    done
}

@test "all profiles have at least one package file" {
    local profiles_dir="${BATS_TEST_DIRNAME}/../data/packages/profiles"

    for profile in "$profiles_dir"/*.txt; do
        local count=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "$line" || "$line" == \#* ]] && continue
            ((count++))
        done < "$profile"
        assert [ "$count" -gt 0 ] \
            "Profile $(basename "$profile") has no package file references"
    done
}

@test "no orphaned package files (not referenced by any profile)" {
    local profiles_dir="${BATS_TEST_DIRNAME}/../data/packages/profiles"
    local packages_dir="${BATS_TEST_DIRNAME}/../data/packages"

    for pkg_file in "$packages_dir"/*.txt; do
        local basename_file=$(basename "$pkg_file")
        local found=false
        for profile in "$profiles_dir"/*.txt; do
            if grep -qw "$basename_file" "$profile"; then
                found=true
                break
            fi
        done
        # Note: This is informational, not a hard failure
        # Some package files might be platform-specific and only referenced conditionally
        if [[ "$found" == "false" ]]; then
            echo "# INFO: ${basename_file} not referenced by any profile" >&3
        fi
    done
}
```

### Where to Put This

Create `tests/test-data-validation.bats` -- separate from core module tests because these validate data files, not code.

**Estimated: 4-6 tests for test-data-validation.bats**

---

## Standard Stack

### Core (Already Installed)

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| bats-core | 1.13.0 | Bash unit test framework | Installed as git submodule |
| bats-support | 0.3.0 | Formatting helpers | Installed as git submodule |
| bats-assert | 2.1.0 | Assertion library | Installed as git submodule |
| ShellCheck | 0.11.0 | Bash static analysis | Installed at /opt/homebrew/bin/shellcheck |

### New (If Pester Is Adopted)

| Library | Version | Purpose | When |
|---------|---------|---------|------|
| Pester | 5.6.x | PowerShell test framework | Only for TEVO-02 (PS unit tests) |

### Not Needed

| Library | Why Not |
|---------|---------|
| bats-mock | Function override (already used in project) is simpler and requires no additional dependency |
| shunit2 | bats-core already adopted, no reason to switch |

---

## Architecture: Recommended New Test Files

```
tests/
  # Existing (keep as-is)
  test-core-logging.bats       # 10 tests (existing)
  test-core-errors.bats        # 9 tests (existing)
  test-core-idempotent.bats    # 11 tests (existing)
  test-core-packages.bats      # 7 tests (existing)
  test_harness.sh              # Smoke test (existing)
  test-linux.sh                # Platform smoke (existing)
  test-macos.sh                # Platform smoke (existing)
  test-dotfiles.sh             # Integration test (existing)
  test-windows.ps1             # PS smoke test (existing)

  # New: TEVO-01 (bats expansion)
  test-core-platform.bats      # ~15-18 tests: OS detection mocking
  test-core-progress.bats      # ~10-12 tests: counters, banner, summary
  test-core-dotfiles.bats      # ~18-22 tests: symlinks, backups in tmpdir
  test-core-interactive.bats   # ~6-8 tests: non-interactive paths

  # New: TEVO-03 (data validation)
  test-data-validation.bats    # ~4-6 tests: profile file references

  # New: integration
  test-integration.bats        # ~5-8 tests: setup.sh --dry-run end-to-end

  # New: contracts
  contracts/
    api-parity.txt             # Declarative Bash<->PS mapping

  # New: TEVO-02 (Pester, lower priority)
  pester/
    logging.Tests.ps1          # ~5 tests
    errors.Tests.ps1           # ~5 tests
    packages.Tests.ps1         # ~4 tests
    progress.Tests.ps1         # ~4 tests
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Command mocking | bats-mock library, PATH manipulation | Shell function override (`uname() { ... }`) | Already proven in the codebase (errors.bats sleep mock). Simpler, no dependencies. |
| Output capture | Custom redirection chains | bats `run` + `assert_output` | Standard bats pattern, handles stdout+stderr uniformly |
| Temp directory lifecycle | Manual mkdir/rm in each test | bats `$BATS_TEST_TMPDIR` + `setup()/teardown()` | Bats provides per-test temp dir automatically |
| PS module testing | Custom Select-String assertions | Pester `Should` + `Mock` + `InModuleScope` | Microsoft-maintained, handles module scoping edge cases |
| API parity validation | Manual grep comparison | Declarative contract file + automated test | Single source of truth, easy to maintain |

---

## Common Pitfalls

### Pitfall 1: Source Guard Blocks Re-Sourcing

**What goes wrong:** platform.sh has `readonly _PLATFORM_SOURCED=1`. If sourced twice in the same process, the `return 0` guard prevents re-initialization.
**How to avoid:** `unset _PLATFORM_SOURCED` in `setup()` before sourcing. This works because bats runs each `@test` in a fresh subshell where the readonly is not set. But if you source in `setup_file()` (once per file), all tests share the same sourced state.
**Rule:** Always source in `setup()`, never in `setup_file()` for core modules.

### Pitfall 2: Mocking uname Affects ALL Subsequent Calls

**What goes wrong:** If you define `uname() { echo "Linux"; }` and the sourced module calls `uname -s` and `uname -m`, both get "Linux".
**How to avoid:** Make the mock dispatch on arguments: `case "$1" in -s) ... ;; -m) ... ;; esac`.

### Pitfall 3: `command -v` Override Breaks Module Loading

**What goes wrong:** platform.sh uses `command -v apt-get` etc. If you override `command` itself, other code that uses `command -v` for different purposes may break.
**How to avoid:** Define the mock narrowly -- only intercept `-v` flag, pass through everything else with `builtin command "$@"`.

### Pitfall 4: HOME Override Affects dotfiles.sh Path Resolution

**What goes wrong:** dotfiles.sh uses `$HOME` for backup paths and symlink targets. If HOME is overridden, path_to_backup_name removes the HOME prefix. If the test source files are NOT under the mocked HOME, the prefix removal produces unexpected results.
**How to avoid:** Ensure test source files are under the mocked HOME or in a sibling directory under the same temp root.

### Pitfall 5: Pester Write-Host Capture Requires Stream Redirection

**What goes wrong:** `$result = Write-Log -Level INFO -Message "test"` returns `$null` because Write-Host writes to the Information stream, not the output stream.
**How to avoid:** Use `6>&1` redirection: `$result = Write-Log -Level INFO -Message "test" 6>&1`. Or mock Write-Host and verify invocation.

### Pitfall 6: interactive.sh Tests Cannot Simulate Real TTY

**What goes wrong:** `show_category_menu` and `ask_tool` check `[[ -t 0 ]]` (is stdin a terminal). In bats, stdin is NOT a terminal, so the functions always take the non-interactive path.
**How to avoid:** This is actually a feature, not a bug. Test the non-interactive codepath (returns 0 = install all). For the interactive codepath, test the logic with `NONINTERACTIVE=true` explicitly set. Do NOT try to simulate a TTY -- it adds complexity with zero value for this project.

---

## Testing interactive.sh

### Strategy: Test Non-Interactive Paths Only

**Confidence: HIGH** -- Both functions have explicit non-interactive fallbacks.

```bash
@test "show_category_menu returns 0 (install all) in non-interactive mode" {
    export NONINTERACTIVE=true
    run show_category_menu "Tools" "description"
    # Return code 0 = install all
    assert_success
}

@test "ask_tool returns 0 (install) in non-interactive mode" {
    export NONINTERACTIVE=true
    run ask_tool "git"
    assert_success
}

@test "show_category_menu returns 0 when stdin is not a terminal" {
    # bats always runs without TTY, so this tests the [[ ! -t 0 ]] branch
    unset NONINTERACTIVE
    run show_category_menu "Tools" "description"
    assert_success
}
```

**Estimated: ~6-8 tests for test-core-interactive.bats**

---

## Priority Ranking

| Priority | Item | New Tests | Effort | Value |
|----------|------|-----------|--------|-------|
| 1 | **TEVO-01a:** test-core-platform.bats | ~15-18 | Medium | HIGH -- platform.sh is the most complex untested module |
| 2 | **TEVO-01b:** test-core-progress.bats | ~10-12 | Low | HIGH -- straightforward, high coverage gain |
| 3 | **TEVO-01c:** test-core-dotfiles.bats | ~18-22 | Medium | MEDIUM -- test-dotfiles.sh already covers main paths |
| 4 | **TEVO-01d:** test-core-interactive.bats | ~6-8 | Low | MEDIUM -- limited testable surface (non-interactive only) |
| 5 | **TEVO-03:** test-data-validation.bats | ~4-6 | Low | HIGH -- prevents silent profile breakage |
| 6 | **Integration:** test-integration.bats | ~5-8 | Low | MEDIUM -- validates end-to-end pipeline |
| 7 | **TEVO-02:** Pester tests | ~15-20 | Medium | LOW-MEDIUM -- PS modules already smoke-tested |
| 8 | **Contracts:** api-parity.txt + tests | ~5-8 | Low | LOW -- mainly documentation value |

**Total new tests: ~80-100 (from current 37 to ~120-140)**

---

## Open Questions

1. **interactive.sh TTY testing depth**
   - What we know: Both functions return 0 in non-interactive mode, which is all bats can test.
   - What's unclear: Is testing only the non-interactive path sufficient, or should we add `expect`-based TTY simulation?
   - Recommendation: Non-interactive path testing is sufficient. TTY simulation adds a heavy dependency (expect/unbuffer) for marginal value.

2. **Pester version: v5 stable or v6 preview?**
   - What we know: Pester v5.6.x is the current stable. v6 is in preview.
   - Recommendation: Use v5 stable. v6 has breaking changes and is not yet released.

3. **Contract tests: hard fail or informational?**
   - What we know: Bash and PS APIs differ by design (consolidated functions in PS).
   - Recommendation: Make the contract file informational (documents mapping), with hard-fail only for "Bash function exists but has no PS equivalent listed."

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection of all 8 core Bash modules and 5 PowerShell modules
- [bats-core documentation](https://bats-core.readthedocs.io/) -- writing-tests, setup/teardown, run helper
- [Pester Quick Start](https://pester.dev/docs/quick-start) -- installation, Describe/It/Should, BeforeAll
- [Pester Unit Testing within Modules](https://pester.dev/docs/usage/modules) -- InModuleScope, Import-Module -Force
- Existing project tests: test-core-logging.bats, test-core-errors.bats, test-dotfiles.sh patterns

### Secondary (MEDIUM confidence)
- [bats-mock (jasonkarns)](https://github.com/jasonkarns/bats-mock) -- evaluated and rejected in favor of function override
- [Pester GitHub](https://github.com/pester/Pester) -- v5.6.x current, v6 preview
- [PowerShell Pester 101](https://adamtheautomator.com/powershell-pester-testing-guide/) -- practical patterns
- [bats-core issue #230](https://github.com/bats-core/bats-core/issues/230) -- function mocking limitations

### Tertiary (LOW confidence)
- Community blog posts on bats mocking patterns (verified against bats-core docs)

---

## Metadata

**Confidence breakdown:**
- Bats expansion (TEVO-01): HIGH -- patterns proven by existing 37 tests, same framework
- Pester setup (TEVO-02): HIGH -- official docs verified, standard approach
- Profile validation (TEVO-03): HIGH -- pure file I/O, no dependencies
- Contract tests: MEDIUM -- novel approach, not battle-tested in similar projects
- Mock strategies: HIGH -- function override already used in codebase (sleep mock in errors.bats)

**Research date:** 2026-02-19
**Valid until:** 2026-03-19 (stable domain)
