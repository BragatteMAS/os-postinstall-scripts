#!/bin/bash
# Test current platform locally
# This script runs tests for the current OS without triggering CI/CD

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🧪 Local Platform Test Runner${NC}"
echo -e "${YELLOW}⚠️  Running tests locally - No CI/CD will be triggered${NC}\n"

# Detect current platform
case "$(uname -s)" in
    Darwin*)    PLATFORM="macos" ;;
    Linux*)     PLATFORM="linux" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *)          PLATFORM="unknown" ;;
esac

echo -e "${BLUE}Detected platform:${NC} $PLATFORM"
echo -e "${BLUE}Test mode:${NC} ${TEST_MODE:-local}"

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Run platform-specific tests
case "$PLATFORM" in
    linux)
        echo -e "\n${PURPLE}Running Linux tests...${NC}"
        
        # Check script syntax
        echo -e "${BLUE}Checking shell script syntax...${NC}"
        find linux -name "*.sh" -type f | while read -r script; do
            if bash -n "$script" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} $script"
            else
                echo -e "${RED}✗${NC} $script - syntax error"
            fi
        done
        
        # Check for required directories
        echo -e "\n${BLUE}Checking Linux directory structure...${NC}"
        for dir in "auto" "config" "distros" "install" "utils" "verify"; do
            if [ -d "linux/$dir" ]; then
                echo -e "${GREEN}✓${NC} linux/$dir/"
            else
                echo -e "${YELLOW}⚠${NC} linux/$dir/ missing"
            fi
        done
        ;;
        
    macos)
        echo -e "\n${PURPLE}Running macOS tests...${NC}"
        
        # Check for mac directory
        if [ -d "mac" ]; then
            echo -e "${GREEN}✓${NC} mac/ directory exists"
            
            # Check for install scripts
            if ls mac/*.sh 2>/dev/null | grep -q .; then
                echo -e "${GREEN}✓${NC} Found macOS scripts"
            else
                echo -e "${YELLOW}⚠${NC} No .sh scripts in mac/"
            fi
        else
            echo -e "${RED}✗${NC} mac/ directory missing"
        fi
        ;;
        
    windows)
        echo -e "\n${PURPLE}Running Windows tests...${NC}"
        
        # Check for PowerShell scripts
        if [ -f "windows/win11.ps1" ]; then
            echo -e "${GREEN}✓${NC} windows/win11.ps1 found"
        else
            echo -e "${RED}✗${NC} windows/win11.ps1 missing"
        fi
        ;;
        
    *)
        echo -e "${RED}Unknown platform: $PLATFORM${NC}"
        exit 1
        ;;
esac

# Common tests for all platforms
echo -e "\n${PURPLE}Running common tests...${NC}"

# Check profiles
echo -e "${BLUE}Checking profiles...${NC}"
for profile in profiles/*.yaml; do
    if [ -f "$profile" ]; then
        echo -e "${GREEN}✓${NC} $profile"
    fi
done

# Check documentation
echo -e "\n${BLUE}Checking documentation...${NC}"
required_docs=("README.md" "CHANGELOG.md" "LICENSE" "CONTRIBUTING.md")
for doc in "${required_docs[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC} $doc"
    else
        echo -e "${RED}✗${NC} $doc missing"
    fi
done

echo -e "\n${GREEN}Local tests completed!${NC}"
echo -e "${YELLOW}To run CI/CD tests, go to GitHub Actions and trigger manually.${NC}"