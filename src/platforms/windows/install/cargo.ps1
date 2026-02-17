#Requires -Version 5.1
#######################################
# Script: cargo.ps1
# Description: Install Cargo (Rust) packages using WinGet-first strategy
# Author: Bragatte
# Date: 2026-02-17
#######################################
# PowerShell equivalent of src/platforms/linux/install/cargo.sh
# Reads cargo.txt from data/packages/ and installs each package
# Strategy: WinGet pre-built binary preferred, cargo install fallback
# Packages with no Windows support are skipped (zellij)
# Failed installations tracked via Add-FailedItem for summary

$ErrorActionPreference = 'Continue'

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/packages.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force

#######################################
# WinGet Mapping
#######################################
# Map cargo package names to WinGet IDs where pre-built binaries exist
# $null = no WinGet package available, use cargo install fallback

$script:WinGetMap = @{
    'bat'            = 'sharkdp.bat'
    'eza'            = 'eza-community.eza'
    'fd-find'        = 'sharkdp.fd'
    'lsd'            = 'lsd-rs.lsd'
    'ripgrep'        = 'BurntSushi.ripgrep.MSVC'
    'dust'           = 'bootandy.dust'
    'bottom'         = 'Clement.bottom'
    'procs'          = 'dalance.procs'
    'tokei'          = 'XAMPPRocky.tokei'
    'hyperfine'      = 'sharkdp.hyperfine'
    'zoxide'         = 'ajeetdsouza.zoxide'
    'git-delta'      = 'dandavison.delta'
    'gitui'          = 'Extrawurst.gitui'
    'starship'       = 'Starship.Starship'
    'nu'             = 'Nushell.Nushell'
    'helix'          = 'Helix.Helix'
    'atuin'          = 'atuinsh.atuin'
    'sd'             = $null
    'bacon'          = $null
    'xsv'            = $null
    'jql'            = $null
    'htmlq'          = $null
    'cargo-watch'    = $null
    'cargo-edit'     = $null
    'cargo-update'   = $null
    'cargo-audit'    = $null
    'cargo-expand'   = $null
    'cargo-outdated' = $null
    'cargo-binstall' = $null
}

# Packages with no Windows support at all
$script:SkipOnWindows = @('zellij')

#######################################
# Helper Functions
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

function Test-CargoInstalled {
    <#
    .SYNOPSIS
        Check if a cargo package is already installed via cargo install --list.
    .PARAMETER PackageName
        The cargo package name to check.
    .OUTPUTS
        System.Boolean - $true if installed, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $output = cargo install --list 2>$null
    if ($output -match "^$([regex]::Escape($PackageName)) ") {
        return $true
    }

    return $false
}

function Install-CargoPackage {
    <#
    .SYNOPSIS
        Install a single cargo package using WinGet-first strategy.
    .DESCRIPTION
        Three-tier logic:
        1. Check SkipOnWindows list (zellij)
        2. Try WinGet if mapping exists (pre-built binary)
        3. Fall back to cargo install if WinGet unavailable or fails
    .PARAMETER PackageName
        The cargo package name from cargo.txt.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    # Skip unsupported packages
    if ($PackageName -in $script:SkipOnWindows) {
        Write-Log -Level DEBUG -Message "Skipping $PackageName (not available on Windows)"
        return
    }

    # Strategy 1: WinGet (preferred - pre-built binary)
    if ($script:WinGetMap.ContainsKey($PackageName)) {
        $wingetId = $script:WinGetMap[$PackageName]

        if ($wingetId) {
            # Idempotent check via WinGet
            if (Test-WinGetInstalled -PackageId $wingetId) {
                Write-Log -Level DEBUG -Message "Already installed (WinGet): $PackageName"
                return
            }

            # DRY_RUN guard
            if ($env:DRY_RUN -eq 'true') {
                Write-Log -Level INFO -Message "[DRY_RUN] Would winget install: $PackageName ($wingetId)"
                return
            }

            Write-Log -Level INFO -Message "Installing via WinGet: $PackageName ($wingetId)"
            winget install --id $wingetId --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Log -Level OK -Message "Installed: $PackageName"
                return
            }

            Write-Log -Level WARN -Message "WinGet failed for $PackageName, trying cargo fallback..."
            # Fall through to cargo install
        }
        # $null mapping = no WinGet package, go directly to cargo fallback
    }

    # Strategy 2: cargo install (fallback)
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Write-Log -Level WARN -Message "Cargo not available, skipping: $PackageName"
        Add-FailedItem -Item $PackageName
        return
    }

    # Idempotent check via cargo
    if (Test-CargoInstalled -PackageName $PackageName) {
        Write-Log -Level DEBUG -Message "Already installed (cargo): $PackageName"
        return
    }

    # DRY_RUN guard
    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level INFO -Message "[DRY_RUN] Would cargo install: $PackageName"
        return
    }

    Write-Log -Level INFO -Message "Installing via cargo: $PackageName"
    cargo install $PackageName 2>$null

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

Write-Log -Level BANNER -Message 'Cargo Package Installer (WinGet-first)'

# WinGet availability check (not fatal -- cargo might still work)
$script:WinGetAvailable = $false
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $script:WinGetAvailable = $true
    Write-Log -Level DEBUG -Message 'WinGet available for pre-built binaries'
} else {
    Write-Log -Level WARN -Message 'WinGet not found -- will use cargo install only'
}

# Load packages from data file
$Packages = Read-PackageFile -FileName 'cargo.txt'

if ($Packages.Count -eq 0) {
    Write-Log -Level WARN -Message 'No packages to install'
    exit 0
}

Write-Log -Level INFO -Message "Loaded $($Packages.Count) packages from cargo.txt"

# Install each package
foreach ($pkg in $Packages) {
    Install-CargoPackage -PackageName $pkg
}

# Summary
Show-FailureSummary
exit 0
