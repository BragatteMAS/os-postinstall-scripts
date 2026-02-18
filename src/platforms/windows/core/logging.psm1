#Requires -Version 5.1
#######################################
# Module: logging.psm1
# Description: Unified logging utilities with color support (SSoT)
# Author: Bragatte
# Date: 2026-02-06
#######################################
# PowerShell equivalent of src/core/logging.sh
# [OK]=Green, [ERROR]=Red, [WARN]=Yellow, [INFO]=Cyan, [DEBUG]=DarkGray
# VERBOSE controls timestamps and debug visibility
# NO_COLOR standard for CI/automation compatibility

function Write-Log {
    <#
    .SYNOPSIS
        Write a formatted log message with color and level prefix.
    .DESCRIPTION
        Single logging function with -Level parameter. Mirrors Bash logging.sh behavior.
        Supports OK, ERROR, WARN, INFO, DEBUG, and BANNER levels.
    .PARAMETER Level
        Log level: OK, ERROR, WARN, INFO, DEBUG, BANNER
    .PARAMETER Message
        The message to display.
    .EXAMPLE
        Write-Log -Level INFO -Message "Starting setup..."
        Write-Log -Level OK -Message "Package installed"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('OK','ERROR','WARN','INFO','DEBUG','BANNER')]
        [string]$Level = 'INFO',
        [string]$Message
    )

    # DEBUG only shown when VERBOSE=true
    if ($Level -eq 'DEBUG' -and $env:VERBOSE -ne 'true') {
        return
    }

    # Timestamp prefix when VERBOSE=true
    $prefix = ''
    if ($env:VERBOSE -eq 'true') {
        $prefix = '[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] '
    }

    # BANNER format: === Message ===
    if ($Level -eq 'BANNER') {
        $bannerText = "=== $Message ==="
        if ($env:NO_COLOR) {
            Write-Host $bannerText
        } else {
            Write-Host $bannerText -ForegroundColor Cyan
        }
        return
    }

    # Color mapping
    $colorMap = @{
        'OK'    = 'Green'
        'ERROR' = 'Red'
        'WARN'  = 'Yellow'
        'INFO'  = 'Cyan'
        'DEBUG' = 'DarkGray'
    }

    $color = $colorMap[$Level]
    $tag = "[$Level]"

    # Respect NO_COLOR standard (https://no-color.org)
    if ($env:NO_COLOR) {
        Write-Host "$tag ${prefix}${Message}"
    } else {
        Write-Host $tag -ForegroundColor $color -NoNewline
        Write-Host " ${prefix}${Message}"
    }
}

Export-ModuleMember -Function Write-Log
