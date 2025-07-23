#!/bin/bash
# Profile-based setup script for OS Post-Install Scripts
# Allows users to install using predefined profiles

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "${SCRIPT_DIR}/utils/profile-loader.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Default values
PROFILE=""
DRY_RUN=false
LIST_ONLY=false
SHOW_DETAILS=false

# Show usage
usage() {
    cat << EOF
${PURPLE}OS Post-Install Scripts - Profile-Based Installer${NC}

Usage: $0 [OPTIONS]

OPTIONS:
    -p, --profile NAME     Use specific profile (default: interactive selection)
    -l, --list            List available profiles and exit
    -d, --details NAME    Show details of a specific profile
    -n, --dry-run         Show what would be installed without doing it
    -h, --help            Show this help message

EXAMPLES:
    $0                    # Interactive profile selection
    $0 -p minimal         # Use minimal profile
    $0 -l                 # List all profiles
    $0 -d devops          # Show devops profile details
    $0 -p student -n      # Dry run with student profile

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -d|--details)
            SHOW_DETAILS=true
            PROFILE="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Header
echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║        OS Post-Install Scripts - Profile Installer     ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
echo

# List profiles and exit if requested
if [[ "$LIST_ONLY" == "true" ]]; then
    list_profiles
    exit 0
fi

# Show profile details and exit if requested
if [[ "$SHOW_DETAILS" == "true" ]]; then
    show_profile_details "$PROFILE"
    exit 0
fi

# Interactive profile selection if not specified
if [[ -z "$PROFILE" ]]; then
    echo -e "${BLUE}Please select a profile:${NC}"
    echo
    
    # Get list of profiles
    profiles=()
    for p in "${SCRIPT_DIR}/profiles"/*.yaml; do
        if [[ -f "$p" ]]; then
            profiles+=("$(basename "$p" .yaml)")
        fi
    done
    
    # Show numbered list
    for i in "${!profiles[@]}"; do
        desc=$(grep -m1 "^description:" "${SCRIPT_DIR}/profiles/${profiles[$i]}.yaml" | cut -d: -f2- | sed 's/^ *//')
        printf "  %2d) %-20s - %s\n" $((i+1)) "${profiles[$i]}" "$desc"
    done
    echo
    
    # Get selection
    read -p "Enter number (1-${#profiles[@]}): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#profiles[@]}" ]]; then
        PROFILE="${profiles[$((selection-1))]}"
        echo
    else
        echo -e "${RED}Invalid selection${NC}"
        exit 1
    fi
fi

# Load the selected profile
if ! load_profile "$PROFILE"; then
    exit 1
fi

# Show what will be installed
echo -e "\n${BLUE}Profile: ${YELLOW}$ACTIVE_PROFILE_NAME${NC}"
echo -e "${BLUE}Description:${NC} $(get_profile_metadata 'description')"
echo

# Confirm installation
if [[ "$DRY_RUN" == "false" ]]; then
    echo -e "${YELLOW}This will install the packages defined in the profile.${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled${NC}"
        exit 0
    fi
fi

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/debian_version ]]; then
            echo "debian"
        elif [[ -f /etc/fedora-release ]]; then
            echo "fedora"
        elif [[ -f /etc/arch-release ]]; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# Install packages based on profile
install_from_profile() {
    local packages=$(get_profile_packages)
    local total=$(echo "$packages" | wc -l)
    local current=0
    
    echo -e "\n${BLUE}Installing packages...${NC}"
    
    # Group packages by type for efficient installation
    local apt_packages=""
    local snap_packages=""
    local flatpak_packages=""
    
    while IFS= read -r package; do
        ((current++))
        
        # Skip empty lines and comments
        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^[[:space:]]*# ]] && continue
        
        # Remove inline comments
        package=$(echo "$package" | sed 's/[[:space:]]*#.*//')
        
        echo -e "\n${BLUE}[$current/$total]${NC} Processing: ${YELLOW}$package${NC}"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Would install: $package"
            continue
        fi
        
        # Determine package manager and accumulate
        case "$OS_TYPE" in
            debian)
                # Check if it's a snap or flatpak
                if [[ "$package" =~ ^snap: ]]; then
                    snap_packages+=" ${package#snap:}"
                elif [[ "$package" =~ ^flatpak: ]]; then
                    flatpak_packages+=" ${package#flatpak:}"
                else
                    apt_packages+=" $package"
                fi
                ;;
            macos)
                echo "  brew install $package"
                ;;
            *)
                echo "  Unsupported OS for automatic installation"
                ;;
        esac
    done <<< "$packages"
    
    # Batch install accumulated packages
    if [[ "$DRY_RUN" == "false" ]] && [[ "$OS_TYPE" == "debian" ]]; then
        if [[ -n "$apt_packages" ]]; then
            echo -e "\n${BLUE}Installing APT packages...${NC}"
            # Source safety module and use it
            source "${SCRIPT_DIR}/utils/package-manager-safety.sh"
            safe_apt_update
            for pkg in $apt_packages; do
                safe_apt_install "$pkg"
            done
        fi
        
        if [[ -n "$snap_packages" ]]; then
            echo -e "\n${BLUE}Installing Snap packages...${NC}"
            for pkg in $snap_packages; do
                sudo snap install "$pkg"
            done
        fi
        
        if [[ -n "$flatpak_packages" ]]; then
            echo -e "\n${BLUE}Installing Flatpak packages...${NC}"
            for pkg in $flatpak_packages; do
                flatpak install -y flathub "$pkg"
            done
        fi
    fi
}

# Main installation
install_from_profile

# Post-install actions
if [[ "$DRY_RUN" == "false" ]]; then
    echo -e "\n${GREEN}✓ Installation complete!${NC}"
    
    # Run post-install message
    message=$(get_profile_metadata 'post_install.message' || echo "Installation finished!")
    echo -e "\n${GREEN}$message${NC}"
else
    echo -e "\n${YELLOW}Dry run complete. No packages were installed.${NC}"
fi

# Show summary
echo -e "\n${BLUE}Summary:${NC}"
echo "Profile used: $ACTIVE_PROFILE_NAME"
echo "OS detected: $OS_TYPE"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "Mode: Dry run (no changes made)"
fi

echo -e "\n${GREEN}Done!${NC}"