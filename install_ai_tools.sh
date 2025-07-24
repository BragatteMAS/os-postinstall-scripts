#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#######################################
# install_ai_tools.sh
# Purpose: Install and configure AI development tools (MCPs + BMAD Method)
# Author: BragatteMAS
# License: MIT
# Version: 1.0.0
# 
# This script automates the installation and configuration of:
# - 4 Essential MCPs (context7, fetch, sequential-thinking, serena)
# - BMAD Method for project management
# - Claude.json configuration
#######################################

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/logging.sh" 2>/dev/null || {
    # Fallback logging functions if logging.sh not available
    log_info() { echo "[INFO] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
}

# Global variables
CLAUDE_CONFIG_PATH=""
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"
SERENA_REPO_PATH=""
UV_COMMAND=""

#######################################
# Detect operating system and set Claude config path
#######################################
detect_claude_config_path() {
    log_info "Detecting operating system and Claude configuration path..."
    
    case "$OSTYPE" in
        darwin*)
            CLAUDE_CONFIG_PATH="$HOME/Library/Application Support/Claude/claude.json"
            ;;
        linux*)
            CLAUDE_CONFIG_PATH="$HOME/.config/Claude/claude.json"
            ;;
        msys*|cygwin*|mingw*)
            CLAUDE_CONFIG_PATH="$APPDATA/Claude/claude.json"
            ;;
        *)
            log_error "Unsupported operating system: $OSTYPE"
            return 1
            ;;
    esac
    
    # Create directory if it doesn't exist
    local config_dir
    config_dir=$(dirname "$CLAUDE_CONFIG_PATH")
    if [[ ! -d "$config_dir" ]]; then
        log_info "Creating Claude configuration directory: $config_dir"
        mkdir -p "$config_dir"
    fi
    
    log_success "Claude config path: $CLAUDE_CONFIG_PATH"
}

#######################################
# Check for required dependencies
#######################################
check_dependencies() {
    log_info "Checking required dependencies..."
    
    local missing_deps=()
    
    # Check for Node.js/npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm (Node.js)")
    fi
    
    # Check for Python
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check for jq (for JSON manipulation)
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them first using your package manager or the main setup.sh script"
        return 1
    fi
    
    log_success "All required dependencies are installed"
}

#######################################
# Find or install UV for Python package management
#######################################
setup_uv() {
    log_info "Setting up UV for Python package management..."
    
    # Check if UV is already installed
    if command -v uv &> /dev/null; then
        UV_COMMAND="uv"
        log_success "UV is already installed: $(which uv)"
        return 0
    fi
    
    # Check common UV installation paths
    local uv_paths=(
        "$HOME/.local/bin/uv"
        "$HOME/.cargo/bin/uv"
        "/usr/local/bin/uv"
    )
    
    for path in "${uv_paths[@]}"; do
        if [[ -x "$path" ]]; then
            UV_COMMAND="$path"
            log_success "Found UV at: $UV_COMMAND"
            return 0
        fi
    done
    
    # Install UV if not found
    log_info "UV not found. Installing UV..."
    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget &> /dev/null; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        log_error "Neither curl nor wget found. Cannot install UV."
        return 1
    fi
    
    # Add UV to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    UV_COMMAND="$HOME/.local/bin/uv"
    
    log_success "UV installed successfully"
}

#######################################
# Clone or update serena repository
#######################################
setup_serena_repo() {
    log_info "Setting up serena repository..."
    
    SERENA_REPO_PATH="$HOME/Documents/GitHub/serena"
    
    if [[ -d "$SERENA_REPO_PATH" ]]; then
        log_info "Serena repository already exists. Updating..."
        (
            cd "$SERENA_REPO_PATH"
            git pull origin main || log_warning "Could not update serena repo"
        )
    else
        log_info "Cloning serena repository..."
        mkdir -p "$(dirname "$SERENA_REPO_PATH")"
        git clone https://github.com/modelcontextprotocol/servers.git "$SERENA_REPO_PATH" || {
            log_error "Failed to clone serena repository"
            return 1
        }
    fi
    
    log_success "Serena repository is ready at: $SERENA_REPO_PATH"
}

#######################################
# Backup existing Claude configuration
#######################################
backup_claude_config() {
    if [[ -f "$CLAUDE_CONFIG_PATH" ]]; then
        log_info "Backing up existing Claude configuration..."
        cp "$CLAUDE_CONFIG_PATH" "${CLAUDE_CONFIG_PATH}${BACKUP_SUFFIX}"
        log_success "Backup created: ${CLAUDE_CONFIG_PATH}${BACKUP_SUFFIX}"
    fi
}

