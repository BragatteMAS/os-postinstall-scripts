#!/usr/bin/env bash
# Verify installed tools and packages
# Part of Story 2: Verification System
set -euo pipefail
IFS=$'\n\t'

# Source utilities
source "$(dirname "$0")/../utils/logging.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL=0
FOUND=0
MISSING=0

# Check function
check_tool() {
    local tool="$1"
    local package="${2:-$1}"  # Use tool name as package name if not specified
    
    ((TOTAL++))
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $tool ($(command -v $tool))"
        ((FOUND++))
    else
        echo -e "${RED}✗${NC} $tool (package: $package)"
        ((MISSING++))
    fi
}

# Check package managers
check_package_manager() {
    local pm="$1"
    local check_cmd="$2"
    
    echo -e "\n${BLUE}=== $pm Packages ===${NC}"
    if ! command -v "$check_cmd" &> /dev/null; then
        echo -e "${YELLOW}⚠${NC} $pm not available"
        return
    fi
}

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              🔍 Installation Verification 🔍                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"

# System Information
echo -e "\n${BLUE}=== System Information ===${NC}"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

# Package Managers
echo -e "\n${BLUE}=== Package Managers ===${NC}"
check_tool apt
check_tool snap
check_tool flatpak

# Development Tools
echo -e "\n${BLUE}=== Development Tools ===${NC}"
check_tool git
check_tool gh "github-cli"
check_tool docker
check_tool docker-compose
check_tool code "visual-studio-code"
check_tool vim
check_tool python3
check_tool pip3
check_tool node "nodejs"
check_tool npm

# Rust Tools
echo -e "\n${BLUE}=== Rust-Powered Tools ===${NC}"
check_tool rustc "rust"
check_tool cargo "rust"
check_tool bat
check_tool eza
check_tool fd "fd-find"
check_tool rg "ripgrep"
check_tool delta "git-delta"
check_tool dust "du-dust"
check_tool bottom "bottom"
check_tool zoxide

# System Tools
echo -e "\n${BLUE}=== System Tools ===${NC}"
check_tool htop
check_tool neofetch
check_tool tree
check_tool jq
check_tool wget
check_tool curl
check_tool ssh "openssh-client"
check_tool zsh

# Check installed packages by package manager
if command -v apt &> /dev/null; then
    echo -e "\n${BLUE}=== APT Package Count ===${NC}"
    apt_count=$(dpkg -l | grep -c "^ii" || echo "0")
    echo "Installed APT packages: $apt_count"
fi

if command -v snap &> /dev/null; then
    echo -e "\n${BLUE}=== Snap Package Count ===${NC}"
    snap_count=$(snap list 2>/dev/null | tail -n +2 | wc -l || echo "0")
    echo "Installed Snap packages: $snap_count"
fi

if command -v flatpak &> /dev/null; then
    echo -e "\n${BLUE}=== Flatpak Package Count ===${NC}"
    flatpak_count=$(flatpak list --app 2>/dev/null | wc -l || echo "0")
    echo "Installed Flatpak apps: $flatpak_count"
fi

# Summary
echo -e "\n${BLUE}=== Verification Summary ===${NC}"
echo "Total checks: $TOTAL"
echo -e "Found: ${GREEN}$FOUND${NC}"
echo -e "Missing: ${RED}$MISSING${NC}"

if [[ $MISSING -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All checked tools are installed!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠ Some tools are missing. Run the appropriate installer.${NC}"
    exit 1
fi