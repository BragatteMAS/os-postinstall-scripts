# Phase 17: Test Expansion - Bash - Research

**Researched:** 2026-02-21
**Domain:** Bash unit testing (bats-core 1.13.0), mocking strategies, data validation, cross-platform contract parity
**Confidence:** HIGH

## Summary

The project currently has 44 passing bats tests across 4 files covering logging.sh, errors.sh, idempotent.sh, and packages.sh. Four core modules remain untested: platform.sh (7 exported functions), progress.sh (3 functions), dotfiles.sh (6 functions), and interactive.sh (2 functions). Additionally, no tests validate profile data integrity or integration-level behavior.

All recommended test patterns have been **empirically verified** on the actual project -- mock uname, mock `command -v`, tmpdir HOME isolation for dotfiles, progress.sh dependency chain sourcing, interactive.sh non-interactive paths, and setup.sh integration tests. Each pattern was written as a throwaway bats file and executed successfully against the real codebase.

**Primary recommendation:** Use the established project patterns (source guard unset + `setup()` sourcing + function override mocking) to expand bats coverage. No new test libraries needed -- bats-core 1.13.0, bats-support, and bats-assert already provide everything required.

## Standard Stack

### Core (Already Installed - No Changes Needed)

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| bats-core | 1.13.0 | Bash unit test framework | `tests/lib/bats-core/` |
| bats-support | latest | Formatting helpers | `tests/lib/bats-support/` |
| bats-assert | latest | Assertion library (`assert_success`, `assert_output`) | `tests/lib/bats-assert/` |

### Not Needed

| Library | Why Not |
|---------|---------|
| bats-mock | Function override (already used in errors.bats `sleep() { :; }`) is simpler, zero deps |
| bats-file | File assertions can be done with `[ -f ]`, `[ -L ]`, `[ -d ]` -- no need for extra lib |
| expect/unbuffer | TTY simulation for interactive.sh -- not needed, non-interactive paths are sufficient |
| shunit2 | Project standardized on bats-core, no reason to introduce a second framework |

## Architecture Patterns

### Established Project Test Pattern

Every existing test file follows this exact pattern. New files MUST follow it:

```bash
#!/usr/bin/env bats
# tests/test-core-MODULE.bats -- Unit tests for src/core/MODULE.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Unset ALL source guards for modules in the dependency chain
    unset _MODULE_SOURCED
    unset _LOGGING_SOURCED  # if module depends on logging.sh
    # Source dependencies first, then the module under test
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/MODULE.sh"
}

teardown() {
    # Clean up temp files/dirs if any were created
    rm -rf "$TEST_DIR"
}

@test "function_name does expected thing" {
    run function_name "arg"
    assert_success
    assert_output --partial "expected"
}
```

### Key Conventions (from existing tests)

1. **Source guards must be unset in setup()** -- Each `@test` runs in a subshell, but `setup()` runs in the same subshell before the test. The `readonly _MODULE_SOURCED=1` pattern means you MUST `unset` the guard before `source`.

2. **NO_COLOR=1 always** -- Prevents ANSI escape codes in test output, making `assert_output` reliable.

3. **Dependencies sourced explicitly** -- If module A depends on logging.sh, source logging.sh first. Do NOT rely on module A's internal sourcing (it uses `BASH_SOURCE[0]` relative paths which may not resolve in test context).

4. **Mocking via function override** -- Define a function with the same name as the command to mock. Bats subshell isolation ensures cleanup. Already proven: `sleep() { :; }` in test-core-errors.bats.

5. **Temp files via mktemp + teardown cleanup** -- `$BATS_TEST_TMPDIR` is available (verified on bats 1.13.0) for per-test temp files. For temp dirs that need HOME override, use `mktemp -d` + `teardown() { rm -rf; }`.

### New Test File Layout

