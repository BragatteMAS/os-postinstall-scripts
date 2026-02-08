# Phase 8.1: Terminal Setup for Windows — Execution Plan

---
wave: 1
depends_on: []
files_modified:
  - examples/terminal-setup.ps1
autonomous: true
---

## Goal

Create `examples/terminal-setup.ps1` — a **standalone** PowerShell script that provides an interactive terminal configuration wizard for Windows, equivalent to the existing `examples/terminal-setup.sh` (Unix).

The script installs modern CLI tools via WinGet, a Nerd Font (per-user, no admin), the Starship prompt, PowerShell aliases with fallbacks, and PSReadLine configuration — all in a single copy-paste-and-run file targeting PowerShell 5.1+.

## must_haves

Derived from the phase goal (goal-backward verification):

1. **Single standalone file** at `examples/terminal-setup.ps1` — no imports, no dependencies on repo modules
2. **PowerShell 5.1 minimum** — no PS 7-only syntax (no `??`, no ternary, no `&&`/`||` pipeline chains)
3. **Interactive wizard mode** (`-Interactive`) matching terminal-setup.sh wizard flow
4. **Dry-run mode** (`-DryRun`) that previews all changes without executing
5. **WinGet CLI tool installation** (bat, eza, fd, ripgrep, delta, zoxide, starship) with idempotent checks
6. **Nerd Font per-user installation** (JetBrainsMono) via GitHub release download — no admin required
7. **Starship config** written to `~/.config/starship.toml` with ASCII-safe symbols
8. **PowerShell profile configuration** — aliases (wrapper functions for parameterized commands), PSReadLine, zoxide init, starship init
9. **Idempotency** — marker-based profile detection, font existence check, WinGet pre-install check
10. **Colored logging** matching the Bash script's log levels (INFO, OK, WARN, ERROR, DRY)

## Tasks

<task id="1" name="create-terminal-setup-ps1">
<title>Create examples/terminal-setup.ps1</title>
<description>
Create the complete standalone PowerShell script at `examples/terminal-setup.ps1`.

**Structure** (mirror terminal-setup.sh section order):

```
1. Header comment block (usage docs, URL)
2. #Requires -Version 5.1
3. param block: -DryRun [switch], -Interactive [switch]
4. Feature flags: $DoFont, $DoTools, $DoStarship, $DoAliases (default $true)
5. Logging functions: Write-Info, Write-Ok, Write-Warn, Write-Error, Write-Dry
6. Interactive wizard: Ask function + wizard flow
7. WinGet detection + tool installation (idempotent)
8. Nerd Font installation (per-user, no admin)
9. Starship config writer
10. Profile setup (detect PS version, backup, marker check, append config block)
11. Main entry point
```

**Key implementation details:**

### Param Block
```powershell
#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Interactive
)
```

### Logging (standalone — do NOT import logging.psm1)
- `Write-Info` — Cyan `[INFO]`
- `Write-Ok` — Green `[OK]`  (indent 2 spaces like Bash)
- `Write-Warn` — Yellow `[WARN]`
- `Write-Error` — Red `[ERROR]` (use Write-Host to avoid PS error stream — name the function `Write-Err` to avoid conflict with built-in)
- `Write-Dry` — Yellow `[DRY]`
- Respect `$env:NO_COLOR` standard

### Interactive Wizard
```powershell
function Ask {
    param([string]$Prompt, [string]$Default = 'y')
    # Return $true/$false
}
```
Wizard prompts: Font, CLI tools, Starship config, Shell aliases (4 items — no zsh plugins on Windows)

### WinGet Detection
- `Get-Command winget -ErrorAction SilentlyContinue`
- If missing: print install instructions (match existing winget.ps1 messaging), exit 0
- WinGet package IDs:
  - `sharkdp.bat`
  - `eza-community.eza`
  - `sharkdp.fd`
  - `BurntSushi.ripgrep.MSVC`
  - `dandavison.delta`
  - `ajeetdsouza.zoxide`
  - `Starship.Starship`

### Idempotent Install Pattern
```powershell
function Test-WinGetInstalled {
    param([string]$PackageId)
    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($PackageId)) {
        return $true
    }
    return $false
}
```
Then for each tool: check -> skip if installed -> install if missing -> report result.
Wrap install call in DryRun check.

### Nerd Font Installation
- Font dir: `$env:LOCALAPPDATA\Microsoft\Windows\Fonts`
- Registry: `HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts`
- Idempotency check: `Test-Path "$fontDir\JetBrainsMonoNerdFont-Regular.ttf"`
- Download URL: `https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip`
- Use `Invoke-WebRequest -UseBasicParsing` (PS 5.1 compatibility)
- `Expand-Archive` for extraction
- Copy all `.ttf` files to font dir
- Register each in HKCU registry
- Clean up temp files
- Wrap in DryRun check

### Starship Config
- Config dir: `Join-Path $HOME '.config'`
- Config file: `Join-Path $configDir 'starship.toml'`
- Backup existing if present
- Write TOML content — SAME as terminal-setup.sh BUT with ASCII-safe character symbols:
  - `success_symbol = "[>](bold green)"` (not Unicode arrows)
  - `error_symbol = "[>](bold red)"` (not Unicode arrows)
  - `symbol = " "` for git_branch (space only, the Nerd Font glyph is optional)
