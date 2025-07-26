#!/usr/bin/env bash
# Update BMAD in .github/BMAD structure to latest version

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔄 Updating BMAD Method to latest version...${NC}"

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    echo "Please run this from your project root"
    exit 1
fi

# Check current version
CURRENT_VERSION=""
if [[ -f ".github/BMAD/bmad-core/core-config.yaml" ]]; then
    CURRENT_VERSION=$(grep "^version:" .github/BMAD/bmad-core/core-config.yaml | cut -d' ' -f2)
    echo -e "${CYAN}Current version: ${CURRENT_VERSION}${NC}"
fi

# Get latest version from npm
LATEST_VERSION=$(npm view bmad-method version 2>/dev/null || echo "")
if [[ -z "$LATEST_VERSION" ]]; then
    echo -e "${RED}Error: Could not fetch latest version from npm${NC}"
    exit 1
fi

echo -e "${CYAN}Latest version: ${LATEST_VERSION}${NC}"

# Check if update is needed
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo -e "${GREEN}✅ Already on latest version${NC}"
    exit 0
fi

# Backup current installation
if [[ -d ".github/BMAD/bmad-core" ]]; then
    echo -e "${YELLOW}📦 Backing up current installation...${NC}"
    BACKUP_DIR=".github/BMAD/.backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r .github/BMAD/bmad-core "$BACKUP_DIR/"
    echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
fi

# Create temporary directory for installation
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}📥 Downloading latest BMAD Method...${NC}"

# Navigate to temp directory
cd "$TEMP_DIR"

# Install latest BMAD
if command -v pnpm &> /dev/null; then
    pnpm dlx bmad-method@latest install --full --ide cursor -d "$TEMP_DIR"
else
    npx bmad-method@latest install --full --ide cursor -d "$TEMP_DIR"
fi

# Navigate back
cd - > /dev/null

# Update the installation
if [[ -d "$TEMP_DIR/.bmad-core" ]]; then
    echo -e "${BLUE}📝 Updating BMAD core files...${NC}"
    
    # Remove old core (but keep user customizations)
    rm -rf .github/BMAD/bmad-core
    
    # Copy new core
    mkdir -p .github/BMAD
    cp -r "$TEMP_DIR/.bmad-core" .github/BMAD/bmad-core
    
    echo -e "${GREEN}✅ Updated to version ${LATEST_VERSION}${NC}"
    
    # Show changelog if significant version change
    if [[ -n "$CURRENT_VERSION" ]]; then
        echo -e "\n${YELLOW}📋 Version updated from ${CURRENT_VERSION} to ${LATEST_VERSION}${NC}"
        echo -e "${CYAN}Check the changelog at: https://github.com/bmadcode/BMAD-METHOD/blob/main/CHANGELOG.md${NC}"
    fi
else
    echo -e "${RED}Error: Installation failed${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}✨ BMAD Method successfully updated!${NC}"
echo -e "${YELLOW}💡 Tip: Review any breaking changes in the changelog${NC}"

# Check if there are any custom agents or modifications
if [[ -d ".github/BMAD/custom" ]] || [[ -d ".github/BMAD/expansion-packs" ]]; then
    echo -e "\n${YELLOW}⚠️  Custom content detected:${NC}"
    [[ -d ".github/BMAD/custom" ]] && echo -e "  - Custom agents in .github/BMAD/custom"
    [[ -d ".github/BMAD/expansion-packs" ]] && echo -e "  - Expansion packs in .github/BMAD/expansion-packs"
    echo -e "${CYAN}These were preserved during the update${NC}"
fi