```
tests/
  # Existing (44 tests, keep as-is)
  test-core-logging.bats        # 11 tests
  test-core-errors.bats         # 16 tests
  test-core-idempotent.bats     # 11 tests
  test-core-packages.bats       # 7 tests (note: 1 is empty/padding)

  # New Phase 17 files
  test-core-platform.bats       # ~15-18 tests (TEST-03)
  test-core-progress.bats       # ~10-12 tests (TEST-04)
  test-core-dotfiles.bats       # ~18-22 tests (TEST-05)
  test-core-interactive.bats    # ~6-8 tests (TEST-06)
  test-data-validation.bats     # ~4-6 tests (TEST-07)
  test-integration.bats         # ~5-8 tests (TEST-08)

  # New directory
  contracts/
    api-parity.txt              # Declarative Bash<->PS mapping (TEST-09)
```

### Anti-Patterns to Avoid

- **Sourcing in `setup_file()` instead of `setup()`:** Source guards are `readonly`. If you source in `setup_file()` (once per file), the readonly variable persists across all tests and cannot be unset. Always source in per-test `setup()`.

- **Mocking uname without argument dispatch:** `uname()` is called with both `-s` and `-m`. A mock that returns a fixed string for all calls produces wrong results. Always dispatch on `$1`.

- **Overriding `command` without passthrough:** platform.sh uses `command -v apt-get`, but other code may use `command` for other purposes. The mock MUST passthrough non `-v` calls: `builtin command "$@"`.

- **Testing setup.sh without --dry-run:** Integration tests MUST always use `--dry-run` to prevent real system changes (sudo prompts, package installations).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Command mocking | bats-mock lib, PATH tricks | Shell function override | Already proven in codebase. Zero deps. |
| Output capture | Custom `2>&1` chains | bats `run` + `assert_output` | Standard, handles stdout+stderr |
| Temp directory lifecycle | Manual mkdir/rm per test | `mktemp -d` in setup + `rm -rf` in teardown | Reliable, already established pattern |
| File existence assertions | Custom test helper | `[ -f "$path" ]`, `[ -L "$path" ]` | Native bash tests, no library needed |
| Profile file parsing in tests | Custom line reader | Same while-read loop as production code | Consistency, already battle-tested |

## Common Pitfalls

### Pitfall 1: Source Guard Blocks Re-Sourcing in Tests

**What goes wrong:** `readonly _PLATFORM_SOURCED=1` prevents re-sourcing. In a test subshell where the variable was inherited, sourcing fails silently (returns 0 without executing).
**Why it happens:** `readonly` variables cannot be unset in the same process. But bats creates fresh subshells for each `@test`, where the parent's `readonly` does not apply.
**How to avoid:** Always `unset _MODULE_SOURCED` in `setup()` before `source`. This works because `setup()` runs in the same fresh subshell as the test.
**Warning signs:** Test passes but function is undefined -- the source was silently skipped.

### Pitfall 2: Mock uname Must Dispatch on Arguments

**What goes wrong:** `detect_platform()` calls `uname -s` for OS and `uname -m` for architecture. A flat mock returns the same value for both.
**Why it happens:** Developer forgets uname is called multiple times with different flags.
**How to avoid:**
```bash
uname() {
    case "$1" in
        -s) echo "Linux" ;;
        -m) echo "x86_64" ;;
        *)  echo "Linux" ;;
    esac
}
```
**Verified:** This pattern tested and confirmed working.

### Pitfall 3: command -v Override Breaks Other Code

**What goes wrong:** Overriding `command` to mock `command -v apt-get` also intercepts all other `command` calls in the sourced modules.
**Why it happens:** `command` is a shell builtin used everywhere.
**How to avoid:** Narrow the mock -- intercept only `-v` flag, pass through everything else:
```bash
command() {
    if [[ "$1" == "-v" ]]; then
        # Mock logic here
        return 1
    fi
    builtin command "$@"
}
```
**Verified:** This pattern tested and confirmed working.

### Pitfall 4: HOME Override Timing for dotfiles.sh