#######################################
# Create or update Claude configuration with MCPs
#######################################
configure_mcps() {
    log_info "Configuring MCPs in Claude..."
    
    # Create base configuration if file doesn't exist
    if [[ ! -f "$CLAUDE_CONFIG_PATH" ]]; then
        log_info "Creating new Claude configuration file..."
        echo '{"mcpServers": {}}' > "$CLAUDE_CONFIG_PATH"
    fi
    
    # Create temporary file for the new configuration
    local temp_config
    temp_config=$(mktemp)
    
    # Build the MCP configuration
    cat > "$temp_config" << EOF
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "serena": {
      "command": "$UV_COMMAND",
      "args": ["run", "--directory", "$SERENA_REPO_PATH", "serena-mcp-server"]
    }
  }
}
EOF
    
    # Merge with existing configuration
    if [[ -f "$CLAUDE_CONFIG_PATH" ]] && [[ -s "$CLAUDE_CONFIG_PATH" ]]; then
        # Merge configurations, preserving existing non-MCP settings
        jq -s '.[0] * .[1]' "$CLAUDE_CONFIG_PATH" "$temp_config" > "${temp_config}.merged"
        mv "${temp_config}.merged" "$CLAUDE_CONFIG_PATH"
    else
        mv "$temp_config" "$CLAUDE_CONFIG_PATH"
    fi
    
    rm -f "$temp_config"
    
    log_success "MCPs configured successfully in Claude"
}

#######################################
# Install BMAD Method
#######################################
install_bmad_method() {
    log_info "Installing BMAD Method..."
    
    # Check if pnpm is available, otherwise use npx
    local package_runner="npx"
    if command -v pnpm &> /dev/null; then
        package_runner="pnpm dlx"
    fi
    
    log_info "Using $package_runner to install BMAD Method..."
    
    # Install BMAD Method with full configuration
    $package_runner bmad-method@latest install --full --ide cursor || {
        log_error "Failed to install BMAD Method"
        return 1
    }
    
    # Check if .claude directory was created
    if [[ -d ".claude" ]]; then
        log_success "BMAD Method installed successfully!"
        log_info "Available slash commands:"
        log_info "  - /generate-prp - Generate PRPs from requirements"
        log_info "  - /execute-prp - Execute implementation with validation"
        log_info "  - /validate-patterns - Verify adherence to project patterns"
    else
        log_warning "BMAD Method installed but .claude directory not found in current directory"
        log_info "You may need to run 'bmad-method install' in your project directory"
    fi
}

#######################################
# Test MCP configuration
#######################################
test_mcp_configuration() {
    log_info "Testing MCP configuration..."
    
    # Test if npx commands work
    log_info "Testing npm/npx availability..."
    if npx --version &> /dev/null; then
        log_success "npx is working correctly"
    else
        log_warning "npx test failed - MCPs may not work properly"
    fi
    
    # Test UV command
    log_info "Testing UV command..."
    if $UV_COMMAND --version &> /dev/null; then
        log_success "UV is working correctly"
    else
        log_warning "UV test failed - serena MCP may not work properly"
    fi
    
    log_info "Note: Full MCP testing requires restarting Claude Desktop"
}

#######################################
# Display post-installation instructions
#######################################
show_post_install_instructions() {
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    🎉 AI Tools Installation Complete! 🎉           ║
╚═══════════════════════════════════════════════════════════════════╝

✅ Installed Components:
   - 4 Essential MCPs (context7, fetch, sequential-thinking, serena)
   - BMAD Method for project management
   - Claude configuration updated

📍 Configuration Location:
   $CLAUDE_CONFIG_PATH

🚀 Next Steps:
   1. Restart Claude Desktop to load the new MCPs
   2. Verify MCPs are active by checking for 'mcp__' prefix in tool names
   3. In your project directory, run: bmad-method install --full

💡 Usage Tips:
   - Add "use context7" to prompts for up-to-date documentation
   - Use sequential-thinking for complex problem decomposition
   - Use serena for efficient codebase searches
   - Access BMAD commands with / in Claude (e.g., /generate-prp)

📚 Documentation:
   - CLAUDE.md - Complete Context Engineering guide
   - CLAUDE-EXTENDED.md - Detailed examples and patterns
   - docs/ai-tools-setup.md - This setup guide

⚠️  Important:
   If MCPs don't appear after restart, check:
   1. Claude Desktop is fully closed and restarted
   2. No error messages in Claude's developer console
   3. The configuration file at: $CLAUDE_CONFIG_PATH

EOF
}

#######################################
# Main installation flow
#######################################
main() {
    log_info "Starting AI Tools installation..."
    
    # Run installation steps
    detect_claude_config_path || exit 1
    check_dependencies || exit 1
    setup_uv || exit 1
    setup_serena_repo || exit 1
    backup_claude_config
    configure_mcps || exit 1
    install_bmad_method || log_warning "BMAD Method installation failed, but MCPs are configured"
    test_mcp_configuration
    
    show_post_install_instructions
    
    log_success "AI Tools installation completed!"
}

# Run main function
main "$@"