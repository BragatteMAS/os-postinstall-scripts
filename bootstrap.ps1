#Requires -Version 5.1
#######################################
# bootstrap.ps1 - Pre-requisites for os-postinstall-scripts on Windows
#
# Run BEFORE setup.ps1. Verifies and installs the minimum needed:
#   - winget (App Installer; ships with Windows 10 1809+ / Windows 11)
#   - Git for Windows
#
# Idempotent. Safe to run multiple times.
#
# Usage: powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
#
# After this, run: .\setup.ps1
#######################################

$ErrorActionPreference = 'Stop'

function Write-Bold($msg) { Write-Host $msg -ForegroundColor White }
function Write-OK($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red }

Write-Bold "os-postinstall-scripts bootstrap (Windows)"
Write-Host "Detected OS: Windows ($([System.Environment]::OSVersion.Version))"
Write-Host ""

# 1. winget (App Installer)
$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Warn "winget not found."
    Write-Host "    Update 'App Installer' from Microsoft Store, then re-run this script."
    Write-Host "    Or install manually: https://github.com/microsoft/winget-cli/releases"
    exit 1
}
Write-OK "winget: $(winget --version)"

# 2. Git
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "[*] Installing Git via winget..."
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail "Git installed but not on PATH. Close and reopen PowerShell, then re-run."
        exit 1
    }
}
Write-OK "git: $(git --version)"

# 3. Git submodules
if (Test-Path .gitmodules) {
    $status = git submodule status 2>&1
    if ($status -match '^-') {
        Write-Host "[*] Initializing git submodules..."
        git submodule update --init --recursive
        Write-OK "Submodules ready"
    } else {
        Write-OK "Submodules already initialized"
    }
}

Write-Host ""
Write-OK "Bootstrap complete."
Write-Host ""
Write-Bold "Next steps:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun                 # preview"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Profile developer      # install (default)"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Profile full           # everything + personal pick"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Profile minimal        # essentials only"
