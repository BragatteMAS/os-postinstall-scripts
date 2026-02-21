#Requires -Version 5.1
#######################################
# Script: ai-tools.ps1
# Description: Install AI tools using prefix-based dispatch (data-driven)
# Author: Bragatte
# Date: 2026-02-17
#######################################
# PowerShell equivalent of src/install/ai-tools.sh
# Reads ai-tools.txt from data/packages/ and dispatches by prefix:
#   npm:  -> npm install -g
#   curl: -> WinGet equivalent on Windows (ollama -> Ollama.Ollama)
#   npx:  -> skip (runs on demand)
#   uv:   -> skip (runs on demand)
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
        curl: maps to WinGet on Windows (ollama -> Ollama.Ollama)
        npx: skipped (runs on demand via npx)
        uv: skipped (runs on demand via uvx)
        bare words: skipped (informational only)
    .PARAMETER Entry
        The entry from ai-tools.txt (e.g., "npm:@anthropic-ai/claude-code").
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
            # On Windows, map curl-installed tools to WinGet equivalents
            switch ($tool) {
                'ollama' {
                    # Idempotent check via WinGet
                    if (Test-WinGetInstalled -PackageId 'Ollama.Ollama') {
                        Write-Log -Level DEBUG -Message "Already installed: ollama"
                        return
                    }

                    # DRY_RUN guard
                    if ($env:DRY_RUN -eq 'true') {
                        Write-Log -Level INFO -Message "[DRY_RUN] Would winget install: Ollama.Ollama"
                        return
                    }

                    Write-Log -Level INFO -Message 'Installing ollama via WinGet...'
                    winget install --id Ollama.Ollama --exact --accept-source-agreements --accept-package-agreements --silent --source winget 2>$null

                    if ($LASTEXITCODE -eq 0) {
                        Write-Log -Level OK -Message 'Installed: ollama'
                    } else {
                        Write-Log -Level WARN -Message 'Failed to install: ollama'
                        Add-FailedItem -Item 'ollama'
                    }
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
$Packages = Read-PackageFile -FileName 'ai-tools.txt'

if ($Packages.Count -eq 0) {
    Write-Log -Level WARN -Message 'No packages to install'
    exit 0
}

Write-Log -Level INFO -Message "Loaded $($Packages.Count) entries from ai-tools.txt"

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
