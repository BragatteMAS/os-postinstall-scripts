# Phase 6: Windows Foundation - Research

**Researched:** 2026-02-06
**Domain:** PowerShell scripting, WinGet package management, Windows automation
**Confidence:** HIGH

## Summary

Phase 6 introduces Windows support via PowerShell and WinGet, mirroring the existing Bash-based infrastructure (setup.sh, core modules, platform installers). The project already has `data/packages/winget.txt` with 35+ package IDs and a legacy `platforms/windows/win11.ps1` one-liner script. The task is to create a proper PowerShell entry point (`setup.ps1`) and a data-driven WinGet installer following the same patterns established in Phases 1-5.

PowerShell is built into Windows 10/11 (zero dependency constraint satisfied). WinGet is pre-installed on Windows 11 and modern Windows 10 (22H2+) via App Installer. The existing codebase patterns (data-driven installation, idempotent checks, failure tracking, colored logging, dual-mode operation) all have clean PowerShell equivalents. The translation is straightforward because PowerShell provides richer built-in features than Bash for many of these patterns.

**Primary recommendation:** Create a self-contained PowerShell layer (`setup.ps1` + `src/platforms/windows/`) that mirrors the Bash architecture 1:1 but uses native PowerShell idioms. Do NOT try to share code between Bash and PowerShell -- they are separate entry points for separate platforms.

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PowerShell | 5.1+ (built-in) | Script execution engine | Ships with Windows 10/11, zero deps |
| WinGet | 1.6+ (built-in) | Package manager CLI | Ships with Windows 11, App Installer on Win10 |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| PowerShell 7 (pwsh) | 7.x | Modern PowerShell | NOT required -- scripts target 5.1 for zero-dep |
| Microsoft.WinGet.Client | PSModule | PowerShell WinGet cmdlets | NOT recommended -- adds dependency, CLI is sufficient |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| WinGet CLI | Microsoft.WinGet.Client module | Adds dependency (must install module first), violates zero-dep principle |
| WinGet CLI | Chocolatey | Requires separate install, not built-in, violates zero-dep |
| PowerShell 5.1 | PowerShell 7 | PS7 not built-in, would need installation first |

**Installation:** None required. PowerShell 5.1 and WinGet are built into the target OS.

## Architecture Patterns

### Recommended Project Structure
```
setup.ps1                              # Windows entry point (NEW)
src/
  platforms/
    windows/
      core/
        logging.psm1                   # Colored logging functions
        packages.psm1                  # Load packages from text files
        errors.psm1                    # Failure tracking and retry
      install/
        winget.ps1                     # Data-driven WinGet installer
      main.ps1                         # Windows orchestrator (profile dispatch)
data/
  packages/
    winget.txt                         # Already exists (35+ packages)
    profiles/
      minimal.txt                      # Add winget.txt entry
      developer.txt                    # Add winget.txt entry
      full.txt                         # Add winget.txt entry
```

### Pattern 1: PowerShell Module Source Guard
**What:** Prevent multiple loading of the same module, equivalent to Bash `_SOURCED` guard
**When to use:** Every `.psm1` module file
**Example:**
```powershell
# PowerShell equivalent of: [[ -n "${_LOGGING_SOURCED:-}" ]] && return 0
if ($script:_LoggingLoaded) { return }
$script:_LoggingLoaded = $true
```
**Note:** If using `Import-Module`, PowerShell handles this automatically (modules are loaded once). The guard is only needed for dot-sourced `.ps1` files. Using `.psm1` modules with `Import-Module` is the PowerShell-idiomatic approach.

### Pattern 2: Data-Driven Package Loading
**What:** Read package list from text file, skip comments/blanks, return array
**When to use:** Loading winget.txt (and potentially other package lists)
**Example:**
```powershell
# PowerShell equivalent of load_packages()
function Read-PackageFile {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        Write-Log -Level ERROR -Message "Package file not found: $FilePath"
        return @()
    }

    $packages = Get-Content -Path $FilePath -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    return @($packages)
}
```

