#!/usr/bin/env bash
#######################################
# Script: install-modular-zsh.sh
# Description: Sets up the modular zsh configuration system
# Author: Bragatte
# Date: 2025-02-05
#######################################

set -euo pipefail
IFS=$'\n\t'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source logging utilities (SSoT)
source "$SCRIPT_DIR/../utils/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

# Configuration
INSTALL_DIR="${HOME}/.config/os-postinstall"
BACKUP_DIR="${HOME}/.config/zsh-backups"

#######################################
# Create backup of existing zshrc
#######################################
backup_existing() {
    if [[ -f "$HOME/.zshrc" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc" "$backup_file"
        log_success "Backed up existing .zshrc to: $backup_file"
    fi
}

#######################################
# Install modular configuration
#######################################
install_modular_config() {
    log_info "Installing modular zsh configuration..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy necessary files
    log_info "Copying configuration files..."
    cp -r "$REPO_ROOT/configs" "$INSTALL_DIR/"
    cp -r "$REPO_ROOT/scripts" "$INSTALL_DIR/"
    
    # Create symlink for zshrc
    log_info "Creating .zshrc symlink..."
    ln -sf "$INSTALL_DIR/configs/shell/zshrc-modular" "$HOME/.zshrc"
    
    # Create local customization file if it doesn't exist
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        cat > "$HOME/.zshrc.local" << 'EOF'
# Local zsh customizations
# This file is not tracked in git
# Add your personal settings here

# Example: Custom aliases
# alias myproject='cd ~/projects/myproject'

# Example: API keys (DO NOT commit these!)
# export MY_API_KEY="your-key-here"

# Example: Local paths
# export PATH="$HOME/bin:$PATH"
EOF
        log_info "Created .zshrc.local for personal customizations"
    fi
}

#######################################
# Configure profile
#######################################
configure_profile() {
    log_info "Configuring shell profile..."
    
    echo ""
    echo "Select your shell profile:"
    echo "1) Minimal  - Essential tools only"
    echo "2) Standard - Balanced setup (recommended)"
    echo "3) Full     - Everything enabled"
    echo ""
    
    read -p "Enter choice [1-3] (default: 2): " choice
    
    case "$choice" in
        1) profile="minimal" ;;
        3) profile="full" ;;
        *) profile="standard" ;;
    esac
    
    # Update configuration
    if [[ -f "$INSTALL_DIR/configs/settings/settings.yaml" ]]; then
        # Use sed to update the profile setting
        sed -i.bak "s/profile: \".*\"/profile: \"$profile\"/" "$INSTALL_DIR/configs/settings/settings.yaml"
        log_success "Set shell profile to: $profile"
    fi
}

#######################################
# Test configuration
#######################################
test_config() {
    log_info "Testing configuration..."
    
    # Source the new configuration
    if zsh -c "source $HOME/.zshrc" 2>/dev/null; then
        log_success "Configuration loads successfully!"
    else
        log_error "Configuration failed to load. Check for errors."
        return 1
    fi
}

#######################################
# Show post-installation instructions
#######################################
show_instructions() {
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                 🎉 Modular Zsh Configuration Installed! 🎉         ║
╚═══════════════════════════════════════════════════════════════════╝

✅ Installation Complete!

📁 Files installed to: $INSTALL_DIR
📝 Configuration: $INSTALL_DIR/configs/settings/settings.yaml
🔧 Local customizations: ~/.zshrc.local

🚀 Next Steps:
   1. Restart your terminal or run: source ~/.zshrc
   2. Customize settings in: $INSTALL_DIR/configs/settings/settings.yaml
   3. Add personal settings to: ~/.zshrc.local
   4. Run 'check_dependencies' to see recommended tools

💡 Available Commands:
   - check_dependencies - Check for missing tools
   - zsh-help          - Show available commands
   - project-status    - Check AI project setup
   - ai-init          - Initialize AI project

📚 Module Management:
   Edit settings.yaml to enable/disable modules:
   
   features:
     shell:
       modules:
         rust_tools: true    # Modern CLI tools
         ai_tools: true      # AI development
         docker: true        # Container tools
         
   Or change profile for preset configurations:
     profile: "minimal"  # or "standard" or "full"

⚠️  Note: Some features require additional tools to be installed.
   Run 'check_dependencies' after reloading to see what's missing.

EOF
}

#######################################
# Main installation flow
#######################################
main() {
    log_info "Starting modular zsh installation..."
    
    # Check requirements
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        log_error "This script requires Bash 4.0 or higher"
        exit 1
    fi
    
    # Confirm installation
    echo ""
    echo "This will install the modular zsh configuration system."
    echo "Your existing .zshrc will be backed up."
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi
    
    # Run installation steps
    backup_existing
    install_modular_config
    configure_profile
    test_config
    
    show_instructions
    
    log_success "Installation completed!"
}

# Run main function
main "$@"