#!/usr/bin/env bash
# verify-migration.sh - Verify the migration was successful
# Author: Bragatte, M.A.S

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verifying migration...${NC}\n"

# Track errors
ERRORS=0

# Function to check if file/directory exists
check_exists() {
    local path="$1"
    local type="$2"  # file or directory
    
    if [[ "$type" == "file" ]] && [[ -f "$path" ]]; then
        echo -e "${GREEN}✓${NC} Found file: $path"
    elif [[ "$type" == "directory" ]] && [[ -d "$path" ]]; then
        echo -e "${GREEN}✓${NC} Found directory: $path"
    else
        echo -e "${RED}✗${NC} Missing $type: $path"
        ((ERRORS++))
    fi
}

# Function to check symlink
check_symlink() {
    local link="$1"
    local target="$2"
    
    if [[ -L "$link" ]]; then
        local actual_target=$(readlink "$link")
        if [[ "$actual_target" == "$target" ]]; then
            echo -e "${GREEN}✓${NC} Symlink OK: $link → $target"
        else
            echo -e "${YELLOW}⚠${NC} Symlink points to: $link → $actual_target (expected $target)"
        fi
    else
        echo -e "${RED}✗${NC} Missing symlink: $link"
        ((ERRORS++))
    fi
}

echo -e "${BLUE}Checking directory structure...${NC}"
# Check main directories
check_exists "scripts/install" "directory"
check_exists "scripts/setup" "directory"
check_exists "scripts/utils" "directory"
check_exists "platforms/linux" "directory"
check_exists "platforms/macos" "directory"
check_exists "platforms/windows" "directory"
check_exists "configs/profiles" "directory"
check_exists "configs/templates/git" "directory"
check_exists "configs/shell" "directory"
check_exists "docs/guides" "directory"
check_exists "docs/architecture" "directory"
check_exists "tools/dev" "directory"
check_exists "tools/check" "directory"

echo -e "\n${BLUE}Checking migrated scripts...${NC}"
# Check install scripts
check_exists "scripts/install/ai-tools.sh" "file"
check_exists "scripts/install/bmad.sh" "file"
check_exists "scripts/install/rust-tools.sh" "file"
check_exists "scripts/install/git-focused.sh" "file"

# Check setup scripts
check_exists "scripts/setup/main.sh" "file"
check_exists "scripts/setup/with-profile.sh" "file"
check_exists "scripts/setup/ai-project.sh" "file"

# Check utils
check_exists "scripts/utils/logging.sh" "file"
check_exists "scripts/utils/package-safety.sh" "file"
check_exists "scripts/utils/profile-loader.sh" "file"

# Check configs
check_exists "configs/shell/zshrc" "file"
check_exists "configs/shell/zshrc-rust.zsh" "file"

echo -e "\n${BLUE}Checking compatibility symlinks...${NC}"
check_symlink "setup.sh" "scripts/setup/main.sh"
check_symlink ".zshrc" "configs/shell/zshrc"

echo -e "\n${BLUE}Checking README files...${NC}"
check_exists "scripts/README.md" "file"
check_exists "platforms/README.md" "file"
check_exists "configs/README.md" "file"

echo -e "\n${BLUE}Checking for removed directories...${NC}"
# These should NOT exist after migration
for dir in lib utils profiles global-git-templates; do
    if [[ -d "$dir" ]]; then
        echo -e "${YELLOW}⚠${NC} Old directory still exists: $dir"
    else
        echo -e "${GREEN}✓${NC} Old directory removed: $dir"
    fi
done

# Test script execution
echo -e "\n${BLUE}Testing script execution...${NC}"
if bash -n scripts/setup/main.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Main setup script syntax OK"
else
    echo -e "${RED}✗${NC} Main setup script has syntax errors"
    ((ERRORS++))
fi

# Summary
echo -e "\n${BLUE}========== Summary ==========${NC}"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}✅ Migration verified successfully!${NC}"
    echo -e "${GREEN}All checks passed.${NC}"
else
    echo -e "${RED}❌ Migration has $ERRORS errors!${NC}"
    echo -e "${YELLOW}Please review the errors above.${NC}"
    exit 1
fi