**What goes wrong:** dotfiles.sh sets `BACKUP_DIR="${HOME}/.dotfiles-backup"` at source time. If HOME is overridden AFTER sourcing, BACKUP_DIR still points to real HOME.
**Why it happens:** Shell variable expansion happens at assignment time, not use time.
**How to avoid:** Override HOME and set BACKUP_DIR/MANIFEST_FILE BEFORE sourcing dotfiles.sh:
```bash
setup() {
    TEST_DIR="$(mktemp -d)"
    export HOME="${TEST_DIR}/home"
    mkdir -p "$HOME"
    export BACKUP_DIR="${HOME}/.dotfiles-backup"
    export MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"
    SESSION_BACKUPS=()
    source ".../dotfiles.sh"
}
```
**Verified:** This pattern tested and confirmed working.

### Pitfall 5: setup.sh EXIT Trap Overrides Exit Code

**What goes wrong:** `setup.sh --invalid-flag` calls `exit 1` in `parse_flags()`, but the EXIT trap runs `cleanup()` which does `exit "${_worst_exit:-0}"`, resulting in exit code 0 instead of 1.
**Why it happens:** The cleanup trap always runs on `exit` and overrides the exit code with `_worst_exit` (which was never set because parse_flags runs before `main()`).
**How to avoid in tests:** For the unknown flag test, check output content rather than exit code:
```bash
@test "setup.sh with unknown flag shows error message" {
    run bash setup.sh --invalid-flag
    assert_output --partial "Unknown option"
    assert_output --partial "--invalid-flag"
}
```
**Note:** This is a real bug in setup.sh (exit code lost). The test documents the current behavior. Fixing the bug is out of scope for this phase but should be noted.

### Pitfall 6: interactive.sh TTY Detection in Bats

**What goes wrong:** `show_category_menu` and `ask_tool` check `[[ -t 0 ]]`. In bats, stdin is never a TTY, so the interactive path is unreachable.
**Why it happens:** Bats pipes stdin for test isolation.
**How to avoid:** This is a feature. Test the non-interactive paths only. Both functions have explicit `NONINTERACTIVE=true` and `! -t 0` fallbacks that return 0 (install all). No TTY simulation needed.
**Verified:** Non-interactive paths work correctly in bats.

### Pitfall 7: progress.sh show_completion_summary Dependencies

**What goes wrong:** `show_completion_summary()` calls `get_failure_count()` (from errors.sh), `show_failure_summary()` (from errors.sh), reads `$FAILURE_LOG`, and uses `$SECONDS`.
**Why it happens:** Progress module has cross-module dependencies.
**How to avoid:** Source the full dependency chain in setup:
```bash
setup() {
    unset _LOGGING_SOURCED _ERRORS_SOURCED _PROGRESS_SOURCED
    source ".../logging.sh"
    source ".../errors.sh"
    source ".../progress.sh"
    clear_failures
    SECONDS=90
    FAILURE_LOG="$(mktemp)"
    export FAILURE_LOG
}
```
**Verified:** This dependency chain sourcing works correctly.

## Code Examples

All examples below have been verified by running actual bats tests against the codebase.

### Pattern 1: Mocking uname for platform.sh

```bash
# Source: Verified on project codebase 2026-02-21
setup() {
    export NO_COLOR=1
    unset _PLATFORM_SOURCED _LOGGING_SOURCED

    uname() {
        case "$1" in
            -s) echo "Linux" ;;
            -m) echo "x86_64" ;;
            *)  echo "Linux" ;;
        esac
    }
    export -f uname

    _MOCK_COMMANDS=("apt-get")
    command() {
        if [[ "$1" == "-v" ]]; then
            local cmd="$2"
            for c in "${_MOCK_COMMANDS[@]}"; do
                [[ "$cmd" == "$c" ]] && return 0
            done
            return 1
        fi
        builtin command "$@"
    }
    export -f command

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/platform.sh"
}
```

### Pattern 2: Tmpdir Isolation for dotfiles.sh

```bash
# Source: Verified on project codebase 2026-02-21
setup() {
    export NO_COLOR=1
    unset _DOTFILES_SOURCED _LOGGING_SOURCED

    TEST_DIR="$(mktemp -d)"
    export HOME="${TEST_DIR}/home"
    mkdir -p "$HOME"
    export BACKUP_DIR="${HOME}/.dotfiles-backup"
    export MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"
    SESSION_BACKUPS=()

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/dotfiles.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}
```

