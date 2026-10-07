#Requires -Version 5.1
#######################################
# Script: ai-tools.ps1
# Description: Install AI tools using prefix-based dispatch (data-driven)
# Author: Bragatte
# Date: 2026-02-17
#######################################
# PowerShell equivalent of src/install/ai-tools.sh
# Reads ai-tools-full.txt from data/packages/ and dispatches by prefix:
#   npm:  -> npm install -g
#   curl: -> retired in 5.7.0 (warns and skips)
#   npx:  -> skip (runs on demand)
#   bun:  -> bun add -g
#   uv:   -> uv tool install
#   bare  -> skip (informational only)
# Failed installations tracked via Add-FailedItem for summary

$ErrorActionPreference = 'Continue'

# Import core modules
Import-Module "$PSScriptRoot/../core/logging.psm1" -Force
Import-Module "$PSScriptRoot/../core/packages.psm1" -Force
Import-Module "$PSScriptRoot/../core/errors.psm1" -Force
Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force

#######################################
# Helper Functions
#######################################

function Install-AiTool {
    <#
    .SYNOPSIS
        Install a single AI tool based on its prefix.
    .DESCRIPTION
        Parses prefix:tool format and dispatches to the correct installer.
        npm: uses npm install -g
        curl: retired in 5.7.0 (warns and skips)
        npx: skipped (runs on demand via npx)
        bun: uses bun add -g
        uv: uses uv tool install
        bare words: skipped (informational only)
    .PARAMETER Entry
        The entry from ai-tools-full.txt (e.g., "npm:@anthropic-ai/claude-code").
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Entry
    )

    # Bare word (no prefix) - skip
    if ($Entry -notmatch ':') {
        Write-Log -Level DEBUG -Message "Skipping unprefixed entry: $Entry"
        return
    }

    # Split on first colon
    $parts = $Entry.Split(':', 2)
    $prefix = $parts[0]
    $tool = $parts[1]

    switch ($prefix) {
        'npm' {
            # Check Node.js availability
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Write-Log -Level WARN -Message "Node.js not found, skipping npm tool: $tool"
                Add-FailedItem -Item $tool
                return
            }

            # Idempotent check
            if (Test-NpmInstalled -PackageName $tool) {
                Write-Log -Level DEBUG -Message "Already installed: $tool"
                return
            }

            # DRY_RUN guard
            if ($env:DRY_RUN -eq 'true') {
                Write-Log -Level INFO -Message "[DRY_RUN] Would npm install -g: $tool"
                return
            }

            Write-Log -Level INFO -Message "Installing npm tool: $tool"
            npm install -g $tool 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Log -Level OK -Message "Installed: $tool"
            } else {
                Write-Log -Level WARN -Message "Failed to install: $tool"
                Add-FailedItem -Item $tool
            }
        }

        'curl' {
            # v5.7.0: curl-installed tools were retired (the only one was ollama).
            Write-Log -Level WARN -Message "curl: entries are no longer supported (removed in 5.7.0): $tool - install it manually"
        }

        'npx' {
            Write-Log -Level DEBUG -Message "Skipping npx tool (runs on demand): $tool"
        }

        'bun' {
            if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
                Write-Log -Level WARN -Message "bun not found, skipping bun tool: $tool"
                Add-FailedItem -Item $tool
                return
            }

            # Idempotent check
            if (Test-BunInstalled -PackageName $tool) {
                Write-Log -Level DEBUG -Message "Already installed: $tool"
                return
            }

            # DRY_RUN guard
            if ($env:DRY_RUN -eq 'true') {
                Write-Log -Level INFO -Message "[DRY_RUN] Would bun add -g: $tool"
                return
            }

            Write-Log -Level INFO -Message "Installing bun tool: $tool"
            bun add -g $tool 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Log -Level OK -Message "Installed: $tool"
            } else {
                Write-Log -Level WARN -Message "Failed to install: $tool"
                Add-FailedItem -Item $tool
            }
        }

        'uv' {
            if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
                Write-Log -Level WARN -Message "uv not found, skipping uv tool: $tool"
                Add-FailedItem -Item $tool
                return
            }

            # Idempotent check
            if (Test-UvToolInstalled -ToolName $tool) {
                Write-Log -Level DEBUG -Message "Already installed: $tool"
                return
            }

            # DRY_RUN guard
            if ($env:DRY_RUN -eq 'true') {
                Write-Log -Level INFO -Message "[DRY_RUN] Would uv tool install: $tool"
                return
            }

            Write-Log -Level INFO -Message "Installing uv tool: $tool"
            uv tool install $tool 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Log -Level OK -Message "Installed: $tool"
            } else {
                Write-Log -Level WARN -Message "Failed to install: $tool"
                Add-FailedItem -Item $tool
            }
        }

        default {
            Write-Log -Level DEBUG -Message "Skipping unknown prefix: $prefix for $tool"
        }
    }
}

function Show-AiSummary {
    <#
    .SYNOPSIS
        Display API key configuration info after installation.
    .DESCRIPTION
        Ported from src/install/ai-tools.sh show_ai_summary().
        Provides guidance on configuring API keys for AI CLI tools.
    #>

    Write-Host ''
    Write-Log -Level INFO -Message 'Configure API keys for AI tools:'
    Write-Log -Level INFO -Message '  ANTHROPIC_API_KEY - for Claude Code'
    Write-Log -Level INFO -Message '  OPENAI_API_KEY   - for Codex'
    Write-Log -Level INFO -Message '  GEMINI_API_KEY   - for Gemini CLI'
    Write-Host ''
}

#######################################
# Main
#######################################

Write-Log -Level BANNER -Message 'AI Coding Tools'

# Load packages from data file
$Packages = Read-PackageFile -FileName 'ai-tools-full.txt'

if ($Packages.Count -eq 0) {
    Write-Log -Level WARN -Message 'No packages to install'
    exit 0
}

Write-Log -Level INFO -Message "Loaded $($Packages.Count) entries from ai-tools-full.txt"

# node, bun and uv installed by winget earlier in this run are not on the PATH
# of the current session yet; add what the registry has.
if ($env:OS -eq 'Windows_NT') {
    $env:Path = @(
        $env:Path
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
    ) -join ';'
}

# Install each tool via prefix dispatch
foreach ($entry in $Packages) {
    Install-AiTool -Entry $entry
}

# Show API key configuration info
Show-AiSummary

# Summary
Show-FailureSummary
$exitCode = Get-ExitCode
exit $exitCode