- Use `Set-Content -Encoding UTF8`

### Profile Setup
- Use `$PROFILE` automatic variable (handles PS 5.1 vs 7+ paths)
- Create profile file if missing: `New-Item -ItemType File -Path $PROFILE -Force`
- Create parent directory if missing
- Marker: `# --- terminal-setup.ps1 ---`
- Check for marker before appending (idempotency)
- Backup existing profile: `$PROFILE.bak.yyyy-MM-dd`
- Profile content block includes:
  1. PSReadLine configuration (PredictionSource History, arrow key history search, Tab MenuComplete)
  2. Built-in alias removal (`Remove-Item Alias:cat`, `Remove-Item Alias:curl`, etc.) with `-ErrorAction SilentlyContinue`
  3. Tool replacement functions with `Get-Command` fallback checks:
     - cat -> bat (with --paging=never)
     - ls/ll/la/lt -> eza
     - grep -> rg
     - find -> fd
     - diff -> delta
  4. Navigation aliases (cd .., etc. — use `Set-Alias` or functions)
  5. Git shortcut functions (gs, gd, ga, gc, gp, gpl, gl, glo, gb)
  6. Utility aliases (h=history, c=clear)
  7. Zoxide init: `Invoke-Expression (& { (zoxide init powershell | Out-String) })`
  8. Starship init (MUST be last): `Invoke-Expression (&starship init powershell)`
  9. End marker: `# --- end terminal-setup.ps1 ---`

### Main Entry Point
```powershell
function Main {
    # Banner
    # DryRun notice
    # WinGet detection
    # Interactive wizard (if -Interactive)
    # Conditional execution of each section based on feature flags
    # Done message with restart instruction
    # Font reminder if installed
}

Main
```

**Critical PS 5.1 constraints to follow:**
- No `??` (null coalescing)
- No ternary operator
- No `&&` / `||` pipeline chain operators
- Always use `-UseBasicParsing` with `Invoke-WebRequest`
- Always use `-Encoding UTF8` when writing files
- Use `[string]::IsNullOrWhiteSpace()` instead of null coalescing
- Use `if/else` instead of ternary

**Anti-patterns to avoid:**
- Do NOT use `New-Alias` (errors if exists) — use `Set-Alias` or just define functions
- Do NOT hardcode profile paths — always use `$PROFILE`
- Do NOT attempt `C:\Windows\Fonts\` without elevation
- Do NOT define `function cat` without first removing `Alias:cat`
- Do NOT name any function `Write-Error` (conflicts with built-in cmdlet)

**File size target:** ~500 lines (comparable to terminal-setup.sh at 485 lines)
</description>
</task>

<task id="2" name="verify-script" depends="1">
<title>Verify terminal-setup.ps1 quality and correctness</title>
<description>
After creating the script, verify the following:

1. **Syntax check**: The file starts with `#Requires -Version 5.1` and `[CmdletBinding()] param(...)` block
2. **No PS 7-only syntax**: Search for `??`, `?:` ternary, `&&`, `||` pipeline operators — none should exist
3. **No repo imports**: No `Import-Module` statements — script is fully standalone
4. **Marker idempotency**: Both start and end markers present in the profile block
5. **DryRun coverage**: Every destructive action (WinGet install, file write, font copy, profile append) has DryRun guard
6. **Section parity with terminal-setup.sh**: Header, logging, wizard, platform detection, tools, font, starship config, profile setup, main — all sections present
7. **WinGet IDs match research**: All 7 package IDs match the research document
8. **Encoding**: All file writes use `-Encoding UTF8`
9. **UseBasicParsing**: All `Invoke-WebRequest` calls include `-UseBasicParsing`
10. **No Write-Error function name**: Logging error function uses alternative name (e.g., `Write-Err`)

Run a line count to confirm script is in the ~400-600 line range (proportional to the Bash version).
</description>
</task>

## Verification Criteria

After all tasks complete, verify:

- [ ] `examples/terminal-setup.ps1` exists and is a single standalone file
- [ ] Script starts with `#Requires -Version 5.1`
- [ ] `param` block accepts `-DryRun` and `-Interactive` switches
- [ ] All 7 CLI tools have correct WinGet IDs
- [ ] Font installation uses per-user path (`$env:LOCALAPPDATA\Microsoft\Windows\Fonts`)
- [ ] Starship config uses ASCII-safe symbols (`>` not Unicode)
- [ ] Profile detection uses `$PROFILE` (not hardcoded paths)
- [ ] Marker-based idempotency (`# --- terminal-setup.ps1 ---`)
- [ ] No `Import-Module` statements (standalone)
- [ ] No PS 7-only syntax (`??`, ternary, `&&`/`||`)
- [ ] All `Invoke-WebRequest` calls use `-UseBasicParsing`
- [ ] All file writes use `-Encoding UTF8`
- [ ] DryRun guards on all destructive operations
- [ ] Script structure mirrors terminal-setup.sh sections
