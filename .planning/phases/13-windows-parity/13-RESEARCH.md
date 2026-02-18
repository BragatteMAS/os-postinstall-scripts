# Phase 13: Windows Parity - Research

**Researched:** 2026-02-18
**Domain:** PowerShell scripting -- CLI flags, step counters, completion summary, CmdletBinding
**Confidence:** HIGH

## Summary

Phase 13 adds four UX features to the Windows PowerShell scripts that already exist on the Unix (Bash) side: CLI flag switches (-DryRun, -Verbose, -Unattended), step counters ([Step X/Y]), a completion summary (profile, platform, duration, failures), and [CmdletBinding()] on core module exported functions. The codebase analysis shows this is a well-scoped phase with clear reference implementations (Unix progress.sh, setup.sh flag parsing, show_completion_summary) and clear targets (setup.ps1, main.ps1, and the 4 core .psm1 modules).

The Windows codebase already has the building blocks: DRY_RUN checks exist in all 4 installer scripts (via `$env:DRY_RUN`), logging.psm1 already supports VERBOSE-driven timestamps, errors.psm1 has Get-FailureCount/Show-FailureSummary, and main.ps1 has the dispatch switch that needs step counters. The work is additive -- adding parameters to setup.ps1, adding step counting to main.ps1's dispatch, adding a new progress.psm1 module, and adding [CmdletBinding()] to existing module functions.

**Primary recommendation:** Create a progress.psm1 module (mirroring progress.sh) with Show-DryRunBanner, Get-PlatformStepCount, and Show-CompletionSummary. Add CLI switches to setup.ps1 and propagate them to main.ps1. Add step counters to main.ps1's dispatch loop. Add [CmdletBinding()] to all core module exported functions (logging.psm1, errors.psm1, packages.psm1, idempotent.psm1).

## Architecture Patterns

### Unix Reference Implementation (the parity target)

The Unix side implements these features across three files:

**1. CLI Flags (setup.sh lines 70-103)**
```bash
# setup.sh parses flags, exports env vars, passes remaining args to main()
parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)   export DRY_RUN=true; shift ;;
            -v|--verbose)   export VERBOSE=true; shift ;;
            -y|--unattended) export UNATTENDED=true; export NONINTERACTIVE=true; shift ;;
        esac
    done
    REMAINING_ARGS=("$@")
}
```

**2. Step Counters (linux/main.sh, macos/main.sh)**
```bash
# Count platform-relevant steps BEFORE dispatch
total_steps=$(count_platform_steps "$profile_file" "linux")
total_steps=$((total_steps + 2))  # +2 for dev-env + rust-cli
current_step=0

# Each dispatch increments and prefixes
current_step=$((current_step + 1))
log_info "[Step ${current_step}/${total_steps}] Installing APT packages..."
bash "${LINUX_DIR}/install/apt.sh"
```

**3. Completion Summary (progress.sh lines 96-139)**
```bash
show_completion_summary() {
    local profile="${1:-unknown}"
    local platform="${2:-unknown}"
    local elapsed=${SECONDS:-0}        # SECONDS builtin, set to 0 at start
    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))
    local fail_count=...               # from FAILURE_LOG file

    log_banner "Setup Complete"        # or "Dry Run Complete"
    log_info "Profile:  ${profile}"
    log_info "Platform: ${platform}"
    log_info "Duration: ${mins}m ${secs}s"
    # then failure details or success message
}
```

### Windows Current State

**setup.ps1 (current):**
- Has `param([string]$Profile = 'developer', [switch]$Help)` -- missing DryRun, Verbose, Unattended switches
- Imports logging.psm1 and errors.psm1
- Dispatches to main.ps1 passing only `-Profile $Profile`
- Has FAILURE_LOG cross-process tracking (line 44)
- Shows basic "Setup Complete" banner at end (line 73) -- no summary data

**main.ps1 (current):**
- Has `param([string]$Profile = '')` -- missing DryRun passthrough
- Install-Profile dispatches in a `foreach/switch` (lines 73-96) -- no step counters
- Dispatches: winget.ps1, cargo.ps1, npm.ps1, ai-tools.ps1

**Core modules (current):**
- logging.psm1: `Write-Log` -- no [CmdletBinding()], uses `param()` directly
- errors.psm1: `Add-FailedItem`, `Show-FailureSummary`, `Get-FailureCount`, `Clear-Failures` -- none have [CmdletBinding()]
- packages.psm1: `Read-PackageFile` -- no [CmdletBinding()]
- idempotent.psm1: `Test-WinGetInstalled`, `Test-NpmInstalled`, `Test-CargoInstalled` -- none have [CmdletBinding()]

