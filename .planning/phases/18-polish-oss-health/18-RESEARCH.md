# Phase 18: Polish & OSS Health - Research

**Researched:** 2026-02-21
**Domain:** Pester testing (PowerShell), OSS health artifacts (SECURITY.md, GitHub Releases), terminal demo GIF (asciinema + agg)
**Confidence:** HIGH

## Summary

Phase 18 covers four distinct deliverables: (1) Pester unit tests for four PowerShell modules, (2) a SECURITY.md responsible disclosure policy, (3) a formatted GitHub Release for v4.0.0, and (4) a demo GIF for the README. Each deliverable is well-understood with mature tooling.

The Pester testing work is the most substantial deliverable. The four target modules (logging.psm1, errors.psm1, packages.psm1, progress.psm1) export a total of 11 functions with clear, testable behavior. The existing Bash bats-core tests for the equivalent shell modules provide a direct blueprint for what to test -- the Pester tests should mirror the same behavioral contracts documented in `tests/contracts/api-parity.txt`. The remaining three deliverables (SECURITY.md, GitHub Release, demo GIF) are standard OSS health artifacts with well-documented patterns.

**Primary recommendation:** Use Pester v5.6.1 with `Import-Module -Force` in `BeforeAll`, test exported functions directly (no InModuleScope needed since all target functions are exported), and mock `Write-Host`/`Write-Log` where needed to capture output. Mirror the existing bats test structure for consistency.

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Pester | 5.6.1 | PowerShell unit testing framework | Only real option for PS testing; ubiquitous in PS ecosystem |
| asciinema | 2.4+ | Terminal session recording | Standard tool for terminal recordings; asciicast v2 format |
| agg | 1.5+ | Convert asciicast to animated GIF | Official asciinema GIF generator; successor to deprecated asciicast2gif |
| gh (GitHub CLI) | 2.x | Create GitHub Releases | Standard CLI for GitHub operations; already used in project |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| PSScriptAnalyzer | latest | PS linting (already configured in project) | Validate test files follow project conventions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| agg | asciicast2gif | Archived/deprecated; agg produces higher quality output with gifski |
| agg | svg-term-cli | SVG output instead of GIF; GitHub README supports both but GIF more universal |
| Manual release notes | `--generate-notes` flag | Auto-generated notes are noisy; curated changelog is better for a milestone release |

### Installation

```powershell
# Pester (PowerShell Gallery)
Install-Module -Name Pester -Force -Scope CurrentUser
```

```bash
# asciinema + agg (macOS via Homebrew)
brew install asciinema agg

# agg via Cargo (cross-platform alternative)
cargo install --git https://github.com/asciinema/agg
```

## Architecture Patterns

### Recommended Test Structure
```
tests/
├── pester/                          # NEW: Pester test directory
│   ├── logging.Tests.ps1            # Tests for logging.psm1 (5-6 tests)
│   ├── errors.Tests.ps1             # Tests for errors.psm1 (5-6 tests)
│   ├── packages.Tests.ps1           # Tests for packages.psm1 (3-4 tests)
│   └── progress.Tests.ps1           # Tests for progress.psm1 (4-5 tests)
├── fixtures/
│   └── packages/                    # Existing fixtures, reusable for PS tests
│       ├── test-apt.txt
│       └── with-comments.txt
├── test-core-logging.bats           # Existing Bash equivalent
├── test-core-errors.bats            # Existing Bash equivalent
├── test-core-packages.bats          # Existing Bash equivalent
└── test-core-progress.bats          # Existing Bash equivalent
```

### Pattern 1: Module Import in BeforeAll
**What:** Load the module under test once per Describe block using BeforeAll with -Force
**When to use:** Every Pester test file for this project
**Example:**
```powershell
# Source: https://pester.dev/docs/quick-start
BeforeAll {
    # -Force ensures latest version is loaded, not cached from previous test run
    Import-Module "$PSScriptRoot/../../src/platforms/windows/core/logging.psm1" -Force
}

Describe 'Write-Log' {
    It 'Outputs [OK] prefix for OK level' {
        # Mock Write-Host to capture output
        Mock Write-Host {}
        Write-Log -Level OK -Message 'test message'
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -match '\[OK\]' -or $args[0] -match '\[OK\]'
        }
    }
}
```

