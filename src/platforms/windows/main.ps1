#Requires -Version 5.1
#######################################
# Script: main.ps1
# Description: Main orchestrator for Windows post-installation
# Author: Bragatte
# Date: 2026-02-06
#######################################
# PowerShell equivalent of src/platforms/linux/main.sh
# Dual-mode: $Profile param for unattended, interactive menu otherwise
# Reads profile file directly, dispatches winget.txt to winget.ps1
# Non-Windows package files (apt.txt, brew.txt, etc.) silently skipped

param(
    [string]$Profile = ''
)

$ErrorActionPreference = 'Continue'

# Import core modules
$WindowsDir = $PSScriptRoot
Import-Module "$WindowsDir/core/logging.psm1" -Force
Import-Module "$WindowsDir/core/packages.psm1" -Force
Import-Module "$WindowsDir/core/errors.psm1" -Force

# Resolve project root and data directory
$ProjectRoot = (Resolve-Path "$WindowsDir/../../..").Path
$DataDir = Join-Path $ProjectRoot 'data'

#######################################
# Show-Menu
# Display Windows profile selection menu
#######################################
function Show-Menu {
    Write-Host ''
    Write-Host '=======================================================' -ForegroundColor Cyan
    Write-Host '         Windows Post-Installation Script               ' -ForegroundColor Cyan
    Write-Host '=======================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Select installation profile:'
    Write-Host '  1. Minimal   (essential packages only)'
    Write-Host '  2. Developer (system + dev tools + AI)'
    Write-Host '  3. Full      (everything)'
    Write-Host '  0. Exit'
    Write-Host ''
}

#######################################
# Install-Profile
# Install packages for a given profile
# Reads profile file directly (no Read-Profile abstraction)
# Dispatches winget.txt to winget.ps1, skips non-Windows files
#######################################
function Install-Profile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileName
    )

    Write-Log -Level INFO -Message "Profile: $ProfileName"

    # Read profile file directly (matching Linux main.sh pattern)
    $profileFile = Join-Path $DataDir 'packages' 'profiles' "$ProfileName.txt"
    if (-not (Test-Path $profileFile)) {
        Write-Log -Level ERROR -Message "Profile not found: $ProfileName"
        return
    }

    $entries = Get-Content -Path $profileFile -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    # Dispatch based on package file type (PLATFORM FILTERING)
    foreach ($pkgFile in $entries) {
        switch ($pkgFile) {
            'winget.txt' {
                Write-Log -Level INFO -Message 'Installing WinGet packages...'
                & "$WindowsDir/install/winget.ps1"
            }
            default {
                # Non-Windows package files (apt.txt, brew.txt, etc.): skip silently
                Write-Log -Level DEBUG -Message "Skipping $pkgFile (not a Windows package file)"
            }
        }
    }
}

#######################################
# Main: Dual-mode operation
# - With $Profile: unattended mode (called from setup.ps1)
# - Without $Profile: interactive menu
#######################################

# Unattended mode (profile passed as parameter)
if ($Profile -ne '') {
    Write-Log -Level INFO -Message "Running in unattended mode with profile: $Profile"
    Install-Profile -ProfileName $Profile
    exit 0
}

# Interactive mode: show menu loop
do {
    Show-Menu
    $choice = Read-Host 'Enter your choice (0-3)'

    switch ($choice) {
        '1' {
            Install-Profile -ProfileName 'minimal'
            Read-Host 'Press Enter to continue...'
        }
        '2' {
            Install-Profile -ProfileName 'developer'
            Read-Host 'Press Enter to continue...'
        }
        '3' {
            Install-Profile -ProfileName 'full'
            Read-Host 'Press Enter to continue...'
        }
        '0' {
            Show-FailureSummary
            Write-Log -Level INFO -Message 'Exiting...'
            exit 0
        }
        default {
            Write-Log -Level WARN -Message 'Invalid choice'
        }
    }
} while ($true)
