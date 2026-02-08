#Requires -Version 5.1
#######################################
# terminal-setup.ps1
# One-script terminal transformation for Windows
#
# Installs modern CLI tools via WinGet, configures a minimal
# Starship prompt, adds productive aliases, and sets up
# PSReadLine — on any Windows machine with WinGet.
#
# Usage:
#   .\terminal-setup.ps1                  # full install (everything)
#   .\terminal-setup.ps1 -Interactive     # wizard mode (choose components)
#   .\terminal-setup.ps1 -DryRun         # preview changes
#
# From: https://github.com/BragatteMAS/os-postinstall-scripts
#######################################

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Interactive
)

# Feature flags (default: install everything)
$DoFont     = $true
$DoTools    = $true
$DoStarship = $true
$DoAliases  = $true

# ---- Logging Functions ------------------------------------------------

function Write-Info {
    param([string]$Message)
    if ($env:NO_COLOR) {
        Write-Host "[INFO] $Message"
    } else {
        Write-Host "[INFO]" -ForegroundColor Cyan -NoNewline
        Write-Host " $Message"
    }
}

function Write-Ok {
    param([string]$Message)
    if ($env:NO_COLOR) {
        Write-Host "  [OK] $Message"
    } else {
        Write-Host "  [OK]" -ForegroundColor Green -NoNewline
        Write-Host " $Message"
    }
}

function Write-Warn {
    param([string]$Message)
    if ($env:NO_COLOR) {
        Write-Host "[WARN] $Message"
    } else {
        Write-Host "[WARN]" -ForegroundColor Yellow -NoNewline
        Write-Host " $Message"
    }
}

function Write-Err {
    param([string]$Message)
    if ($env:NO_COLOR) {
        Write-Host "[ERROR] $Message"
    } else {
        Write-Host "[ERROR]" -ForegroundColor Red -NoNewline
        Write-Host " $Message"
    }
}

function Write-Dry {
    param([string]$Message)
    if ($env:NO_COLOR) {
        Write-Host "[DRY]  Would: $Message"
    } else {
        Write-Host "[DRY]" -ForegroundColor Yellow -NoNewline
        Write-Host "  Would: $Message"
    }
}

# ---- Interactive Wizard -----------------------------------------------

function Ask {
    param(
        [string]$Prompt,
        [string]$Default = 'y'
    )

    if ($Default -eq 'y') {
        $hint = '[Y/n]'
    } else {
        $hint = '[y/N]'
    }

    $response = Read-Host "  ? $Prompt $hint"

    if ([string]::IsNullOrWhiteSpace($response)) {
        $response = $Default
    }

    return ($response -match '^[Yy]')
}

function Invoke-Wizard {
    Write-Host ''
    Write-Host 'Choose what to install:' -ForegroundColor White
    Write-Host ''

    if (-not (Ask -Prompt 'Nerd Font (JetBrainsMono)?' -Default 'y')) {
        $script:DoFont = $false
    }
    if (-not (Ask -Prompt 'CLI tools (bat, eza, fd, rg, delta, zoxide, starship)?' -Default 'y')) {
        $script:DoTools = $false
    }
    if (-not (Ask -Prompt 'Starship prompt config?' -Default 'y')) {
        $script:DoStarship = $false
    }
    if (-not (Ask -Prompt 'Shell aliases (40+ shortcuts)?' -Default 'y')) {
        $script:DoAliases = $false
    }

    Write-Host ''
}

# ---- WinGet Detection + Tool Installation -----------------------------

function Test-WinGetInstalled {
    param([string]$PackageId)

    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($PackageId)) {
        return $true
    }
    return $false
}

function Install-CliTools {
    Write-Info 'Installing modern CLI tools...'

    $tools = @(
        @{ Name = 'bat';      Id = 'sharkdp.bat' }
        @{ Name = 'eza';      Id = 'eza-community.eza' }
        @{ Name = 'fd';       Id = 'sharkdp.fd' }
        @{ Name = 'ripgrep';  Id = 'BurntSushi.ripgrep.MSVC' }
        @{ Name = 'delta';    Id = 'dandavison.delta' }
        @{ Name = 'zoxide';   Id = 'ajeetdsouza.zoxide' }
        @{ Name = 'starship'; Id = 'Starship.Starship' }
    )

    foreach ($tool in $tools) {
        if (Test-WinGetInstalled -PackageId $tool.Id) {
            Write-Ok $tool.Name
        } else {
            if ($DryRun) {
                Write-Dry "winget install --id $($tool.Id) --exact --silent"
            } else {
                Write-Info "Installing: $($tool.Name)"
                winget install --id $tool.Id --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok $tool.Name
                } else {
                    Write-Warn "Failed to install: $($tool.Name) ($($tool.Id))"
                }
            }
        }
    }
}

