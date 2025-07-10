#!/usr/bin/env bash
# Main orchestrator for Linux post-installation
set -euo pipefail
IFS=$'\n\t'

# Source utilities
source "$(dirname "$0")/utils/logging.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show menu
show_menu() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           🐧 Linux Post-Installation Script 🐧                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Select installation type:"
    echo "1. Full installation (APT + Snap + Flatpak)"
    echo "2. APT packages only"
    echo "3. Snap packages only"
    echo "4. Flatpak packages only"
    echo "5. Anaconda/Python setup"
    echo "6. Desktop environments"
    echo "7. Verify installation"
    echo "0. Exit"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1)
            log "Starting full installation..."
            bash "$(dirname "$0")/install/apt.sh"
            bash "$(dirname "$0")/install/snap.sh"
            bash "$(dirname "$0")/install/flatpak.sh"
            ;;
        2)
            bash "$(dirname "$0")/install/apt.sh"
            ;;
        3)
            bash "$(dirname "$0")/install/snap.sh"
            ;;
        4)
            bash "$(dirname "$0")/install/flatpak.sh"
            ;;
        5)
            bash "$(dirname "$0")/install/anaconda.sh"
            ;;
        6)
            bash "$(dirname "$0")/install/desktop-environments.sh"
            ;;
        7)
            if [[ -f "$(dirname "$0")/verify/check-installation.sh" ]]; then
                bash "$(dirname "$0")/verify/check-installation.sh"
            else
                echo "Verification script not yet implemented"
            fi
            ;;
        0)
            log "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
