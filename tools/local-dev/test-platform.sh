#!/bin/bash
# Test specific platform locally (cross-platform simulation)
# This script simulates testing for different platforms without CI/CD

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🧪 Cross-Platform Local Test Runner${NC}"
echo -e "${YELLOW}⚠️  Simulating platform: ${OS_TARGET}${NC}"
echo -e "${YELLOW}⚠️  This is a LOCAL simulation - No CI/CD will be triggered${NC}\n"

# Get target platform from environment
TARGET_PLATFORM="${OS_TARGET:-linux}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Platform-specific checks
case "$TARGET_PLATFORM" in
    linux)
        echo -e "${PURPLE}Simulating Linux environment tests...${NC}"
        
        # Check Ubuntu-specific scripts
        echo -e "\n${BLUE}Checking Ubuntu/Debian scripts...${NC}"
        if [ -f "linux/install/apt.sh" ]; then
            echo -e "${GREEN}✓${NC} APT package manager script found"
            # Simulate syntax check
            bash -n "linux/install/apt.sh" 2>/dev/null && \
                echo -e "${GREEN}✓${NC} APT script syntax OK" || \
                echo -e "${RED}✗${NC} APT script has syntax errors"
        fi
        
        # Check for distro-specific directories
        echo -e "\n${BLUE}Checking distribution support...${NC}"
        for distro in "Ubuntu" "Mint" "POP-OS"; do
            if [ -d "linux/distros/$distro" ]; then
                echo -e "${GREEN}✓${NC} $distro support found"
            else
                echo -e "${YELLOW}⚠${NC} $distro directory missing"
            fi
        done
        
        # Simulate package availability check
        echo -e "\n${BLUE}Simulating package availability...${NC}"
        echo -e "${GREEN}✓${NC} git (would be checked with apt-cache)"
        echo -e "${GREEN}✓${NC} curl (would be checked with apt-cache)"
        echo -e "${GREEN}✓${NC} wget (would be checked with apt-cache)"
        ;;
        
    windows)
        echo -e "${PURPLE}Simulating Windows environment tests...${NC}"
        
        # Check PowerShell scripts
        echo -e "\n${BLUE}Checking Windows scripts...${NC}"
        if [ -f "windows/win11.ps1" ]; then
            echo -e "${GREEN}✓${NC} Windows 11 script found"
            # Basic check for PowerShell syntax markers
            if grep -q "winget" "windows/win11.ps1"; then
                echo -e "${GREEN}✓${NC} Winget commands detected"
            fi
        fi
        
        # Simulate winget package checks
        echo -e "\n${BLUE}Simulating winget package availability...${NC}"
        echo -e "${GREEN}✓${NC} Microsoft.WindowsTerminal (would check with winget)"
        echo -e "${GREEN}✓${NC} Git.Git (would check with winget)"
        echo -e "${GREEN}✓${NC} Microsoft.VisualStudioCode (would check with winget)"
        ;;
        
    darwin)
        echo -e "${PURPLE}Simulating macOS environment tests...${NC}"
        
        # Check for Homebrew formulas
        echo -e "\n${BLUE}Checking macOS scripts...${NC}"
        if [ -d "mac" ]; then
            echo -e "${GREEN}✓${NC} macOS directory found"
            
            # Simulate Homebrew checks
            echo -e "\n${BLUE}Simulating Homebrew package availability...${NC}"
            echo -e "${GREEN}✓${NC} git (would check with brew)"
            echo -e "${GREEN}✓${NC} wget (would check with brew)"
            echo -e "${GREEN}✓${NC} curl (would check with brew)"
        else
            echo -e "${RED}✗${NC} macOS directory missing"
        fi
        ;;
        
    *)
        echo -e "${RED}Unknown platform: $TARGET_PLATFORM${NC}"
        echo -e "${YELLOW}Supported platforms: linux, windows, darwin${NC}"
        exit 1
        ;;
esac

# Cross-platform compatibility checks
echo -e "\n${PURPLE}Cross-platform compatibility checks...${NC}"

# Check for platform-agnostic scripts
echo -e "${BLUE}Checking shared components...${NC}"
shared_scripts=(
    "setup.sh"
    "setup-with-profile.sh"
    "install_ai_tools.sh"
)

for script in "${shared_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo -e "${GREEN}✓${NC} $script (cross-platform)"
    else
        echo -e "${YELLOW}⚠${NC} $script missing"
    fi
done

# Profile compatibility
echo -e "\n${BLUE}Checking profile compatibility for $TARGET_PLATFORM...${NC}"
for profile in profiles/*.yaml; do
    if [ -f "$profile" ]; then
        profile_name=$(basename "$profile" .yaml)
        echo -e "${GREEN}✓${NC} Profile '$profile_name' available"
    fi
done

echo -e "\n${GREEN}Local simulation completed for $TARGET_PLATFORM!${NC}"
echo -e "${BLUE}Note:${NC} This was a simulation. Actual platform testing requires:"
echo -e "  - For Linux: Run on actual Linux system or container"
echo -e "  - For Windows: Run on Windows with WSL or native"
echo -e "  - For macOS: Run on actual macOS system"
echo -e "\n${YELLOW}For real CI/CD tests, trigger manually in GitHub Actions.${NC}"