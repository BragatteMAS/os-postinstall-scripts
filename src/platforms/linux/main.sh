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

source "${SCRIPT_DIR}/../../core/packages.sh" || {
    log_error "Failed to load packages.sh"
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
    echo "1. Full installation (APT + Cargo)"
    echo "2. APT packages only"
    echo "3. Cargo (Rust) packages only"
    echo "4. Snap packages only"
    echo "5. Flatpak packages only"
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
            log_info "Starting full installation..."
            bash "${SCRIPT_DIR}/install/apt.sh"
            bash "${SCRIPT_DIR}/install/cargo.sh"
            ;;
        2)
            bash "${SCRIPT_DIR}/install/apt.sh"
            ;;
        3)
            bash "${SCRIPT_DIR}/install/cargo.sh"
            ;;
        4)
            # TODO: Migrate snap.sh to data-driven in Phase 5
            log_warn "Snap installer not yet migrated to new structure"
            ;;
        5)
            # TODO: Migrate flatpak.sh to data-driven in Phase 5
            log_warn "Flatpak installer not yet migrated to new structure"
            ;;
        6)
            # TODO: Migrate desktop-environments.sh in Phase 5
            log_warn "Desktop environments installer not yet migrated"
            ;;
        7)
            log_info "Verification not yet implemented"
            ;;
        0)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_warn "Invalid choice"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
