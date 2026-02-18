#Requires -Version 5.1
#######################################
# setup.ps1 - Windows Post-Installation Entry Point
# Run with: powershell -ExecutionPolicy Bypass -File .\setup.ps1
#######################################
# Usage: .\setup.ps1 [-Profile <name>] [-DryRun] [-Verbose] [-Unattended] [-Help]
#
# Profiles: minimal, developer, full
#
# This script detects Windows and runs the platform-specific installer.
#
# Environment variables (set automatically by CLI switches):
#   DRY_RUN=true    - Set by -DryRun switch
#   UNATTENDED=true - Set by -Unattended switch
#   NO_COLOR=1      - Disable colored output
#######################################

param(
    [string]$Profile = 'developer',
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Unattended,
    [switch]$Help
)

$ErrorActionPreference = 'Continue'

# Map CLI switches to environment variables
if ($DryRun)     { $env:DRY_RUN = 'true' }
if ($Verbose)    { $env:VERBOSE = 'true' }
if ($Unattended) { $env:UNATTENDED = 'true' }

$StartTime = Get-Date

# Help flag
if ($Help) {
    Write-Host 'Usage: .\setup.ps1 [-Profile <name>] [-DryRun] [-Verbose] [-Unattended] [-Help]'
    Write-Host ''
    Write-Host 'Options:'
    Write-Host '  -DryRun      Show what would be done without making changes'
    Write-Host '  -Verbose     Enable debug output and timestamps'
    Write-Host '  -Unattended  Skip confirmation prompts'
    Write-Host '  -Help        Show this help message'
    Write-Host ''
    Write-Host 'Profiles:'
    Write-Host '  minimal    - Essential tools only'
    Write-Host '  developer  - Development environment (default)'
    Write-Host '  full       - Everything'
    Write-Host ''
    exit 0
}

# Import core modules
Import-Module "$PSScriptRoot/src/platforms/windows/core/logging.psm1" -Force
Import-Module "$PSScriptRoot/src/platforms/windows/core/errors.psm1" -Force
Import-Module "$PSScriptRoot/src/platforms/windows/core/progress.psm1" -Force

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

# Completion summary (reads FAILURE_LOG internally, shows profile/platform/duration/failures)
Show-CompletionSummary -Profile $Profile -Platform 'Windows' -StartTime $StartTime

# Cleanup failure log
if ($env:FAILURE_LOG -and (Test-Path $env:FAILURE_LOG)) {
    Remove-Item $env:FAILURE_LOG -Force -ErrorAction SilentlyContinue
}

exit 0
