#Requires -Version 5.1
#######################################
# Module: progress.psm1
# Description: Step counter helpers, DRY_RUN banner, and completion summary for UX feedback
# Author: Bragatte
# Date: 2026-02-18
#######################################
# PowerShell equivalent of src/core/progress.sh
# Show-DryRunBanner, Get-PlatformStepCount, Show-CompletionSummary

# Import logging module
Import-Module "$PSScriptRoot/logging.psm1" -Force

function Show-DryRunBanner {
    <#
    .SYNOPSIS
        Display a prominent banner when DRY_RUN=true.
    .DESCRIPTION
        Checks $env:DRY_RUN and displays a warning banner if active.
        No-op if DRY_RUN is not 'true'.
    #>
    [CmdletBinding()]
    param()

    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level WARN -Message '========================================='
        Write-Log -Level WARN -Message '  DRY RUN MODE - No changes will be made'
        Write-Log -Level WARN -Message '========================================='
    }
}

function Get-PlatformStepCount {
    <#
    .SYNOPSIS
        Count how many package files in a profile are relevant to Windows.
    .DESCRIPTION
        Reads a profile file and counts entries that map to Windows installers
        (winget.txt, cargo.txt, npm.txt, ai-tools.txt).
    .PARAMETER ProfileFile
        Path to the profile file.
    .OUTPUTS
        System.Int32
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileFile
    )

    if (-not (Test-Path $ProfileFile)) {
        return 0
    }

    $count = 0
    $entries = Get-Content -Path $ProfileFile -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    foreach ($entry in $entries) {
        switch ($entry) {
            'winget.txt'    { $count++ }
            'cargo.txt'     { $count++ }
            'npm.txt'       { $count++ }
            'ai-tools.txt'  { $count++ }
        }
    }

    return $count
}

function Show-CompletionSummary {
    <#
    .SYNOPSIS
        Display a rich end-of-run summary with profile, platform, duration, and results.
    .DESCRIPTION
        Mirrors src/core/progress.sh show_completion_summary().
        Shows banner, profile info, duration, and failure status.
    .PARAMETER Profile
        Profile name used for the run.
    .PARAMETER Platform
        Platform identifier (e.g. 'Windows').
    .PARAMETER StartTime
        DateTime when setup began, used to compute elapsed time.
    #>
    [CmdletBinding()]
    param(
        [string]$Profile = 'unknown',
        [string]$Platform = 'Windows',
        [Parameter(Mandatory = $true)]
        [datetime]$StartTime
    )

    $elapsed = (Get-Date) - $StartTime
    $mins = [math]::Floor($elapsed.TotalMinutes)
    $secs = $elapsed.Seconds

    # Read failure count from cross-process FAILURE_LOG file
    $failCount = 0
    $failItems = @()
    if ($env:FAILURE_LOG -and (Test-Path $env:FAILURE_LOG -ErrorAction SilentlyContinue)) {
        $failItems = Get-Content $env:FAILURE_LOG -ErrorAction SilentlyContinue
        if ($failItems) {
            $failCount = @($failItems).Count
        }
    }

    Write-Host ''
    if ($env:DRY_RUN -eq 'true') {
        Write-Log -Level BANNER -Message 'Dry Run Complete'
    } else {
        Write-Log -Level BANNER -Message 'Setup Complete'
    }

    Write-Log -Level INFO -Message "Profile:  $Profile"
    Write-Log -Level INFO -Message "Platform: $Platform"
    Write-Log -Level INFO -Message "Duration: ${mins}m ${secs}s"
    Write-Host ''

    if ($failCount -gt 0) {
        Write-Log -Level WARN -Message "Completed with $failCount failure(s)"
        Write-Host '  Failed items:'
        foreach ($item in $failItems) {
            Write-Host "    - $item"
        }
        Write-Host ''
    } else {
        Write-Log -Level OK -Message 'All sections completed successfully'
    }

    Write-Host ''
}

Export-ModuleMember -Function Show-DryRunBanner, Get-PlatformStepCount, Show-CompletionSummary