### Pattern 3: Fixture Profile for count_platform_steps

```bash
# Source: Verified on project codebase 2026-02-21
@test "count_platform_steps counts linux-relevant files" {
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

### Pattern 4: Profile Validation (File Reference Check)

```bash
# Source: Verified pattern against project data structure
@test "all profile files reference existing package files" {
    local profiles_dir="${BATS_TEST_DIRNAME}/../data/packages/profiles"
    local packages_dir="${BATS_TEST_DIRNAME}/../data/packages"

    for profile in "$profiles_dir"/*.txt; do
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "$line" || "$line" == \#* ]] && continue
            [ -f "${packages_dir}/${line}" ] || \
                fail "Profile $(basename "$profile") references '${line}' but file does not exist"
        done < "$profile"
    done
}
```

### Pattern 5: Contract Parity File Format

```
# tests/contracts/api-parity.txt
# Bash/PowerShell API Parity Contract
# Format: bash_module | bash_function | ps_module | ps_function | behavior
#
# This file documents the mapping between Bash and PowerShell implementations.
# Bash has more granular functions; PS consolidates into fewer functions with parameters.
# This is by design (see docs/adr/ADR-006).
#
# Modules with PS equivalents: logging, errors, packages, idempotent, progress
# Modules without PS equivalents: platform (N/A), dotfiles (N/A), interactive (N/A)

logging.sh  | log_ok "msg"          | logging.psm1    | Write-Log -Level OK -Message "msg"       | outputs [OK] prefix
logging.sh  | log_error "msg"       | logging.psm1    | Write-Log -Level ERROR -Message "msg"    | outputs [ERROR] prefix to stderr
logging.sh  | log_warn "msg"        | logging.psm1    | Write-Log -Level WARN -Message "msg"     | outputs [WARN] prefix
logging.sh  | log_info "msg"        | logging.psm1    | Write-Log -Level INFO -Message "msg"     | outputs [INFO] prefix
logging.sh  | log_debug "msg"       | logging.psm1    | Write-Log -Level DEBUG -Message "msg"    | silent unless VERBOSE=true
logging.sh  | log_banner "n" "v"    | logging.psm1    | Write-Log -Level BANNER -Message "n"     | outputs === name === format
errors.sh   | record_failure "pkg"  | errors.psm1     | Add-FailedItem -Item "pkg"               | increments failure count
errors.sh   | show_failure_summary  | errors.psm1     | Show-FailureSummary                      | lists failed items or success msg
errors.sh   | get_failure_count     | errors.psm1     | Get-FailureCount                         | returns integer count
errors.sh   | clear_failures        | errors.psm1     | Clear-Failures                           | resets count to 0
errors.sh   | compute_exit_code     | errors.psm1     | Get-ExitCode                             | 0=success, 1=partial failure
packages.sh | load_packages "f.txt" | packages.psm1   | Read-PackageFile -FileName "f.txt"       | reads package list, skips comments
idempotent.sh | is_installed "cmd"  | idempotent.psm1 | Test-WinGetInstalled -PackageId "id"     | checks if package installed
progress.sh | show_dry_run_banner   | progress.psm1   | Show-DryRunBanner                        | banner when DRY_RUN=true
progress.sh | count_platform_steps  | progress.psm1   | Get-PlatformStepCount                    | count platform-relevant files
progress.sh | show_completion_summary | progress.psm1  | Show-CompletionSummary                   | end-of-run summary with duration
```

## Detailed Test Plan per Module

### TEST-03: test-core-platform.bats (~15-18 tests)

| # | Test | Function | Strategy |
|---|------|----------|----------|
| 1 | detect_platform sets DETECTED_OS=linux for uname=Linux | detect_platform | mock uname -s "Linux" |
| 2 | detect_platform sets DETECTED_OS=macos for uname=Darwin | detect_platform | mock uname -s "Darwin" |
| 3 | detect_platform sets DETECTED_OS=windows for uname=MINGW | detect_platform | mock uname -s "MINGW64_NT" |
| 4 | detect_platform sets DETECTED_OS=unknown for uname=FreeBSD | detect_platform | mock uname -s "FreeBSD" |
| 5 | detect_platform sets DETECTED_ARCH=x86_64 | detect_platform | mock uname -m "x86_64" |
| 6 | detect_platform sets DETECTED_ARCH=arm64 | detect_platform | mock uname -m "arm64" |
| 7 | detect_platform sets DETECTED_ARCH=aarch64 as arm64 | detect_platform | mock uname -m "aarch64" |
| 8 | detect_platform sets DETECTED_PKG=apt with apt-get | detect_platform | mock command -v apt-get |
| 9 | detect_platform sets DETECTED_PKG=brew with brew | detect_platform | mock command -v brew |
| 10 | detect_platform sets DETECTED_PKG empty with no pkg mgr | detect_platform | mock command -v returns 1 |
| 11 | detect_platform sets DETECTED_BASH from BASH_VERSINFO | detect_platform | use real BASH_VERSINFO |
| 12 | verify_bash_version passes with Bash >= 4 | verify_bash_version | real BASH_VERSINFO (5.x) |
| 13 | verify_bash_version warns on macOS with Bash < 4 | verify_bash_version | needs BASH_VERSINFO override or skip |
| 14 | verify_supported_distro passes for macOS | verify_supported_distro | set DETECTED_OS=macos |
| 15 | verify_supported_distro passes for ubuntu | verify_supported_distro | set DETECTED_DISTRO=ubuntu |
| 16 | verify_supported_distro warns for unsupported (non-tty) | verify_supported_distro | set DETECTED_DISTRO=arch |
| 17 | verify_package_manager fails when DETECTED_PKG empty | verify_package_manager | set DETECTED_PKG="" |
| 18 | verify_package_manager passes when DETECTED_PKG=apt | verify_package_manager | set DETECTED_PKG=apt |
| 19 | request_sudo skips in DRY_RUN mode | request_sudo | DRY_RUN=true |
| 20 | check_internet non-interactive continues on failure | check_internet | mock curl to fail |

**Note on verify_bash_version Bash<4 test:** BASH_VERSINFO is read-only. We cannot override it. Options: (a) skip test with note "requires Bash < 4", (b) test the function's output on current Bash 5 (passes, no warning). Recommendation: test the passing path only, document the Bash<4 path as untestable on Bash 5.

### TEST-04: test-core-progress.bats (~10-12 tests)

| # | Test | Function | Strategy |
|---|------|----------|----------|
| 1 | show_dry_run_banner outputs banner when DRY_RUN=true | show_dry_run_banner | DRY_RUN=true |
| 2 | show_dry_run_banner outputs nothing when DRY_RUN unset | show_dry_run_banner | unset DRY_RUN |
| 3 | show_dry_run_banner outputs nothing when DRY_RUN=false | show_dry_run_banner | DRY_RUN=false |
| 4 | count_platform_steps counts linux-relevant files | count_platform_steps | fixture profile |
| 5 | count_platform_steps counts macos-relevant files | count_platform_steps | fixture profile |
| 6 | count_platform_steps returns 0 for missing file | count_platform_steps | nonexistent path |
| 7 | count_platform_steps returns 0 for empty profile | count_platform_steps | empty file |
| 8 | count_platform_steps skips comments | count_platform_steps | comments-only file |
| 9 | show_completion_summary shows success with no failures | show_completion_summary | clear_failures, SECONDS=90 |
| 10 | show_completion_summary shows failure count | show_completion_summary | FAILURE_LOG with items |
| 11 | show_completion_summary shows dry-run label | show_completion_summary | DRY_RUN=true |
| 12 | show_completion_summary shows profile and platform | show_completion_summary | check output contains args |

**Dependencies:** Must source logging.sh + errors.sh + progress.sh. Must set FAILURE_LOG to temp file and clean in teardown.

### TEST-05: test-core-dotfiles.bats (~18-22 tests)

| # | Test | Function | Strategy |
|---|------|----------|----------|
| 1 | path_to_backup_name converts simple dotfile (.zshrc) | path_to_backup_name | pure function |
| 2 | path_to_backup_name converts nested path (.config/git/ignore) | path_to_backup_name | pure function |
| 3 | path_to_backup_name returns error for empty arg | path_to_backup_name | empty string |
| 4 | path_to_backup_name includes date suffix | path_to_backup_name | check .bak.YYYY-MM-DD |
| 5 | backup_with_manifest creates backup dir | backup_with_manifest | real file in tmpdir |
| 6 | backup_with_manifest writes to manifest file | backup_with_manifest | check manifest contents |
| 7 | backup_with_manifest handles name collision | backup_with_manifest | backup same file twice |
| 8 | backup_with_manifest skips in DRY_RUN mode | backup_with_manifest | DRY_RUN=true |
| 9 | backup_with_manifest fails on empty arg | backup_with_manifest | empty string |
| 10 | create_dotfile_symlink creates symlink | create_dotfile_symlink | source+target in tmpdir |
| 11 | create_dotfile_symlink backs up existing file | create_dotfile_symlink | pre-existing target |
| 12 | create_dotfile_symlink replaces existing symlink | create_dotfile_symlink | pre-existing symlink |
| 13 | create_dotfile_symlink creates parent directory | create_dotfile_symlink | nested target path |
| 14 | create_dotfile_symlink fails for missing source | create_dotfile_symlink | nonexistent source |
| 15 | create_dotfile_symlink fails for empty args | create_dotfile_symlink | empty strings |
| 16 | create_dotfile_symlink dry-run does not create symlink | create_dotfile_symlink | DRY_RUN=true |
| 17 | unlink_dotfiles removes symlink | unlink_dotfiles | pre-existing symlink |
| 18 | unlink_dotfiles restores backup from manifest | unlink_dotfiles | backup+symlink in tmpdir |
| 19 | unlink_dotfiles skips non-symlink files | unlink_dotfiles | regular file |
| 20 | unlink_dotfiles handles nonexistent target | unlink_dotfiles | missing path |
| 21 | show_backup_summary shows empty message | show_backup_summary | SESSION_BACKUPS=() |
| 22 | list_backups shows message for empty dir | list_backups | no .bak files |

### TEST-06: test-core-interactive.bats (~6-8 tests)

| # | Test | Function | Strategy |
|---|------|----------|----------|
| 1 | show_category_menu returns 0 with NONINTERACTIVE=true | show_category_menu | NONINTERACTIVE=true |
| 2 | show_category_menu returns 0 when stdin not TTY | show_category_menu | bats default (no TTY) |
| 3 | show_category_menu uses default category name | show_category_menu | no args |
| 4 | ask_tool returns 0 with NONINTERACTIVE=true | ask_tool | NONINTERACTIVE=true |
| 5 | ask_tool returns 0 when stdin not TTY | ask_tool | bats default (no TTY) |
| 6 | ask_tool uses default tool name | ask_tool | no args |
| 7 | show_category_menu output includes category name | show_category_menu | check output partial |
| 8 | ask_tool output includes tool name | ask_tool | check output partial |

**Note:** Tests 7-8 will only show output in the non-interactive path if the function echoes before the TTY check. Looking at the code: `show_category_menu` echoes AFTER the TTY check (`[[ ! -t 0 ]]` returns 0 early), so output tests may show empty output. Adjust: only test return code for non-interactive, test output only for NONINTERACTIVE=true which still returns before echoing. Focus on return codes.

### TEST-07: test-data-validation.bats (~4-6 tests)

| # | Test | Function | Strategy |
|---|------|----------|----------|
| 1 | All profiles reference existing package files | file check | iterate profiles, check each ref |
| 2 | No empty profiles (each has >= 1 package file) | line count | count non-comment lines |
| 3 | No orphaned package files | reverse check | each .txt in packages/ referenced by >= 1 profile |
| 4 | Profile files are valid text (no binary) | file check | file command or simple check |
| 5 | Expected profiles exist (minimal, developer, full) | file check | assert 3 profiles exist |
| 6 | Package files have at least one package | line count | non-empty non-comment lines |

### TEST-08: test-integration.bats (~5-8 tests)

| # | Test | Function | Strategy |
|---|------|----------|----------|
| 1 | setup.sh --help shows usage | --help flag | assert_output --partial "Usage:" |
| 2 | setup.sh --dry-run developer completes | --dry-run | assert output partial "DRY RUN" |
| 3 | setup.sh --dry-run minimal completes | --dry-run | assert output partial "DRY RUN" |
| 4 | setup.sh --dry-run full completes | --dry-run | assert output partial "DRY RUN" |
| 5 | setup.sh --dry-run shows detected platform | --dry-run | assert output partial "Detected:" |
| 6 | setup.sh unknown flag shows error message | bad flag | assert output partial "Unknown option" |
| 7 | setup.sh --verbose adds timestamps | --dry-run -v | assert output matches timestamp pattern |
| 8 | setup.sh default profile is developer | --dry-run (no profile) | assert output partial "developer" |

**CRITICAL:** Test 6 (unknown flag) cannot use `assert_failure` because of the EXIT trap bug (see Pitfall 5). Use `assert_output --partial "Unknown option"` instead. The exit code will be 0 due to the trap override.

### TEST-09: Contract Parity (api-parity.txt + validation tests)

The contract file maps 5 paired modules (logging, errors, packages, idempotent, progress). Three modules have no PS equivalent (platform, dotfiles, interactive).

Validation test in a new file `test-contracts.bats` or added to `test-data-validation.bats`:

| # | Test | Strategy |
|---|------|----------|
| 1 | All Bash exported functions from paired modules appear in api-parity.txt | grep export -f, check contract |
| 2 | All PS exported functions from paired modules appear in api-parity.txt | grep Export-ModuleMember, check contract |
| 3 | Contract file is well-formed (no empty lines in data section, pipe-separated) | format validation |

## Complete Bash/PS Export Function Inventory

### Bash Exported Functions (for contract mapping)

**logging.sh (16 functions):**
- Core: `setup_colors`, `log_ok`, `log_error`, `log_warn`, `log_info`, `log_debug`, `log_banner`
- Aliases: `log`, `log_success`, `log_warning`, `info`, `error`, `warning`, `success`
- Internal: `_strip_colors`, `_timestamp`, `_write_log`

**errors.sh (10 functions):**
- `retry_with_backoff`, `record_failure`, `show_failure_summary`, `get_failure_count`, `clear_failures`, `compute_exit_code`, `safe_curl_sh`, `create_temp_dir`, `cleanup_temp_dir`, `cleanup`, `signal_cleanup`, `setup_error_handling`

**packages.sh (7 functions):**
- `load_packages`, `load_profile`, `get_packages_for_manager`
- Internal: `_log_packages_error`, `_log_packages_warn`, `_log_packages_debug`, `_log_packages_info`

**idempotent.sh (10 functions):**
- `is_installed`, `is_apt_installed`, `is_brew_installed`, `ensure_line_in_file`, `ensure_dir`, `ensure_symlink`, `add_to_path`, `prepend_to_path`, `append_to_path`, `backup_if_exists`, `backup_and_copy`

**progress.sh (3 functions):**
- `show_dry_run_banner`, `count_platform_steps`, `show_completion_summary`

**platform.sh (7 functions) -- NO PS equivalent:**
- `detect_platform`, `verify_bash_version`, `verify_supported_distro`, `verify_package_manager`, `check_internet`, `request_sudo`, `verify_all`

**dotfiles.sh (6 functions) -- NO PS equivalent:**
- `path_to_backup_name`, `backup_with_manifest`, `create_dotfile_symlink`, `unlink_dotfiles`, `show_backup_summary`, `list_backups`

**interactive.sh (2 functions) -- NO PS equivalent:**
- `show_category_menu`, `ask_tool`

### PowerShell Exported Functions

**logging.psm1:** `Write-Log`
**errors.psm1:** `Add-FailedItem`, `Show-FailureSummary`, `Get-FailureCount`, `Clear-Failures`, `Get-ExitCode`
**packages.psm1:** `Read-PackageFile`
**idempotent.psm1:** `Test-WinGetInstalled`, `Test-NpmInstalled`, `Test-CargoInstalled`
**progress.psm1:** `Show-DryRunBanner`, `Get-PlatformStepCount`, `Show-CompletionSummary`

## Known Bugs/Limitations Discovered During Research

### Bug: setup.sh EXIT Trap Swallows Non-Zero Exit Codes

**Severity:** Low (only affects unknown flag handling)
**Location:** setup.sh lines 54-67, 98
**Description:** `parse_flags()` calls `exit 1` for unknown flags, but the EXIT trap runs `cleanup()` which does `exit "${_worst_exit:-0}"`. Since `_worst_exit` defaults to 0 and `parse_flags` runs before `main()` sets it, the process exits 0.
**Impact on tests:** `assert_failure` cannot be used for the unknown flag integration test. Use `assert_output` only.
**Recommendation:** Document in test file as known limitation. Fix is out of scope for this phase.

### Limitation: BASH_VERSINFO Is Read-Only

**Impact:** Cannot test `verify_bash_version` failure path (Bash < 4) when running on Bash 5.x.
**Workaround:** Skip the failure-path test with `skip "Requires Bash < 4"`. Test only the passing path.

### Limitation: /etc/os-release Not Available on macOS

**Impact:** Cannot test `detect_platform`'s Linux distro detection path on macOS.
**Workaround:** Skip with `skip "Linux-only: /etc/os-release detection"`. Test DETECTED_DISTRO="unknown" path (which is what happens on macOS with mocked Linux uname).

## Open Questions

1. **Should the unknown-flag bug in setup.sh be fixed in this phase?**
   - What we know: The EXIT trap overrides `exit 1` to `exit 0`.
   - Recommendation: Document as known limitation, fix in a future phase. The test should verify the error message output, not the exit code.

2. **Should contract validation tests require pwsh?**
   - What we know: Contract file is a static text file. Bash-side validation can check Bash exports against the file. PS-side validation would need pwsh.
   - Recommendation: Only validate the Bash side in bats tests. PS side is informational (manual verification or future Pester tests).

3. **npm.txt in count_platform_steps: Should it count for linux?**
   - What we know: `count_platform_steps` does NOT count npm.txt for either linux or macos -- it only counts platform-specific package managers (apt, flatpak, snap for linux; brew, brew-cask for macos) plus ai-tools.txt and cargo.txt for linux.
   - Recommendation: Test the actual behavior, not what we think it should be. The fixture tests verify actual counting logic.

## Sources

### Primary (HIGH confidence)
- Direct code inspection of all 8 Bash core modules (src/core/*.sh)
- Direct code inspection of all 5 PowerShell modules (src/platforms/windows/core/*.psm1)
- Existing test files (4 .bats files, 44 tests) -- pattern extraction
- **Empirical verification:** All recommended mock/test patterns executed as real bats tests against the codebase and confirmed passing
- bats-core 1.13.0 (installed at tests/lib/bats-core/, verified `BATS_TEST_TMPDIR` availability)

### Secondary (MEDIUM confidence)
- Prior research document: `.planning/phases/research-test-expansion/RESEARCH.md` (2026-02-19) -- validated and updated with empirical findings
- bats-core documentation (writing tests, run helper, setup/teardown lifecycle)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- zero new dependencies, everything already installed and verified
- Architecture patterns: HIGH -- all patterns empirically verified against actual codebase
- Mock strategies: HIGH -- uname mock, command mock, HOME override all tested and passing
- Pitfalls: HIGH -- discovered real EXIT trap bug through testing, all gotchas verified
- Contract parity: MEDIUM -- format is novel but straightforward; validation approach untested beyond design
- Test counts: MEDIUM -- estimates based on function analysis; actual count may vary +/- 15%

**Research date:** 2026-02-21
**Valid until:** 2026-03-21 (stable domain -- bats-core and bash testing patterns are mature)
