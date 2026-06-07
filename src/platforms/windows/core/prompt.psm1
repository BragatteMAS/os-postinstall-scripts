#Requires -Version 5.1
#######################################
# Module: prompt.psm1
# Description: Single source of truth for default-bearing prompts (SSoT)
# Author: Bragatte
# Date: 2026-06-07
#######################################
# PowerShell sibling of src/core/prompt.sh::prompt_default - same contract:
#   - The visible prompt reads:  <Text> [<Keys>, default=<Default>]:
#   - <Default> is BOTH displayed and returned, so they cannot diverge - the
#     bug class fixed piecemeal on the bash side across v5.4.0/v5.4.4/v5.4.6.
#   - NONINTERACTIVE=true, a non-interactive host, and empty input all resolve
#     to <Default>; the unattended pick logs "Auto-selected: <Default>".
#   - Returns ONLY the resolved value on the output stream (Write-Log uses
#     Write-Host, so logging never pollutes a captured result).
# Timeout is intentionally omitted: no Windows prompt needs one (the bash
# siblings use a timeout only for the dev-env opt-ins, which Windows lacks).

# Defensive: Read-Default needs Write-Log for the unattended notice.
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    Import-Module "$PSScriptRoot/logging.psm1" -Force
}

function Read-Default {
    <#
    .SYNOPSIS
        Prompt for one choice, rendering a hint that cannot lie about the default.
    .PARAMETER Text
        Prompt text (NO trailing hint - it is rendered here).
    .PARAMETER Default
        Value displayed AND returned on empty input or a non-interactive host.
    .PARAMETER Keys
        Keys label shown in brackets (e.g. '0-3', 'Y/n'). Optional.
    .EXAMPLE
        $choice = Read-Default -Text 'Enter your choice' -Default '2' -Keys '0-3'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Default,
        [string]$Keys = ''
    )

    # Render the hint FROM the default so display and behaviour stay in lockstep.
    if ($Keys -ne '') {
        $hint = "[$Keys, default=$Default]"
    } else {
        $hint = "[default=$Default]"
    }

    # Unattended / non-interactive host: take the default and announce it.
    $interactive = ($env:NONINTERACTIVE -ne 'true') -and
                   [Environment]::UserInteractive -and
                   -not [Console]::IsInputRedirected
    if (-not $interactive) {
        Write-Log -Level INFO -Message "Auto-selected: $Default"
        return $Default
    }

    $answer = Read-Host "$Text $hint"
    if ([string]::IsNullOrEmpty($answer)) {
        return $Default
    }
    return $answer
}

Export-ModuleMember -Function Read-Default
