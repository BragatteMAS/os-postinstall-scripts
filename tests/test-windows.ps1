#Requires -Version 5.1
#######################################
# Script: test-windows.ps1
# Description: Tests for Windows platform scripts
# Validates file existence, content patterns, and anti-patterns
# Author: Bragatte
# Date: 2026-02-08
#######################################

# Test runner setup
$script:Passed = 0
$script:Failed = 0
$script:Total = 0

function Assert-Pass {
    param([string]$Name, [scriptblock]$Test)
    $script:Total++
    try {
        $null = & $Test 2>$null
        $script:Passed++
        Write-Host "[PASS] $Name"
    } catch {
        $script:Failed++
        Write-Host "[FAIL] $Name"
    }
}

function Assert-Contains {
    param([string]$Name, [string]$Path, [string]$Pattern)
    $script:Total++
    if (Select-String -Path $Path -Pattern $Pattern -Quiet) {
        $script:Passed++
        Write-Host "[PASS] $Name"
    } else {
        $script:Failed++
        Write-Host "[FAIL] $Name"
    }
}

function Assert-NotContains {
    param([string]$Name, [string]$Path, [string]$Pattern)
    $script:Total++
    if (-not (Select-String -Path $Path -Pattern $Pattern -Quiet)) {
        $script:Passed++
        Write-Host "[PASS] $Name"
    } else {
        $script:Failed++
        Write-Host "[FAIL] $Name"
    }
}

# Resolve project root (tests/ -> project root)
$ProjectRoot = (Resolve-Path "$PSScriptRoot/..").Path

Write-Host "========================================="
Write-Host "  Windows Platform Tests"
Write-Host "========================================="
Write-Host ""

#######################################
# 1. File existence checks
#######################################
Write-Host "--- File Existence Checks ---"

Assert-Pass "main.ps1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/main.ps1")) { throw "missing" }
}
Assert-Pass "winget.ps1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/install/winget.ps1")) { throw "missing" }
}
Assert-Pass "logging.psm1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/core/logging.psm1")) { throw "missing" }
}
Assert-Pass "packages.psm1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/core/packages.psm1")) { throw "missing" }
}
Assert-Pass "errors.psm1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/core/errors.psm1")) { throw "missing" }
}
Assert-Pass "setup.ps1 exists" {
    if (-not (Test-Path "$ProjectRoot/setup.ps1")) { throw "missing" }
}
Assert-Pass "cargo.ps1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/install/cargo.ps1")) { throw "missing" }
}
Assert-Pass "npm.ps1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/install/npm.ps1")) { throw "missing" }
}
Assert-Pass "ai-tools.ps1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/install/ai-tools.ps1")) { throw "missing" }
}

Write-Host ""

#######################################
# 2. Content validation (critical patterns)
#######################################
Write-Host "--- Content Checks ---"

Assert-Contains "Write-Log in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "Write-Log"
Assert-Contains "winget list in winget.ps1" "$ProjectRoot/src/platforms/windows/install/winget.ps1" "winget list"
Assert-Contains "ErrorActionPreference in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "ErrorActionPreference"
Assert-Contains "Export-ModuleMember in errors.psm1" "$ProjectRoot/src/platforms/windows/core/errors.psm1" "Export-ModuleMember"
Assert-Contains "NO_COLOR in logging.psm1" "$ProjectRoot/src/platforms/windows/core/logging.psm1" "NO_COLOR"
Assert-Contains "FAILURE_LOG in errors.psm1" "$ProjectRoot/src/platforms/windows/core/errors.psm1" "FAILURE_LOG"
Assert-Contains "FAILURE_LOG in setup.ps1" "$ProjectRoot/setup.ps1" "FAILURE_LOG"
Assert-Contains "WARN in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "WARN"
Assert-Contains "cargo.txt in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "cargo\.txt"
Assert-Contains "Requires -Version 5.1 in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "Requires -Version 5\.1"

# cargo.ps1 content
Assert-Contains "WinGetMap in cargo.ps1" "$ProjectRoot/src/platforms/windows/install/cargo.ps1" "WinGetMap"
Assert-Contains "Read-PackageFile cargo.txt in cargo.ps1" "$ProjectRoot/src/platforms/windows/install/cargo.ps1" "Read-PackageFile.*cargo\.txt"
Assert-Contains "zellij skip in cargo.ps1" "$ProjectRoot/src/platforms/windows/install/cargo.ps1" "zellij"
Assert-Contains "DRY_RUN in cargo.ps1" "$ProjectRoot/src/platforms/windows/install/cargo.ps1" "DRY_RUN"

