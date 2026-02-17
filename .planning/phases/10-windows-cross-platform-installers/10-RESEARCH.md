# Phase 10: Windows Cross-Platform Installers - Research

**Researched:** 2026-02-17
**Domain:** PowerShell scripting, Windows package management (cargo/npm/ai-tools)
**Confidence:** HIGH

## Summary

Phase 10 closes the last integration gap identified in the v2.1 audit: Windows `main.ps1` currently WARN-skips `cargo.txt`, `npm.txt`, and `ai-tools.txt`. Three new PowerShell installer scripts are needed, each following the established pattern from `winget.ps1` (Phase 6). The Unix equivalents (`cargo.sh`, `ai-tools.sh`, `fnm.sh`) provide clear behavioral specifications to port.

The critical architectural decision is **how to install cargo.txt packages on Windows**. Unlike Linux (which uses `cargo install` from source), Windows should prefer WinGet pre-built binaries where available, falling back to `cargo install` only for packages not in WinGet. This avoids requiring MSVC build tools and eliminates 10+ minute compile times per package. For npm.txt, Node.js must already be available (installed via WinGet in winget.txt, or the user installs fnm separately). For ai-tools.txt, the prefix-based dispatch pattern from the Unix version ports directly to PowerShell `switch` statements.

**Primary recommendation:** Create three scripts (`cargo.ps1`, `npm.ps1`, `ai-tools.ps1`) in `src/platforms/windows/install/`, each following the exact structure of `winget.ps1`. Use WinGet as the primary installation method for cargo.txt packages (with cargo-install fallback), `npm install -g` for npm.txt packages, and prefix-based dispatch for ai-tools.txt entries.

## Standard Stack

### Core (Ships with Windows - Zero External Dependencies)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PowerShell | 5.1+ | Script runtime | Ships with Windows 10/11 |
| WinGet | latest | Primary package installer | Ships with Windows 11, available on Win10 |
| npm | via Node.js | npm global package installer | Standard Node.js toolchain |
| cargo | via rustup | Rust package installer (fallback) | Only for packages not in WinGet |

### Supporting (Already in Codebase)

| Module | Location | Purpose | When to Use |
|--------|----------|---------|-------------|
| logging.psm1 | core/ | Write-Log with levels | All output |
| packages.psm1 | core/ | Read-PackageFile | Loading .txt data files |
| errors.psm1 | core/ | Add-FailedItem, Show-FailureSummary | Failure tracking |

### No New Dependencies Required

This phase requires zero new libraries or modules. Everything is built on existing codebase infrastructure plus OS-bundled tools (WinGet, PowerShell, npm, cargo).

## Architecture Patterns

### Recommended Project Structure

```
src/platforms/windows/
├── core/
│   ├── logging.psm1      # (existing)
│   ├── packages.psm1     # (existing)
│   └── errors.psm1       # (existing)
├── install/
│   ├── winget.ps1         # (existing) - reference pattern
│   ├── cargo.ps1          # NEW - cargo.txt installer
│   ├── npm.ps1            # NEW - npm.txt installer
│   └── ai-tools.ps1      # NEW - ai-tools.txt installer
└── main.ps1               # (existing) - update dispatch switch
```

### Pattern 1: Script Template (from winget.ps1)

**What:** Every installer follows the exact same structure as `winget.ps1`
**When to use:** All three new scripts

```powershell
#Requires -Version 5.1
# Header comment block

$ErrorActionPreference = 'Continue'

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/packages.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force

# Tool availability check function
# Per-package idempotent check function
# Per-package install function

# Main
Write-Log -Level BANNER -Message 'Banner Title'

# Check tool availability (exit gracefully if not available)
# Load packages: $Packages = Read-PackageFile -FileName 'xxx.txt'
# Install loop with idempotent check
# Show-FailureSummary
exit 0
```

### Pattern 2: WinGet-First Strategy for Cargo Packages

**What:** Map cargo package names to WinGet IDs where available; fall back to `cargo install`
**When to use:** cargo.ps1 only
**Why:** Avoids MSVC build tools requirement, eliminates long compile times, uses pre-built binaries

