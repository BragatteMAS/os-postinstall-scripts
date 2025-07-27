#!/usr/bin/env bash
# Update BMAD Method to latest version
# Simple, clean, functional

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔄 Updating BMAD Method to latest version...${NC}"

# Check if BMAD is installed
if [[ ! -d ".bmad-core" ]]; then
    echo -e "${RED}✗ BMAD not found in .bmad-core${NC}"
    echo -e "${YELLOW}💡 Run './install_bmad.sh' first${NC}"
    exit 1
fi

# Get current version
CURRENT_VERSION=""
if [[ -f ".bmad-core/install-manifest.yaml" ]]; then
    CURRENT_VERSION=$(grep "^version:" .bmad-core/install-manifest.yaml 2>/dev/null | cut -d' ' -f2 || echo "unknown")
    echo -e "${CYAN}Current version: ${CURRENT_VERSION}${NC}"
fi

# Get latest version from npm
echo -e "${BLUE}🔍 Checking for updates...${NC}"
LATEST_VERSION=$(npm view bmad-method version 2>/dev/null || echo "")
if [[ -z "$LATEST_VERSION" ]]; then
    echo -e "${RED}✗ Could not fetch latest version from npm${NC}"
    exit 1
fi

echo -e "${CYAN}Latest version: ${LATEST_VERSION}${NC}"

# Check if update is needed
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo -e "${GREEN}✅ Already on latest version${NC}"
    exit 0
fi

# Backup current installation
echo -e "${YELLOW}📦 Backing up current installation...${NC}"
BACKUP_DIR=".bmad-backup-$(date +%Y%m%d-%H%M%S)"
cp -r .bmad-core "$BACKUP_DIR"
echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"

# Update BMAD
echo -e "${BLUE}🚀 Updating BMAD Method...${NC}"
if command -v pnpm &> /dev/null; then
    pnpm dlx bmad-method@latest update
elif command -v npm &> /dev/null; then
    npx bmad-method@latest update
else
    echo -e "${RED}✗ No package manager found${NC}"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# Verify update
NEW_VERSION=$(grep "^version:" .bmad-core/install-manifest.yaml 2>/dev/null | cut -d' ' -f2 || echo "unknown")
if [[ "$NEW_VERSION" == "$LATEST_VERSION" ]]; then
    echo -e "${GREEN}✅ Successfully updated to v${LATEST_VERSION}${NC}"
    rm -rf "$BACKUP_DIR"
else
    echo -e "${YELLOW}⚠️  Update may have failed. Backup kept at: $BACKUP_DIR${NC}"
fi

echo -e "${CYAN}📋 Changelog: https://github.com/bmadcode/BMAD-METHOD/blob/main/CHANGELOG.md${NC}"