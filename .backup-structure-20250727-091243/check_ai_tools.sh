#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#######################################
# check_ai_tools.sh
# Purpose: Verify AI tools installation status (MCPs + BMAD)
# Author: Bragatte, M.A.S
# License: MIT
# Version: 1.0.0
#######################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Icons
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"

# Configuration
CLAUDE_CONFIG_PATH=""
BMAD_FOUND=false
MCPS_CONFIGURED=false

#######################################
# Show banner
#######################################
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║                  🤖 AI Tools Status Check 🤖                      ║
║                    MCPs + BMAD Verification                       ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#######################################
# Detect Claude config path
#######################################
detect_claude_config() {
    case "$OSTYPE" in
        darwin*)
            CLAUDE_CONFIG_PATH="$HOME/Library/Application Support/Claude/claude.json"
            ;;
        linux*)
            CLAUDE_CONFIG_PATH="$HOME/.config/Claude/claude.json"
            ;;
        msys*|cygwin*|mingw*)
            CLAUDE_CONFIG_PATH="$APPDATA/Claude/claude.json"
            ;;
        *)
            echo -e "${RED}${CROSS} Unsupported OS: $OSTYPE${NC}"
            return 1
            ;;
    esac
}

#######################################
# Check MCPs configuration
#######################################
check_mcps() {
    echo -e "\n${PURPLE}=== MCP Configuration Status ===${NC}\n"
    
    if [[ ! -f "$CLAUDE_CONFIG_PATH" ]]; then
        echo -e "${RED}${CROSS} Claude config not found at: $CLAUDE_CONFIG_PATH${NC}"
        echo -e "${YELLOW}${INFO} Run: ./install_ai_tools.sh to configure MCPs${NC}"
        return 1
    fi
    
    # Check for required MCPs
    local mcps=("context7" "fetch" "sequential-thinking" "serena")
    local all_found=true
    
    for mcp in "${mcps[@]}"; do
        if grep -q "\"$mcp\"" "$CLAUDE_CONFIG_PATH" 2>/dev/null; then
            echo -e "${GREEN}${CHECK} $mcp${NC} - Configured"
        else
            echo -e "${RED}${CROSS} $mcp${NC} - Not configured"
            all_found=false
        fi
    done
    
    if $all_found; then
        MCPS_CONFIGURED=true
        echo -e "\n${GREEN}${CHECK} All MCPs are configured!${NC}"
        echo -e "${YELLOW}${INFO} Remember to restart Claude Desktop to activate them${NC}"
    else
        echo -e "\n${RED}${CROSS} Some MCPs are missing${NC}"
        echo -e "${YELLOW}${INFO} Run: ./install_ai_tools.sh to fix this${NC}"
    fi
}

#######################################
# Check BMAD installation
#######################################
check_bmad() {
    echo -e "\n${PURPLE}=== BMAD Method Status ===${NC}\n"
    
    # Check current project
    if [[ -d ".claude" ]]; then
        echo -e "${GREEN}${CHECK} BMAD installed in current directory${NC}"
        BMAD_FOUND=true
        
        # List available commands
        if [[ -d ".claude/commands" ]]; then
            echo -e "\n${BLUE}Available slash commands:${NC}"
            for cmd in .claude/commands/*.md; do
                if [[ -f "$cmd" ]]; then
                    basename "$cmd" .md | sed 's/^/  \//g'
                fi
            done
        fi
        
        # Check for project docs
        echo -e "\n${BLUE}Project documentation:${NC}"
        local docs=("CLAUDE.md" "PRD.md" "STORIES.md" "STATUS.md")
        for doc in "${docs[@]}"; do
            if [[ -f "$doc" ]] || [[ -f ".github/PROJECT_DOCS/$doc" ]]; then
                echo -e "  ${GREEN}${CHECK} $doc${NC}"
            else
                echo -e "  ${YELLOW}${WARNING} $doc${NC} - Missing"
            fi
        done
    else
        echo -e "${RED}${CROSS} BMAD not installed in current directory${NC}"
        echo -e "${YELLOW}${INFO} Run: bmad-method install --full${NC}"
    fi
    
    # Check global BMAD installation
    if command -v bmad-method &> /dev/null; then
        echo -e "\n${GREEN}${CHECK} BMAD CLI available globally${NC}"
    else
        echo -e "\n${YELLOW}${WARNING} BMAD CLI not found in PATH${NC}"
        echo -e "${INFO} Install with: npm install -g bmad-method"
    fi
}

#######################################
# Check dependencies
#######################################
check_dependencies() {
    echo -e "\n${PURPLE}=== Dependencies Status ===${NC}\n"
    
    local deps=(
        "node:Node.js"
        "npm:NPM"
        "git:Git"
        "jq:JSON processor"
        "python3:Python 3"
        "uv:UV package manager"
    )
    
    for dep in "${deps[@]}"; do
        IFS=':' read -r cmd name <<< "$dep"
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>/dev/null | head -n1 || echo "unknown")
            echo -e "${GREEN}${CHECK} $name${NC} - $version"
        else
            echo -e "${RED}${CROSS} $name${NC} - Not installed"
        fi
    done
}

#######################################
# Show quick setup instructions
#######################################
show_quick_setup() {
    echo -e "\n${PURPLE}=== Quick Setup Commands ===${NC}\n"
    
    if ! $MCPS_CONFIGURED; then
        echo -e "${BLUE}1. Install MCPs (one time only):${NC}"
        echo -e "   ${YELLOW}./install_ai_tools.sh${NC}"
        echo -e "   Then restart Claude Desktop\n"
    fi
    
    if ! $BMAD_FOUND; then
        echo -e "${BLUE}2. Install BMAD in this project:${NC}"
        echo -e "   ${YELLOW}npx bmad-method@latest install --full --ide cursor${NC}"
        echo -e "   Or with pnpm: ${YELLOW}pnpm dlx bmad-method@latest install --full${NC}\n"
    fi
    
    if $MCPS_CONFIGURED && $BMAD_FOUND; then
        echo -e "${GREEN}${CHECK} Everything is configured! You're ready to go!${NC}\n"
        echo -e "${BLUE}Tips:${NC}"
        echo -e "  - Use 'use context7' in prompts for updated docs"
        echo -e "  - Type / in Claude to see available BMAD commands"
        echo -e "  - Check STATUS.md for project health"
    fi
}

#######################################
# Main
#######################################
main() {
    show_banner
    detect_claude_config
    
    # Run all checks
    check_dependencies
    check_mcps
    check_bmad
    
    # Show summary and next steps
    echo -e "\n${PURPLE}=== Summary ===${NC}\n"
    
    if $MCPS_CONFIGURED; then
        echo -e "${GREEN}${CHECK} MCPs: Configured${NC}"
    else
        echo -e "${RED}${CROSS} MCPs: Not configured${NC}"
    fi
    
    if $BMAD_FOUND; then
        echo -e "${GREEN}${CHECK} BMAD: Installed in project${NC}"
    else
        echo -e "${YELLOW}${WARNING} BMAD: Not in current project${NC}"
    fi
    
    show_quick_setup
}

# Run
main "$@"