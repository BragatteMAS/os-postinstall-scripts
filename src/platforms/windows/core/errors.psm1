#Requires -Version 5.1
#######################################
# Module: errors.psm1
# Description: Error handling, failure tracking, and summary utilities
# Author: Bragatte
# Date: 2026-02-06
#######################################
# PowerShell equivalent of src/core/errors.sh
# Tracks failed items and shows summary at end
# Always exit 0 - failures shown in summary (pragmatic approach)

# Import logging module
Import-Module "$PSScriptRoot/logging.psm1" -Force

# Simple array for failure tracking
# For ~35 packages, += performance is irrelevant; KISS over ArrayList/List
$script:FailedItems = @()

function Add-FailedItem {
    <#
    .SYNOPSIS
        Record a failed item for the end-of-run summary.
    .DESCRIPTION
        Appends the item to the failure list and logs an error message.
    .PARAMETER Item
        Name or description of the failed item.
    .EXAMPLE
        Add-FailedItem -Item 'git'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Item
    )

    $script:FailedItems += $Item
    Write-Log -Level ERROR -Message "Failed: $Item"

    # Cross-process tracking via shared file (matches Bash FAILURE_LOG pattern)
    if ($env:FAILURE_LOG -and (Test-Path (Split-Path $env:FAILURE_LOG -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue)) {
        Add-Content -Path $env:FAILURE_LOG -Value $Item -Encoding UTF8
    }
}

function Show-FailureSummary {
    <#
    .SYNOPSIS
        Display summary of all failed items.
    .DESCRIPTION
        If no failures, shows success message. Otherwise lists all failed items.
    #>
    [CmdletBinding()]
    param()

    $count = $script:FailedItems.Count

    if ($count -eq 0) {
        Write-Log -Level OK -Message 'All operations completed successfully'
        return
    }

    Write-Log -Level WARN -Message "Summary: $count item(s) failed"
    foreach ($item in $script:FailedItems) {
        Write-Host "    - $item"
    }
}

function Get-FailureCount {
    <#
    .SYNOPSIS
        Return the number of failed items.
    .OUTPUTS
        System.Int32
    #>
    [CmdletBinding()]
    param()

    return $script:FailedItems.Count
}

function Clear-Failures {
    <#
    .SYNOPSIS
        Reset the failure tracking list.
    #>
    [CmdletBinding()]
    param()

    $script:FailedItems = @()
}

Export-ModuleMember -Function Add-FailedItem, Show-FailureSummary, Get-FailureCount, Clear-Failures
