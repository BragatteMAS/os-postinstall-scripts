#Requires -Version 5.1
#######################################
# Script: npm.ps1
# Description: Install npm global packages (data-driven)
# Author: Bragatte
# Date: 2026-02-17
#######################################
# PowerShell equivalent of npm global installs from src/install/fnm.sh
# Reads npm.txt from data/packages/ and installs each package via npm install -g
# Uses npm list -g for idempotent check (handles scoped packages like @scope/pkg)
# Failed installations tracked via Add-FailedItem for summary

$ErrorActionPreference = 'Continue'

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/packages.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force

#######################################
# Helper Functions
#######################################

function Test-NpmInstalled {
    <#
    .SYNOPSIS
        Check if an npm package is installed globally.
    .DESCRIPTION
        Uses npm list -g which works for both scoped (@scope/pkg) and unscoped packages.
        Per Phase 5 decision: scoped packages need npm-level check (not Get-Command).
    .PARAMETER PackageName
        The npm package name to check.
    .OUTPUTS
        System.Boolean - $true if installed globally, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    npm list -g $PackageName 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Install-NpmPackage {
    <#
    .SYNOPSIS
        Install a single npm package globally with idempotent check.
    .DESCRIPTION
        Checks if package is already installed before attempting install.
        Uses npm install -g for global installation.
        Tracks failures via Add-FailedItem.
    .PARAMETER PackageName
        The npm package name to install globally.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    # Idempotent check
    if (Test-NpmInstalled -PackageName $PackageName) {
        Write-Log -Level DEBUG -Message "Already installed: $PackageName"
        return
    }

    # DRY_RUN guard
    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level INFO -Message "[DRY_RUN] Would npm install -g: $PackageName"
        return
    }

    Write-Log -Level INFO -Message "Installing: $PackageName"

    npm install -g $PackageName 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level OK -Message "Installed: $PackageName"
    } else {
        Write-Log -Level WARN -Message "Failed to install: $PackageName"
        Add-FailedItem -Item $PackageName
    }
}

#######################################
# Main
#######################################

Write-Log -Level BANNER -Message 'NPM Global Package Installer'

# Node.js availability check
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Log -Level WARN -Message 'Node.js not found - skipping npm packages'
    Write-Host ''
    Write-Host '  Node.js is required for npm global packages.'
    Write-Host '  Install options:'
    Write-Host '    1. WinGet: winget install Schniz.fnm (winget.txt includes fnm)'
    Write-Host '    2. Download from: https://nodejs.org'
    Write-Host ''
    exit 0
}

# Also check npm specifically
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Log -Level WARN -Message 'npm not found - Node.js may be installed without npm'
    exit 0
}

# Load packages from data file
$Packages = Read-PackageFile -FileName 'npm.txt'

if ($Packages.Count -eq 0) {
    Write-Log -Level WARN -Message 'No packages to install'
    exit 0
}

Write-Log -Level INFO -Message "Loaded $($Packages.Count) packages from npm.txt"

# Install each package
foreach ($pkg in $Packages) {
    Install-NpmPackage -PackageName $pkg
}

# Summary
Show-FailureSummary
exit 0