**DRY_RUN already works** in all installer scripts via `$env:DRY_RUN -eq 'true'` checks. What is missing is:
1. A CLI switch to set it (currently must be set as env var externally)
2. A DryRun banner (progress.sh `show_dry_run_banner` equivalent)
3. Propagation from setup.ps1 -> main.ps1 -> installers

### Recommended Project Structure Addition

```
src/platforms/windows/core/
  logging.psm1       # existing -- add [CmdletBinding()] to Write-Log
  errors.psm1        # existing -- add [CmdletBinding()] to 4 functions
  packages.psm1      # existing -- add [CmdletBinding()] to Read-PackageFile
  idempotent.psm1    # existing -- add [CmdletBinding()] to 3 functions
  progress.psm1      # NEW -- Show-DryRunBanner, Get-PlatformStepCount, Show-CompletionSummary
```

### Pattern 1: DryRun Flag Propagation via Environment Variable

**What:** setup.ps1 sets `$env:DRY_RUN = 'true'` when -DryRun switch is present. Installer scripts already check `$env:DRY_RUN`.

**When to use:** This preserves the existing cross-platform pattern where DRY_RUN is an environment variable, not a ShouldProcess flag.

**Why not ShouldProcess/WhatIf:** Per project decision (STATE.md), ShouldProcess/WhatIf breaks cross-platform DRY_RUN consistency. The Unix side uses `DRY_RUN=true` env var; Windows must match.

```powershell
# setup.ps1 - new param block
param(
    [string]$Profile = 'developer',
    [switch]$DryRun,
    [switch]$Verbose,       # Note: conflicts with CmdletBinding's built-in -Verbose
    [switch]$Unattended,
    [switch]$Help
)

# Map switches to environment variables (matching Unix pattern)
if ($DryRun)     { $env:DRY_RUN = 'true' }
if ($Verbose)    { $env:VERBOSE = 'true' }  # see Pitfall 2 below
if ($Unattended) { $env:UNATTENDED = 'true' }
```

**IMPORTANT design choice:** setup.ps1 and main.ps1 are **scripts** (.ps1), not module functions (.psm1). They use `param()` blocks directly. The [CmdletBinding()] requirement (WPAR-04) applies to **module exported functions** only (per STATE.md decision: "core module functions only, not all installer scripts").

### Pattern 2: Step Counter in main.ps1

**What:** Count Windows-relevant package files from the profile, then prefix each dispatch with [Step X/Y].

**How Unix does it:** `count_platform_steps()` in progress.sh reads the profile file and counts entries matching the platform.

```powershell
# progress.psm1 - new function
function Get-PlatformStepCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileFile
    )

    $count = 0
    if (-not (Test-Path $ProfileFile)) { return 0 }

    $entries = Get-Content -Path $ProfileFile -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    foreach ($entry in $entries) {
        switch ($entry) {
            'winget.txt'   { $count++ }
            'cargo.txt'    { $count++ }
            'npm.txt'      { $count++ }
            'ai-tools.txt' { $count++ }
        }
    }

    return $count
}
```

Then in main.ps1's Install-Profile:
```powershell
$totalSteps = Get-PlatformStepCount -ProfileFile $profileFile
$currentStep = 0

# In the dispatch switch:
'winget.txt' {
    $currentStep++
    Write-Log -Level INFO -Message "[Step ${currentStep}/${totalSteps}] Installing WinGet packages..."
    & "$WindowsDir/install/winget.ps1"
}
```

### Pattern 3: Completion Summary

**What:** After main.ps1 completes, setup.ps1 shows profile, platform, duration, and failure count.

**PowerShell duration approach:** Use `[System.Diagnostics.Stopwatch]` or simple `$StartTime = Get-Date` / `$elapsed = (Get-Date) - $StartTime`.

```powershell
# progress.psm1 - new function
function Show-CompletionSummary {
    [CmdletBinding()]
    param(
        [string]$Profile = 'unknown',
        [string]$Platform = 'Windows',
        [datetime]$StartTime
    )

    $elapsed = (Get-Date) - $StartTime
    $mins = [math]::Floor($elapsed.TotalMinutes)
    $secs = $elapsed.Seconds

    $failCount = 0
    if ($env:FAILURE_LOG -and (Test-Path $env:FAILURE_LOG)) {
        $failCount = (Get-Content $env:FAILURE_LOG -ErrorAction SilentlyContinue | Measure-Object).Count
    }

    Write-Host ''
    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level BANNER -Message 'Dry Run Complete'
    } else {
        Write-Log -Level BANNER -Message 'Setup Complete'
    }

    Write-Log -Level INFO -Message "Profile:  $Profile"
    Write-Log -Level INFO -Message "Platform: $Platform"
    Write-Log -Level INFO -Message "Duration: ${mins}m ${secs}s"
    Write-Host ''

    if ($failCount -gt 0) {
        Write-Log -Level WARN -Message "Completed with $failCount failure(s)"
        # ... list failures from FAILURE_LOG
    } else {
        Write-Log -Level OK -Message 'All sections completed successfully'
    }
    Write-Host ''
}
```

