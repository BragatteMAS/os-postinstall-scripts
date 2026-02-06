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

# Summary and exit
Show-FailureSummary
Write-Log -Level BANNER -Message 'Setup Complete'
exit 0
