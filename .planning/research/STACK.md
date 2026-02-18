# Technology Stack: Quality & Parity Improvements

**Project:** OS Post-Install Scripts v3.0 Quality Milestone
**Researched:** 2026-02-18
**Confidence:** HIGH (verified with official releases, documentation, and multiple sources)
**Scope:** Additions/changes for Bash unit testing, PowerShell quality improvements, and shell script static analysis

---

## Executive Summary

The existing stack (Bash 4+, PowerShell 5.1+, zero runtime deps) is solid and unchanged. This research focuses exclusively on **dev-time quality tooling** needed to raise the project score from 7.5/10 to 9+/10 as identified by 4 specialist reviewers. Three tool categories are needed:

1. **Bash unit testing:** bats-core 1.13.0 with bats-support + bats-assert helper libraries
2. **Shell static analysis:** ShellCheck 0.11.0 + shfmt 3.12.0 with a local lint runner script
3. **PowerShell quality:** CmdletBinding pattern adoption + PSScriptAnalyzer 1.24.0 for linting

All tools are dev-time only. Zero new runtime dependencies. The existing custom test harness (`test_harness.sh`, `test-linux.sh`, `test-windows.ps1`) is retained for integration/smoke tests, while bats-core handles unit testing of individual core module functions.

---

## Recommended Stack Additions

