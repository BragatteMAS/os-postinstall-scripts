#Requires -Version 5.1
#######################################
# Script: csv.ps1
# Description: Install Rust tools from data/packages.csv (data-driven)
# Author: Bragatte
# Date: 2026-10-08
#######################################
# PowerShell equivalent of src/core/csv.sh
# Reads the rows of one category (rust-cli, rust-dev, ...) and installs each
# tool from the `winget` column; a row without a winget ID falls back to cargo.
# Idempotent: a tool whose binary is already on the PATH is skipped.
# A row with no winget ID on a machine without cargo is reported as
# unavailable, not as a failure: Rust is not part of the Windows manifests.
# Failed installations tracked via Add-FailedItem for summary

# NOTE: param() must be the first statement in the script (see winget.ps1).
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^rust-[a-z]+$')]
    [string]$Category
)

$ErrorActionPreference = 'Continue'

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force
Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force

$ProjectRoot = (Resolve-Path "$PSScriptRoot/../../../..").Path
$CsvFile = Join-Path (Join-Path $ProjectRoot 'data') 'packages.csv'

#######################################
# Helper Functions
#######################################

function Read-CsvCategory {
    <#
    .SYNOPSIS
        Return the rows of data/packages.csv that belong to one category.
    .PARAMETER Path
        Path to packages.csv. Lines starting with # are comments.
    .PARAMETER Name
        Category to keep (column 1).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $rows = Get-Content -Path $Path -Encoding UTF8 |
        Where-Object { $_.Trim() -ne '' -and -not $_.TrimStart().StartsWith('#') } |
        ConvertFrom-Csv

    return ,@($rows | Where-Object { $_.category -eq $Name })
}

function Install-CsvTool {
    <#
    .SYNOPSIS
        Install one tool of the CSV and report what happened.
    .PARAMETER Row
        A row of packages.csv (name, cargo, binary, winget, ...).
    .OUTPUTS
        System.String - installed, skipped, unavailable or failed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Row
    )

    $name = $Row.name
    $bin = if ($Row.binary) { $Row.binary } else { $name }

    # Idempotent: skip if the binary is already on the PATH
    if (Get-Command $bin -ErrorAction SilentlyContinue) {
        Write-Log -Level DEBUG -Message "[skip] $name (already in PATH as $bin)"
        return 'skipped'
    }

    $hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    $hasCargo = [bool](Get-Command cargo -ErrorAction SilentlyContinue)

    if ($Row.winget -and $hasWinget) {
        if (Test-WinGetInstalled -PackageId $Row.winget) {
            Write-Log -Level DEBUG -Message "[skip] $name (winget has $($Row.winget))"
            return 'skipped'
        }
        if ($env:DRY_RUN -eq 'true') {
            Write-Log -Level INFO -Message "[DRY_RUN] Would winget install: $($Row.winget)"
            return 'installed'
        }
        Write-Log -Level INFO -Message "Installing $name (winget: $($Row.winget))"
        winget install --id $Row.winget --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log -Level OK -Message "Installed: $name"
            return 'installed'
        }
        Write-Log -Level WARN -Message "winget failed for $name (exit $LASTEXITCODE)"
    }

    if ($Row.cargo -and $hasCargo) {
        if (Test-CargoInstalled -PackageName $Row.cargo) {
            Write-Log -Level DEBUG -Message "[skip] $name (cargo has $($Row.cargo))"
            return 'skipped'
        }
        if ($env:DRY_RUN -eq 'true') {
            Write-Log -Level INFO -Message "[DRY_RUN] Would cargo install: $($Row.cargo)"
            return 'installed'
        }
        Write-Log -Level INFO -Message "Installing $name (cargo: $($Row.cargo))"
        # cargo-binstall downloads a release binary; cargo install compiles
        if (Get-Command cargo-binstall -ErrorAction SilentlyContinue) {
            cargo binstall -y --no-confirm $Row.cargo 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log -Level OK -Message "Installed: $name"
                return 'installed'
            }
        }
        cargo install $Row.cargo 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log -Level OK -Message "Installed: $name"
            return 'installed'
        }
        Write-Log -Level ERROR -Message "Failed to install: $name (cargo exit $LASTEXITCODE)"
        return 'failed'
    }

    # Nothing left to try. A winget attempt that ran and failed is a failure.
    # Otherwise the machine lacks the tool that could install it: no winget,
    # or a crates.io-only tool on a machine without cargo.
    if ($Row.winget -and $hasWinget) {
        Write-Log -Level ERROR -Message "Failed to install: $name"
        return 'failed'
    }
    $why = if ($Row.winget) { 'winget not found' } else { 'no winget package' }
    Write-Log -Level WARN -Message "Unavailable: $name ($why; cargo would need Rust: winget install Rustlang.Rustup)"
    return 'unavailable'
}

#######################################
# Main
#######################################

Write-Log -Level BANNER -Message "Rust Tools Installer (csv:$Category)"

if (-not (Test-Path -LiteralPath $CsvFile -PathType Leaf)) {
    Write-Log -Level WARN -Message "CSV not found: $CsvFile (csv:$Category skipped)"
    exit 1
}

$Rows = Read-CsvCategory -Path $CsvFile -Name $Category

# An unknown category must be a failure, never a silent success (same rule as
# install_csv_category in src/core/csv.sh).
if ($Rows.Count -eq 0) {
    Write-Log -Level WARN -Message "csv:$Category resolved 0 entries from $CsvFile"
    Add-FailedItem -Item "csv:$Category (0 entries)"
    Show-FailureSummary
    exit 1
}

# cargo installed by rustup earlier in this run is not on the PATH of the
# current session yet; add what the registry has.
if ($env:OS -eq 'Windows_NT') {
    $env:Path = @(
        $env:Path
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
    ) -join ';'
}

$counts = @{ installed = 0; skipped = 0; unavailable = 0; failed = 0 }
foreach ($row in $Rows) {
    $result = Install-CsvTool -Row $row
    $counts[$result]++
    if ($result -eq 'failed') { Add-FailedItem -Item "$($row.name) (csv:$Category)" }
}

Write-Log -Level INFO -Message ("Summary (csv:$Category): {0} installed, {1} skipped, {2} unavailable, {3} failed (total {4})" -f `
    $counts.installed, $counts.skipped, $counts.unavailable, $counts.failed, $Rows.Count)

# Summary
Show-FailureSummary
$exitCode = Get-ExitCode
exit $exitCode
