#!/bin/zsh
# ==============================================================================
# Module: AI Tools Configuration
# Description: AI development tools, MCPs, and BMAD Method integration
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ AI TOOLS CONFIGURATION                                                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Claude Desktop configuration
export CLAUDE_CONFIG_PATH="${HOME}/Library/Application Support/Claude/claude.json"

## MCP (Model Context Protocol) helpers
alias claude-config='${EDITOR} "$CLAUDE_CONFIG_PATH"'
alias mcp-status='echo "Checking MCP status..."; cat "$CLAUDE_CONFIG_PATH" 2>/dev/null | jq . || echo "Claude config not found"'

## BMAD Method helpers
alias bmad='pnpm dlx bmad-method@latest'
alias bmad-install='bmad install --full --ide claude-code --ide cursor'
alias bmad-update='bmad update'
alias bmad-init='bmad init'

## Claude.md management
alias claude-edit='${EDITOR} CLAUDE.md'
alias claude-check='[[ -f CLAUDE.md ]] && echo "✅ CLAUDE.md exists" || echo "❌ CLAUDE.md not found"'

## AI project initialization
ai-init() {
    echo "🤖 Initializing AI-enabled project..."

    # Check for CLAUDE.md
    if [[ ! -f "CLAUDE.md" ]]; then
        echo "Creating CLAUDE.md..."
        curl -sL https://raw.githubusercontent.com/bragatte/os-postinstall-scripts/main/CLAUDE.md -o CLAUDE.md
    fi

    # Install BMAD if .bmad directory doesn't exist
    if [[ ! -d ".bmad" ]]; then
        echo "Installing BMAD Method..."
        pnpm dlx bmad-method@latest install --full --ide claude-code --ide cursor
    fi

    # Create basic project structure
    mkdir -p docs .github/workflows tests

    echo "✅ AI project initialized!"
}

## Project status checking
project-status() {
    echo "📊 Project Status Check"
    echo "======================"

    # Check for key files
    local files=(
        "CLAUDE.md:Claude configuration"
        "STATUS.md:Project status tracking"
        "PRD.md:Product requirements"
        "STORIES.md:User stories"
        "CHANGELOG.md:Version history"
        ".bmad:BMAD Method"
    )

    for file_desc in "${files[@]}"; do
        local file="${file_desc%%:*}"
        local desc="${file_desc#*:}"
        if [[ -e "$file" ]]; then
            echo "✅ $file - $desc"
        else
            echo "❌ $file - $desc (missing)"
        fi
    done
}

## Quick MCP test
test-mcps() {
    echo "🧪 Testing MCPs in Claude..."
    echo "1. Open Claude Desktop"
    echo "2. Type: 'List available MCP tools'"
    echo "3. You should see tools prefixed with 'mcp__'"
    echo ""
    echo "Expected tools:"
    echo "  - mcp__context7__* (documentation)"
    echo "  - mcp__fetch__* (web requests)"
    echo "  - mcp__sequential-thinking__* (reasoning)"
    echo "  - mcp__serena__* (code search)"
    echo "  - mcp__fastapi__* (FastAPI docs)"
    echo "  - mcp__A2A__* (Google A2A tools)"
    echo "  - mcp__system-prompts-and-models-of-ai__* (prompts library)"
}

## Update all AI tools
ai-update() {
    echo "🔄 Updating AI tools..."

    # Update BMAD
    if command -v bmad &> /dev/null; then
        echo "Updating BMAD Method..."
        bmad update
    fi

    # Update CLAUDE.md
    if [[ -f "CLAUDE.md" ]]; then
        echo "Checking for CLAUDE.md updates..."
        curl -sL https://raw.githubusercontent.com/bragatte/os-postinstall-scripts/main/CLAUDE.md -o CLAUDE.md.new
        if ! diff -q CLAUDE.md CLAUDE.md.new > /dev/null; then
            echo "New version available! Review changes:"
            diff CLAUDE.md CLAUDE.md.new || true
            echo ""
            read -q "REPLY?Update CLAUDE.md? (y/n) "
            echo ""
            if [[ "$REPLY" == "y" ]]; then
                mv CLAUDE.md.new CLAUDE.md
                echo "✅ CLAUDE.md updated"
            else
                rm CLAUDE.md.new
            fi
        else
            rm CLAUDE.md.new
            echo "✅ CLAUDE.md is up to date"
        fi
    fi
}

## Aliases for common AI workflows
alias ai-plan='echo "use sequential-thinking" | pbcopy; echo "📋 Copied planning prompt to clipboard"'
alias ai-docs='echo "use context7" | pbcopy; echo "📋 Copied documentation prompt to clipboard"'
alias ai-search='echo "use serena for code search" | pbcopy; echo "📋 Copied search prompt to clipboard"'

## Environment variables for AI tools
export AI_TOOLS_ENABLED=true
export BMAD_AUTO_UPDATE=false