```powershell
# Mapping: cargo package name -> WinGet package ID
# Only tools with confirmed WinGet packages are listed here
$WinGetMapping = @{
    'bat'          = 'sharkdp.bat'
    'eza'          = 'eza-community.eza'
    'fd-find'      = 'sharkdp.fd'
    'ripgrep'      = 'BurntSushi.ripgrep.MSVC'
    'zoxide'       = 'ajeetdsouza.zoxide'
    'git-delta'    = 'dandavison.delta'
    'bottom'       = 'Clement.bottom'
    'hyperfine'    = 'sharkdp.hyperfine'
    'starship'     = 'Starship.Starship'
    'nu'           = 'Nushell.Nushell'
    'helix'        = 'Helix.Helix'
    'atuin'        = 'atuinsh.atuin'
}

# For each package in cargo.txt:
# 1. Check WinGet mapping -> use winget install if available
# 2. No mapping -> check if cargo available -> cargo install
# 3. No cargo -> skip with WARN
```

### Pattern 3: Prefix-Based Dispatch for AI Tools

**What:** Parse `prefix:package` format and route to correct installer
**When to use:** ai-tools.ps1 only
**Ported from:** `src/install/ai-tools.sh` (Phase 5)

```powershell
# Parse prefix from entry
if ($entry -notmatch ':') {
    Write-Log -Level DEBUG -Message "Skipping unprefixed entry: $entry"
    continue
}
$prefix = $entry.Split(':')[0]
$tool = $entry.Substring($prefix.Length + 1)

switch ($prefix) {
    'npm'  { # npm install -g $tool }
    'curl' { # Handle curl-installed tools (ollama -> winget on Windows) }
    'npx'  { # Skip - runs on demand }
    'uv'   { # Skip - runs on demand }
    default { # Skip unknown prefix }
}
```

### Pattern 4: Idempotent Check Patterns

**What:** Check before install to avoid redundant operations
**Per-tool patterns:**

```powershell
# WinGet idempotent check (from Phase 6 decision: double-check)
function Test-WinGetInstalled {
    param([string]$PackageId)
    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($PackageId)) {
        return $true
    }
    return $false
}

# npm idempotent check (from Phase 5 decision: npm list -g)
function Test-NpmInstalled {
    param([string]$PackageName)
    $output = npm list -g $PackageName 2>$null
    return ($LASTEXITCODE -eq 0)
}

# cargo idempotent check
function Test-CargoInstalled {
    param([string]$PackageName)
    $output = cargo install --list 2>$null
    return ($output -match "^$([regex]::Escape($PackageName)) ")
}
```

### Anti-Patterns to Avoid

- **Don't require Rust/MSVC for common tools:** Most cargo.txt tools have WinGet packages. Only fall back to `cargo install` for packages not in WinGet.
- **Don't install Node.js inside npm.ps1:** The script should check if `node`/`npm` is available and skip with WARN if not. Node.js installation is the user's responsibility (via WinGet in winget.txt or fnm).
- **Don't use `curl` for ollama on Windows:** Use `winget install Ollama.Ollama` instead. The `curl:ollama` prefix in ai-tools.txt maps to WinGet on Windows.
- **Don't use interactive menus:** The Unix scripts have interactive category selection (`show_category_menu`). Windows installers are called from `main.ps1` in unattended mode only -- no interactivity needed.
- **Don't try to install zellij on Windows:** Zellij does not support Windows. Skip it with DEBUG log.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package file parsing | Custom parser | `Read-PackageFile` from packages.psm1 | Already exists, tested, handles comments/blanks |
| Failure tracking | Custom error list | `Add-FailedItem` from errors.psm1 | Cross-process tracking via FAILURE_LOG already works |
| Logging | Write-Host calls | `Write-Log` from logging.psm1 | Consistent levels, NO_COLOR support, VERBOSE timestamps |
| WinGet idempotent check | Custom registry lookup | `winget list --id --exact` + output match | Phase 6 decision, already proven in winget.ps1 |
| npm global check | `Get-Command` | `npm list -g $pkg` | Phase 5 decision: scoped packages need npm-level check |
| Ollama Windows install | curl download | `winget install Ollama.Ollama --silent` | Native Windows package available |

**Key insight:** All infrastructure exists from Phases 1 and 6. This phase is purely about writing three dispatcher scripts using established patterns.

## Common Pitfalls

