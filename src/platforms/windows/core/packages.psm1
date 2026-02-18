#Requires -Version 5.1
#######################################
# Module: packages.psm1
# Description: Package loading utilities for data-driven installation
# Author: Bragatte
# Date: 2026-02-06
#######################################
# PowerShell equivalent of src/core/packages.sh
# Reads package list files from data/packages/
# Trims whitespace, skips comments (#) and blank lines
# Returns string array of package names

# Directory setup - resolve project root via Resolve-Path
$script:ProjectRoot = (Resolve-Path "$PSScriptRoot/../../../..").Path
$script:DataDir = Join-Path $script:ProjectRoot 'data'

function Read-PackageFile {
    <#
    .SYNOPSIS
        Read a package list file and return package names as a string array.
    .DESCRIPTION
        Reads a text file with one package per line. Trims whitespace,
        skips blank lines and lines starting with #.
        If FileName is not an absolute path, resolves relative to data/packages/.
    .PARAMETER FileName
        File name (relative to data/packages/) or absolute path.
    .OUTPUTS
        System.String[] - Array of package names.
    .EXAMPLE
        $packages = Read-PackageFile -FileName 'winget.txt'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    # Resolve path: absolute or relative to DataDir/packages/
    if ([System.IO.Path]::IsPathRooted($FileName)) {
        $filePath = $FileName
    } else {
        $filePath = Join-Path (Join-Path $script:DataDir 'packages') $FileName
    }

    # Check file exists
    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        Write-Warning "Package file not found: $filePath"
        return @()
    }

    # Read, trim, filter comments and blank lines
    $packages = @()
    $lines = Get-Content -Path $filePath -Encoding UTF8

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        # Skip blank lines and comments
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) {
            continue
        }

        $packages += $trimmed
    }

    return ,$packages
}

Export-ModuleMember -Function Read-PackageFile
