#!/usr/bin/env bash
# ==============================================================================
# Rust-First Development Environment Setup
# Agnostic: macOS and Linux
# Author: Bragatte, M.A.S
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
ARCH=$(uname -m)

echo -e "${BLUE}🦀 Rust-First Development Environment Setup${NC}"
echo -e "${BLUE}📦 System: $OS | Architecture: $ARCH${NC}"
echo ""

# ==============================================================================
# SECTION 1: Rust Installation
# ==============================================================================
install_rust() {
    if command -v rustc &> /dev/null; then
        echo -e "${GREEN}✓ Rust already installed: $(rustc --version)${NC}"
    else
        echo -e "${YELLOW}📦 Installing Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Install essential components
    rustup component add rust-analyzer clippy rustfmt
}

# ==============================================================================
# SECTION 2: Essential Rust Tools
# ==============================================================================
RUST_TOOLS=(
    # Terminal tools
    "bat:cat with syntax highlighting"
    "eza:modern ls with icons"
    "fd-find:faster find"
    "ripgrep:ultrafast grep"
    "git-delta:improved diff"
    "dust:du with tree visualization"
    "bottom:system monitor"
    "procs:modern ps"
    "sd:simpler sed"
    "tokei:code statistics"
    "zoxide:smart cd"
    "hyperfine:benchmarking"
    "gitui:git interface in terminal"
    "lsd:another modern ls"
    
    # Development tools
    "cargo-watch:auto-reload for projects"
    "cargo-edit:add deps easily"
    "cargo-update:update cargo tools"
    "cargo-audit:check vulnerabilities"
    "cargo-expand:expand macros"
    "cargo-outdated:check outdated deps"
    "bacon:Rust task executor"
    
    # Data tools
    "xsv:CSV manipulation"
    "jql:JSON queries"
    "htmlq:like jq but for HTML"
    
    # Shell and utilities
    "starship:customizable prompt"
    "nu:data-oriented shell"
    "helix:modern modal editor"
    "zellij:terminal multiplexer"
    "atuin:improved shell history"
)

install_rust_tools() {
    echo -e "${YELLOW}📦 Installing Rust tools...${NC}"
    
    # Try to use cargo-binstall first (faster)
    if ! command -v cargo-binstall &> /dev/null; then
        echo -e "${YELLOW}📦 Installing cargo-binstall for faster downloads...${NC}"
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    fi
    
    for tool_info in "${RUST_TOOLS[@]}"; do
        IFS=':' read -r tool description <<< "$tool_info"
        
        # Check if already installed
        if command -v "${tool%%-*}" &> /dev/null || cargo install --list | grep -q "^$tool"; then
            echo -e "${GREEN}✓ $tool already installed${NC}"
        else
            echo -e "${YELLOW}📦 Installing $tool - $description${NC}"
            
            # Use binstall if available, otherwise cargo install
            if command -v cargo-binstall &> /dev/null; then
                cargo binstall -y "$tool" || cargo install "$tool"
            else
                cargo install "$tool"
            fi
        fi
    done
}

# ==============================================================================
# SECTION 3: Agnostic Dependency Installation
# ==============================================================================
install_system_deps() {
    echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
    
    case "$OS" in
        "macos")
            # Install Homebrew if necessary
            if ! command -v brew &> /dev/null; then
                echo -e "${YELLOW}📦 Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Dependencies via Homebrew
            brew install git curl wget cmake pkg-config openssl
            ;;
            
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y git curl wget build-essential cmake pkg-config libssl-dev
            ;;
            
        "fedora"|"rhel"|"centos")
            sudo dnf install -y git curl wget gcc cmake pkgconfig openssl-devel
            ;;
            
        "arch"|"manjaro")
            sudo pacman -Syu --noconfirm git curl wget base-devel cmake pkg-config openssl
            ;;
            
        "opensuse")
            sudo zypper install -y git curl wget gcc cmake pkg-config libopenssl-devel
            ;;
            
        *)
            echo -e "${RED}⚠️  Unrecognized system. Install manually: git, curl, wget, build tools${NC}"
            ;;
    esac
}

# ==============================================================================
# SECTION 4: Python with UV
# ==============================================================================
install_uv() {
    if command -v uv &> /dev/null; then
        echo -e "${GREEN}✓ UV already installed: $(uv --version)${NC}"
    else
        echo -e "${YELLOW}📦 Installing UV (ultrafast Python manager)...${NC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
}

# ==============================================================================
# SECTION 5: Portable Configurations
# ==============================================================================
setup_portable_configs() {
    echo -e "${YELLOW}📝 Creating portable configurations...${NC}"
    
    # Create configurations directory
    mkdir -p "$HOME/.config/portable-dev"
    
    # Tool detection file
    cat > "$HOME/.config/portable-dev/detect_tools.sh" << 'EOF'
#!/usr/bin/env bash
# Detects installed tools and configures appropriate aliases

detect_and_alias() {
    local rust_tool="$1"
    local fallback="$2"
    local alias_name="$3"
    
    if command -v "$rust_tool" &> /dev/null; then
        alias "$alias_name"="$rust_tool"
    elif command -v "$fallback" &> /dev/null; then
        alias "$alias_name"="$fallback"
    fi
}

# Detection system with fallbacks
detect_and_alias "bat" "cat" "cat"
detect_and_alias "eza" "ls" "ls"
detect_and_alias "fd" "find" "find"
detect_and_alias "rg" "grep" "grep"
detect_and_alias "dust" "du" "du"
detect_and_alias "procs" "ps" "ps"
detect_and_alias "sd" "sed" "sed"
detect_and_alias "bottom" "top" "top"
detect_and_alias "delta" "diff" "diff"

# Export variables based on available tools
if command -v bat &> /dev/null; then
    export BAT_THEME="gruvbox-dark"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v delta &> /dev/null; then
    export GIT_PAGER="delta"
fi

if command -v eza &> /dev/null; then
    export EZA_COLORS="uu=0:gu=0"
fi
EOF
    
    chmod +x "$HOME/.config/portable-dev/detect_tools.sh"
}

