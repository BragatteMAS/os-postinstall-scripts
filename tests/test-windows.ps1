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

Write-Host ""

#######################################
# 3. Anti-pattern checks (must NOT contain)
#######################################
Write-Host "--- Anti-pattern Checks ---"

Assert-NotContains "no Write-Error in logging.psm1" "$ProjectRoot/src/platforms/windows/core/logging.psm1" "Write-Error"
Assert-NotContains "no ErrorActionPreference Stop in main.ps1" "$ProjectRoot/src/platforms/windows/main.ps1" "ErrorActionPreference\s*=\s*'Stop'"

Write-Host ""

#######################################
# Summary
#######################################
Write-Host "========================================="
Write-Host "Results: $Passed passed, $Failed failed, $Total total"
Write-Host "========================================="
if ($Failed -eq 0) { exit 0 } else { exit 1 }