### 1. Bash Unit Testing: bats-core

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| [bats-core](https://github.com/bats-core/bats-core) | 1.13.0 | Bash unit test framework | Industry standard, TAP-compliant, active maintenance (Nov 2024 release), tests run as Bash itself so zero abstraction penalty |
| [bats-support](https://github.com/bats-core/bats-support) | 0.3.0 | Formatting helpers for bats | Required by bats-assert, provides output formatting for test results |
| [bats-assert](https://github.com/bats-core/bats-assert) | 2.1.0 | Assertion library for bats | `assert_success`, `assert_failure`, `assert_output` -- eliminates manual `[ "$status" -eq 0 ]` boilerplate |

**Why bats-core over the existing custom test runner:**

The current `test_harness.sh` and `test-linux.sh` use custom `assert_pass`/`assert_fail` functions that only test script existence, permissions, and grep patterns. They are effectively **smoke tests** (does it exist? does the syntax parse? does it contain expected patterns?). They cannot:

- Test individual functions from source-able modules (logging.sh, errors.sh, idempotent.sh, packages.sh)
- Capture and assert on function return codes and stdout/stderr separately
- Run setup/teardown for isolated test environments
- Produce standardized TAP output for tooling integration

bats-core directly addresses these gaps. Each `@test` block runs in a subshell with `errexit`, the `run` helper captures exit code in `$status` and output in `$output`, and `load` sources library files for function-level testing.

**What to test (8 core modules):**

| Module | Testable Functions | Priority |
|--------|-------------------|----------|
| `logging.sh` | `log_ok`, `log_error`, `log_warn`, `log_info`, `log_debug`, `setup_colors` | HIGH -- every module depends on this |
| `errors.sh` | `retry_with_backoff`, `record_failure`, `show_failure_summary`, `get_failure_count`, `clear_failures` | HIGH -- critical infrastructure |
| `idempotent.sh` | `is_installed`, `ensure_line_in_file`, `ensure_dir`, `ensure_symlink`, `add_to_path`, `backup_if_exists` | HIGH -- idempotency guarantees |
| `packages.sh` | `load_packages`, `load_profile`, `get_packages_for_manager` | HIGH -- data-driven core |
| `platform.sh` | `detect_platform`, `verify_bash_version`, `check_internet` | MEDIUM -- platform-dependent, harder to mock |
| `progress.sh` | `show_dry_run_banner`, `count_platform_steps`, `show_completion_summary` | MEDIUM -- UX, less critical |
| `interactive.sh` | Menu functions | LOW -- interactive I/O hard to test |
| `dotfiles.sh` | Dotfile operations | LOW -- filesystem-heavy |

**Example test pattern for this project's modules:**

```bash
#!/usr/bin/env bats
# tests/unit/test-errors.bats

setup() {
    # Source the module under test
    # Provide logging stubs since errors.sh depends on logging.sh
    export NO_COLOR=1
    source "${BATS_TEST_DIRNAME}/../../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../../src/core/errors.sh"
    # Reset state between tests
    clear_failures
}

@test "record_failure adds item to FAILED_ITEMS" {
    record_failure "test-package"
    [ "$(get_failure_count)" -eq 1 ]
}

@test "retry_with_backoff succeeds on first try" {
    run retry_with_backoff true
    assert_success
}

@test "retry_with_backoff fails after max attempts" {
    run retry_with_backoff false
    assert_failure
}

@test "clear_failures resets count to zero" {
    record_failure "pkg-a"
    record_failure "pkg-b"
    clear_failures
    [ "$(get_failure_count)" -eq 0 ]
}
```

**Installation method: git submodule (recommended for this project)**

Git submodules are the right choice because:
- No npm/brew dependency at dev time (aligns with zero-dep philosophy)
- Pinned versions in `.gitmodules` (reproducible)
- Works on all 3 platforms (Linux, macOS, Windows via Git Bash)
- Project already uses Git

```bash
# One-time setup
git submodule add https://github.com/bats-core/bats-core.git tests/lib/bats-core
git submodule add https://github.com/bats-core/bats-support.git tests/lib/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/lib/bats-assert

# Running tests
./tests/lib/bats-core/bin/bats tests/unit/
```

**Coexistence with existing test runners:**

The existing tests are NOT replaced. Directory structure becomes:

```
tests/
  test_harness.sh          # KEEP: existing smoke tests (file existence, permissions, structure)
  test-linux.sh            # KEEP: existing platform smoke tests (syntax, patterns, anti-patterns)
  test-macos.sh            # KEEP: existing platform smoke tests
  test-windows.ps1         # KEEP: existing platform smoke tests (PowerShell)
  test-dotfiles.sh         # KEEP: existing dotfiles smoke tests
  unit/                    # NEW: bats-core unit tests
    test-logging.bats      # NEW: unit tests for logging.sh functions
    test-errors.bats       # NEW: unit tests for errors.sh functions
    test-idempotent.bats   # NEW: unit tests for idempotent.sh functions
    test-packages.bats     # NEW: unit tests for packages.sh functions
    test-platform.bats     # NEW: unit tests for platform.sh functions
    test-progress.bats     # NEW: unit tests for progress.sh functions
  lib/                     # NEW: bats-core and helpers (git submodules)
    bats-core/
    bats-support/
    bats-assert/
```

**Confidence:** HIGH -- bats-core is the de facto standard for Bash testing. Version 1.13.0 confirmed via [GitHub releases](https://github.com/bats-core/bats-core/releases). Active project (14k+ stars, regular releases through 2024). Helper libraries actively maintained (bats-assert updated Nov 2025).

---

### 2. Shell Static Analysis: ShellCheck + shfmt

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| [ShellCheck](https://github.com/koalaman/shellcheck) | 0.11.0 | Bash/sh static analysis | Industry standard. Catches 400+ shell pitfalls. v0.11.0 released Aug 2025 |
| [shfmt](https://github.com/mvdan/sh) | 3.12.0 | Shell script formatter | Consistent formatting. v3.12.0 released Jul 2024. Supports Bash dialect |

**Current state:** The existing STACK.md from Feb 2024 already recommends these tools but the project has no lint runner script and no `.shellcheckrc` configuration. The codebase uses `# shellcheck source=` directives in a few places (good) but has no systematic enforcement.

**ShellCheck configuration for this project:**

```ini
# .shellcheckrc
# Shell dialect
shell=bash

# Severity: error, warning, info, style
# Start permissive, tighten over time
severity=warning

# Disable specific checks that conflict with project conventions:
# SC2034: variable appears unused (false positive with sourced modules using export -f)
# SC1091: not following source (we use dynamic source paths)
disable=SC2034,SC1091

# Enable optional checks
enable=require-variable-braces
enable=check-unassigned-uppercase
```

**shfmt configuration for this project:**

```
# .editorconfig (shfmt reads this)
[*.sh]
indent_style = space
indent_size = 4
shell_variant = bash
binary_next_line = true
switch_case_indent = true
```

**Local lint runner script (no CI required):**

Since this project explicitly does NOT use CI/CD, a `lint.sh` runner script gives the same benefits manually:

```bash
#!/usr/bin/env bash
# tools/lint.sh -- Run all quality checks locally
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== ShellCheck ==="
find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" -name '*.sh' -type f | while read -r f; do
    shellcheck "$f" && echo "  OK: $f" || true
done

echo ""
echo "=== shfmt (diff mode) ==="
shfmt -d -i 4 -bn -ci "$PROJECT_ROOT/src/" "$PROJECT_ROOT/tests/"

echo ""
echo "=== Done ==="
```

**Installation (dev machine only):**

```bash
# macOS
brew install shellcheck shfmt

# Linux (Debian/Ubuntu)
sudo apt install shellcheck
# shfmt: download binary or use Go
go install mvdan.cc/sh/v3/cmd/shfmt@latest

# Or via snap (both platforms)
sudo snap install shellcheck shfmt
```

**Confidence:** HIGH -- ShellCheck v0.11.0 confirmed via [GitHub releases](https://github.com/koalaman/shellcheck/releases) (Aug 2025). shfmt v3.12.0 confirmed via [GitHub releases](https://github.com/mvdan/sh/releases) (Jul 2024). Both tools recommended by Microsoft Engineering Playbook, GitLab Shell Standards, and Google Shell Style Guide.

---

### 3. PowerShell Quality: CmdletBinding + PSScriptAnalyzer

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| [CmdletBinding()] | N/A (language feature) | Advanced function behavior | Adds `-Verbose`, `-ErrorAction`, `-WhatIf` for free. PowerShell 5.1+ native |
| [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) | 1.24.0 | PowerShell static analysis | Microsoft-maintained, 80+ rules. v1.24.0 released Mar 2025. Now requires PS 5.1+ minimum |

#### 3a. CmdletBinding Pattern Adoption

**Current state of PowerShell modules:**

The existing `.psm1` modules are functional but use basic function definitions without `[CmdletBinding()]`. Analysis:

| Module | Current Pattern | Issue |
|--------|----------------|-------|
| `logging.psm1` -- `Write-Log` | `param()` without CmdletBinding | No `-Verbose` flow-through, no `-ErrorAction` on caller side |
| `errors.psm1` -- `Add-FailedItem` | `param()` with `[Parameter(Mandatory)]` | Partially there, missing CmdletBinding |
| `packages.psm1` -- `Read-PackageFile` | `param()` with `[Parameter(Mandatory)]` | Partially there, missing CmdletBinding |
| `winget.ps1` -- `Install-WinGetPackage` | `param()` with `[Parameter(Mandatory)]` | Missing CmdletBinding, missing ShouldProcess for install actions |

**Recommended CmdletBinding pattern for this project:**

For **module functions** (`.psm1` files), add `[CmdletBinding()]` to every exported function. This project does NOT need `begin{}/process{}/end{}` blocks (no pipeline processing) but DOES benefit from:

1. **`[CmdletBinding()]` on all exported functions** -- enables `-Verbose`, `-Debug`, `-ErrorAction` common parameters
2. **`[CmdletBinding(SupportsShouldProcess)]` on functions that install/modify** -- enables `-WhatIf` which replaces the manual `DRY_RUN` env var check
3. **Parameter validation attributes** -- `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`
4. **Try/catch with `-ErrorAction Stop`** -- for external command error handling

**Example transformation for this project:**

BEFORE (current `winget.ps1` Install-WinGetPackage):
```powershell
function Install-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    # Manual DRY_RUN check
    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level INFO -Message "[DRY_RUN] Would winget install: $PackageId"
        return
    }
    winget install --id $PackageId --exact --silent --source winget 2>$null
    if ($LASTEXITCODE -ne 0) {
        Add-FailedItem -Item $PackageId
    }
}
```

AFTER (with CmdletBinding):
```powershell
function Install-WinGetPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId
    )

    # ShouldProcess replaces manual DRY_RUN check
    # Callers use -WhatIf flag instead of env var
    if (-not $PSCmdlet.ShouldProcess($PackageId, 'Install WinGet package')) {
        return
    }

    Write-Log -Level INFO -Message "Installing: $PackageId"

    try {
        $null = winget install --id $PackageId --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "winget install failed with exit code $LASTEXITCODE"
        }
        Write-Log -Level OK -Message "Installed: $PackageId"
    }
    catch {
        Write-Log -Level WARN -Message "Failed to install: $PackageId -- $_"
        Add-FailedItem -Item $PackageId
    }
}
```

**Important: DRY_RUN compatibility**

The existing `DRY_RUN` env var pattern is used across both Bash and PowerShell. Two options:

- **Option A (recommended):** Keep `DRY_RUN` env var as the cross-platform interface. In PowerShell, check `$env:DRY_RUN` in the entry point script (`setup.ps1`) and convert to `-WhatIf` for downstream calls. This preserves backward compatibility.
- **Option B:** Replace `DRY_RUN` with native `-WhatIf` in PowerShell. Cleaner PowerShell, but breaks cross-platform symmetry.

Recommendation: **Option A** -- add CmdletBinding/ShouldProcess to functions but keep the `DRY_RUN` bridge at the entry point.

#### 3b. PSScriptAnalyzer Integration

**Installation:**

```powershell
# Install (one-time, on dev machine)
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

**Configuration file:**

```powershell
# PSScriptAnalyzerSettings.psd1
@{
    Severity = @('Error', 'Warning')

    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSProvideCommentHelp = @{
            Enable = $true
            Placement = 'begin'
        }
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }
    }

    ExcludeRules = @(
        # Allow Write-Host for user-facing output (this is a CLI tool, not a module for piping)
        'PSAvoidUsingWriteHost'
    )
}
```

**Local lint runner for PowerShell (Windows):**

```powershell
# tools/lint.ps1
$ProjectRoot = (Resolve-Path "$PSScriptRoot/..").Path

Write-Host "=== PSScriptAnalyzer ===" -ForegroundColor Cyan

$files = Get-ChildItem -Path "$ProjectRoot/src/platforms/windows" -Recurse -Include '*.ps1','*.psm1'
$files += Get-Item "$ProjectRoot/setup.ps1"

foreach ($file in $files) {
    $results = Invoke-ScriptAnalyzer -Path $file.FullName -Settings "$ProjectRoot/PSScriptAnalyzerSettings.psd1"
    if ($results) {
        Write-Host "  ISSUES: $($file.Name)" -ForegroundColor Yellow
        $results | Format-Table -Property Line, Severity, RuleName, Message -AutoSize
    } else {
        Write-Host "  OK: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
```

**Confidence:** HIGH -- PSScriptAnalyzer v1.24.0 confirmed via [GitHub releases](https://github.com/PowerShell/PSScriptAnalyzer/releases) (Mar 2025). CmdletBinding is a core PowerShell language feature documented in [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute). Patterns verified via [PowerShell Scripting Best Practices 2025](https://dstreefkerk.github.io/2025-06-powershell-scripting-best-practices/).

---

### 4. PowerShell Testing: NOT Pester (Decision)

| Technology | Version | Decision | Why |
|------------|---------|----------|-----|
| [Pester](https://github.com/pester/Pester) | 5.7.1 | **DEFER** | Pester v3.4.0 ships with Windows but is outdated; v5.x requires install. Project has 8 PowerShell files total. Custom test runner (`test-windows.ps1`) is adequate for current scope. Cost of adoption exceeds benefit. |

**Rationale:** The PowerShell surface area is small (3 modules + 5 scripts = 8 files). The existing `test-windows.ps1` with `Assert-Pass`/`Assert-Contains`/`Assert-NotContains` covers the needed patterns. Pester would require either:
- Installing Pester 5.x (breaks zero-dep-for-testing goal on Windows)
- Using the ancient Pester 3.4.0 that ships with Windows (limited, different API)

**Revisit when:** PowerShell file count exceeds 15, or PowerShell modules need mocking support.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Bash testing | bats-core 1.13.0 | shunit2 | bats-core has 10x community adoption, better docs, TAP output. shunit2 is xUnit-style which is less natural for shell. |
| Bash testing | bats-core 1.13.0 | Custom harness (current) | Custom harness lacks function-level testing, setup/teardown, run helper, assertion library. Good for smoke tests but not unit tests. |
| Bash linting | ShellCheck 0.11.0 | bashate | ShellCheck is semantic analysis (catches real bugs). bashate is style-only. Not comparable. |
| Shell formatting | shfmt 3.12.0 | beautysh | shfmt is parser-based (correct). beautysh is regex-based (fragile). shfmt has 10x adoption. |
| PS testing | Defer Pester | Pester 5.7.1 | Small PowerShell surface area. Custom runner adequate. Revisit at 15+ files. |
| PS linting | PSScriptAnalyzer 1.24.0 | No alternative | It IS the standard. Microsoft-maintained. No competitors worth considering. |
| PS quality | CmdletBinding | Keep current | Reviewer-identified gap. CmdletBinding is free (language feature) and adds -Verbose/-WhatIf/-ErrorAction with zero cost. |

---

## Installation Summary

### Dev Machine Setup (all platforms)

```bash
# === Bash Testing (all platforms) ===
# Add bats-core + helpers as git submodules
cd /path/to/os-postinstall-scripts
git submodule add https://github.com/bats-core/bats-core.git tests/lib/bats-core
git submodule add https://github.com/bats-core/bats-support.git tests/lib/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/lib/bats-assert

# === ShellCheck + shfmt ===
# macOS
brew install shellcheck shfmt

# Linux (Debian/Ubuntu)
sudo apt install shellcheck
go install mvdan.cc/sh/v3/cmd/shfmt@latest
# OR: sudo snap install shfmt

# === Run all quality checks ===
# Bash linting
shellcheck src/**/*.sh
shfmt -d -i 4 -bn -ci src/ tests/

# Bash unit tests
./tests/lib/bats-core/bin/bats tests/unit/

# Existing smoke tests (unchanged)
bash tests/test_harness.sh
bash tests/test-linux.sh
```

```powershell
# === PowerShell (Windows only) ===
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# Run linting
Invoke-ScriptAnalyzer -Path src/platforms/windows -Recurse -Settings PSScriptAnalyzerSettings.psd1

# Existing tests (unchanged)
powershell -File tests/test-windows.ps1
```

---

## Version Matrix

### Quality Tools (Dev-Time Only)

| Tool | Version | Platform | Install Method | Status |
|------|---------|----------|---------------|--------|
| bats-core | 1.13.0 | Linux/macOS | git submodule | NEW |
| bats-support | 0.3.0 | Linux/macOS | git submodule | NEW |
| bats-assert | 2.1.0 | Linux/macOS | git submodule | NEW |
| ShellCheck | 0.11.0 | Linux/macOS | brew/apt | NEW (enforcement) |
| shfmt | 3.12.0 | Linux/macOS | brew/go | NEW (enforcement) |
| PSScriptAnalyzer | 1.24.0 | Windows | PowerShell Gallery | NEW |

### Unchanged Runtime Stack

| Technology | Version | Platform | Status |
|------------|---------|----------|--------|
| Bash | 4.0+ | Linux/macOS | UNCHANGED |
| PowerShell | 5.1+ | Windows | UNCHANGED (quality patterns improved) |
| Homebrew | Latest | macOS | UNCHANGED |
| APT | System | Linux | UNCHANGED |
| winget | 1.6+ | Windows | UNCHANGED |

---

## VS Code Extensions (Recommended)

| Extension | ID | Purpose |
|-----------|----|---------|
| ShellCheck | timonwong.shellcheck | Inline Bash linting |
| shell-format | foxundermoon.shell-format | Auto-formatting (uses shfmt) |
| Bats | jetmartin.bats | Syntax highlighting for .bats files |
| PowerShell | ms-vscode.PowerShell | PS linting via PSScriptAnalyzer built-in |

---

## Confidence Assessment

| Recommendation | Confidence | Reason |
|----------------|------------|--------|
| bats-core for Bash unit testing | HIGH | v1.13.0 verified via GitHub releases. 14k+ stars. De facto standard. |
| bats helpers via git submodule | HIGH | Recommended by bats-core docs. Zero external deps. |
| ShellCheck 0.11.0 | HIGH | v0.11.0 verified (Aug 2025). Microsoft/GitLab/Google recommend it. |
| shfmt 3.12.0 | HIGH | v3.12.0 verified (Jul 2024). Parser-based, not regex. |
| CmdletBinding adoption | HIGH | Native PowerShell feature. Zero cost. Reviewer-identified gap. |
| PSScriptAnalyzer 1.24.0 | HIGH | v1.24.0 verified (Mar 2025). Microsoft-maintained. |
| Defer Pester | MEDIUM | Justified by small PS surface area, but may miss edge cases in modules |
| Keep existing test runners | HIGH | They test different things (smoke vs unit). Complementary, not redundant. |

---

## Sources

### Official Releases (HIGH confidence)
- [bats-core v1.13.0 Release](https://github.com/bats-core/bats-core/releases) -- Nov 7, 2024
- [ShellCheck v0.11.0 Release](https://github.com/koalaman/shellcheck/releases) -- Aug 4, 2025
- [shfmt v3.12.0 Release](https://github.com/mvdan/sh/releases) -- Jul 6, 2024
- [PSScriptAnalyzer v1.24.0 Release](https://github.com/PowerShell/PSScriptAnalyzer/releases) -- Mar 18, 2025
- [Pester v5.7.1](https://www.powershellgallery.com/packages/pester/5.7.1) -- PowerShell Gallery

### Official Documentation (HIGH confidence)
- [bats-core Writing Tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- Test syntax, run helper, setup/teardown
- [bats-core Installation](https://bats-core.readthedocs.io/en/stable/installation.html) -- Installation methods
- [bats-assert](https://github.com/bats-core/bats-assert) -- Assertion library API
- [bats-support](https://github.com/bats-core/bats-support) -- Support library API
- [bats-file](https://github.com/bats-core/bats-file) -- Filesystem assertion API
- [ShellCheck Wiki Integration](https://www.shellcheck.net/wiki/Integration) -- Editor/CI integration patterns
- [PSScriptAnalyzer Overview](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview) -- Microsoft Learn
- [CmdletBinding Attribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute) -- Microsoft Learn

### Best Practices (MEDIUM confidence)
- [PowerShell Scripting Best Practices 2025](https://dstreefkerk.github.io/2025-06-powershell-scripting-best-practices/) -- CmdletBinding patterns
- [PowerShell Error Handling Guide](https://adamtheautomator.com/powershell-error-handling/) -- try/catch with -ErrorAction Stop
- [Microsoft Engineering Playbook - Bash Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/bash/) -- shellcheck/shfmt integration
- [Testing Bash Scripts with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide) -- Practical testing patterns

---

*Last updated: 2026-02-18*
*Scope: Quality milestone tooling only. See original STACK.md (2026-02-04) for full runtime stack decisions.*