# ==============================================================================
# SECTION 6: Remote Bootstrap Script
# ==============================================================================
create_bootstrap_script() {
    echo -e "${YELLOW}📝 Creating bootstrap script...${NC}"
    
    cat > "$HOME/.config/portable-dev/bootstrap.sh" << 'EOF'
#!/usr/bin/env bash
# Quick bootstrap for new environments
# Usage: curl -sSL https://your-repo/bootstrap.sh | bash

echo "🚀 Bootstrapping Rust development environment..."

# Clone configuration repository
if [[ -n "$1" ]]; then
    REPO_URL="$1"
else
    read -p "Enter your configuration repository URL: " REPO_URL
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone repo
git clone "$REPO_URL" config-repo || {
    echo "Error cloning repository"
    exit 1
}

# Execute installation
cd config-repo
if [[ -f "install_rust_tools.sh" ]]; then
    bash install_rust_tools.sh
fi

# Copy configurations
[[ -f "zshrc" ]] && cp zshrc "$HOME/.zshrc"
[[ -f ".gitconfig" ]] && cp .gitconfig "$HOME/.gitconfig"

# Clean up
cd /
rm -rf "$TEMP_DIR"

echo "✅ Bootstrap complete! Restart your shell."
EOF
    
    chmod +x "$HOME/.config/portable-dev/bootstrap.sh"
}

# ==============================================================================
# SECTION 7: Smart Aliases for zshrc
# ==============================================================================
create_smart_aliases() {
    echo -e "${YELLOW}📝 Creating smart aliases system...${NC}"
    
    cat > "$HOME/.config/portable-dev/smart_aliases.zsh" << 'EOF'
# Smart aliases system with automatic detection

# Helper function to create conditional aliases
smart_alias() {
    local name="$1"
    local rust_cmd="$2"
    local fallback="$3"
    
    if command -v "${rust_cmd%% *}" &> /dev/null; then
        alias "$name"="$rust_cmd"
    elif [[ -n "$fallback" ]] && command -v "${fallback%% *}" &> /dev/null; then
        alias "$name"="$fallback"
    fi
}

# Terminal & Navigation
smart_alias "ls" "eza --icons --group-directories-first" "ls --color=auto"
smart_alias "ll" "eza -la --icons --git" "ls -la"
smart_alias "la" "eza -a --icons" "ls -a"
smart_alias "lt" "eza --tree --icons" "tree"
smart_alias "cat" "bat --style=plain" "cat"
smart_alias "grep" "rg" "grep --color=auto"
smart_alias "find" "fd" "find"
smart_alias "ps" "procs" "ps aux"
smart_alias "top" "bottom" "htop"
smart_alias "du" "dust" "du -h"
smart_alias "sed" "sd" "sed"

# Git with delta
if command -v delta &> /dev/null; then
    alias gdiff='git diff | delta'
else
    alias gdiff='git diff --color'
fi

# Universal installation function
install_tool() {
    local tool="$1"
    
    # First try via cargo
    if command -v cargo &> /dev/null; then
        echo "🦀 Installing $tool via cargo..."
        cargo install "$tool"
        return
    fi
    
    # Detect package manager
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install "$tool"
    elif command -v apt &> /dev/null; then
        sudo apt install -y "$tool"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$tool"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "$tool"
    else
        echo "❌ Install manually: $tool"
    fi
}

# Quick setup in new environment
quick_setup() {
    echo "🚀 Quick Rust environment setup..."
    
    # Install Rust if necessary
    if ! command -v cargo &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Install essential tools
    local essential_tools=("bat" "eza" "fd-find" "ripgrep" "zoxide" "starship")
    
    for tool in "${essential_tools[@]}"; do
        if ! command -v "${tool%%-*}" &> /dev/null; then
            cargo install "$tool"
        fi
    done
    
    echo "✅ Basic environment configured!"
}
EOF
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
main() {
    echo -e "${BLUE}🦀 Starting Rust-first configuration...${NC}"
    
    # Installation steps
    install_system_deps
    install_rust
    install_rust_tools
    install_uv
    setup_portable_configs
    create_bootstrap_script
    create_smart_aliases
    
    # Create quick installation command
    echo -e "${YELLOW}📝 Creating quick installation command...${NC}"
    cat > "$HOME/.config/portable-dev/quick_install.sh" << 'EOF'
#!/usr/bin/env bash
# Quick installation via curl
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install_rust_tools.sh | bash
EOF
    
    echo -e "${GREEN}✅ Configuration complete!${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Source your .zshrc: source ~/.zshrc"
    echo "2. For new PC: curl -sSL [your-repo]/install_rust_tools.sh | bash"
    echo "3. Use 'quick_setup' for minimal installation"
    echo "4. Use 'install_tool <name>' to install tools"
}

# Execute
main "$@"