# npm.ps1 content
Assert-Contains "npm install -g in npm.ps1" "$ProjectRoot/src/platforms/windows/install/npm.ps1" "npm install -g"
Assert-Contains "Read-PackageFile npm.txt in npm.ps1" "$ProjectRoot/src/platforms/windows/install/npm.ps1" "Read-PackageFile.*npm\.txt"
Assert-Contains "node check in npm.ps1" "$ProjectRoot/src/platforms/windows/install/npm.ps1" "Get-Command node"
Assert-Contains "DRY_RUN in npm.ps1" "$ProjectRoot/src/platforms/windows/install/npm.ps1" "DRY_RUN"

# ai-tools.ps1 content
Assert-Contains "prefix dispatch in ai-tools.ps1" "$ProjectRoot/src/platforms/windows/install/ai-tools.ps1" "switch.*prefix"
Assert-Contains "Ollama WinGet in ai-tools.ps1" "$ProjectRoot/src/platforms/windows/install/ai-tools.ps1" "Ollama\.Ollama"
Assert-Contains "Read-PackageFile ai-tools in ai-tools.ps1" "$ProjectRoot/src/platforms/windows/install/ai-tools.ps1" "Read-PackageFile.*ai-tools\.txt"
Assert-Contains "DRY_RUN in ai-tools.ps1" "$ProjectRoot/src/platforms/windows/install/ai-tools.ps1" "DRY_RUN"

# main.ps1 dispatch (replaces WARN checks)
Assert-Contains "cargo dispatch in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "install/cargo\.ps1"
Assert-Contains "npm dispatch in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "install/npm\.ps1"
Assert-Contains "ai-tools dispatch in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "install/ai-tools\.ps1"

Write-Host ""

#######################################
# 3. Anti-pattern checks (must NOT contain)
#######################################
Write-Host "--- Anti-pattern Checks ---"

Assert-NotContains "no Write-Error in logging.psm1" "$ProjectRoot/src/platforms/windows/core/logging.psm1" "Write-Error"
Assert-NotContains "no ErrorActionPreference Stop in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "ErrorActionPreference\s*=\s*'Stop'"
Assert-NotContains "no WARN skip for cargo in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "Cargo installer not yet implemented"
Assert-NotContains "no WARN skip for npm in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "npm installer not yet implemented"
Assert-NotContains "no WARN skip for ai-tools in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "AI tools installer not yet implemented"

Write-Host ""

#######################################
# 4. Phase 13: Windows Parity checks
#######################################
Write-Host "--- Phase 13: Windows Parity ---"

# progress.psm1 existence
Assert-Pass "progress.psm1 exists" {
    if (-not (Test-Path "$ProjectRoot/src/platforms/windows/core/progress.psm1")) { throw "missing" }
}

# setup.ps1 CLI switches
Assert-Contains "-DryRun switch in setup.ps1" "$ProjectRoot/setup.ps1" '\[switch\]\$DryRun'
Assert-Contains "-Verbose switch in setup.ps1" "$ProjectRoot/setup.ps1" '\[switch\]\$Verbose'
Assert-Contains "-Unattended switch in setup.ps1" "$ProjectRoot/setup.ps1" '\[switch\]\$Unattended'

# Environment variable mapping
Assert-Contains "DRY_RUN env mapping in setup.ps1" "$ProjectRoot/setup.ps1" "env:DRY_RUN.*=.*'true'"
Assert-Contains "VERBOSE env mapping in setup.ps1" "$ProjectRoot/setup.ps1" "env:VERBOSE.*=.*'true'"
Assert-Contains "UNATTENDED env mapping in setup.ps1" "$ProjectRoot/setup.ps1" "env:UNATTENDED.*=.*'true'"

# StartTime and summary
Assert-Contains "StartTime in setup.ps1" "$ProjectRoot/setup.ps1" "StartTime.*=.*Get-Date"
Assert-Contains "Show-CompletionSummary in setup.ps1" "$ProjectRoot/setup.ps1" "Show-CompletionSummary"

