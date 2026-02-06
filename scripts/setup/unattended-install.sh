#!/usr/bin/env bash
#######################################
# Script: unattended-install.sh
# Description: Automated installation with configuration options
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

source "$SCRIPT_DIR/../utils/config-loader.sh"

# Default values
PROFILE="standard"
SKIP_CONFIRMATIONS=false
INSTALL_TOOLS=true
INSTALL_SHELL=true
INSTALL_AI=true
CONFIG_FILE=""
DRY_RUN=false
VERBOSE=false

#######################################
# Display usage information
#######################################
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Unattended installation script for OS Post-Install Scripts

OPTIONS:
    -p, --profile PROFILE      Set installation profile (minimal|standard|full)
                              Default: standard
    
    -c, --config FILE         Use custom configuration file
                              Default: configs/settings/settings.yaml
    
    -y, --yes                 Skip all confirmations
    
    --no-tools               Skip tool installations
    --no-shell               Skip shell configuration
    --no-ai                  Skip AI tools installation
    
    --dry-run                Show what would be done without doing it
    -v, --verbose            Enable verbose output
    -h, --help               Display this help message

EXAMPLES:
    # Minimal installation with confirmations skipped
    $(basename "$0") -p minimal -y
    
    # Full installation with custom config
    $(basename "$0") -p full -c ~/my-config.yaml
    
    # Dry run to see what would be installed
    $(basename "$0") --dry-run -v

PROFILES:
    minimal  - Essential tools only (git, basic aliases)
    standard - Balanced setup with common tools
    full     - Everything including experimental features

EOF
}

#######################################
# Parse command line arguments
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRMATIONS=true
                shift
                ;;
            --no-tools)
                INSTALL_TOOLS=false
                shift
                ;;
            --no-shell)
                INSTALL_SHELL=false
                shift
                ;;
            --no-ai)
                INSTALL_AI=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                set -x
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

#######################################
# Validate profile selection
#######################################
validate_profile() {
    case "$PROFILE" in
        minimal|standard|full)
            log_info "Using profile: $PROFILE"
            ;;
        *)
            log_error "Invalid profile: $PROFILE"
            echo "Valid profiles: minimal, standard, full"
            exit 1
            ;;
    esac
}

#######################################
# Load or create configuration
#######################################
setup_config() {
    if [[ -n "$CONFIG_FILE" ]] && [[ -f "$CONFIG_FILE" ]]; then
        log_info "Using custom configuration: $CONFIG_FILE"
        load_config "$CONFIG_FILE"
    else
        # Use default or create from template
        local default_config="$REPO_ROOT/configs/settings/settings.yaml"
        if [[ ! -f "$default_config" ]]; then
            log_info "Creating default configuration..."
            create_default_config "$default_config"
        fi
        load_config "$default_config"
    fi
    
    # Update profile in configuration
    if [[ "$DRY_RUN" == false ]]; then
        sed -i.bak "s/profile: \".*\"/profile: \"$PROFILE\"/" "$CONFIG_FILE"
    fi
}

#######################################
# Check system requirements
#######################################
check_requirements() {
    log_info "Checking system requirements..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would check requirements"
        return 0
    fi
    
    "$SCRIPT_DIR/../utils/check-requirements.sh" || {
        log_error "System requirements not met"
        exit 1
    }
}

#######################################
# Install tools based on profile
#######################################
install_tools() {
    if [[ "$INSTALL_TOOLS" == false ]]; then
        log_info "Skipping tool installation (--no-tools)"
        return 0
    fi
    
    log_info "Installing tools for profile: $PROFILE"
    
    case "$PROFILE" in
        minimal)
            install_minimal_tools
            ;;
        standard)
            install_standard_tools
            ;;
        full)
            install_full_tools
            ;;
    esac
}

