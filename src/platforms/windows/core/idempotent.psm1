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
    [CmdletBinding()]
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
    [CmdletBinding()]
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $output = (cargo install --list 2>$null) -join "`n"
    if ($output -match "(?m)^$([regex]::Escape($PackageName)) ") {
        return $true
    }

    return $false
}

function Test-BunInstalled {
    <#
    .SYNOPSIS
        Check if a package is installed globally with bun.
    .PARAMETER PackageName
        The package name, with or without a version suffix (e.g., "@openai/codex@latest").
    .OUTPUTS
        System.Boolean - $true if installed globally, $false otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    # Drop a trailing @version; the leading @ of a scoped package stays
    $name = $PackageName -replace '(?<=.)@[^@/]*$', ''
    $listed = bun pm ls -g 2>$null
    if ($LASTEXITCODE -ne 0) { return $false }
    return [bool]($listed | Select-String -SimpleMatch -Pattern " $name@" -Quiet)
}

function Test-UvToolInstalled {
    <#
    .SYNOPSIS
        Check if a tool is installed with uv tool.
    .PARAMETER ToolName
        The tool name or a git+URL; a URL is listed under its repository name.
    .OUTPUTS
        System.Boolean - $true if installed, $false otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    $name = $ToolName
    if ($name -like 'git+*') {
        $name = ($name -replace '\.git$', '').TrimEnd('/').Split('/')[-1]
    }
    $listed = uv tool list 2>$null
    if ($LASTEXITCODE -ne 0) { return $false }
    return [bool]($listed | Select-String -Pattern ('^' + [regex]::Escape($name) + ' ') -Quiet)
}

Export-ModuleMember -Function Test-WinGetInstalled, Test-NpmInstalled, Test-CargoInstalled, Test-BunInstalled, Test-UvToolInstalled
