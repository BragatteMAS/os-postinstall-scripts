#!/usr/bin/env bash
# Install BMAD Method in native location (.bmad-core)
# Simple, clean, functional

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Installing BMAD Method...${NC}"

# Check if in git repository (recommended but not required)
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Not in a git repository. It's recommended to initialize with 'git init' first.${NC}"
    echo -n "Continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${RED}✗ Installation cancelled${NC}"
        exit 1
    fi
fi

# Check if BMAD already exists
if [[ -d ".bmad-core" ]]; then
    echo -e "${YELLOW}⚠️  BMAD already installed in .bmad-core${NC}"
    echo -n "Reinstall? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
    rm -rf .bmad-core
fi

# Install BMAD using preferred package manager
echo -e "${BLUE}📦 Installing BMAD Method...${NC}"
echo -e "${CYAN}Default configuration: Claude-code + Cursor${NC}"
if command -v pnpm &> /dev/null; then
    pnpm dlx bmad-method@latest install --full --ide cursor --ide claude-code
elif command -v npm &> /dev/null; then
    npx bmad-method@latest install --full --ide cursor --ide claude-code
else
    echo -e "${RED}✗ No package manager found. Please install pnpm or npm.${NC}"
    exit 1
fi

# Check if installation was successful
if [[ -d ".bmad-core" ]]; then
    echo -e "${GREEN}✅ BMAD Method installed successfully!${NC}"
    echo -e "${CYAN}📍 Location: .bmad-core/ (ignored by git)${NC}"
    echo -e "${CYAN}🎯 Commands: bmad-install, bmad-update, bmad-status${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi

# Check .gitignore
if [[ -f ".gitignore" ]] && ! grep -q "^\.bmad-core/$" .gitignore; then
    echo -e "${YELLOW}💡 Don't forget to add '.bmad-core/' to your .gitignore${NC}"
fi