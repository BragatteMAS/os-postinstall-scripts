#!/usr/bin/env bash
# upgrade-bash.sh - Upgrade Bash to version 4.0+ on macOS

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Bash Upgrade Script ===${NC}\n"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}This script is only needed for macOS.${NC}"
    echo -e "${GREEN}Your system likely already has Bash 4.0+${NC}"
    exit 0
fi

# Check current Bash version
current_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo -e "Current Bash version: ${YELLOW}$current_version${NC}"

if [[ "${current_version%%.*}" -ge 4 ]]; then
    echo -e "${GREEN}✓ Bash is already version 4.0 or higher!${NC}"
    exit 0
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew is not installed.${NC}"
    echo -e "${YELLOW}Installing Homebrew first...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install latest Bash
echo -e "\n${BLUE}Installing latest Bash via Homebrew...${NC}"
brew install bash

# Get the path to the new bash
if [[ -f "/opt/homebrew/bin/bash" ]]; then
    NEW_BASH="/opt/homebrew/bin/bash"  # M1/M2 Macs
elif [[ -f "/usr/local/bin/bash" ]]; then
    NEW_BASH="/usr/local/bin/bash"     # Intel Macs
else
    echo -e "${RED}✗ Could not find newly installed Bash${NC}"
    exit 1
fi

# Verify new version
new_version=$($NEW_BASH --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo -e "\nNew Bash version: ${GREEN}$new_version${NC}"
echo -e "Location: ${GREEN}$NEW_BASH${NC}"

# Add to shells if not already there
echo -e "\n${BLUE}Adding new Bash to allowed shells...${NC}"
if ! grep -q "$NEW_BASH" /etc/shells; then
    echo "$NEW_BASH" | sudo tee -a /etc/shells
    echo -e "${GREEN}✓ Added to /etc/shells${NC}"
else
    echo -e "${GREEN}✓ Already in /etc/shells${NC}"
fi

# Ask if user wants to change default shell
echo -e "\n${YELLOW}Do you want to set the new Bash as your default shell?${NC}"
echo -e "Current shell: $SHELL"
echo -n "Change to $NEW_BASH? (y/N): "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    chsh -s "$NEW_BASH"
    echo -e "${GREEN}✓ Default shell changed to $NEW_BASH${NC}"
    echo -e "${YELLOW}Note: You'll need to open a new terminal for the change to take effect.${NC}"
else
    echo -e "${BLUE}Default shell unchanged.${NC}"
    echo -e "${YELLOW}To use the new Bash, run: $NEW_BASH${NC}"
fi

# Verify installation
echo -e "\n${BLUE}=== Installation Summary ===${NC}"
echo -e "Old Bash: ${YELLOW}/bin/bash${NC} (version $current_version)"
echo -e "New Bash: ${GREEN}$NEW_BASH${NC} (version $new_version)"

# Test new bash
echo -e "\n${BLUE}Testing new Bash features...${NC}"
$NEW_BASH -c 'declare -A test_array=([key]="value"); echo "✓ Associative arrays work!"'

echo -e "\n${GREEN}=== Bash upgrade completed successfully! ===${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Open a new terminal window"
echo -e "2. Run: bash --version"
echo -e "3. Continue with the installation"