# progress.psm1 content
Assert-Contains "Show-DryRunBanner in progress.psm1" "$ProjectRoot/src/platforms/windows/core/progress.psm1" "function Show-DryRunBanner"
Assert-Contains "Get-PlatformStepCount in progress.psm1" "$ProjectRoot/src/platforms/windows/core/progress.psm1" "function Get-PlatformStepCount"
Assert-Contains "Show-CompletionSummary in progress.psm1" "$ProjectRoot/src/platforms/windows/core/progress.psm1" "function Show-CompletionSummary"
Assert-Contains "Export-ModuleMember in progress.psm1" "$ProjectRoot/src/platforms/windows/core/progress.psm1" "Export-ModuleMember"

# Step counters in main.ps1
Assert-Contains "Step counter pattern in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" '\[Step.*totalSteps'
Assert-Contains "Get-PlatformStepCount in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "Get-PlatformStepCount"
Assert-Contains "Show-DryRunBanner in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "Show-DryRunBanner"
Assert-Contains "progress.psm1 import in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "progress\.psm1"

# No CmdletBinding in scripts (only in module functions)
Assert-NotContains "no CmdletBinding in setup.ps1" "$ProjectRoot/setup.ps1" "CmdletBinding"
Assert-NotContains "no CmdletBinding in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "CmdletBinding"

# CmdletBinding in core modules (WPAR-04)
Assert-Contains "[CmdletBinding] in logging.psm1 Write-Log" "$ProjectRoot/src/platforms/windows/core/logging.psm1" "CmdletBinding"
Assert-Contains "[CmdletBinding] in errors.psm1 Add-FailedItem" "$ProjectRoot/src/platforms/windows/core/errors.psm1" "CmdletBinding"
Assert-Contains "[CmdletBinding] in packages.psm1 Read-PackageFile" "$ProjectRoot/src/platforms/windows/core/packages.psm1" "CmdletBinding"
Assert-Contains "[CmdletBinding] in idempotent.psm1" "$ProjectRoot/src/platforms/windows/core/idempotent.psm1" "CmdletBinding"

# Verify count: exactly 1 in logging, 4 in errors, 1 in packages, 3 in idempotent
Assert-Pass "logging.psm1 has 1 CmdletBinding" {
    $count = (Select-String -Path "$ProjectRoot/src/platforms/windows/core/logging.psm1" -Pattern 'CmdletBinding').Count
    if ($count -ne 1) { throw "expected 1, got $count" }
}
Assert-Pass "errors.psm1 has 4 CmdletBinding" {
    $count = (Select-String -Path "$ProjectRoot/src/platforms/windows/core/errors.psm1" -Pattern 'CmdletBinding').Count
    if ($count -ne 4) { throw "expected 4, got $count" }
}
Assert-Pass "packages.psm1 has 1 CmdletBinding" {
    $count = (Select-String -Path "$ProjectRoot/src/platforms/windows/core/packages.psm1" -Pattern 'CmdletBinding').Count
    if ($count -ne 1) { throw "expected 1, got $count" }
}
Assert-Pass "idempotent.psm1 has 3 CmdletBinding" {
    $count = (Select-String -Path "$ProjectRoot/src/platforms/windows/core/idempotent.psm1" -Pattern 'CmdletBinding').Count
    if ($count -ne 3) { throw "expected 3, got $count" }
}

# Anti-pattern: no ShouldProcess anywhere
Assert-NotContains "no ShouldProcess in logging.psm1" "$ProjectRoot/src/platforms/windows/core/logging.psm1" "ShouldProcess"
Assert-NotContains "no ShouldProcess in errors.psm1" "$ProjectRoot/src/platforms/windows/core/errors.psm1" "ShouldProcess"
Assert-NotContains "no ShouldProcess in packages.psm1" "$ProjectRoot/src/platforms/windows/core/packages.psm1" "ShouldProcess"
Assert-NotContains "no ShouldProcess in idempotent.psm1" "$ProjectRoot/src/platforms/windows/core/idempotent.psm1" "ShouldProcess"

# CmdletBinding in progress.psm1 (created in 13-01, should already have it)
Assert-Contains "[CmdletBinding] in progress.psm1" "$ProjectRoot/src/platforms/windows/core/progress.psm1" "CmdletBinding"

Write-Host ""

#######################################
# Summary
#######################################
Write-Host "========================================="
Write-Host "Results: $Passed passed, $Failed failed, $Total total"
Write-Host "========================================="
if ($Failed -eq 0) { exit 0 } else { exit 1 }
