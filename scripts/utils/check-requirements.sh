#!/usr/bin/env bash
# check-requirements.sh - Verify system meets minimum requirements

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track if all requirements are met
REQUIREMENTS_MET=true

echo -e "${BLUE}=== System Requirements Check ===${NC}\n"

# Function to check command exists and version
check_tool() {
    local tool=$1
    local min_version=$2
    local version_cmd=$3
    local version_pattern=$4
    
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}✗ $tool: NOT INSTALLED${NC}"
        REQUIREMENTS_MET=false
        return 1
    fi
    
    if [[ -n "$min_version" ]]; then
        local installed_version
        installed_version=$($version_cmd 2>/dev/null | grep -oE "$version_pattern" | head -1)
        
        if [[ -n "$installed_version" ]]; then
            # Simple version comparison (works for x.y format)
            local installed_major="${installed_version%%.*}"
            local required_major="${min_version%%.*}"
            
            if [[ "$installed_major" -ge "$required_major" ]]; then
                echo -e "${GREEN}✓ $tool: $installed_version${NC}"
            else
                echo -e "${YELLOW}⚠ $tool: $installed_version (requires $min_version+)${NC}"
                REQUIREMENTS_MET=false
            fi
        else
            echo -e "${YELLOW}⚠ $tool: installed (version unknown)${NC}"
        fi
    else
        echo -e "${GREEN}✓ $tool: installed${NC}"
    fi
}

# Check Operating System
echo -e "${YELLOW}Operating System:${NC}"
case "$OSTYPE" in
    darwin*)
        echo -e "  ${GREEN}✓ macOS detected${NC}"
        # Check macOS version
        macos_version=$(sw_vers -productVersion)
        echo -e "  Version: $macos_version"
        ;;
    linux*)
        echo -e "  ${GREEN}✓ Linux detected${NC}"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo -e "  Distribution: $NAME $VERSION"
        fi
        ;;
    msys*|cygwin*|mingw*)
        echo -e "  ${GREEN}✓ Windows (Git Bash/WSL) detected${NC}"
        ;;
    *)
        echo -e "  ${RED}✗ Unknown OS: $OSTYPE${NC}"
        REQUIREMENTS_MET=false
        ;;
esac
echo ""

# Check Shell Requirements
echo -e "${YELLOW}Shell Requirements:${NC}"

# Check Bash version
echo -n "  Bash: "
bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
bash_major="${bash_version%%.*}"
if [[ "$bash_major" -ge 4 ]]; then
    echo -e "${GREEN}✓ $bash_version${NC}"
else
    echo -e "${RED}✗ $bash_version (requires 4.0+)${NC}"
    REQUIREMENTS_MET=false
    
    # Provide upgrade instructions
    echo -e "\n  ${YELLOW}To upgrade Bash:${NC}"
    case "$OSTYPE" in
        darwin*)
            echo "    brew install bash"
            echo "    echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells"
            echo "    chsh -s /opt/homebrew/bin/bash"
            ;;
        linux*)
            echo "    Use your package manager to update bash"
            ;;
    esac
fi

# Check Zsh
echo -n "  Zsh: "
check_tool "zsh" "5.0" "zsh --version" "[0-9]+\.[0-9]+"
echo ""

# Check Core Dependencies
echo -e "${YELLOW}Core Dependencies:${NC}"
check_tool "git" "2.25" "git --version" "[0-9]+\.[0-9]+"
check_tool "curl" "" "" ""
check_tool "jq" "1.6" "jq --version" "[0-9]+\.[0-9]+"
echo ""

# Check Package Managers
echo -e "${YELLOW}Package Managers:${NC}"
case "$OSTYPE" in
    darwin*)
        if command -v brew &> /dev/null; then
            echo -e "  ${GREEN}✓ Homebrew: $(brew --version | head -1)${NC}"
        else
            echo -e "  ${RED}✗ Homebrew: NOT INSTALLED${NC}"
            echo -e "  ${YELLOW}Install with:${NC}"
            echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            REQUIREMENTS_MET=false
        fi
        ;;
    linux*)
        # Check common package managers
        for pm in apt dnf pacman zypper; do
            if command -v $pm &> /dev/null; then
                echo -e "  ${GREEN}✓ $pm: available${NC}"
                break
            fi
        done
        ;;
esac

# Check npm
check_tool "npm" "" "" ""
echo ""

# Check Optional but Recommended Tools
echo -e "${YELLOW}Recommended Tools:${NC}"
check_tool "python3" "3.8" "python3 --version" "[0-9]+\.[0-9]+"
check_tool "node" "16" "node --version" "[0-9]+"
check_tool "rustc" "" "rustc --version" "[0-9]+\.[0-9]+\.[0-9]+"
echo ""

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
if [[ "$REQUIREMENTS_MET" == true ]]; then
    echo -e "${GREEN}✓ All minimum requirements are met!${NC}"
    echo -e "${GREEN}You can proceed with the installation.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some requirements are not met.${NC}"
    echo -e "${YELLOW}Please install missing dependencies before proceeding.${NC}"
    echo -e "\nRefer to REQUIREMENTS.md for detailed instructions."
    exit 1
fi