### Pitfall 1: PATH Not Refreshed After WinGet Install
**What goes wrong:** After `winget install Rustlang.Rustup`, `cargo` is not in PATH for the current session.
**Why it happens:** WinGet modifies the system PATH, but the current PowerShell session still has the old PATH.
**How to avoid:** Refresh PATH after installing rustup:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```
**Warning signs:** `Get-Command cargo` fails immediately after rustup install.

### Pitfall 2: cargo install Requires MSVC Build Tools
**What goes wrong:** `cargo install bat` fails with "linker 'link.exe' not found"
**Why it happens:** Rust on Windows needs MSVC C++ build tools for compiling from source
**How to avoid:** Use WinGet pre-built binaries as primary strategy. Only fall back to `cargo install` if user already has Rust installed AND WinGet doesn't have the package.
**Warning signs:** MSVC build tools require ~6GB download, completely inappropriate for a post-install script.

### Pitfall 3: npm Global Packages Need Elevated Permissions Sometimes
**What goes wrong:** `npm install -g typescript` fails with EACCES or permission errors
**Why it happens:** On Windows, npm global install typically works without elevation, but path issues can occur if Node.js was installed for all users.
**How to avoid:** Don't attempt elevation. If npm install -g fails, record the failure and continue (pragmatic approach, matching existing pattern).
**Warning signs:** Permission errors in npm output.

### Pitfall 4: Zellij Not Available on Windows
**What goes wrong:** Attempting to install zellij on Windows fails.
**Why it happens:** Zellij only supports Linux and macOS. No Windows binaries exist.
**How to avoid:** Skip packages with no Windows equivalent. Log at DEBUG level (matching the "non-Windows package files" pattern from main.ps1).
**Warning signs:** The cargo.txt file lists zellij, but it won't work on Windows.

### Pitfall 5: Scoped npm Packages in Check
**What goes wrong:** `npm list -g @anthropic-ai/claude-code` might behave differently from unscoped packages
**Why it happens:** Scoped packages (starting with @) have different npm list output formatting
**How to avoid:** Use `npm list -g $tool 2>$null` and check `$LASTEXITCODE` (0 = installed). This works for both scoped and unscoped packages. This was the Phase 5 decision.
**Warning signs:** False negatives in idempotent check for scoped packages.

### Pitfall 6: cargo-binstall PowerShell Install Script Modifies ExecutionPolicy
**What goes wrong:** The cargo-binstall install script sets `Set-ExecutionPolicy Unrestricted -Scope Process`
**Why it happens:** The official install script is designed for interactive use
**How to avoid:** Don't install cargo-binstall via the PS1 script. If the WinGet-first strategy covers most packages, cargo-binstall is rarely needed. If cargo is available and binstall is not, just use `cargo install` directly.
**Warning signs:** ExecutionPolicy changes could affect subsequent script behavior.

## Code Examples

### Example 1: cargo.ps1 Core Structure

```powershell
# Source: Ported from src/platforms/linux/install/cargo.sh + winget.ps1 pattern

# WinGet-first mapping for cargo.txt packages
$script:WinGetMap = @{
    'bat'          = 'sharkdp.bat'
    'eza'          = 'eza-community.eza'
    'fd-find'      = 'sharkdp.fd'
    'lsd'          = 'lsd-rs.lsd'
    'ripgrep'      = 'BurntSushi.ripgrep.MSVC'
    'dust'         = 'bootandy.dust'
    'bottom'       = 'Clement.bottom'
    'procs'        = 'dalance.procs'
    'tokei'        = 'XAMPPRocky.tokei'
    'hyperfine'    = 'sharkdp.hyperfine'
    'sd'           = $null   # Not in WinGet - cargo install or skip
    'zoxide'       = 'ajeetdsouza.zoxide'
    'git-delta'    = 'dandavison.delta'
    'gitui'        = 'Extrawurst.gitui'
    'starship'     = 'Starship.Starship'
    'nu'           = 'Nushell.Nushell'
    'helix'        = 'Helix.Helix'
    'atuin'        = 'atuinsh.atuin'
    'zellij'       = $null   # Not available on Windows
    'bacon'        = $null   # Not in WinGet - cargo install or skip
    'xsv'          = $null   # Not in WinGet - cargo install or skip
    'jql'          = $null   # Not in WinGet - cargo install or skip
    'htmlq'        = $null   # Not in WinGet - cargo install or skip
    'cargo-watch'  = $null   # cargo subcommand - cargo install only
    'cargo-edit'   = $null   # cargo subcommand - cargo install only
    'cargo-update' = $null   # cargo subcommand - cargo install only
    'cargo-audit'  = $null   # cargo subcommand - cargo install only
    'cargo-expand' = $null   # cargo subcommand - cargo install only
    'cargo-outdated' = $null # cargo subcommand - cargo install only
    'cargo-binstall' = $null # cargo subcommand - cargo install only
}

# Packages to skip on Windows entirely
$script:SkipOnWindows = @('zellij')

