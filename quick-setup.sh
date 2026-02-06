#!/usr/bin/env bash
# quick-setup.sh - Quick setup with automatic requirements installation

set -euo pipefail
IFS=$'\n\t'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== OS Post-Install Scripts - Quick Setup ===${NC}\n"

# Function to install requirements on macOS
install_macos_requirements() {
    echo -e "${YELLOW}Installing requirements for macOS...${NC}"
    
    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        echo -e "${BLUE}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install required tools
    echo -e "${BLUE}Installing required tools...${NC}"
    brew install bash git curl jq
    
    # Get new bash path
    if [[ -f "/opt/homebrew/bin/bash" ]]; then
        NEW_BASH="/opt/homebrew/bin/bash"
    elif [[ -f "/usr/local/bin/bash" ]]; then
        NEW_BASH="/usr/local/bin/bash"
    fi
    
    # Add to shells if needed
    if [[ -n "${NEW_BASH:-}" ]] && ! grep -q "$NEW_BASH" /etc/shells; then
        echo "$NEW_BASH" | sudo tee -a /etc/shells
    fi
    
    echo -e "${GREEN}✓ macOS requirements installed${NC}"
}

# Function to install requirements on Linux
install_linux_requirements() {
    echo -e "${YELLOW}Installing requirements for Linux...${NC}"
    
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y bash git curl jq build-essential
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y bash git curl jq gcc make
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm bash git curl jq base-devel
    else
        echo -e "${RED}Unsupported package manager${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Linux requirements installed${NC}"
}

# Detect OS and install requirements
echo -e "${BLUE}Detecting operating system...${NC}"
case "$OSTYPE" in
    darwin*)
        echo -e "Detected: ${GREEN}macOS${NC}"
        install_macos_requirements
        ;;
    linux*)
        echo -e "Detected: ${GREEN}Linux${NC}"
        install_linux_requirements
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
        exit 1
        ;;
esac

# Now run the main setup with the updated bash
echo -e "\n${BLUE}Running main setup...${NC}"

# Use the new bash if available
if [[ -n "${NEW_BASH:-}" ]] && [[ -x "$NEW_BASH" ]]; then
    echo -e "${BLUE}Using updated Bash: $NEW_BASH${NC}"
    exec "$NEW_BASH" ./setup.sh "$@"
else
    # On Linux or if bash was already updated
    exec bash ./setup.sh "$@"
fi