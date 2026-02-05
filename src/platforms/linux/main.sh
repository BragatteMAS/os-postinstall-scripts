#!/usr/bin/env bash
#######################################
# Script: main.sh
# Description: Main orchestrator for Linux post-installation
# Author: Bragatte
# Date: 2026-02-05
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Source core utilities from src/core/
source "${SCRIPT_DIR}/../../core/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${SCRIPT_DIR}/../../core/platform.sh" || {
    log_error "Failed to load platform.sh"
    exit 1
}

# Cleanup function
cleanup() {
    local exit_code=$?
    [[ $exit_code -ne 0 ]] && log "Exiting ${SCRIPT_NAME} with code $exit_code"
    exit $exit_code
}
trap cleanup EXIT INT TERM

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