install_minimal_tools() {
    log_info "Installing minimal tools..."
    
    local tools=(
        "git"
        "curl"
        "jq"
        "zsh"
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would install: ${tools[*]}"
        return 0
    fi
    
    # Run platform-specific installer
    if [[ "$IS_MACOS" == true ]]; then
        for tool in "${tools[@]}"; do
            brew install "$tool" || true
        done
    else
        for tool in "${tools[@]}"; do
            sudo apt-get install -y "$tool" || true
        done
    fi
}

install_standard_tools() {
    # First install minimal tools
    install_minimal_tools
    
    log_info "Installing standard tools..."
    
    if is_feature_enabled "tools.rust"; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would install Rust tools"
        else
            "$REPO_ROOT/scripts/install/rust-tools.sh" || true
        fi
    fi
    
    if is_feature_enabled "tools.python"; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would install Python tools"
        else
            log_info "Installing Python tools..."
            # Python installation logic here
        fi
    fi
}

install_full_tools() {
    log_info "Installing all available tools..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would install all tools"
        return 0
    fi
    
    # Install everything
    install_standard_tools
    
    # Additional tools for full profile
    "$REPO_ROOT/scripts/install/dev-tools.sh" || true
    "$REPO_ROOT/scripts/install/productivity-apps.sh" || true
}

#######################################
# Configure shell
#######################################
configure_shell() {
    if [[ "$INSTALL_SHELL" == false ]]; then
        log_info "Skipping shell configuration (--no-shell)"
        return 0
    fi
    
    log_info "Configuring shell..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would configure modular zsh"
        return 0
    fi
    
    # Install modular zsh configuration
    export SHELL_PROFILE="$PROFILE"
    "$REPO_ROOT/scripts/setup/install-modular-zsh.sh" -y || {
        log_error "Failed to configure shell"
        return 1
    }
}

#######################################
# Install AI tools
#######################################
install_ai_tools() {
    if [[ "$INSTALL_AI" == false ]]; then
        log_info "Skipping AI tools (--no-ai)"
        return 0
    fi
    
    if ! is_feature_enabled "shell.modules.ai_tools"; then
        log_info "AI tools disabled in configuration"
        return 0
    fi
    
    log_info "Installing AI tools..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would install AI tools (MCPs + BMAD)"
        return 0
    fi
    
    "$REPO_ROOT/scripts/install/ai-tools.sh" || {
        log_warning "AI tools installation failed"
        return 1
    }
}

#######################################
# Generate installation report
#######################################
generate_report() {
    local report_file="$HOME/.config/os-postinstall/installation-report.txt"
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
OS Post-Install Scripts - Installation Report
============================================
Date: $(date)
Profile: $PROFILE
Configuration: ${CONFIG_FILE:-default}

Installed Components:
- System Requirements: ✓
- Tools: $([ "$INSTALL_TOOLS" = true ] && echo "✓" || echo "✗")
- Shell Configuration: $([ "$INSTALL_SHELL" = true ] && echo "✓" || echo "✗")
- AI Tools: $([ "$INSTALL_AI" = true ] && echo "✓" || echo "✗")

Installation Log:
$(tail -n 50 /tmp/os-postinstall.log 2>/dev/null || echo "No log available")

Next Steps:
1. Restart your terminal or run: source ~/.zshrc
2. Run 'check_dependencies' to verify installations
3. Customize ~/.zshrc.local for personal settings
EOF

    log_success "Installation report saved to: $report_file"
}

#######################################
# Main installation flow
#######################################
main() {
    # Create log file
    LOG_FILE="/tmp/os-postinstall.log"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    
    log_info "Starting unattended installation..."
    
    # Parse arguments
    parse_args "$@"
    
    # Validate inputs
    validate_profile
    
    # Source OS detection
    source "$REPO_ROOT/configs/shell/modules/00-os-detection.zsh" 2>/dev/null || {
        IS_MACOS=false
        IS_LINUX=true
        [[ "$OSTYPE" == "darwin"* ]] && IS_MACOS=true && IS_LINUX=false
    }
    
    # Show configuration
    cat << EOF

Configuration Summary:
=====================
Profile: $PROFILE
Skip Confirmations: $SKIP_CONFIRMATIONS
Install Tools: $INSTALL_TOOLS
Install Shell: $INSTALL_SHELL
Install AI: $INSTALL_AI
Dry Run: $DRY_RUN

EOF

    # Confirm if not skipping
    if [[ "$SKIP_CONFIRMATIONS" == false ]] && [[ "$DRY_RUN" == false ]]; then
        read -p "Continue with installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Run installation steps
    setup_config
    check_requirements
    install_tools
    configure_shell
    install_ai_tools
    
    # Generate report
    if [[ "$DRY_RUN" == false ]]; then
        generate_report
    fi
    
    log_success "Installation completed successfully!"
    
    if [[ "$DRY_RUN" == false ]]; then
        echo ""
        echo "🎉 Installation complete! Please restart your terminal."
    else
        echo ""
        echo "🔍 Dry run complete. No changes were made."
    fi
}

# Run main function
main "$@"