### Pattern 4: CmdletBinding() Addition

**What:** Add `[CmdletBinding()]` attribute before `param()` in all exported module functions.

**Scope:** Core .psm1 modules only (per STATE.md decision). 4 modules, 9 functions total:
- logging.psm1: Write-Log (1)
- errors.psm1: Add-FailedItem, Show-FailureSummary, Get-FailureCount, Clear-Failures (4)
- packages.psm1: Read-PackageFile (1)
- idempotent.psm1: Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled (3)

```powershell
# Before:
function Write-Log {
    param(
        [ValidateSet('OK','ERROR','WARN','INFO','DEBUG','BANNER')]
        [string]$Level = 'INFO',
        [string]$Message
    )
    ...
}

# After:
function Write-Log {
    [CmdletBinding()]
    param(
        [ValidateSet('OK','ERROR','WARN','INFO','DEBUG','BANNER')]
        [string]$Level = 'INFO',
        [string]$Message
    )
    ...
}
```

**What [CmdletBinding()] enables:**
- `-Verbose` and `-Debug` common parameters propagate automatically
- `$PSCmdlet` object becomes available
- `Write-Verbose` and `Write-Debug` cmdlets respect caller's preference
- Does NOT break existing callers (fully backward compatible)

### Anti-Patterns to Avoid

- **ShouldProcess/WhatIf on custom DryRun:** Per project decision, do NOT use `[CmdletBinding(SupportsShouldProcess)]`. The DRY_RUN env var pattern must be consistent across Bash and PowerShell.
- **Passing DryRun as parameter through call chain:** The env var `$env:DRY_RUN` already propagates to child scripts automatically. Do NOT add a -DryRun parameter to main.ps1 or installer scripts.
- **$VerbosePreference instead of $env:VERBOSE:** The existing logging.psm1 checks `$env:VERBOSE -eq 'true'`. Keep this pattern. [CmdletBinding()] adds native -Verbose support ON TOP of this, it does not replace it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Duration tracking | Custom timer logic | `$StartTime = Get-Date; $elapsed = (Get-Date) - $StartTime` | TimeSpan object gives .TotalMinutes, .Seconds for free |
| Step counting | Hardcoded step numbers | Read profile file dynamically, count Windows-relevant entries | Stays correct when profiles change |
| Verbose propagation | Manual $Verbose flag threading | [CmdletBinding()] + $env:VERBOSE env var (dual approach) | CmdletBinding is the PS standard; env var is the cross-platform bridge |

## Common Pitfalls

### Pitfall 1: -Verbose Name Collision with CmdletBinding

**What goes wrong:** If setup.ps1 declares `[switch]$Verbose` in its param block AND has `[CmdletBinding()]`, PowerShell throws an error because -Verbose is a reserved common parameter when CmdletBinding is active.

**Why it happens:** [CmdletBinding()] automatically adds -Verbose, -Debug, -ErrorAction, etc. as common parameters.

**How to avoid:** setup.ps1 and main.ps1 are scripts, NOT module functions. Per the WPAR-04 scope decision, [CmdletBinding()] goes on core module functions only. So setup.ps1 keeps its plain `param([switch]$Verbose)` block without [CmdletBinding()], and maps it to `$env:VERBOSE = 'true'`.

**Warning signs:** "A parameter with the name 'Verbose' was already defined" error.

### Pitfall 2: DryRun Banner Shows After Installers Already Started

**What goes wrong:** If the DryRun banner is only in setup.ps1, but main.ps1 starts dispatching before showing it, the user doesn't see the banner early enough.

**How to avoid:** Show DryRun banner in Install-Profile (main.ps1) before the dispatch loop, matching the Unix pattern where `show_dry_run_banner` is called at the start of `install_profile()`.

### Pitfall 3: Step Count Off-By-One for Minimal vs Developer/Full