function Install-CargoPackage {
    param([string]$PackageName)

    # Skip unsupported packages
    if ($PackageName -in $script:SkipOnWindows) {
        Write-Log -Level DEBUG -Message "Skipping $PackageName (not available on Windows)"
        return
    }

    # Strategy 1: WinGet (preferred - pre-built binary)
    $wingetId = $script:WinGetMap[$PackageName]
    if ($wingetId) {
        if (Test-WinGetInstalled -PackageId $wingetId) {
            Write-Log -Level DEBUG -Message "Already installed (WinGet): $PackageName"
            return
        }
        Write-Log -Level INFO -Message "Installing via WinGet: $PackageName ($wingetId)"
        winget install --id $wingetId --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log -Level OK -Message "Installed: $PackageName"
            return
        }
        Write-Log -Level WARN -Message "WinGet failed for $PackageName, trying cargo..."
    }

    # Strategy 2: cargo install (fallback)
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Write-Log -Level WARN -Message "Cargo not available, skipping: $PackageName"
        Add-FailedItem -Item $PackageName
        return
    }
    # ... cargo install fallback
}
```

### Example 2: npm.ps1 Core Structure

```powershell
# Source: Ported from fnm.sh global npm install + winget.ps1 pattern

function Test-NpmInstalled {
    param([string]$PackageName)
    npm list -g $PackageName 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Install-NpmPackage {
    param([string]$PackageName)

    if (Test-NpmInstalled -PackageName $PackageName) {
        Write-Log -Level DEBUG -Message "Already installed: $PackageName"
        return
    }

    Write-Log -Level INFO -Message "Installing: $PackageName"
    npm install -g $PackageName 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level OK -Message "Installed: $PackageName"
    } else {
        Write-Log -Level WARN -Message "Failed to install: $PackageName"
        Add-FailedItem -Item $PackageName
    }
}

# Main
Write-Log -Level BANNER -Message 'NPM Global Package Installer'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Log -Level WARN -Message 'Node.js not found - skipping npm packages'
    # ... guidance message
    exit 0
}

$Packages = Read-PackageFile -FileName 'npm.txt'
foreach ($pkg in $Packages) {
    Install-NpmPackage -PackageName $pkg
}
Show-FailureSummary
exit 0
```

### Example 3: ai-tools.ps1 Prefix Dispatch

```powershell
# Source: Ported from src/install/ai-tools.sh prefix dispatch

function Install-AiTool {
    param([string]$Entry)

    # Bare word (no prefix) - skip
    if ($Entry -notmatch ':') {
        Write-Log -Level DEBUG -Message "Skipping unprefixed entry: $Entry"
        return
    }

    $parts = $Entry.Split(':', 2)
    $prefix = $parts[0]
    $tool = $parts[1]

    switch ($prefix) {
        'npm' {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Write-Log -Level WARN -Message "Node.js not found, skipping npm tool: $tool"
                Add-FailedItem -Item $tool
                return
            }
            # npm list -g idempotent check + npm install -g
        }
        'curl' {
            # On Windows, map curl-installed tools to WinGet equivalents
            switch ($tool) {
                'ollama' {
                    # winget install Ollama.Ollama
                }
                default {
                    Write-Log -Level DEBUG -Message "Skipping unknown curl tool: $tool"
                }
            }
        }
        'npx' {
            Write-Log -Level DEBUG -Message "Skipping npx tool (runs on demand): $tool"
        }
        'uv' {
            Write-Log -Level DEBUG -Message "Skipping uv tool (runs on demand): $tool"
        }
        default {
            Write-Log -Level DEBUG -Message "Skipping unknown prefix: $prefix for $tool"
        }
    }
}
```

### Example 4: main.ps1 Dispatch Update

```powershell
# Replace the WARN-skip blocks in main.ps1 with actual dispatch:

