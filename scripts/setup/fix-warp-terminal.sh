#!/bin/bash
# ==============================================================================
# Fix Warp Terminal Configuration
# Resolves initialization conflicts with Warp Terminal
# Author: Bragatte, M.A.S
# ==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running in Warp Terminal
check_warp_terminal() {
    if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
        print_status "Warp Terminal detected"
        return 0
    else
        print_warning "Not running in Warp Terminal"
        print_status "This script is designed for Warp Terminal compatibility"
        return 1
    fi
}

# Function to backup current .zshrc
backup_zshrc() {
    local backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_file"
        print_success "Backup created: $backup_file"
    else
        print_warning "No .zshrc found to backup"
    fi
}

# Function to create minimal Warp-compatible .zshrc
create_minimal_zshrc() {
    local zshrc_file="$HOME/.zshrc"
    
    print_status "Creating minimal Warp-compatible .zshrc..."
    
    cat > "$zshrc_file" << 'EOF'
#!/bin/zsh
# ==============================================================================
# Minimal Warp Terminal Compatible Configuration
# Created by OS Post-Install Scripts
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ WARP TERMINAL COMPATIBILITY                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Disable Warp's automatic initialization to prevent conflicts
export WARP_DISABLE_AUTO_INIT=true
export WARP_DISABLE_AUTO_TITLE=true
export WARP_HONOR_PS1=1
export WARP_USE_SSH_WRAPPER=0
export WARP_DISABLE_COMPLETIONS=true
export WARP_BOOTSTRAPPED=1

## Set session ID if not already set
if [[ -z "$WARP_SESSION_ID" ]]; then
    export WARP_SESSION_ID="$(date +%s)$RANDOM"
fi

## Disable Warp's built-in functions that conflict
unset -f warp_precmd 2>/dev/null || true
unset -f warp_preexec 2>/dev/null || true
unset -f warp_update_prompt_vars 2>/dev/null || true

## Clear problematic variables
unset WARP_BOOTSTRAP_VAR 2>/dev/null || true
unset WARP_INITIAL_WORKING_DIR 2>/dev/null || true

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ BASIC SHELL CONFIGURATION                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Enable command history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE

## Basic prompt
PS1='%n@%m %~ %# '

## Enable completion
autoload -Uz compinit
compinit

## Basic aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

## Reload configuration
alias reload='source ~/.zshrc'
alias sz='source ~/.zshrc'

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ WARP STATUS FUNCTIONS                                                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

warp_status() {
    echo "🔍 Warp Terminal Status:"
    echo "   TERM_PROGRAM: $TERM_PROGRAM"
    echo "   WARP_SESSION_ID: $WARP_SESSION_ID"
    echo "   WARP_DISABLE_AUTO_INIT: $WARP_DISABLE_AUTO_INIT"
    echo "   WARP_HONOR_PS1: $WARP_HONOR_PS1"
    echo "   WARP_DISABLE_AUTO_TITLE: $WARP_DISABLE_AUTO_TITLE"
    echo "   WARP_USE_SSH_WRAPPER: $WARP_USE_SSH_WRAPPER"
    echo "   WARP_DISABLE_COMPLETIONS: $WARP_DISABLE_COMPLETIONS"
}

warp_reset() {
    echo "🔄 Resetting Warp Terminal configuration..."
    unset WARP_DISABLE_AUTO_INIT
    unset WARP_DISABLE_AUTO_TITLE
    unset WARP_HONOR_PS1
    unset WARP_USE_SSH_WRAPPER
    unset WARP_DISABLE_COMPLETIONS
    unset WARP_SESSION_ID
    unset WARP_BOOTSTRAPPED
    echo "✅ Configuration reset"
}

alias warp-status='warp_status'
alias warp-reset='warp_reset'

print_success "Minimal Warp-compatible configuration created"
echo "🚀 Warp Terminal should now work without conflicts"
echo "💡 Use 'warp-status' to check configuration"
echo "💡 Use 'reload' to reload configuration"
EOF

    print_success "Minimal .zshrc created"
}

# Function to install full configuration
install_full_configuration() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$(dirname "$script_dir")")"
    local config_file="$project_root/configs/shell/zshrc"
    
    if [[ -f "$config_file" ]]; then
        print_status "Installing full configuration..."
        cp "$config_file" "$HOME/.zshrc"
        print_success "Full configuration installed"
    else
        print_error "Full configuration file not found: $config_file"
        return 1
    fi
}

# Function to install Warp compatibility file
install_warp_compatibility() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$(dirname "$script_dir")")"
    local compatibility_file="$project_root/configs/shell/warp-compatibility.zsh"
    
    if [[ -f "$compatibility_file" ]]; then
        print_status "Installing Warp compatibility file..."
        cp "$compatibility_file" "$HOME/.warp-compatibility.zsh"
        
        # Add source line to .zshrc if not already present
        if ! grep -q "warp-compatibility.zsh" "$HOME/.zshrc" 2>/dev/null; then
            echo "source ~/.warp-compatibility.zsh" >> "$HOME/.zshrc"
        fi
        
        print_success "Warp compatibility file installed"
    else
        print_error "Warp compatibility file not found: $compatibility_file"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --minimal     Create minimal Warp-compatible configuration"
    echo "  --full        Install full configuration with Warp compatibility"
    echo "  --compat      Install only Warp compatibility file"
    echo "  --backup      Create backup of current .zshrc"
    echo "  --status      Show current Warp Terminal status"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --minimal    # Quick fix with minimal config"
    echo "  $0 --full       # Install full configuration"
    echo "  $0 --backup     # Backup current configuration"
}

# Function to show current status
show_status() {
    echo "🔍 Current Warp Terminal Status:"
    echo "   TERM_PROGRAM: ${TERM_PROGRAM:-not set}"
    echo "   WARP_SESSION_ID: ${WARP_SESSION_ID:-not set}"
    echo "   WARP_DISABLE_AUTO_INIT: ${WARP_DISABLE_AUTO_INIT:-not set}"
    echo "   WARP_HONOR_PS1: ${WARP_HONOR_PS1:-not set}"
    echo "   WARP_DISABLE_AUTO_TITLE: ${WARP_DISABLE_AUTO_TITLE:-not set}"
    echo "   WARP_USE_SSH_WRAPPER: ${WARP_USE_SSH_WRAPPER:-not set}"
    echo "   WARP_DISABLE_COMPLETIONS: ${WARP_DISABLE_COMPLETIONS:-not set}"
    echo ""
    echo "📁 Configuration files:"
    echo "   .zshrc exists: $([[ -f "$HOME/.zshrc" ]] && echo "Yes" || echo "No")"
    echo "   .warp-compatibility.zsh exists: $([[ -f "$HOME/.warp-compatibility.zsh" ]] && echo "Yes" || echo "No")"
}

# Main function
main() {
    print_status "Warp Terminal Configuration Fixer"
    print_status "=================================="
    
    # Check if running in Warp Terminal
    check_warp_terminal
    
    # Parse command line arguments
    case "${1:-}" in
        --minimal)
            backup_zshrc
            create_minimal_zshrc
            print_success "Minimal configuration installed"
            ;;
        --full)
            backup_zshrc
            install_full_configuration
            print_success "Full configuration installed"
            ;;
        --compat)
            install_warp_compatibility
            print_success "Warp compatibility installed"
            ;;
        --backup)
            backup_zshrc
            ;;
        --status)
            show_status
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            print_warning "No option specified"
            echo ""
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
    
    print_status "Done!"
}

# Run main function
main "$@" 