### Pattern 2: Environment Variable Isolation
**What:** Set and clean environment variables per test to avoid cross-contamination
**When to use:** Tests that depend on `$env:VERBOSE`, `$env:NO_COLOR`, `$env:DRY_RUN`, `$env:FAILURE_LOG`
**Example:**
```powershell
# Source: Project convention matching Bash bats pattern
Describe 'Write-Log' {
    BeforeEach {
        $env:NO_COLOR = '1'
        $env:VERBOSE = $null
    }
    AfterEach {
        $env:NO_COLOR = $null
        $env:VERBOSE = $null
    }

    It 'Shows DEBUG when VERBOSE=true' {
        $env:VERBOSE = 'true'
        Mock Write-Host {}
        Write-Log -Level DEBUG -Message 'visible'
        Should -Invoke Write-Host -Times 1
    }

    It 'Suppresses DEBUG when VERBOSE is not true' {
        $env:VERBOSE = $null
        Mock Write-Host {}
        Write-Log -Level DEBUG -Message 'hidden'
        Should -Invoke Write-Host -Times 0
    }
}
```

### Pattern 3: Module State Reset for errors.psm1
**What:** The errors module uses `$script:FailedItems` array that persists across tests if the module stays loaded. Must reset between tests.
**When to use:** errors.Tests.ps1
**Example:**
```powershell
BeforeAll {
    Import-Module "$PSScriptRoot/../../src/platforms/windows/core/errors.psm1" -Force
}

Describe 'Add-FailedItem' {
    BeforeEach {
        # Reset failure tracking before each test
        Clear-Failures
        Mock Write-Host {}
    }

    It 'Increments failure count' {
        Add-FailedItem -Item 'test-pkg'
        Get-FailureCount | Should -Be 1
    }
}
```

### Pattern 4: Temp File Fixtures for packages.psm1
**What:** Create temp package files for Read-PackageFile tests since packages.psm1 resolves paths relative to its own DataDir
**When to use:** packages.Tests.ps1 -- pass absolute paths to bypass relative resolution
**Example:**
```powershell
BeforeAll {
    Import-Module "$PSScriptRoot/../../src/platforms/windows/core/packages.psm1" -Force
}

Describe 'Read-PackageFile' {
    It 'Reads packages from a file with absolute path' {
        $tmpFile = Join-Path $TestDrive 'test-packages.txt'
        @('pkg-a', '# comment', '', 'pkg-b', '  pkg-c  ') | Set-Content $tmpFile
        $result = Read-PackageFile -FileName $tmpFile
        $result.Count | Should -Be 3
        $result | Should -Contain 'pkg-a'
        $result | Should -Contain 'pkg-b'
        $result | Should -Contain 'pkg-c'
    }
}
```

