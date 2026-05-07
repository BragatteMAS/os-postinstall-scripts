#Requires -Version 5.1
#######################################
# Script: winget.ps1
# Description: Install WinGet packages (data-driven)
# Author: Bragatte
# Date: 2026-02-06
#######################################
# PowerShell equivalent of src/platforms/linux/install/apt.sh
# Reads winget.txt from data/packages/ and installs each package idempotently
# Uses winget list --id --exact for idempotent check before install
# Failed installations tracked via Add-FailedItem for summary

$ErrorActionPreference = 'Continue'

# Accept which winget file to load (winget.txt | winget-developer.txt | winget-full.txt)
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('winget.txt', 'winget-developer.txt', 'winget-full.txt')]
    [string]$PackageFile = 'winget.txt'
)

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/packages.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force
Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force

#######################################
# WinGet Helper Functions
#######################################

function Install-WinGetPackage {
    <#
    .SYNOPSIS
        Install a single WinGet package idempotently with failure classifier.
    .DESCRIPTION
        Checks if package is already installed before attempting install.
        Uses --id --exact for precise matching, --silent for quiet install.
        On failure, classifies the error (package missing, hash mismatch,
        already installed, network) and emits an actionable hint. Mirrors
        the brew-cask.sh classifier pattern from v5.4.2.
    .PARAMETER PackageId
        The exact WinGet package ID to install.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    if (Test-WinGetInstalled -PackageId $PackageId) {
        Write-Log -Level DEBUG -Message "Already installed: $PackageId"
        return
    }

    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level INFO -Message "[DRY_RUN] Would winget install: $PackageId"
        return
    }

    Write-Log -Level INFO -Message "Installing: $PackageId"

    $errBuf = winget install --id $PackageId --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>&1 | Out-String
    $rc = $LASTEXITCODE

    if ($rc -eq 0) {
        Write-Log -Level OK -Message "Installed: $PackageId"
        return
    }

    $reason = "exit $rc"
    $hint = ''
    if ($errBuf -match 'No package found matching|No applicable upgrade found') {
        $reason = 'package not found in winget source'
        $hint = "Fix: winget search $PackageId  (find correct ID; check casing)"
    }
    elseif ($errBuf -match 'already installed|is already in scope') {
        $reason = 'already installed (state file out of sync)'
        $hint = "Fix: winget list --id $PackageId  (verify); next setup will reconcile"
    }
    elseif ($errBuf -match 'hash.*mismatch|installer hash') {
        $reason = 'installer hash mismatch (winget manifest stale)'
        $hint = 'Fix: winget source update  (refresh manifest cache); then re-run'
    }
    elseif ($errBuf -match '0x80072|connection|network|timeout|HRESULT 0x800704C') {
        $reason = 'network error'
        $hint = 'Fix: re-run setup.ps1 — idempotent, only retries the missing items'
    }

    Write-Log -Level ERROR -Message "Failed to install: $PackageId ($reason)"
    if ($hint -ne '') { Write-Log -Level INFO -Message "  -> $hint" }
    Add-FailedItem -Item $PackageId
}

#######################################
# Main
#######################################

Write-Log -Level BANNER -Message 'WinGet Package Installer'

# WinGet availability check
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log -Level ERROR -Message 'WinGet not found'
    Write-Host ''
    Write-Host '  WinGet is required but not installed.'
    Write-Host '  Install options:'
    Write-Host "    1. Update 'App Installer' from Microsoft Store"
    Write-Host '    2. Download from: https://aka.ms/getwinget'
    Write-Host '    3. Windows 11 includes WinGet by default'
    Write-Host ''
    exit 0
}

# Load packages from data file
$Packages = Read-PackageFile -FileName 'winget.txt'

if ($Packages.Count -eq 0) {
    Write-Log -Level WARN -Message 'No packages to install'
    exit 0
}

Write-Log -Level INFO -Message "Loaded $($Packages.Count) packages from winget.txt"

# Install each package
foreach ($pkg in $Packages) {
    Install-WinGetPackage -PackageId $pkg
}

# Summary (failures tracked in THIS process scope -- callers can't see them)
Show-FailureSummary
$exitCode = Get-ExitCode
exit $exitCode