### Pattern 3: Idempotent WinGet Install
**What:** Check if package is installed before attempting install
**When to use:** Every package installation
**Example:**
```powershell
function Test-WinGetInstalled {
    param([string]$PackageId)

    $result = winget list --id $PackageId --exact --accept-source-agreements 2>&1
    return $LASTEXITCODE -eq 0
}

function Install-WinGetPackage {
    param([string]$PackageId)

    if (Test-WinGetInstalled -PackageId $PackageId) {
        Write-Log -Level DEBUG -Message "Already installed: $PackageId"
        return $true
    }

    Write-Log -Level INFO -Message "Installing: $PackageId"

    winget install --id $PackageId --exact --silent `
        --accept-source-agreements `
        --accept-package-agreements `
        --source winget 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level OK -Message "Installed: $PackageId"
        return $true
    } else {
        Write-Log -Level WARN -Message "Failed to install: $PackageId (exit code: $LASTEXITCODE)"
        return $false
    }
}
```

### Pattern 4: Colored Logging (PowerShell)
**What:** [OK]/[ERROR]/[WARN]/[INFO]/[DEBUG] format matching Bash output
**When to use:** All user-visible output
**Example:**
```powershell
function Write-Log {
    param(
        [ValidateSet('OK','ERROR','WARN','INFO','DEBUG')]
        [string]$Level = 'INFO',
        [string]$Message
    )

    # Skip DEBUG unless VERBOSE
    if ($Level -eq 'DEBUG' -and -not $script:Verbose) { return }

    $colors = @{
        OK    = 'Green'
        ERROR = 'Red'
        WARN  = 'Yellow'
        INFO  = 'Cyan'
        DEBUG = 'DarkGray'
    }

    $prefix = if ($script:Verbose) { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] " } else { "" }
    $tag = "[$Level]"

    Write-Host $tag -ForegroundColor $colors[$Level] -NoNewline
    Write-Host " ${prefix}${Message}"

    # Write to log file if configured
    if ($script:LogFile) {
        "${tag} ${prefix}${Message}" | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
    }
}
```

### Pattern 5: Failure Tracking
**What:** Collect failed items, show summary at end, always exit 0
**When to use:** Main install loop
**Example:**
```powershell
$script:FailedItems = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Item)
    $script:FailedItems.Add($Item)
    Write-Log -Level ERROR -Message "Failed: $Item"
}

function Show-FailureSummary {
    if ($script:FailedItems.Count -eq 0) {
        Write-Log -Level OK -Message "All operations completed successfully"
        return
    }

    Write-Host ""
    Write-Log -Level WARN -Message "Summary: $($script:FailedItems.Count) item(s) failed"
    Write-Host "  Failed items:"
    foreach ($item in $script:FailedItems) {
        Write-Host "    - $item"
    }
    Write-Host ""
}
```

### Pattern 6: Dual-Mode Entry (Unattended / Interactive)
**What:** Accept profile as argument (unattended) or show menu (interactive)
**When to use:** setup.ps1 and main.ps1
**Example:**
```powershell
param(
    [ValidateSet('minimal','developer','full')]
    [string]$Profile,

    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Unattended
)

if ($Profile) {
    # Unattended mode
    Install-Profile -Name $Profile
} else {
    # Interactive menu
    Show-Menu
}
```

### Pattern 7: WinGet Availability Check
**What:** Detect if WinGet is available, provide guidance if not
**When to use:** Early in setup.ps1, before any install attempts
**Example:**
```powershell
function Test-WinGetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Show-WinGetGuidance {
    Write-Log -Level ERROR -Message "WinGet is not available on this system."
    Write-Host ""
    Write-Host "  WinGet comes pre-installed on Windows 11 and Windows 10 22H2+."
    Write-Host "  To install or update WinGet:"
    Write-Host "    1. Open Microsoft Store"
    Write-Host "    2. Search for 'App Installer'"
    Write-Host "    3. Install or update it"
    Write-Host ""
    Write-Host "  Or download from: https://github.com/microsoft/winget-cli/releases"
    Write-Host ""
}
```

### Pattern 8: $PSScriptRoot for Path Resolution
**What:** Resolve script directory, equivalent to Bash SCRIPT_DIR
**When to use:** All scripts that reference relative paths
**Example:**
```powershell
# PowerShell automatic variable -- equivalent to Bash SCRIPT_DIR
$ScriptRoot = $PSScriptRoot