**What goes wrong:** Unix adds +2 steps for dev-env + rust-cli on non-minimal profiles. Windows doesn't have separate dev-env/rust-cli steps (all handled by winget.ps1/cargo.ps1), so the step count logic is simpler. Copying Unix logic verbatim would produce wrong counts.

**How to avoid:** Windows step count = count of Windows-relevant entries in profile file. No extra steps needed. The `Get-PlatformStepCount` function only counts winget.txt, cargo.txt, npm.txt, ai-tools.txt.

Profile step counts for Windows:
- minimal.txt: winget.txt = 1 step
- developer.txt: winget.txt + cargo.txt + npm.txt + ai-tools.txt = 4 steps
- full.txt: winget.txt + cargo.txt + npm.txt + ai-tools.txt = 4 steps

### Pitfall 4: Failure Count Reads Empty FAILURE_LOG as 0 Lines

**What goes wrong:** `Get-Content` on an empty file returns `$null`, and `($null | Measure-Object).Count` returns 0, which is correct. But if the file doesn't exist, `Get-Content` throws unless `-ErrorAction SilentlyContinue` is used.

**How to avoid:** Guard with `Test-Path` first AND use `-ErrorAction SilentlyContinue`.

### Pitfall 5: SECONDS Builtin Does Not Exist in PowerShell

**What goes wrong:** Unix uses Bash's `$SECONDS` builtin for duration tracking. PowerShell has no equivalent automatic counter.

**How to avoid:** Use `$StartTime = Get-Date` at the start of setup.ps1, pass it through to Show-CompletionSummary. Use `(Get-Date) - $StartTime` to compute elapsed TimeSpan.

### Pitfall 6: Import-Module ordering matters for progress.psm1

**What goes wrong:** progress.psm1 calls Write-Log from logging.psm1. If progress.psm1 is imported before logging.psm1, Write-Log is not available.

**How to avoid:** In progress.psm1, import logging.psm1 at the top (same pattern as errors.psm1 line 13: `Import-Module "$PSScriptRoot/logging.psm1" -Force`).

## Code Examples

### setup.ps1 Updated Parameter Block

```powershell
param(
    [string]$Profile = 'developer',
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Unattended,
    [switch]$Help
)

$ErrorActionPreference = 'Continue'

# Map CLI switches to environment variables (cross-platform bridge)
if ($DryRun)     { $env:DRY_RUN = 'true' }
if ($Verbose)    { $env:VERBOSE = 'true' }
if ($Unattended) { $env:UNATTENDED = 'true' }
```

### setup.ps1 Help Text Update

```powershell
if ($Help) {
    Write-Host 'Usage: .\setup.ps1 [-Profile <name>] [-DryRun] [-Verbose] [-Unattended] [-Help]'
    Write-Host ''
    Write-Host 'Options:'
    Write-Host '  -DryRun      Show what would be done without making changes'
    Write-Host '  -Verbose     Enable debug output and timestamps'
    Write-Host '  -Unattended  Skip confirmation prompts'
    Write-Host '  -Help        Show this help message'
    Write-Host ''
    Write-Host 'Profiles:'
    Write-Host '  minimal    - Essential tools only'
    Write-Host '  developer  - Development environment (default)'
    Write-Host '  full       - Everything'
    Write-Host ''
    exit 0
}
```

### setup.ps1 Duration and Summary

```powershell
# At top of setup.ps1, after parameter mapping:
$StartTime = Get-Date

# Import modules (including new progress.psm1)
Import-Module "$PSScriptRoot/src/platforms/windows/core/logging.psm1" -Force
Import-Module "$PSScriptRoot/src/platforms/windows/core/errors.psm1" -Force
Import-Module "$PSScriptRoot/src/platforms/windows/core/progress.psm1" -Force

# ... dispatch to main.ps1 ...

# At end, replace the simple banner with rich summary:
Show-CompletionSummary -Profile $Profile -Platform 'Windows' -StartTime $StartTime
```

### main.ps1 Step Counter Integration

