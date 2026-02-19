# Phase 14: Testing & Documentation - Research

**Researched:** 2026-02-18
**Domain:** Bash unit testing (bats-core), shell/PS linting (ShellCheck + PSScriptAnalyzer), README documentation
**Confidence:** HIGH

## Summary

Phase 14 is the final phase of the v3.0 milestone. It validates the cleaned-up codebase from Phases 11-13 with unit tests for four core Bash modules (logging.sh, errors.sh, packages.sh, idempotent.sh), creates local lint runner scripts (tools/lint.sh for ShellCheck, tools/lint.ps1 for PSScriptAnalyzer), and closes two README documentation gaps (EXTRA_PACKAGES/SKIP_PACKAGES in Customization, Windows Troubleshooting section).

All prerequisite phases (11: Flag & Boolean, 12: Structure & DRY, 13: Windows Parity) are complete. The codebase is in its final structural state -- tests will validate finished behavior, not intermediate states. The existing custom test files (test_harness.sh, test-linux.sh, test-macos.sh, test-dotfiles.sh, test-windows.ps1) are retained as smoke/integration tests; bats-core handles function-level unit testing of core modules.

**Primary recommendation:** Split into two plans: (1) TEST-01 + TEST-02 (bats unit tests + lint runners), (2) DOC-01 + DOC-02 (README documentation additions). The testing plan should execute first since lint runners may surface issues that affect documentation claims.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| [bats-core](https://github.com/bats-core/bats-core) | 1.13.0 | Bash unit test framework | Industry standard, TAP-compliant, 14k+ stars, Nov 2024 release. Tests run as Bash -- zero abstraction penalty |
| [bats-support](https://github.com/bats-core/bats-support) | 0.3.0 | Formatting helpers for bats | Required by bats-assert, provides output formatting |
| [bats-assert](https://github.com/bats-core/bats-assert) | 2.1.0 | Assertion library for bats | `assert_success`, `assert_failure`, `assert_output` -- eliminates manual boilerplate |
| [ShellCheck](https://github.com/koalaman/shellcheck) | 0.11.0 | Bash/sh static analysis | Industry standard. 400+ shell pitfalls. **Already installed on dev machine** |
| [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) | 1.24.0 | PowerShell static analysis | Microsoft-maintained, 80+ rules. The only PS linter worth using |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| [shfmt](https://github.com/mvdan/sh) | 3.12.0 | Shell formatter | Optional -- adds formatting enforcement to lint runner. **Not currently installed** |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bats-core | Custom harness (current pattern) | Current harness lacks function-level testing, setup/teardown, run helper. Good for smoke, not unit tests |
| bats-core | shunit2 | bats-core has 10x community adoption, better docs. shunit2 is xUnit-style, less natural for shell |
| git submodule install | brew install bats-core | Submodule pins version, no external dep, works on all platforms |
| ShellCheck | bashate | ShellCheck is semantic (catches bugs). bashate is style-only. Not comparable |
| PSScriptAnalyzer | Nothing | It IS the standard. Microsoft-maintained. No competitors |

**Installation:**

```bash
# bats-core + helpers (git submodule -- no brew/apt dependency)
git submodule add https://github.com/bats-core/bats-core.git tests/lib/bats-core
git submodule add https://github.com/bats-core/bats-support.git tests/lib/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/lib/bats-assert

# ShellCheck (already installed: /opt/homebrew/bin/shellcheck v0.11.0)
# On Linux: sudo apt install shellcheck

# PSScriptAnalyzer (Windows only, one-time)
# Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

## Architecture Patterns

### Recommended Test File Structure

```
tests/
  test_harness.sh          # KEEP: existing smoke tests
  test-linux.sh            # KEEP: existing platform smoke tests
  test-macos.sh            # KEEP: existing platform smoke tests
  test-dotfiles.sh         # KEEP: existing dotfiles integration tests
  test-windows.ps1         # KEEP: existing PS smoke tests
  test-core-logging.bats   # NEW: unit tests for logging.sh
  test-core-errors.bats    # NEW: unit tests for errors.sh
  test-core-idempotent.bats # NEW: unit tests for idempotent.sh
  test-core-packages.bats  # NEW: unit tests for packages.sh
  lib/                     # NEW: bats-core and helpers (git submodules)
    bats-core/
    bats-support/
    bats-assert/
tools/
  lint.sh                  # NEW: ShellCheck runner for all .sh files
  lint.ps1                 # NEW: PSScriptAnalyzer runner for all .ps1/.psm1 files
```

**Note on file naming:** The success criteria says `bats tests/test-core-*.bats` -- so test files go directly in `tests/` (not a `tests/unit/` subdirectory) and use the `test-core-*.bats` naming pattern. This differs from the `tests/unit/` structure suggested in STACK.md research. The success criteria takes precedence.

### Pattern 1: bats-core Unit Test for Sourced Modules

**What:** Source a core module in setup(), test individual functions with `run`
**When to use:** Testing pure functions from logging.sh, errors.sh, idempotent.sh, packages.sh

```bash
#!/usr/bin/env bats
# tests/test-core-errors.bats

# Load bats helpers
load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    # Prevent color output in test context
    export NO_COLOR=1
    # Source dependencies first
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/errors.sh"
    # Reset state between tests
    clear_failures
}

@test "record_failure increments failure count" {
    record_failure "test-package"
    [ "$(get_failure_count)" -eq 1 ]
}

@test "clear_failures resets count to zero" {
    record_failure "pkg-a"
    record_failure "pkg-b"
    clear_failures
    [ "$(get_failure_count)" -eq 0 ]
}

@test "retry_with_backoff succeeds on first try" {
    run retry_with_backoff true
    assert_success
}

@test "retry_with_backoff fails after max attempts" {
    run retry_with_backoff false
    assert_failure
}
```

### Pattern 2: Testing Modules with Source Guards

**What:** Handle `readonly` collision and source-guard re-entry when testing modules
**When to use:** Testing packages.sh (has DATA_DIR readonly guard), logging.sh (has _LOGGING_SOURCED guard)

```bash
# Each @test in bats runs in a SUBSHELL -- this means source guards
# using readonly variables are reset between tests automatically.
# The setup() function re-sources the module for each test.

setup() {
    # packages.sh checks -z DATA_DIR before setting readonly.
    # Pre-set DATA_DIR to point to test fixtures to avoid the real data/ path.
    export DATA_DIR="${BATS_TEST_DIRNAME}/fixtures"

    # CRITICAL: Each bats @test runs in a fresh subshell, so the
    # _PACKAGES_SOURCED readonly guard is NOT set. Source succeeds cleanly.
    source "${BATS_TEST_DIRNAME}/../src/core/packages.sh"
}
```

### Pattern 3: Lint Runner Script

**What:** Local script that runs ShellCheck on all .sh files, reports results
**When to use:** Manual quality check before commits (no CI)

```bash
#!/usr/bin/env bash
# tools/lint.sh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

echo "=== ShellCheck ==="
while IFS= read -r -d '' f; do
    if shellcheck -x "$f"; then
        echo "  OK: $f"
    else
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" "$PROJECT_ROOT/setup.sh" "$PROJECT_ROOT/config.sh" -name '*.sh' -type f -print0 2>/dev/null)

echo ""
echo "=== Results ==="
if [ $ERRORS -eq 0 ]; then
    echo "All files passed."
else
    echo "$ERRORS file(s) had issues."
    exit 1
fi
```

### Anti-Patterns to Avoid

- **Testing with real package managers:** Never call `apt install`, `brew install`, `dpkg -s` etc. in tests. Mock external commands with shell functions (`dpkg() { return 0; }`) or test only the logic path, not the command execution.
- **Relying on system state:** Tests must not depend on whether a package is actually installed. Use fixtures and mocks.
- **Changing exit codes in test wrappers:** The project has an "always exit 0" policy (ADR-001). Do not change this. bats tests exit non-zero on failure -- that is correct because bats is a dev tool, not a runtime script.
- **Putting .bats files in tests/unit/ subdirectory:** Success criteria explicitly says `bats tests/test-core-*.bats`. Files go in `tests/` root.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bash assertion library | Custom assert_eq/assert_pass | bats-assert | 50+ assertion types, standardized API, maintained |
| Test runner with setup/teardown | Custom main() + trap cleanup | bats-core | Each @test runs in isolated subshell, setup/teardown built-in |
| Shell linter | Custom regex checks | ShellCheck | Semantic analysis catches 400+ real bugs, not just style |
| PS linter | Custom Select-String checks | PSScriptAnalyzer | 80+ rules, Microsoft-maintained |

**Key insight:** The existing test-linux.sh/test-macos.sh pattern (grep for patterns, check syntax) is valuable for smoke testing but cannot test function behavior. bats-core addresses this specific gap without replacing what works.

## Common Pitfalls

### Pitfall 1: Source Guard Collisions in Tests

**What goes wrong:** Sourcing `logging.sh` sets `readonly _LOGGING_SOURCED=1`. If the test runner tries to source it again in the same process, it exits early (`return 0`) -- which means fresh state is NOT loaded.
**Why it happens:** Source guards prevent double-loading in production. In tests, you want fresh state for each test.
**How to avoid:** bats runs each `@test` in a separate subshell, so `readonly` variables are reset automatically. Use `setup()` to source modules -- this runs before each `@test` in a fresh subshell context. Do NOT source modules at file top-level in bats files.
**Warning signs:** Tests pass individually but fail when run together; variable state leaking between tests.

### Pitfall 2: DATA_DIR readonly in packages.sh Tests

**What goes wrong:** packages.sh has `if [[ -z "${DATA_DIR:-}" ]]; then DATA_DIR=...; readonly DATA_DIR; fi`. If DATA_DIR is not pre-set, it resolves relative to `src/core/../../data` which works in production but may not resolve correctly from the test directory.
**Why it happens:** The guard uses relative path resolution from `BASH_SOURCE[0]`.
**How to avoid:** Pre-set `DATA_DIR` before sourcing packages.sh in `setup()`. Point it to a test fixtures directory with mock package files.
**Warning signs:** "Package file not found" errors in tests; tests working from project root but failing from other directories.

### Pitfall 3: retry_with_backoff Has Real Sleep Calls

**What goes wrong:** `retry_with_backoff false` calls `sleep 5` and `sleep 15` between retries, making tests take 20+ seconds.
**Why it happens:** The production function has hardcoded delays (5s, 15s, 30s).
**How to avoid:** Either (a) override `sleep` as a no-op function in test setup (`sleep() { :; }`), or (b) test only the success path (which returns immediately), or (c) accept the delay for thorough testing. Option (a) is recommended.
**Warning signs:** Test suite takes >30 seconds when it should take <5 seconds.

### Pitfall 4: FAILURE_LOG File in errors.sh Tests

**What goes wrong:** `record_failure` writes to `$FAILURE_LOG` file. If FAILURE_LOG is unset, the write is silently skipped. If set to a real path, test failures leave temp files.
**Why it happens:** Cross-process failure tracking uses a shared file.
**How to avoid:** In `setup()`, either set `FAILURE_LOG` to a temp file (cleaned in `teardown()`), or leave it unset and test only the in-process `FAILED_ITEMS` array behavior.
**Warning signs:** Tests pass but create orphan temp files; test failures not detected because they only check FAILURE_LOG, not FAILED_ITEMS array.

### Pitfall 5: ShellCheck SC2034 False Positives with export -f

**What goes wrong:** ShellCheck reports "variable appears unused" for variables that are used by exported functions in other scripts.
**Why it happens:** ShellCheck analyzes one file at a time; it cannot see cross-file usage via `export -f`.
**How to avoid:** Use `.shellcheckrc` with `disable=SC2034,SC1091`. SC1091 (not following source) is another common false positive with dynamic source paths.
**Warning signs:** Lint runner reports dozens of "unused variable" warnings that are false positives; temptation to litter code with `# shellcheck disable` inline comments.

### Pitfall 6: README EXTRA_PACKAGES Documentation Gap

**What goes wrong:** EXTRA_PACKAGES and SKIP_PACKAGES are declared in config.sh as empty arrays but never actually consumed by any installer. Documenting them as "working features" would be misleading.
**Why it happens:** They were added in Phase 2 as forward-looking hooks but no installer reads them.
**How to avoid:** Verify current usage before documenting. If no installer consumes them, document them honestly as "declared in config.sh for future use" OR implement the consumption logic as part of this phase. The success criteria says "documents EXTRA_PACKAGES and SKIP_PACKAGES environment variables with examples" -- this is documentation, not implementation.
**Warning signs:** Users set EXTRA_PACKAGES expecting packages to install, nothing happens.

## Code Examples

### Example: test-core-logging.bats

```bash
#!/usr/bin/env bats
# tests/test-core-logging.bats

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Each @test runs in subshell -- source guard resets automatically
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
}

@test "log_ok outputs [OK] prefix" {
    run log_ok "test message"
    assert_success
    assert_output --partial "[OK]"
    assert_output --partial "test message"
}

@test "log_error outputs [ERROR] prefix to stderr" {
    run log_error "bad thing"
    # Note: bats `run` captures both stdout and stderr in $output
    assert_output --partial "[ERROR]"
    assert_output --partial "bad thing"
}

@test "log_warn outputs [WARN] prefix" {
    run log_warn "careful"
    assert_success
    assert_output --partial "[WARN]"
}

@test "log_info outputs [INFO] prefix" {
    run log_info "something happened"
    assert_success
    assert_output --partial "[INFO]"
}

@test "log_debug is silent when VERBOSE is not true" {
    unset VERBOSE
    run log_debug "hidden message"
    assert_success
    assert_output ""
}

@test "log_debug outputs when VERBOSE=true" {
    export VERBOSE=true
    run log_debug "visible message"
    assert_success
    assert_output --partial "[DEBUG]"
    assert_output --partial "visible message"
}

@test "log_debug is silent when VERBOSE=false" {
    export VERBOSE=false
    run log_debug "should be hidden"
    assert_success
    assert_output ""
}

@test "setup_colors respects NO_COLOR" {
    export NO_COLOR=1
    setup_colors
    [ -z "$RED" ]
    [ -z "$GREEN" ]
    [ -z "$NC" ]
}

@test "backward compat aliases work" {
    run log "via log alias"
    assert_success
    assert_output --partial "[INFO]"

    run log_success "via success alias"
    assert_success
    assert_output --partial "[OK]"
}

@test "log_banner includes name" {
    run log_banner "MyScript" "1.0"
    assert_success
    assert_output --partial "MyScript"
    assert_output --partial "v1.0"
}
```

### Example: test-core-idempotent.bats

```bash
#!/usr/bin/env bats
# tests/test-core-idempotent.bats

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    source "${BATS_TEST_DIRNAME}/../src/core/idempotent.sh"
    # Create temp directory for file operations
    TEST_TEMP="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "is_installed returns 0 for bash" {
    run is_installed bash
    assert_success
}

@test "is_installed returns 1 for nonexistent command" {
    run is_installed "definitely_not_a_real_command_xyz"
    assert_failure
}

@test "is_installed returns 1 for empty argument" {
    run is_installed ""
    assert_failure
}

@test "ensure_line_in_file adds line to new file" {
    local testfile="${TEST_TEMP}/testfile.txt"
    run ensure_line_in_file "hello world" "$testfile"
    assert_success
    run grep -c "hello world" "$testfile"
    assert_output "1"
}

@test "ensure_line_in_file is idempotent" {
    local testfile="${TEST_TEMP}/testfile.txt"
    ensure_line_in_file "hello" "$testfile"
    ensure_line_in_file "hello" "$testfile"
    run grep -c "hello" "$testfile"
    assert_output "1"
}

@test "ensure_dir creates directory" {
    local testdir="${TEST_TEMP}/newdir/subdir"
    run ensure_dir "$testdir"
    assert_success
    [ -d "$testdir" ]
}

@test "ensure_symlink creates symlink" {
    local source="${TEST_TEMP}/source.txt"
    local target="${TEST_TEMP}/link.txt"
    echo "content" > "$source"
    run ensure_symlink "$source" "$target"
    assert_success
    [ -L "$target" ]
}

@test "add_to_path adds new path" {
    local orig_path="$PATH"
    add_to_path "/test/new/path"
    [[ ":$PATH:" == *":/test/new/path:"* ]]
    export PATH="$orig_path"
}

@test "add_to_path is idempotent" {
    local orig_path="$PATH"
    add_to_path "/test/unique/path"
    local after_first="$PATH"
    add_to_path "/test/unique/path"
    [ "$PATH" = "$after_first" ]
    export PATH="$orig_path"
}

@test "backup_if_exists creates backup of existing file" {
    local testfile="${TEST_TEMP}/config.txt"
    echo "original" > "$testfile"
    run backup_if_exists "$testfile"
    assert_success
    # Backup file should exist with .bak.DATE suffix
    local backup_count
    backup_count=$(ls "${TEST_TEMP}"/config.txt.bak.* 2>/dev/null | wc -l | tr -d ' ')
    [ "$backup_count" -ge 1 ]
}

@test "backup_if_exists returns 0 for nonexistent file" {
    run backup_if_exists "${TEST_TEMP}/does_not_exist.txt"
    assert_success
}
```

### Example: test-core-packages.bats

```bash
#!/usr/bin/env bats
# tests/test-core-packages.bats

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Pre-set DATA_DIR to test fixtures BEFORE sourcing packages.sh
    export DATA_DIR="${BATS_TEST_DIRNAME}/fixtures"
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/packages.sh"
}

@test "load_packages fails with no argument" {
    run load_packages
    assert_failure
}

@test "load_packages fails with nonexistent file" {
    run load_packages "nonexistent-file.txt"
    assert_failure
}

@test "load_packages reads packages from fixture file" {
    # Requires: tests/fixtures/packages/test-apt.txt with known content
    load_packages "test-apt.txt"
    [ "${#PACKAGES[@]}" -gt 0 ]
}

@test "load_packages skips comments and blank lines" {
    # Requires: tests/fixtures/packages/with-comments.txt
    load_packages "with-comments.txt"
    for pkg in "${PACKAGES[@]}"; do
        [[ "$pkg" != \#* ]]
        [[ -n "$pkg" ]]
    done
}
```

### Example: tools/lint.sh

```bash
#!/usr/bin/env bash
# tools/lint.sh -- Run ShellCheck on all .sh files
# Usage: bash tools/lint.sh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

echo "=== ShellCheck ==="
while IFS= read -r -d '' f; do
    if shellcheck -x "$f" 2>&1; then
        echo "  OK: $(basename "$f")"
    else
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" \
    -name '*.sh' -type f -print0 2>/dev/null)

# Also check root-level shell scripts
for rootfile in "$PROJECT_ROOT/setup.sh" "$PROJECT_ROOT/config.sh"; do
    if [ -f "$rootfile" ]; then
        if shellcheck -x "$rootfile" 2>&1; then
            echo "  OK: $(basename "$rootfile")"
        else
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

echo ""
echo "=== Results ==="
if [ $ERRORS -eq 0 ]; then
    echo "All files passed ShellCheck."
    exit 0
else
    echo "$ERRORS file(s) had issues."
    exit 1
fi
```

### Example: tools/lint.ps1

```powershell
#Requires -Version 5.1
# tools/lint.ps1 -- Run PSScriptAnalyzer on all PowerShell files
# Usage: powershell -File tools/lint.ps1
$ProjectRoot = (Resolve-Path "$PSScriptRoot/..").Path
$Errors = 0

Write-Host "=== PSScriptAnalyzer ===" -ForegroundColor Cyan

$files = @()
$files += Get-ChildItem -Path "$ProjectRoot/src/platforms/windows" -Recurse -Include '*.ps1','*.psm1'
$files += Get-Item "$ProjectRoot/setup.ps1"
$files += Get-ChildItem -Path "$ProjectRoot/tests" -Filter '*.ps1'

foreach ($file in $files) {
    $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Warning,Error
    if ($results) {
        Write-Host "  ISSUES: $($file.Name)" -ForegroundColor Yellow
        $results | Format-Table -Property Line, Severity, RuleName, Message -AutoSize
        $Errors++
    } else {
        Write-Host "  OK: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
if ($Errors -eq 0) {
    Write-Host "All files passed PSScriptAnalyzer." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$Errors file(s) had issues." -ForegroundColor Yellow
    exit 1
}
```

## Codebase Findings: Current State

### Modules to Test (4 core modules -- TEST-01 scope)

| Module | File | Functions | Test Complexity | Notes |
|--------|------|-----------|-----------------|-------|
| logging.sh | `src/core/logging.sh` | 12 (log_ok, log_error, log_warn, log_info, log_debug, log_banner + 6 aliases) | LOW | Pure output functions. Test prefix strings and VERBOSE gating. NO_COLOR=1 disables ANSI in tests |
| errors.sh | `src/core/errors.sh` | 8 (retry_with_backoff, record_failure, show_failure_summary, get_failure_count, clear_failures, create_temp_dir, cleanup_temp_dir, setup_error_handling) | MEDIUM | retry_with_backoff has sleep calls (mock sleep). FAILURE_LOG file I/O needs temp dir |
| idempotent.sh | `src/core/idempotent.sh` | 10 (is_installed, is_apt_installed, is_brew_installed, ensure_line_in_file, ensure_dir, ensure_symlink, add_to_path, prepend_to_path, append_to_path, backup_if_exists + backup_and_copy) | LOW | Mostly filesystem ops. Use TEST_TEMP dir. Mock dpkg/brew for is_apt_installed/is_brew_installed |
| packages.sh | `src/core/packages.sh` | 3 (load_packages, load_profile, get_packages_for_manager) | MEDIUM | Requires pre-set DATA_DIR + fixture files. Test comment/blank skipping, error paths |

### Files to Lint (TEST-02 scope)

**Shell (.sh files -- 37 total):**
- `setup.sh`, `config.sh` (root)
- `src/core/*.sh` (8 files)
- `src/platforms/linux/main.sh`, `src/platforms/linux/install/*.sh` (5 files)
- `src/platforms/macos/main.sh`, `src/platforms/macos/install/*.sh` (4 files)
- `src/install/*.sh` (7 files)
- `data/dotfiles/**/*.sh` (5 files)
- `tests/*.sh` (4 files)
- `examples/**/*.sh` (3 files)

**PowerShell (.ps1/.psm1 -- 14 total):**
- `setup.ps1` (root)
- `src/platforms/windows/main.ps1` (1 file)
- `src/platforms/windows/install/*.ps1` (4 files)
- `src/platforms/windows/core/*.psm1` (5 files)
- `tests/test-windows.ps1` (1 file)
- `examples/terminal-setup.ps1` (1 file)

### README Gaps (DOC-01, DOC-02)

**DOC-01 -- EXTRA_PACKAGES / SKIP_PACKAGES:**
- Currently declared in `config.sh` lines 38-41 as empty arrays
- `docs/installation-profiles.md` lines 87-88 mention them in one line each
- README Customization section (lines 419-458) does NOT mention them
- **Important finding:** No installer currently reads EXTRA_PACKAGES or SKIP_PACKAGES. They are declared but never consumed. Documentation should be honest about this -- either "declared for future use" or the phase implements consumption logic. Success criteria says "documents ... environment variables with examples" -- documenting what they are and how to set them is the minimum

**DOC-02 -- Windows Troubleshooting:**
- README Troubleshooting section (lines 517-583) has one Windows item: "WinGet not recognized" (lines 575-582)
- Missing: execution policy (`-ExecutionPolicy Bypass`), PATH issues after WinGet installs, PowerShell version requirements
- setup.ps1 line 4 shows the execution policy bypass pattern: `powershell -ExecutionPolicy Bypass -File .\setup.ps1`
- setup.ps1 line 1 shows `#Requires -Version 5.1`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom test harness only | bats-core + custom harness coexistence | This phase | Function-level testing for core modules |
| Manual shellcheck invocation | tools/lint.sh runner script | This phase | Consistent, repeatable lint checks |
| No PS linting | tools/lint.ps1 with PSScriptAnalyzer | This phase | Catches PS antipatterns |
| EXTRA_PACKAGES undocumented in README | Documented in Customization section | This phase | Users can discover the feature |
| One Windows troubleshooting item | Three Windows troubleshooting items | This phase | Covers execution policy, WinGet, PATH |

## Open Questions

1. **EXTRA_PACKAGES/SKIP_PACKAGES: document-only or implement?**
   - What we know: config.sh declares them, no installer consumes them
   - What's unclear: Does the owner want Phase 14 to implement consumption logic or just document the declaration?
   - Recommendation: Document as declared with a note about current status. Implementation is a feature addition, not documentation. If the owner wants consumption logic, it should be a separate task within the plan.

2. **shfmt inclusion in tools/lint.sh**
   - What we know: shfmt is NOT installed on the dev machine. ShellCheck IS installed (v0.11.0)
   - What's unclear: Should tools/lint.sh include shfmt if it is not installed?
   - Recommendation: Make shfmt optional in lint.sh -- check `command -v shfmt` before running. ShellCheck is the mandatory part of TEST-02.

3. **.shellcheckrc creation**
   - What we know: No `.shellcheckrc` exists in the project. ShellCheck runs with defaults.
   - What's unclear: Should Phase 14 create a `.shellcheckrc` to suppress known false positives (SC2034, SC1091)?
   - Recommendation: Yes -- create `.shellcheckrc` so `tools/lint.sh` produces clean output. Without it, lint runner will report false positives for every exported variable and dynamic source path.

4. **PSScriptAnalyzerSettings.psd1 creation**
   - What we know: No settings file exists. The project uses Write-Host extensively (PSScriptAnalyzer warns about this by default).
   - What's unclear: Should a settings file be created to exclude PSAvoidUsingWriteHost?
   - Recommendation: Yes -- create `PSScriptAnalyzerSettings.psd1` in project root. Without it, PSScriptAnalyzer will flag every Write-Host as a warning, which is correct for modules but wrong for CLI tools.

5. **Test fixtures for packages.sh**
   - What we know: packages.sh tests need a DATA_DIR with mock package files
   - What's unclear: Should tests use real data/packages/ files or synthetic fixtures?
   - Recommendation: Create `tests/fixtures/packages/` with small synthetic test files. This isolates tests from real package list changes and keeps tests fast. Minimum: `test-apt.txt` (3-4 packages), `with-comments.txt` (mix of packages, comments, blank lines), `profiles/test-profile.txt` (lists test-apt.txt).

## Sources

### Primary (HIGH confidence)

- [bats-core v1.13.0 Release](https://github.com/bats-core/bats-core/releases) -- Nov 2024
- [bats-core documentation](https://bats-core.readthedocs.io/) -- setup/teardown, run helper, load directive
- [ShellCheck v0.11.0](https://github.com/koalaman/shellcheck/releases) -- Aug 2025. **Verified installed locally: `/opt/homebrew/bin/shellcheck` v0.11.0**
- [PSScriptAnalyzer v1.24.0](https://github.com/PowerShell/PSScriptAnalyzer/releases) -- Mar 2025
- Direct code inspection: all 4 core modules (logging.sh, errors.sh, idempotent.sh, packages.sh), config.sh, README.md, setup.ps1
- Project STACK.md research (2026-02-18) -- bats patterns, lint runner patterns, PSScriptAnalyzer settings
- Project REQUIREMENTS.md -- TEST-01, TEST-02, DOC-01, DOC-02 definitions
- Project ROADMAP.md -- Phase 14 success criteria

### Secondary (MEDIUM confidence)

- [bats-assert v2.1.0](https://github.com/bats-core/bats-assert) -- assertion patterns
- [bats-support v0.3.0](https://github.com/bats-core/bats-support) -- formatting helpers
- [shfmt v3.12.0](https://github.com/mvdan/sh/releases) -- Jul 2024 (not installed, optional)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tool versions verified via official releases and local installation check
- Architecture: HIGH -- file structure derived from success criteria; test patterns from bats-core docs and STACK.md research
- Pitfalls: HIGH -- all pitfalls confirmed by reading actual source code (source guards, DATA_DIR readonly, retry_with_backoff delays)
- Documentation gaps: HIGH -- exact README line numbers identified; EXTRA_PACKAGES non-consumption confirmed by grep

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (stable domain, tools rarely change)
