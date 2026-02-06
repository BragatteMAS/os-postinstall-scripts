#!/usr/bin/env bash
#######################################
# Script: agent-os.sh
# Description: Agent-OS Installation Script
# Author: Bragatte
# Date: 2025-02-05
#######################################

set -euo pipefail
IFS=$'\n\t'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source logging utilities (SSoT)
source "${SCRIPT_DIR}/../utils/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

# Configuration
AGENT_OS_HOME="$HOME/.agent-os"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NODE_MIN_VERSION="16.0.0"

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Compare versions
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Node.js
    if ! command_exists node; then
        log_error "Node.js is not installed. Please install Node.js ${NODE_MIN_VERSION} or higher."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | sed 's/v//')
    if ! version_ge "$NODE_VERSION" "$NODE_MIN_VERSION"; then
        log_error "Node.js version $NODE_VERSION is too old. Please upgrade to ${NODE_MIN_VERSION} or higher."
        exit 1
    fi
    log_success "Node.js $NODE_VERSION found"
    
    # Check npm
    if ! command_exists npm; then
        log_error "npm is not installed. Please install npm."
        exit 1
    fi
    log_success "npm $(npm -v) found"
    
    # Check SQLite3
    if ! command_exists sqlite3; then
        log_warning "SQLite3 not found. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - SQLite comes pre-installed
            log_info "SQLite should be pre-installed on macOS"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y sqlite3
            elif command_exists yum; then
                sudo yum install -y sqlite
            else
                log_error "Cannot install SQLite3. Please install it manually."
                exit 1
            fi
        fi
    fi
    log_success "SQLite3 found"
}

# Create Agent-OS structure if it doesn't exist
create_structure() {
    log_info "Creating Agent-OS structure..."
    
    # Check if already exists
    if [ -d "$AGENT_OS_HOME" ]; then
        log_warning "Agent-OS already exists at $AGENT_OS_HOME"
        read -p "Do you want to reinstall? This will backup existing data. (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
        
        # Backup existing installation
        BACKUP_DIR="$AGENT_OS_HOME.backup.$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up to $BACKUP_DIR"
        mv "$AGENT_OS_HOME" "$BACKUP_DIR"
    fi
    
    # Copy structure from repository
    log_info "Copying files from repository..."
    cp -r "$HOME/.agent-os" "$AGENT_OS_HOME" 2>/dev/null || true
    
    # Ensure all directories exist
    mkdir -p "$AGENT_OS_HOME"/{core,agents,templates,memory,hooks,bin,config,logs}
    
    log_success "Structure created"
}

# Install npm dependencies
install_dependencies() {
    log_info "Installing npm dependencies..."
    
    cd "$AGENT_OS_HOME"
    
    # Install dependencies
    npm install --production
    
    # Build TypeScript files
    log_info "Building TypeScript files..."
    npm run build
    
    log_success "Dependencies installed"
}

# Initialize database
initialize_database() {
    log_info "Initializing database..."
    
    # Create database file
    touch "$AGENT_OS_HOME/memory/agents.db"
    
    # Initialize schema
    sqlite3 "$AGENT_OS_HOME/memory/agents.db" << EOF
CREATE TABLE IF NOT EXISTS agent_memory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    task_id TEXT NOT NULL,
    context TEXT,
    result TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS agent_learning (
    pattern TEXT PRIMARY KEY,
    agent_name TEXT NOT NULL,
    success_rate REAL DEFAULT 0.0,
    usage_count INTEGER DEFAULT 0,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agent_memory_agent_name 
ON agent_memory(agent_name);

CREATE INDEX IF NOT EXISTS idx_agent_memory_created_at 
ON agent_memory(created_at);
EOF
    
    log_success "Database initialized"
}

# Setup global command
setup_global_command() {
    log_info "Setting up global command..."
    
    # Make CLI executable
    chmod +x "$AGENT_OS_HOME/bin/agent-os"
    
    # Create symlink in PATH
    if [ -d "/usr/local/bin" ]; then
        sudo ln -sf "$AGENT_OS_HOME/bin/agent-os" /usr/local/bin/agent-os
        log_success "Global command 'agent-os' installed"
    else
        log_warning "Could not install global command. Add $AGENT_OS_HOME/bin to your PATH:"
        echo "export PATH=\"\$PATH:$AGENT_OS_HOME/bin\""
    fi
}

# Create example configuration
create_example_config() {
    log_info "Creating example configuration..."
    
    # Create agent mapping example
    cat > "$AGENT_OS_HOME/config/agent-mapping.yaml.example" << 'EOF'
# Agent Mapping Configuration
# Maps custom agents to native Claude agents

mappings:
  # Custom agent that extends a native agent
  - custom: analyst
    extends: .claude/agents/core/researcher.md
    enhancements:
      - persistent_memory
      - custom_prompts
  
  # Direct mapping to native agent
  - custom: architect  
    extends: .claude/agents/architecture/system-design/arch-system-design.md
    
  # Use native agent for specific patterns
  - use_native: .claude/agents/testing/unit/tdd-london-swarm.md
    when: "test.*unit|tdd"
    
  # Completely custom agent
  - custom_only: orchestrator
    no_native_equivalent: true
EOF
    
    log_success "Example configuration created"
}

# Print success message and next steps
print_success() {
    echo
    log_success "Agent-OS installed successfully!"
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Test the installation:"
    echo "   agent-os --version"
    echo
    echo "2. Initialize in a project:"
    echo "   cd /your/project"
    echo "   agent-os init"
    echo
    echo "3. List available agents:"
    echo "   agent-os list"
    echo
    echo "4. Run an agent:"
    echo "   agent-os run analyst \"analyze requirements for user authentication\""
    echo
    echo -e "${BLUE}Documentation:${NC} $AGENT_OS_HOME/README.md"
    echo -e "${BLUE}Configuration:${NC} $AGENT_OS_HOME/config.yaml"
}

# Main installation
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Agent-OS Installation Script  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    check_prerequisites
    create_structure
    install_dependencies
    initialize_database
    setup_global_command
    create_example_config
    print_success
}

# Run main function
main "$@"