'cargo.txt' {
    Write-Log -Level INFO -Message 'Installing Cargo packages...'
    & "$WindowsDir/install/cargo.ps1"
}
'npm.txt' {
    Write-Log -Level INFO -Message 'Installing NPM global packages...'
    & "$WindowsDir/install/npm.ps1"
}
'ai-tools.txt' {
    Write-Log -Level INFO -Message 'Installing AI tools...'
    & "$WindowsDir/install/ai-tools.ps1"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `cargo install` from source on Windows | WinGet pre-built binaries for most Rust CLI tools | 2024+ | Eliminates MSVC requirement, 10x faster installs |
| ollama curl install script (Unix) | `winget install Ollama.Ollama` (Windows) | 2024 | Native Windows package, no curl needed |
| nvm for Node.js | fnm via WinGet (`Schniz.fnm`) | 2024 | Faster, Rust-based, better Windows support |
| Helix via `cargo install` | `winget install Helix.Helix` | 2024 | `cargo install` not supported for Helix (runtime dir issue) |

**Not available on Windows:**
- **zellij:** Linux/macOS only terminal multiplexer. No Windows port exists.

**Packages requiring `cargo install` fallback (no WinGet package found):**
- sd, bacon, xsv, jql, htmlq
- cargo-watch, cargo-edit, cargo-update, cargo-audit, cargo-expand, cargo-outdated, cargo-binstall
- Note: cargo-* extensions are only useful if the user has Rust installed anyway, so `cargo install` is appropriate for them.

## Open Questions

1. **WinGet package IDs for lesser-known tools (sd, bacon, xsv, jql, htmlq)**
   - What we know: These are available via `cargo install` but may or may not have WinGet packages
   - What's unclear: Exact WinGet package IDs (need Windows machine to verify with `winget search`)
   - Recommendation: Code the WinGet mapping with `$null` for unknown ones. They fall through to `cargo install` if Rust is available, otherwise skip with WARN. Can be updated later after testing on Windows.

2. **Should cargo.ps1 install Rust/rustup if not present?**
   - What we know: Linux `cargo.sh` installs rustup via curl if cargo not found. WinGet has `Rustlang.Rustup`.
   - What's unclear: Whether auto-installing Rust is appropriate (requires MSVC build tools for compilation)
   - Recommendation: Do NOT auto-install Rust. If most packages install via WinGet, Rust is only needed for the cargo-* extensions. If cargo is not available, skip cargo-install-only packages with WARN. This keeps the script simpler and avoids the MSVC dependency trap.

3. **DRY_RUN support**
   - What we know: All existing installers check `$env:DRY_RUN -eq 'true'` before mutations
   - What's unclear: Nothing -- this is well-established
   - Recommendation: Follow established pattern. Check DRY_RUN before every `winget install`, `npm install -g`, and `cargo install` call.

## Sources

### Primary (HIGH confidence)
- Existing codebase: `winget.ps1`, `cargo.sh`, `ai-tools.sh`, `fnm.sh`, `main.ps1` -- direct examination of patterns to follow
- Existing codebase: `logging.psm1`, `packages.psm1`, `errors.psm1` -- core modules API
- [Zellij installation docs](https://zellij.dev/documentation/installation) -- confirms Linux/macOS only

### Secondary (MEDIUM confidence)
- [Rust installation docs](https://doc.rust-lang.org/book/ch01-01-installation.html) -- Windows rustup installation
- [rustup book - Installation](https://rust-lang.github.io/rustup/installation/index.html) -- silent install with `-y`, CARGO_HOME, RUSTUP_HOME env vars
- [cargo-binstall GitHub](https://github.com/cargo-bins/cargo-binstall) -- PowerShell install script
- [fnm GitHub](https://github.com/Schniz/fnm) -- `winget install Schniz.fnm`, PowerShell env setup
- [npm docs - global install](https://docs.npmjs.com/downloading-and-installing-packages-globally/) -- npm install -g
- [Ollama Windows download](https://ollama.com/download/windows) -- WinGet install method
- [Helix package managers](https://docs.helix-editor.com/package-managers.html) -- WinGet `Helix.Helix`, cargo install not supported
- [winget.run](https://winget.run/) -- WinGet package ID verification (sharkdp.bat, sharkdp.fd, dandavison.delta, etc.)
- [winstall.app](https://winstall.app/apps/Helix.Helix) -- Helix WinGet confirmation
- [Atuin installation docs](https://docs.atuin.sh/cli/guide/installation/) -- Windows/PowerShell tier 2 support

### Tertiary (LOW confidence)
- WinGet package IDs for: `lsd-rs.lsd`, `bootandy.dust`, `dalance.procs`, `Extrawurst.gitui`, `atuinsh.atuin` -- inferred from GitHub org/repo patterns, need verification on Windows machine

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- zero new dependencies, all built on existing codebase
- Architecture: HIGH -- direct port of proven patterns from winget.ps1 and Unix equivalents
- Pitfalls: HIGH -- well-documented Windows-specific issues with PATH, MSVC, permissions
- WinGet package IDs (common tools): MEDIUM -- verified via winget.run but not tested on live Windows
- WinGet package IDs (less common tools): LOW -- inferred, need Windows testing

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable domain, no fast-moving parts)