### Anti-Patterns to Avoid
- **InModuleScope overuse:** All four modules only export public functions. Use direct calls, not InModuleScope. InModuleScope is only needed for testing private/unexported functions.
- **Not using -Force on Import-Module:** Without -Force, PowerShell caches modules and tests may run against stale code.
- **Testing Write-Host output with `6>&1`:** This is fragile. Mock Write-Host and use Should -Invoke instead.
- **Shared state leakage:** errors.psm1 uses `$script:FailedItems` -- always call `Clear-Failures` in BeforeEach.
- **Hardcoded paths in packages tests:** Use `$TestDrive` (Pester's built-in temp directory) and absolute paths.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PS output capture | Custom output redirect tricks | `Mock Write-Host {}` + `Should -Invoke` | Write-Host cannot be captured with stdout redirect; mocking is the Pester standard |
| Test temp dirs | Manual `New-Item -Type Directory` | Pester's `$TestDrive` | Auto-cleaned, unique per test run, guaranteed isolation |
| SECURITY.md content | Write from scratch | Adapt established template (see Code Examples section) | Standard sections expected by GitHub Security tab integration |
| Release notes formatting | Manual CHANGELOG parsing | `gh release create v4.0.0 --notes-from-tag` + curated notes file | Tag is annotated with milestone info; supplement with curated changelog |
| Demo GIF | Screen recording + conversion | `asciinema rec` + `agg` pipeline | Purpose-built for terminal GIFs; produces optimized output |

**Key insight:** Each deliverable has a standard tool/template. The value is in correct configuration and project-specific adaptation, not in building from scratch.

## Common Pitfalls

### Pitfall 1: Write-Host Cannot Be Captured Like Regular Output
**What goes wrong:** Tests try to capture Write-Host output using `$result = Write-Log ...` and get nothing.
**Why it happens:** Write-Host writes directly to the host UI, not stdout. It bypasses PowerShell's output stream.
**How to avoid:** Mock Write-Host and assert invocation with `Should -Invoke`. This is the Pester standard for testing UI output.
**Warning signs:** Tests that use `4>&1`, `6>&1` redirects for Write-Host output.

### Pitfall 2: Module State Persistence Between Tests
**What goes wrong:** errors.psm1 tests pass individually but fail when run together because `$script:FailedItems` accumulates.
**Why it happens:** Import-Module with -Force reloads the module, but if tests share a session, script-scope variables persist between Describe blocks unless explicitly reset.
**How to avoid:** Call `Clear-Failures` in `BeforeEach` for every errors.psm1 test. Also use `Import-Module -Force` in `BeforeAll`.
**Warning signs:** Tests that pass alone but fail in batch; failure counts are unexpectedly high.

### Pitfall 3: Relative Path Resolution in packages.psm1
**What goes wrong:** packages.psm1 resolves `$script:ProjectRoot` from `$PSScriptRoot` at import time. When imported from the test directory, the relative path `../../../..` resolves incorrectly.
**Why it happens:** `$PSScriptRoot` is the directory of the module file, not the test file. The relative path resolution in the module's `$script:ProjectRoot = (Resolve-Path "$PSScriptRoot/../../../..").Path` works correctly when the module is in its real location.
**How to avoid:** For tests, always pass absolute paths to `Read-PackageFile`. Use `$TestDrive` for temp fixture files. The module handles absolute paths correctly (line 39-40 of packages.psm1).
**Warning signs:** "Package file not found" warnings in test output despite correct test setup.

### Pitfall 4: Cross-Module Dependencies (errors.psm1 -> logging.psm1)
**What goes wrong:** Importing errors.psm1 fails because it does `Import-Module "$PSScriptRoot/logging.psm1" -Force` internally.
**Why it happens:** errors.psm1 and progress.psm1 both import logging.psm1 using `$PSScriptRoot` relative paths. This works correctly as long as the modules are in their actual directory (which they are).
**How to avoid:** Import the module under test directly; its internal Import-Module calls will resolve correctly via `$PSScriptRoot`. No need to pre-import dependencies in the test file.
**Warning signs:** "Module not found" errors when importing errors.psm1 or progress.psm1 from tests.

### Pitfall 5: asciinema Recording Environment
**What goes wrong:** Demo GIF shows personal prompt, wrong colors, or unintended environment details.
**Why it happens:** asciinema records the real shell environment including custom prompts, environment variables, and history.
**How to avoid:** Record with a clean environment: `env -i HOME=$HOME TERM=xterm-256color asciinema rec` or use `--env` flag to control exported variables.
**Warning signs:** GIF shows username, hostname, or personal configuration details.

### Pitfall 6: GitHub Release for Existing Tag
**What goes wrong:** `gh release create v4.0.0` fails because the tag already exists but no release is created.
**Why it happens:** The tag v4.0.0 already exists as an annotated tag. `gh release create` can create a release from an existing tag.
**How to avoid:** Use `gh release create v4.0.0 --notes-file <file>` which attaches a release to the existing tag.
**Warning signs:** None if using the correct command; verify with `gh release view v4.0.0` after creation.

## Code Examples

### Verified: Complete logging.Tests.ps1 Pattern
```powershell
# Source: Pester v5 docs + project Bash equivalent (tests/test-core-logging.bats)
BeforeAll {
    Import-Module "$PSScriptRoot/../../src/platforms/windows/core/logging.psm1" -Force
}

Describe 'Write-Log' {
    BeforeEach {
        $env:NO_COLOR = '1'
        $env:VERBOSE = $null
        Mock Write-Host {}
    }
    AfterEach {
        $env:NO_COLOR = $null
        $env:VERBOSE = $null
    }

    It 'Outputs [OK] tag for OK level' {
        Write-Log -Level OK -Message 'test message'
        Should -Invoke Write-Host -ParameterFilter { "$args" -match '\[OK\]' }
    }

    It 'Outputs [ERROR] tag for ERROR level' {
        Write-Log -Level ERROR -Message 'bad thing'
        Should -Invoke Write-Host -ParameterFilter { "$args" -match '\[ERROR\]' }
    }

    It 'Outputs [WARN] tag for WARN level' {
        Write-Log -Level WARN -Message 'careful'
        Should -Invoke Write-Host -ParameterFilter { "$args" -match '\[WARN\]' }
    }

    It 'Outputs [INFO] tag for INFO level' {
        Write-Log -Level INFO -Message 'something'
        Should -Invoke Write-Host -ParameterFilter { "$args" -match '\[INFO\]' }
    }

    It 'Suppresses DEBUG when VERBOSE is not true' {
        $env:VERBOSE = $null
        Write-Log -Level DEBUG -Message 'hidden'
        Should -Invoke Write-Host -Times 0
    }

    It 'Shows DEBUG when VERBOSE=true' {
        $env:VERBOSE = 'true'
        Write-Log -Level DEBUG -Message 'visible'
        Should -Invoke Write-Host -Times 1 -Scope It
    }
}
```

### Verified: errors.psm1 State Management Pattern
```powershell
# Source: Pester v5 module testing docs + project Bash equivalent (tests/test-core-errors.bats)
BeforeAll {
    Import-Module "$PSScriptRoot/../../src/platforms/windows/core/errors.psm1" -Force
}

Describe 'Failure Tracking' {
    BeforeEach {
        Clear-Failures
        Mock Write-Host {}
        # Unset FAILURE_LOG to avoid cross-process file writes during tests
        $env:FAILURE_LOG = $null
    }

    It 'Add-FailedItem increments failure count' {
        Add-FailedItem -Item 'test-pkg'
        Get-FailureCount | Should -Be 1
    }

    It 'Multiple failures increment correctly' {
        Add-FailedItem -Item 'pkg-1'
        Add-FailedItem -Item 'pkg-2'
        Add-FailedItem -Item 'pkg-3'
        Get-FailureCount | Should -Be 3
    }

    It 'Clear-Failures resets count to zero' {
        Add-FailedItem -Item 'pkg-a'
        Add-FailedItem -Item 'pkg-b'
        Clear-Failures
        Get-FailureCount | Should -Be 0
    }

    It 'Get-ExitCode returns 0 when no failures' {
        Get-ExitCode | Should -Be 0
    }

    It 'Get-ExitCode returns 1 when failures exist' {
        Add-FailedItem -Item 'failed-pkg'
        Get-ExitCode | Should -Be 1
    }
}
```

### Verified: SECURITY.md Template
```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 4.x     | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in this
project, please report it responsibly.

### How to Report

1. **Do NOT open a public issue** for security vulnerabilities
2. Email: [owner email or use GitHub Security Advisories]
3. Or use GitHub's [private vulnerability reporting](https://github.com/BragatteMAS/os-postinstall-scripts/security/advisories/new)

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment:** Within 3 business days
- **Assessment:** Within 7 business days
- **Resolution:** Dependent on severity; critical issues prioritized

### Scope

This policy covers the `os-postinstall-scripts` repository including:
- Shell scripts (Bash, PowerShell)
- Package installation logic
- Dotfiles management
- Configuration files

### Out of Scope

- Third-party packages installed by the scripts (report to package maintainers)
- Issues in upstream tools (apt, brew, winget, etc.)

## Disclosure Policy

- We follow coordinated disclosure
- We will credit reporters in the release notes (unless anonymity is requested)
- Public disclosure after a fix is available and users have had time to update
```

### Verified: GitHub Release Creation Command
```bash
# Source: https://cli.github.com/manual/gh_release_create
# v4.0.0 tag already exists as annotated tag with milestone message

# Option A: Use notes from the annotated tag
gh release create v4.0.0 --notes-from-tag --title "v4.0.0 - Quality & Parity Milestone"

# Option B: Use curated notes from file (recommended for milestone release)
gh release create v4.0.0 \
  --title "v4.0.0 - Quality & Parity Milestone" \
  --notes-file release-notes-v4.0.0.md

# Option C: Inline notes with HEREDOC
gh release create v4.0.0 --title "v4.0.0" --notes "$(cat <<'EOF'
## Highlights

- 16 requirements completed across 4 phases
- 120+ bats-core tests passing
- Full Bash/PowerShell API parity
- Cross-platform: Linux, macOS, Windows

## What's New

See [CHANGELOG.md](CHANGELOG.md) for complete details.
EOF
)"
```

### Verified: asciinema + agg Demo GIF Pipeline
```bash
# Source: https://docs.asciinema.org/manual/agg/usage/

# Step 1: Record terminal session
asciinema rec demo.cast

# Step 2: Convert to GIF with optimized settings
agg --theme monokai --font-size 16 --speed 2 demo.cast assets/demo.gif

# Step 3: Reference in README
# Already has placeholder: <!-- Terminal demo GIF: record with asciinema + agg, save as assets/demo.gif -->
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pester v4 `Assert-*` syntax | Pester v5 `Should -Be` pipeline syntax | Pester 5.0 (2020) | All examples must use v5 syntax |
| asciicast2gif (Node.js) | agg (Rust, gifski) | 2022 | Higher quality GIFs, better performance |
| Pester v4 `Mock` anywhere | Pester v5 scope-based mocks | Pester 5.0 (2020) | Mocks must be in the correct Describe/Context/It block |
| Manual GitHub releases | `gh release create` | gh CLI v2+ | Scriptable, reproducible release creation |

**Deprecated/outdated:**
- asciicast2gif: Archived, replaced by agg
- Pester v4 syntax (`Assert-MockCalled`): Replaced by `Should -Invoke` in v5
- `$args` in Mock ParameterFilter without `param()`: Still works in v5, but auto-available params are preferred

## Open Questions

1. **Write-Host Mock Assertion Strategy**
   - What we know: Write-Log calls Write-Host with various parameters (-ForegroundColor, -NoNewline, positional). Mocking and asserting on specific parameters requires careful ParameterFilter usage.
   - What's unclear: The exact parameter binding when Write-Host is called with `-ForegroundColor $color -NoNewline` then a separate `Write-Host " ${prefix}${Message}"` (two calls per log line in color mode).
   - Recommendation: Use `$env:NO_COLOR = '1'` in tests to force single Write-Host call per log line, making assertions simpler. This matches the Bash test pattern (`export NO_COLOR=1` in setup).

2. **Demo GIF Content**
   - What we know: The README placeholder says "Terminal demo recording coming soon." The goal is a GIF showing the tool in action.
   - What's unclear: What exact scenario to record (dry-run of minimal profile? developer profile? specific feature?).
   - Recommendation: Record `./setup.sh --dry-run minimal` on Linux or macOS -- short, shows key features (progress, colors, dry-run banner) without requiring actual package installation. Alternative: use a static placeholder image if recording is impractical without a Linux/macOS environment.

3. **Pester Availability on macOS**
   - What we know: The dev environment is macOS (Darwin 25.3.0). Pester requires PowerShell.
   - What's unclear: Whether PowerShell Core (pwsh) is installed on the current machine.
   - Recommendation: Check with `pwsh -v` and `Get-Module -ListAvailable Pester`. If not available, tests can still be written and verified structure-wise, with actual execution deferred to a Windows environment. The test files themselves are platform-independent PowerShell.

## Sources

### Primary (HIGH confidence)
- [Pester v5 Quick Start](https://pester.dev/docs/quick-start) - Test structure, Describe/It/Should syntax, BeforeAll pattern
- [Pester v5 Module Testing](https://pester.dev/docs/usage/modules) - InModuleScope, -ModuleName Mock, module loading
- [Pester v5 Mocking](https://pester.dev/docs/usage/mocking) - Mock syntax, Should -Invoke, ParameterFilter
- [PowerShell Gallery Pester 5.6.1](https://www.powershellgallery.com/packages/pester/5.6.1) - Current version verification
- [gh release create manual](https://cli.github.com/manual/gh_release_create) - Release creation flags and options
- [GitHub SECURITY.md docs](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository) - Security policy file integration

### Secondary (MEDIUM confidence)
- [agg documentation](https://docs.asciinema.org/manual/agg/) - agg installation and usage
- [agg GitHub](https://github.com/asciinema/agg) - Installation methods, Cargo/Homebrew
- [agg Homebrew formula](https://formulae.brew.sh/formula/agg) - Homebrew availability confirmed
- [Pester Discussion #2109](https://github.com/pester/Pester/discussions/2109) - InModuleScope vs -ModuleName best practices

### Tertiary (LOW confidence)
- None. All findings verified with at least one primary or secondary source.

## Project-Specific Analysis

### Existing Test Parity Blueprint
The `tests/contracts/api-parity.txt` file provides an exact mapping of what Pester tests should cover:

| PS Module | Exported Functions | Bash Equivalent Tests | Estimated Pester Tests |
|-----------|-------------------|----------------------|----------------------|
| logging.psm1 | Write-Log (6 levels) | test-core-logging.bats (10 tests) | 5-6 tests |
| errors.psm1 | Add-FailedItem, Show-FailureSummary, Get-FailureCount, Clear-Failures, Get-ExitCode | test-core-errors.bats (15 tests) | 5-6 tests |
| packages.psm1 | Read-PackageFile | test-core-packages.bats (7 tests) | 3-4 tests |
| progress.psm1 | Show-DryRunBanner, Get-PlatformStepCount, Show-CompletionSummary | test-core-progress.bats (10 tests) | 4-5 tests |
| **Total** | **11 functions** | **42 bats tests** | **17-21 Pester tests** |

### Prior Decisions That Constrain This Phase
- **No CI/CD automation** (permanent): Tests are manual-only. No GitHub Actions workflow for Pester.
- **No CmdletBinding changes**: Modules already have `[CmdletBinding()]` on exported functions with empty `param()` where needed.
- **No Pester for idempotent.psm1**: Explicitly out of scope (requires real winget/npm/cargo mocks).
- **No ShouldProcess/WhatIf**: Modules use `$env:DRY_RUN` pattern, not PS native ShouldProcess.
- **Bare [CmdletBinding()]**: No ShouldProcess parameter on any module function.

### Key Module Characteristics for Testing

**logging.psm1 (1 exported function):**
- `Write-Log` with `-Level` and `-Message` parameters
- 6 levels: OK, ERROR, WARN, INFO, DEBUG, BANNER
- DEBUG suppressed unless `$env:VERBOSE -eq 'true'`
- VERBOSE adds timestamp prefix
- NO_COLOR disables color output
- BANNER format: `=== Message ===`
- Uses Write-Host (not Write-Output) for all output

**errors.psm1 (5 exported functions):**
- `$script:FailedItems` array tracks failures (script scope, persists across calls)
- `Add-FailedItem` appends + logs + writes to `$env:FAILURE_LOG` file
- `Show-FailureSummary` shows success or failure list
- `Get-FailureCount` returns integer
- `Get-ExitCode` returns 0 (success) or 1 (partial failure)
- `Clear-Failures` resets array
- Imports logging.psm1 internally
- Exports variables: `$EXIT_SUCCESS`, `$EXIT_PARTIAL_FAILURE`, `$EXIT_CRITICAL`

**packages.psm1 (1 exported function):**
- `Read-PackageFile` takes filename (relative or absolute)
- Relative paths resolve to `data/packages/` from project root
- Skips blank lines and `#` comments
- Trims whitespace
- Returns `@()` for missing files (with Write-Warning)
- Uses `,` operator on return for array preservation

**progress.psm1 (3 exported functions):**
- `Show-DryRunBanner` -- no-op unless `$env:DRY_RUN -eq 'true'`
- `Get-PlatformStepCount` -- counts Windows-relevant entries in profile file
- `Show-CompletionSummary` -- reads `$env:FAILURE_LOG`, shows banner/duration/results
- Imports logging.psm1 internally
- `Show-CompletionSummary` has `-StartTime` mandatory parameter (DateTime)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Pester is the only PS testing framework; asciinema+agg are standard; gh CLI is well-documented
- Architecture: HIGH - All four modules are small, well-documented, with exported-only public APIs; bats tests provide exact blueprint
- Pitfalls: HIGH - Write-Host mocking, module state persistence, and path resolution are well-documented Pester patterns
- SECURITY.md: HIGH - Standard GitHub feature with clear documentation
- GitHub Release: HIGH - v4.0.0 annotated tag exists; gh CLI commands are straightforward
- Demo GIF: MEDIUM - Tool chain is clear but actual recording depends on environment availability

**Research date:** 2026-02-21
**Valid until:** 2026-03-21 (30 days -- all tools are stable/mature)
