#Requires -Version 5.1
#######################################
# Module: idempotent.psm1
# Description: Shared idempotent check helpers for Windows installers
# Author: Bragatte
# Date: 2026-02-18
#######################################
# PowerShell equivalent of src/core/idempotent.sh
# Provides Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
# Each .ps1 installer imports this module independently (separate process scope)

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

function Test-NpmInstalled {
    <#
    .SYNOPSIS
        Check if an npm package is installed globally.
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

Export-ModuleMember -Function Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled
