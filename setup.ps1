#Requires -Version 5.1
#######################################
# setup.ps1 - Windows Post-Installation Entry Point
# Run with: powershell -ExecutionPolicy Bypass -File .\setup.ps1
#######################################
# Usage: .\setup.ps1 [-Profile <name>] [-Help]
#
# Profiles: minimal, developer, full
#
# This script detects Windows and runs the platform-specific installer.
#
# Environment variables:
#   VERBOSE=true    - Enable debug output and timestamps
#   NO_COLOR=1      - Disable colored output
#######################################

param(
    [string]$Profile = 'developer',
    [switch]$Help
)

$ErrorActionPreference = 'Continue'

# Help flag
if ($Help) {
    Write-Host 'Usage: .\setup.ps1 [-Profile <name>] [-Help]'
    Write-Host ''
    Write-Host 'Profiles:'
    Write-Host '  minimal    - Essential tools only'
    Write-Host '  developer  - Development environment (default)'
    Write-Host '  full       - Everything'
    Write-Host ''
    Write-Host 'Environment variables:'
    Write-Host '  VERBOSE=true    - Enable debug output and timestamps'
    Write-Host '  NO_COLOR=1      - Disable colored output'
    exit 0
}

# Import core modules
Import-Module "$PSScriptRoot/src/platforms/windows/core/logging.psm1" -Force
Import-Module "$PSScriptRoot/src/platforms/windows/core/errors.psm1" -Force

# Cross-process failure tracking (mirrors Bash FAILURE_LOG pattern)
$env:FAILURE_LOG = Join-Path ([System.IO.Path]::GetTempPath()) "ospostinstall-failures-$PID.log"

# Banner and profile info
Write-Log -Level BANNER -Message 'OS Post-Install Scripts (Windows)'
Write-Log -Level INFO -Message "Profile: $Profile"

# Dispatch to main.ps1
$MainScript = Join-Path $PSScriptRoot 'src' 'platforms' 'windows' 'main.ps1'

if (Test-Path -LiteralPath $MainScript -PathType Leaf) {
    & $MainScript -Profile $Profile
} else {
    Write-Log -Level ERROR -Message "Windows platform handler not found: $MainScript"
    exit 0
}

# Failure aggregation via $env:FAILURE_LOG file (cross-process tracking)
# Child processes write to this file via Add-FailedItem in errors.psm1
if ($env:FAILURE_LOG -and (Test-Path $env:FAILURE_LOG)) {
    $failures = Get-Content $env:FAILURE_LOG -ErrorAction SilentlyContinue
    if ($failures) {
        Write-Log -Level WARN -Message "Child process failures detected:"
        foreach ($item in $failures) {
            Write-Host "    - $item"
        }
    }
    Remove-Item $env:FAILURE_LOG -Force -ErrorAction SilentlyContinue
}

Write-Log -Level BANNER -Message 'Setup Complete'
exit 0
