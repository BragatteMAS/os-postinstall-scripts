#!/bin/bash

# AI Context Template - Master Installation Script
# Provides multiple installation options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "┌─────────────────────────────────────────┐"
echo "│       AI Context Template Setup         │"
echo "│                                         │"
echo "│  'Adapt what is useful,                 │"
echo "│   reject what is useless,               │"
echo "│   and add what is specifically          │"
echo "│   your own.'                            │"
echo "│                      - Bruce Lee        │"
echo "└─────────────────────────────────────────┘"
echo -e "${NC}"

# Function to show menu
show_menu() {
    echo -e "${GREEN}Choose your setup method:${NC}"
    echo ""
    echo "1) 🚀 Minimal Setup (2 minutes)"
    echo "   Creates 3 essential files for immediate use"
    echo ""
    echo "2) 🔍 Smart Detection (Auto-detect AI tools)"
    echo "   Detects Claude, Copilot, Cursor, etc. and creates optimized configs"
    echo ""
    echo "3) 💬 Interactive Setup (Guided experience)"
    echo "   Step-by-step wizard with options"
    echo ""
    echo "4) 📊 From Git History (Analyze existing project)"
    echo "   Generates context from your git repository"
    echo ""
    echo "5) 📚 View Documentation"
    echo "   Learn more before installing"
    echo ""
    echo "6) ❌ Exit"
    echo ""
}

# Function to run scripts
run_script() {
    local script=$1
    local script_path="./scripts/$script"
    
    if [[ -f "$script_path" ]]; then
        echo -e "${BLUE}Running $script...${NC}"
        bash "$script_path"
    else
        # Try to download from GitHub
        echo -e "${YELLOW}Script not found locally. Downloading...${NC}"
        local url="https://raw.githubusercontent.com/BragatteMAS/ai-context-template/main/scripts/$script"
        
        if command -v curl &> /dev/null; then
            curl -fsSL "$url" | bash
        elif command -v wget &> /dev/null; then
            wget -qO- "$url" | bash
        else
            echo -e "${RED}Error: Neither curl nor wget found. Please install one.${NC}"
            exit 1
        fi
    fi
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            echo ""
            run_script "minimal-setup.sh"
            break
            ;;
        2)
            echo ""
            run_script "smart-ai-detector.sh"
            break
            ;;
        3)
            echo ""
            # Check if Node.js is installed
            if command -v node &> /dev/null; then
                if [[ -f "./scripts/interactive-setup.js" ]]; then
                    node ./scripts/interactive-setup.js
                else
                    echo -e "${YELLOW}Downloading interactive setup...${NC}"
                    npx create-ai-context
                fi
            else
                echo -e "${RED}Node.js is required for interactive setup.${NC}"
                echo "Install Node.js or choose another option."
                echo ""
                continue
            fi
            break
            ;;
        4)
            echo ""
            run_script "auto-generate-from-git.sh"
            break
            ;;
        5)
            echo ""
            echo -e "${BLUE}📚 Documentation${NC}"
            echo ""
            echo "AI Context Template helps AI assistants understand your project by providing:"
            echo "- Project overview and technical stack"
            echo "- Coding conventions and patterns"
            echo "- Areas where AI can help most"
            echo ""
            echo "After setup, you'll have a .ai/ folder with context files that help"
            echo "Claude, Copilot, Cursor, ChatGPT, and other AI tools work more effectively"
            echo "with your codebase."
            echo ""
            echo "Visit: https://github.com/BragatteMAS/ai-context-template"
            echo ""
            read -p "Press Enter to return to menu..."
            echo ""
            continue
            ;;
        6)
            echo -e "${GREEN}Thanks for using AI Context Template!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select 1-6.${NC}"
            echo ""
            continue
            ;;
    esac
done

# Success message
echo ""
echo -e "${GREEN}✨ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Fill out .ai/1-QUESTIONS.md with your project details"
echo "2. Customize the generated AI configuration files"
echo "3. Commit the files to share context with your team"
echo ""
echo -e "${BLUE}Happy coding with AI assistance! 🚀${NC}"