```powershell
function Install-Profile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileName
    )

    Write-Log -Level INFO -Message "Profile: $ProfileName"

    $profileFile = Join-Path $DataDir 'packages' 'profiles' "$ProfileName.txt"
    if (-not (Test-Path $profileFile)) {
        Write-Log -Level ERROR -Message "Profile not found: $ProfileName"
        return
    }

    # Show DRY_RUN banner if active
    Show-DryRunBanner

    # Count Windows-relevant steps
    $totalSteps = Get-PlatformStepCount -ProfileFile $profileFile
    $currentStep = 0

    # Read profile and dispatch
    $entries = Get-Content -Path $profileFile -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    foreach ($pkgFile in $entries) {
        switch ($pkgFile) {
            'winget.txt' {
                $currentStep++
                Write-Log -Level INFO -Message "[Step ${currentStep}/${totalSteps}] Installing WinGet packages..."
                & "$WindowsDir/install/winget.ps1"
            }
            'cargo.txt' {
                $currentStep++
                Write-Log -Level INFO -Message "[Step ${currentStep}/${totalSteps}] Installing Cargo packages..."
                & "$WindowsDir/install/cargo.ps1"
            }
            'npm.txt' {
                $currentStep++
                Write-Log -Level INFO -Message "[Step ${currentStep}/${totalSteps}] Installing NPM global packages..."
                & "$WindowsDir/install/npm.ps1"
            }
            'ai-tools.txt' {
                $currentStep++
                Write-Log -Level INFO -Message "[Step ${currentStep}/${totalSteps}] Installing AI tools..."
                & "$WindowsDir/install/ai-tools.ps1"
            }
            default {
                Write-Log -Level DEBUG -Message "Skipping $pkgFile (not a Windows package file)"
            }
        }
    }
}
```

### CmdletBinding Addition Example (errors.psm1)

```powershell
function Add-FailedItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Item
    )

    $script:FailedItems += $Item
    Write-Log -Level ERROR -Message "Failed: $Item"

    if ($env:FAILURE_LOG -and (Test-Path (Split-Path $env:FAILURE_LOG -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue)) {
        Add-Content -Path $env:FAILURE_LOG -Value $Item -Encoding UTF8
    }
}
```

## Implementation Scope Summary

### Files to CREATE (1 new file)
| File | Purpose |
|------|---------|
| `src/platforms/windows/core/progress.psm1` | Show-DryRunBanner, Get-PlatformStepCount, Show-CompletionSummary |

### Files to MODIFY (6 existing files)
| File | Changes |
|------|---------|
| `setup.ps1` | Add -DryRun, -Verbose, -Unattended switches; env var mapping; StartTime; import progress.psm1; replace banner with Show-CompletionSummary |
| `src/platforms/windows/main.ps1` | Import progress.psm1; step counters in Install-Profile; DryRun banner call |
| `src/platforms/windows/core/logging.psm1` | Add [CmdletBinding()] to Write-Log |
| `src/platforms/windows/core/errors.psm1` | Add [CmdletBinding()] to 4 functions |
| `src/platforms/windows/core/packages.psm1` | Add [CmdletBinding()] to Read-PackageFile |
| `src/platforms/windows/core/idempotent.psm1` | Add [CmdletBinding()] to 3 functions |

### Files to EXTEND (1 test file)
| File | Changes |
|------|---------|
| `tests/test-windows.ps1` | Add checks for: -DryRun parameter in setup.ps1, [CmdletBinding()] in core modules, progress.psm1 existence, Step X/Y pattern in main.ps1, Show-CompletionSummary in setup.ps1 |

### Total scope: 1 new file + 6 modifications + 1 test extension = ~150-200 lines of new/changed code

## Open Questions

None. All design decisions are already locked in STATE.md:
- CmdletBinding scope: core module functions only (resolved)
- No ShouldProcess/WhatIf (resolved)
- No Pester (resolved)
- Exit code: always 0 (resolved per ADR-001)

## Sources

### Primary (HIGH confidence)
- **Codebase analysis:** Direct reading of all 14 relevant files (setup.ps1, setup.sh, main.ps1, macos/main.sh, linux/main.sh, config.sh, progress.sh, logging.sh, errors.sh, logging.psm1, errors.psm1, packages.psm1, idempotent.psm1, test-windows.ps1)
- **STATE.md:** Project decisions on CmdletBinding scope, ShouldProcess rejection, Pester rejection
- **ADR-001:** Error resilience strategy (always exit 0, failure tracking)
- **ADR-006:** Cross-platform dispatch strategy (env var bridge between Bash/PowerShell)
- **ROADMAP.md:** Phase 13 requirements and success criteria

### Secondary (MEDIUM confidence)
- **PowerShell CmdletBinding behavior:** Well-established PowerShell feature, documented in Microsoft official docs. The -Verbose common parameter conflict with explicit param declaration is a known behavior.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new libraries, all changes are within existing PowerShell scripts
- Architecture: HIGH - directly mirroring proven Unix patterns with clear 1:1 mapping
- Pitfalls: HIGH - identified from actual codebase analysis and known PowerShell behaviors

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (stable -- no external dependencies, internal codebase only)