# ---- Nerd Font Installation (per-user, no admin) ---------------------

function Install-NerdFont {
    Write-Info 'Installing JetBrainsMono Nerd Font (per-user)...'

    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $checkFile = Join-Path $fontDir 'JetBrainsMonoNerdFont-Regular.ttf'

    # Idempotency check
    if (Test-Path $checkFile) {
        Write-Ok 'JetBrainsMono Nerd Font'
        return
    }

    if ($DryRun) {
        Write-Dry 'Download and install JetBrainsMono Nerd Font to per-user font directory'
        return
    }

    $downloadUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
    $tempDir = Join-Path $env:TEMP "nerd-font-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $zipFile = Join-Path $tempDir 'JetBrainsMono.zip'

    try {
        # Create temp and font directories
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        if (-not (Test-Path $fontDir)) {
            New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
        }

        # Download
        Write-Info 'Downloading from GitHub releases...'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing

        # Extract
        Write-Info 'Extracting fonts...'
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

        # Copy TTF files and register in registry
        $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        $ttfFiles = Get-ChildItem -Path $tempDir -Filter '*.ttf' -Recurse
        foreach ($ttf in $ttfFiles) {
            $dest = Join-Path $fontDir $ttf.Name
            Copy-Item -Path $ttf.FullName -Destination $dest -Force

            # Register font for current user
            $fontName = [System.IO.Path]::GetFileNameWithoutExtension($ttf.Name)
            New-ItemProperty -Path $regPath -Name "$fontName (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
        }

        Write-Ok "JetBrainsMono Nerd Font ($($ttfFiles.Count) files)"
    }
    catch {
        Write-Err "Font installation failed: $_"
    }
    finally {
        # Cleanup temp files
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ---- Starship Config -------------------------------------------------

function Install-StarshipConfig {
    Write-Info 'Configuring starship prompt...'

    $configDir = Join-Path $HOME '.config'
    $configFile = Join-Path $configDir 'starship.toml'

    if (-not (Test-Path $configDir)) {
        if ($DryRun) {
            Write-Dry "Create directory: $configDir"
        } else {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
    }

    # Backup existing config
    if (Test-Path $configFile) {
        $backupFile = "$configFile.bak.$(Get-Date -Format 'yyyy-MM-dd')"
        if ($DryRun) {
            Write-Dry "Backup $configFile -> $backupFile"
        } else {
            Copy-Item -Path $configFile -Destination $backupFile -Force
            Write-Warn "Backed up existing starship.toml -> $backupFile"
        }
    }

    if ($DryRun) {
        Write-Dry "Write starship.toml to $configFile"
        return
    }

    $starshipConfig = @'
"$schema" = "https://starship.rs/config-schema.json"

format = """
$directory\
$git_branch\
$git_status\
$cmd_duration\
$line_break\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold purple"

[git_status]
format = "[$all_status$ahead_behind]($style) "
style = "bold red"

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "
style = "bold yellow"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[package]
disabled = true
[nodejs]
disabled = true
[python]
disabled = true
[rust]
disabled = true
[golang]
disabled = true
[java]
disabled = true
[ruby]
disabled = true
[php]
disabled = true
[docker_context]
disabled = true
[kubernetes]
disabled = true
[aws]
disabled = true
[gcloud]
disabled = true
[azure]
disabled = true
'@

    Set-Content -Path $configFile -Value $starshipConfig -Encoding UTF8
    Write-Ok "Starship config written to $configFile"
}

# ---- Profile Setup ---------------------------------------------------

function Install-ProfileConfig {
    Write-Info "Configuring PowerShell profile ($PROFILE)..."

    $marker = '# --- terminal-setup.ps1 ---'
    $endMarker = '# --- end terminal-setup.ps1 ---'

    # Create profile parent directory if missing
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) {
        if ($DryRun) {
            Write-Dry "Create directory: $profileDir"
        } else {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
    }

    # Create profile file if missing
    if (-not (Test-Path $PROFILE)) {
        if ($DryRun) {
            Write-Dry "Create profile: $PROFILE"
        } else {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        }
    }

    # Idempotency: check for marker
    if (-not $DryRun) {
        $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($profileContent) -and $profileContent.Contains($marker)) {
            Write-Ok "Already configured in $PROFILE"
            return
        }
    }

    # Backup existing profile
    if ((Test-Path $PROFILE) -and (Get-Item $PROFILE).Length -gt 0) {
        $backupFile = "$PROFILE.bak.$(Get-Date -Format 'yyyy-MM-dd')"
        if ($DryRun) {
            Write-Dry "Backup $PROFILE -> $backupFile"
        } else {
            Copy-Item -Path $PROFILE -Destination $backupFile -Force
            Write-Info "Backed up -> $backupFile"
        }
    }

    if ($DryRun) {
        Write-Dry "Append aliases + PSReadLine + starship init to $PROFILE"
        return
    }

    # Build the profile block
    $profileBlock = @"

$marker

# PSReadLine configuration
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

"@

    if ($DoAliases) {
        $profileBlock += @'

# --- Aliases and Functions ---

# Remove built-in aliases that conflict with modern tools
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
Remove-Item Alias:curl -Force -ErrorAction SilentlyContinue
Remove-Item Alias:diff -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

# Modern tool replacements (with fallback)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat --paging=never @args }
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls  { eza @args }
    function ll  { eza -la --git --group-directories-first @args }
    function la  { eza -a @args }
    function lt  { eza --tree --level=2 @args }
} else {
    function ll  { Get-ChildItem -Force @args }
    function la  { Get-ChildItem -Force @args }
}

if (Get-Command rg -ErrorAction SilentlyContinue) {
    function grep { rg @args }
}

if (Get-Command fd -ErrorAction SilentlyContinue) {
    function find { fd @args }
}

if (Get-Command delta -ErrorAction SilentlyContinue) {
    function diff { delta @args }
}

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Git shortcuts
function gs  { git status @args }
function gd  { git diff @args }
function ga  { git add @args }
function gc  { git commit @args }
function gp  { git push @args }
function gpl { git pull @args }
function gl  { git log --oneline -20 @args }
function glo { git log --oneline --graph --all @args }
function gb  { git branch @args }

# Utility aliases
Set-Alias -Name h -Value Get-History -Force
Set-Alias -Name c -Value Clear-Host -Force

'@
    }

    $profileBlock += @'

# Zoxide (smarter cd)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Starship prompt (must be last)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

'@

    $profileBlock += $endMarker

    Add-Content -Path $PROFILE -Value $profileBlock -Encoding UTF8
    Write-Ok "Profile configured: $PROFILE"
}

# ---- Main Entry Point ------------------------------------------------

function Main {
    Write-Host ''
    Write-Host 'Terminal Setup' -ForegroundColor White -NoNewline
    Write-Host ' - from os-postinstall-scripts'
    Write-Host 'https://github.com/BragatteMAS/os-postinstall-scripts'
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY-RUN MODE - no changes will be made' -ForegroundColor Yellow
        Write-Host ''
    }

    # WinGet detection
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Err 'WinGet not found'
        Write-Host ''
        Write-Host '  WinGet is required but not installed.'
        Write-Host '  Install options:'
        Write-Host "    1. Update 'App Installer' from Microsoft Store"
        Write-Host '    2. Download from: https://aka.ms/getwinget'
        Write-Host '    3. Windows 11 includes WinGet by default'
        Write-Host ''
        exit 0
    }

    Write-Ok 'Detected: Windows (WinGet) - PowerShell'

    # Interactive wizard
    if ($Interactive) {
        Invoke-Wizard
    }

    # Conditional execution based on feature flags
    if ($DoFont) {
        Install-NerdFont
    }

    if ($DoTools) {
        Install-CliTools
    }

    if ($DoStarship) {
        Install-StarshipConfig
    }

    Install-ProfileConfig

    Write-Host ''
    Write-Ok 'Done! Restart your terminal or open a new PowerShell window.'

    if ($DoFont) {
        Write-Host ''
        Write-Host 'IMPORTANT:' -ForegroundColor Yellow -NoNewline
        Write-Host ' Set your terminal font to ' -NoNewline
        Write-Host 'JetBrainsMono Nerd Font' -ForegroundColor White
        Write-Host '           in Windows Terminal Settings > Profiles > Appearance for icons to display correctly.'
    }

    Write-Host ''
}

Main
