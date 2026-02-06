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

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/packages.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force

#######################################
# WinGet Helper Functions
#######################################

function Test-WinGetInstalled {
    <#
    .SYNOPSIS
        Check if a WinGet package is already installed.
    .PARAMETER PackageId
        The exact WinGet package ID to check.
    .OUTPUTS
        System.Boolean - $true if installed, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($PackageId)) {
        return $true
    }

    return $false
}

function Install-WinGetPackage {
    <#
    .SYNOPSIS
        Install a single WinGet package idempotently.
    .DESCRIPTION
        Checks if package is already installed before attempting install.
        Uses --id --exact for precise matching, --silent for quiet install.
        Tracks failures via Add-FailedItem.
    .PARAMETER PackageId
        The exact WinGet package ID to install.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    # Idempotent check
    if (Test-WinGetInstalled -PackageId $PackageId) {
        Write-Log -Level DEBUG -Message "Already installed: $PackageId"
        return
    }

    Write-Log -Level INFO -Message "Installing: $PackageId"

    winget install --id $PackageId --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level OK -Message "Installed: $PackageId"
    } else {
        Write-Log -Level WARN -Message "Failed to install: $PackageId"
        Add-FailedItem -Item $PackageId
    }
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

exit 0