# Resolve project paths (equivalent to config.sh)
$ProjectRoot = $ScriptRoot  # for setup.ps1 at repo root
$SrcDir      = Join-Path $ProjectRoot 'src'
$DataDir     = Join-Path $ProjectRoot 'data'
$CoreDir     = Join-Path $SrcDir 'platforms' 'windows' 'core'
```

### Anti-Patterns to Avoid
- **Using Microsoft.WinGet.Client module:** Adds an external dependency that must be installed first. Violates zero-dep principle. Use `winget` CLI directly.
- **Using `Set-ExecutionPolicy` inside the script:** Permanent system change. Instead, instruct users to run with `-ExecutionPolicy Bypass`.
- **Parsing winget text output with regex:** WinGet CLI output format is unstable. Use `--id --exact` and `$LASTEXITCODE` instead of parsing text.
- **Using `$ErrorActionPreference = 'Stop'`:** This is the PowerShell equivalent of `set -e`. The project explicitly avoids this pattern (continue on failure).
- **Using `exit 1`:** Per project convention, always exit 0. Failures shown in summary.
- **Sharing code between Bash and PowerShell:** These are separate platforms. Each has its own entry point and modules. Data files (winget.txt, profiles/) are shared.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Check if winget installed | PATH check or where.exe | `Get-Command winget -EA SilentlyContinue` | Handles aliases, PATH issues |
| Internet connectivity check | Raw socket test | `Test-NetConnection -ComputerName www.google.com -Port 443 -InformationLevel Quiet` | Built-in, returns boolean |
| Admin elevation check | whoami parsing | `([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')` | Canonical .NET pattern |
| Reading text files | Manual stream reader | `Get-Content -Encoding UTF8` with pipeline | Handles encoding, line-by-line |
| Array operations | ArrayList + manual | `[System.Collections.Generic.List[string]]::new()` | Type-safe, no `+=` overhead |
| Color output | ANSI escape codes | `Write-Host -ForegroundColor` | Works on all PowerShell versions, respects terminal |
| Path joining | String concatenation | `Join-Path` | Handles separators correctly |

**Key insight:** PowerShell has richer built-in cmdlets than Bash for most of these operations. Use native PowerShell patterns, not Bash-to-PowerShell transliterations.

## Common Pitfalls

### Pitfall 1: WinGet Not Found on Windows 10
**What goes wrong:** Script fails immediately because winget is not in PATH
**Why it happens:** WinGet comes via App Installer on Windows 10 but may not be updated or installed on older builds. WinGet is only guaranteed on Windows 11 and Windows 10 22H2+.
**How to avoid:** Check for winget availability early. Provide clear installation guidance. Do NOT attempt to auto-install winget (violates simplicity principle and can fail in complex ways).
**Warning signs:** `Get-Command winget` throws, or `winget --version` returns nothing.

### Pitfall 2: Execution Policy Blocks Script
**What goes wrong:** Users double-click setup.ps1 or run it and get "execution of scripts is disabled" error
**Why it happens:** Default Windows execution policy is `Restricted` (no scripts). Downloaded scripts are also marked with "Zone.Identifier" alternate data stream.
**How to avoid:** Document the run command prominently: `powershell -ExecutionPolicy Bypass -File .\setup.ps1`. Include this in README and in setup.ps1 header comments.
**Warning signs:** Script never starts, or error about "not digitally signed."

### Pitfall 3: winget list --id Returns False Positives
**What goes wrong:** Idempotent check says package is installed when it's not (or vice versa)
**Why it happens:** `winget list --id` uses substring matching by default. Searching for "Git" matches "Git.Git", "GitHub.cli", "GitHub.GitHubDesktop", etc. Without `--exact`, results are unreliable.
**How to avoid:** Always use `winget list --id $PackageId --exact`. Check `$LASTEXITCODE` rather than parsing output text.
**Warning signs:** Packages skipped that should be installed.

### Pitfall 4: PowerShell 5.1 vs 7 Differences
**What goes wrong:** Script uses PS7-only features and fails on built-in PowerShell 5.1
**Why it happens:** Developer tests with pwsh 7.x but Windows ships with 5.1. Features like `??=`, ternary operators, `ForEach-Object -Parallel` are PS7-only.
**How to avoid:** Target PowerShell 5.1 explicitly. Test on Windows PowerShell 5.1. Avoid: null-coalescing (`??`), ternary (`?:`), pipeline parallelism, `Clean` block in functions.
**Warning signs:** Syntax errors on fresh Windows install.

### Pitfall 5: WinGet Source Agreements Prompt
**What goes wrong:** Script hangs waiting for user to accept source agreements
**Why it happens:** First-time winget usage requires accepting the source agreement. Without `--accept-source-agreements`, winget prompts interactively.
**How to avoid:** Always include `--accept-source-agreements` and `--accept-package-agreements` on every winget command.
**Warning signs:** Script appears to hang during first run.

### Pitfall 6: UAC Elevation for System-Scope Installs
**What goes wrong:** Some packages fail to install because they need admin rights
**Why it happens:** WinGet installs default to user scope when possible, but some packages require machine-wide install (admin required).
**How to avoid:** Do NOT auto-elevate. Use `--scope user` as default. Warn user that some packages may need admin. Document running as admin for full install.
**Warning signs:** Exit code indicating elevation required. Some packages silently install to user-only.

### Pitfall 7: $ErrorActionPreference Conflicts
**What goes wrong:** A cmdlet throws a terminating error and the entire script stops
**Why it happens:** If `$ErrorActionPreference` is set to `'Stop'` or a cmdlet uses `-ErrorAction Stop`, any error terminates execution.
**How to avoid:** Set `$ErrorActionPreference = 'Continue'` at script level (matches project's "no set -e" pattern). Use try/catch only around specific operations where you need to catch errors.
**Warning signs:** Script exits after first failed package instead of continuing.

## Code Examples

### Complete WinGet Installer Pattern (winget.ps1)
```powershell
# Source: Derived from project patterns (apt.sh, flatpak.sh) translated to PowerShell
#Requires -Version 5.1

param(
    [switch]$Post  # Two-pass support equivalent to --post
)

$ErrorActionPreference = 'Continue'

# Resolve paths
$WinDir = $PSScriptRoot
$CoreDir = Join-Path $WinDir 'core'

# Import modules
Import-Module (Join-Path $CoreDir 'logging.psm1') -Force
Import-Module (Join-Path $CoreDir 'packages.psm1') -Force
Import-Module (Join-Path $CoreDir 'errors.psm1') -Force

# Banner
Write-Log -Level INFO -Message "=== WinGet Package Installer ==="

# Determine package file
$pkgFile = if ($Post) { 'winget-post.txt' } else { 'winget.txt' }

# Check winget availability
if (-not (Test-WinGetAvailable)) {
    Show-WinGetGuidance
    exit 0  # Always exit 0
}

# Load packages
$packages = Read-PackageFile -FileName $pkgFile
if ($packages.Count -eq 0) {
    Write-Log -Level WARN -Message "No packages to install from $pkgFile"
    exit 0
}

Write-Log -Level INFO -Message "Loaded $($packages.Count) packages from $pkgFile"

# Install loop
foreach ($pkg in $packages) {
    if (-not (Install-WinGetPackage -PackageId $pkg)) {
        Add-Failure -Item $pkg
    }
}

# Summary
Show-FailureSummary
exit 0
```

### Entry Point Pattern (setup.ps1)
```powershell
# Source: Mirrors setup.sh structure
#Requires -Version 5.1

<#
.SYNOPSIS
    OS Post-Install Scripts - Windows Setup
.DESCRIPTION
    Installs packages via WinGet based on selected profile.
    Run: powershell -ExecutionPolicy Bypass -File .\setup.ps1 [profile]
.PARAMETER Profile
    Installation profile: minimal, developer, full
.PARAMETER DryRun
    Show what would be done without making changes
.PARAMETER Verbose
    Enable debug output
#>

param(
    [ValidateSet('minimal','developer','full','')]
    [string]$Profile = '',

    [switch]$DryRun,
    [switch]$Unattended
)

$ErrorActionPreference = 'Continue'
$ScriptRoot = $PSScriptRoot

# Load Windows platform handler
$mainScript = Join-Path $ScriptRoot 'src' 'platforms' 'windows' 'main.ps1'

if (-not (Test-Path $mainScript)) {
    Write-Host "[ERROR] Windows platform handler not found: $mainScript" -ForegroundColor Red
    exit 0
}

# Dispatch
& $mainScript -Profile $Profile -DryRun:$DryRun -Unattended:$Unattended
```

### Profile Reading Pattern
```powershell
# Source: Derived from packages.sh load_profile() + main.sh dispatch
function Install-Profile {
    param([string]$ProfileName)

    $profileFile = Join-Path $script:DataDir 'packages' 'profiles' "$ProfileName.txt"

    if (-not (Test-Path $profileFile)) {
        Write-Log -Level ERROR -Message "Profile not found: $ProfileName"
        return
    }

    $entries = Get-Content -Path $profileFile -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    foreach ($entry in $entries) {
        switch ($entry) {
            'winget.txt' {
                Write-Log -Level INFO -Message "Installing WinGet packages..."
                & (Join-Path $script:WinDir 'install' 'winget.ps1')
            }
            # Skip non-Windows entries silently
            { $_ -in 'apt.txt','apt-post.txt','flatpak.txt','flatpak-post.txt','snap.txt','snap-post.txt' } {
                Write-Log -Level DEBUG -Message "Skipping $_ (Linux only)"
            }
            { $_ -in 'brew.txt','brew-cask.txt' } {
                Write-Log -Level DEBUG -Message "Skipping $_ (macOS only)"
            }
            default {
                Write-Log -Level WARN -Message "Unknown package file: $_"
            }
        }
    }
}
```

### Internet Connectivity Check
```powershell
# Source: PowerShell built-in cmdlet, equivalent to check_internet() in platform.sh
function Test-InternetConnection {
    try {
        $result = Test-NetConnection -ComputerName www.google.com -Port 443 `
            -InformationLevel Quiet -WarningAction SilentlyContinue
        return $result
    }
    catch {
        return $false
    }
}
```

### Administrator Check
```powershell
# Source: Standard .NET pattern for Windows admin detection
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Chocolatey for Windows pkg mgmt | WinGet (built-in) | Windows 10 21H2+ / Win11 | No external installer needed |
| One-liner winget chains | Data-driven package files | This project Phase 2 | winget.txt already exists |
| PowerShell ISE | VS Code + PowerShell ext | 2020+ | ISE deprecated in PS7 |
| `Write-Output` for display | `Write-Host -ForegroundColor` for UI | Always for interactive scripts | Proper separation of output streams |
| `$host.UI.RawUI.ForegroundColor` | `Write-Host -ForegroundColor` per message | Modern PS | Cleaner, per-message colors |

**Deprecated/outdated:**
- `platforms/windows/win11.ps1`: Legacy one-liner with hardcoded winget chains. Will be superseded by data-driven winget.ps1.
- PowerShell ISE: Deprecated, not relevant for scripts.
- `winget install` without `--accept-source-agreements`: Always include for automation.

## Open Questions

Things that could not be fully resolved:

1. **WinGet exit code for "already installed"**
   - What we know: Exit code 0 means success. The code `0x8A15010D` (-1978334963) means "another version already installed" and `0x8A15010E` means "higher version already installed."
   - What's unclear: Whether `winget install` on an already-installed package returns 0 or a specific "already installed" code varies by version. The `winget list --id --exact` pre-check is more reliable.
   - Recommendation: Use `winget list --id --exact` as the idempotent check before install. Do NOT rely on winget install's exit code for idempotency.

2. **Profile winget.txt additions for Windows**
   - What we know: Current profiles list apt.txt, brew.txt, etc. They need winget.txt added.
   - What's unclear: Should winget.txt be in all profiles or only developer/full?
   - Recommendation: Add winget.txt to all three profiles (minimal, developer, full). The winget.txt file itself can be split later into winget.txt / winget-post.txt if needed.

3. **Cross-platform installers (cargo, npm, ai-tools) on Windows**
   - What we know: Phase 6 scope is "basic WinGet support" only. Cargo, npm, and AI tools are cross-platform but currently only have Bash installers.
   - What's unclear: Should Phase 6 include PowerShell versions of dev-env.sh, rust-cli.sh, ai-tools.sh?
   - Recommendation: Out of scope for Phase 6. Phase 6 focuses on WinGet only (PKG-03). Cross-platform PowerShell installers can be a future phase.

## Sources

### Primary (HIGH confidence)
- [Microsoft Learn: winget install](https://learn.microsoft.com/en-us/windows/package-manager/winget/install) - Install command options, flags, examples
- [Microsoft Learn: winget list](https://learn.microsoft.com/en-us/windows/package-manager/winget/list) - List command options, filtering, exact match
- [Microsoft Learn: winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) - WinGet overview, availability, requirements
- [GitHub: winget-cli returnCodes.md](https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md) - Exit codes (0x8A15010D, etc.)
- [Microsoft Learn: about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies) - Execution policy, Bypass
- [Microsoft Learn: about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables) - $ErrorActionPreference
- [Microsoft Learn: Write-Host](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-host) - Color output parameters

### Secondary (MEDIUM confidence)
- [SS64: Winget Install](https://ss64.com/nt/winget-install.html) - Command reference, verified against MS docs
- [4sysops: Test-NetConnection vs Test-Connection](https://4sysops.com/archives/test-netconnection-vs-test-connection-testing-a-network-connection-with-powershell/) - Network testing patterns

### Tertiary (LOW confidence)
- [GitHub: winget-cli discussions](https://github.com/microsoft/winget-cli/discussions/4065) - Community patterns for WinGet automation
- [Petri: Check Admin Privileges](https://petri.com/how-to-check-a-powershell-script-is-running-with-admin-privileges/) - Admin check pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - WinGet and PowerShell 5.1 are built into Windows, verified via Microsoft docs
- Architecture: HIGH - Direct translation of existing Bash patterns with PowerShell idioms, well-understood
- Pitfalls: HIGH - Documented in Microsoft Learn and verified via winget-cli GitHub issues
- Code examples: MEDIUM - Synthesized from project patterns + PowerShell docs, not tested on Windows

**Research date:** 2026-02-06
**Valid until:** 2026-03-06 (stable -- WinGet CLI and PowerShell 5.1 are mature, slow-moving)
