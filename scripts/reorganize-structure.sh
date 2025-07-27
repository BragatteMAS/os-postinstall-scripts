#!/usr/bin/env bash
# Reorganize script structure
# Part of Story 1: Script Organization
set -euo pipefail
IFS=$'\n\t'

source linux/auto/logging.sh

log "🔄 Starting script reorganization..."

# Create new directory structure
log "Creating new directory structure..."

mkdir -p linux/install
mkdir -p linux/config
mkdir -p linux/verify
mkdir -p linux/utils

# Move and rename scripts with consistent naming
log "Moving scripts to new structure..."

# Install scripts
if [[ -f "linux/auto/auto_apt.sh" ]]; then
    cp linux/auto/auto_apt.sh linux/install/apt.sh
    log "  ✓ Moved auto_apt.sh → install/apt.sh"
fi

if [[ -f "linux/auto/auto_snap.sh" ]]; then
    cp linux/auto/auto_snap.sh linux/install/snap.sh
    log "  ✓ Moved auto_snap.sh → install/snap.sh"
fi

if [[ -f "linux/auto/auto_flat.sh" ]]; then
    cp linux/auto/auto_flat.sh linux/install/flatpak.sh
    log "  ✓ Moved auto_flat.sh → install/flatpak.sh"
fi

if [[ -f "linux/auto/anaconda3.sh" ]]; then
    cp linux/auto/anaconda3.sh linux/install/anaconda.sh
    log "  ✓ Moved anaconda3.sh → install/anaconda.sh"
fi

if [[ -f "linux/auto/flavors.sh" ]]; then
    cp linux/auto/flavors.sh linux/install/desktop-environments.sh
    log "  ✓ Moved flavors.sh → install/desktop-environments.sh"
fi

# Utils
if [[ -f "linux/auto/logging.sh" ]]; then
    cp linux/auto/logging.sh linux/utils/logging.sh
    log "  ✓ Moved logging.sh → utils/logging.sh"
fi

# Create main orchestrator script
log "Creating main orchestrator script..."

cat > linux/main.sh << 'EOF'
#!/usr/bin/env bash
# Main orchestrator for Linux post-installation
set -euo pipefail
IFS=$'\n\t'

# Source utilities
source "${SCRIPT_DIR}/../utils/logging.sh""

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
EOF

chmod +x linux/main.sh

# Create compatibility wrapper for post_install.sh
log "Creating compatibility wrapper..."

cat > linux/post_install_new.sh << 'EOF'
#!/usr/bin/env bash
# Compatibility wrapper - redirects to new main.sh
set -euo pipefail
IFS=$'\n\t'

echo "Note: post_install.sh has been reorganized into main.sh"
echo "Redirecting to new structure..."
echo ""

exec "$(dirname "$0")/main.sh" "$@"
EOF

chmod +x linux/post_install_new.sh

# Update install_rust_tools.sh name for consistency
if [[ -f "install_rust_tools.sh" ]]; then
    cp install_rust_tools.sh install-rust-tools.sh
    log "  ✓ Created install-rust-tools.sh with consistent naming"
fi

log "✅ Reorganization complete!"
log ""
log "New structure created:"
log "  linux/"
log "  ├── main.sh           # New main orchestrator"
log "  ├── install/          # Installation scripts"
log "  │   ├── apt.sh"
log "  │   ├── snap.sh"
log "  │   ├── flatpak.sh"
log "  │   ├── anaconda.sh"
log "  │   └── desktop-environments.sh"
log "  ├── utils/            # Utility scripts"
log "  │   └── logging.sh"
log "  └── verify/           # Verification scripts"
log ""
log "Note: Original files preserved in linux/auto/ for rollback"