#!/usr/bin/env bash
# ==============================================================================
# Setup Universal - Ponto de entrada único para todos os sistemas
# Compatível com: macOS, Linux, WSL, e até Windows (via Git Bash)
# Author: Bragatte, M.A.S
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
REPO_URL="${REPO_URL:-https://github.com/BragatteMAS/os-postinstall-scripts}"
REPO_DIR="$HOME/.config/linux-postinstall"
DEFAULT_PROFILE="${DEFAULT_PROFILE:-developer-standard}"
USE_PROFILE=false

# Parse arguments
SKIP_REQUIREMENTS=false
for arg in "$@"; do
    case $arg in
        --profile=*)
            USE_PROFILE=true
            PROFILE="${arg#*=}"
            shift
            ;;
        --minimal)
            USE_PROFILE=true
            PROFILE="developer-minimal"
            shift
            ;;
        --skip-requirements)
            SKIP_REQUIREMENTS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --profile=NAME       Use specific installation profile"
            echo "  --minimal            Use minimal installation profile"
            echo "  --skip-requirements  Skip requirements check"
            echo "  --help               Show this help"
            exit 0
            ;;
    esac
done

# Banner
show_banner() {
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║          🚀 Universal Development Setup 🚀                    ║
    ║                    Rust-First & Agnostic                      ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
}

# Detect system
detect_system() {
    local os=""
    local distro=""
    local version=""
    local arch=$(uname -m)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
        version=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os="linux"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro="$ID"
            version="$VERSION_ID"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        os="windows"
        version="Git Bash"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        os="wsl"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro="$ID"
            version="$VERSION_ID"
        fi
    fi
    
    echo "$os|$distro|$version|$arch"
}

# Menu principal
show_menu() {
    local system_info="$1"
    IFS='|' read -r os distro version arch <<< "$system_info"
    
    echo -e "\n${BLUE}Detected System:${NC}"
    echo -e "  OS: ${GREEN}$os${NC}"
    [[ -n "$distro" ]] && echo -e "  Distro: ${GREEN}$distro $version${NC}"
    echo -e "  Arch: ${GREEN}$arch${NC}"
    
    echo -e "\n${PURPLE}Installation Options:${NC}"
    echo "  1) 🦀 Install Rust tools only"
    echo "  2) 📦 Install system tools (apt/brew/etc)"
    echo "  3) 🔧 Complete setup (Rust + System + Configs)"
    echo "  4) 🐍 Install Python with UV"
    echo "  5) 🐳 Install Docker/Podman"
    echo "  6) 📁 Sync dotfiles"
    echo "  7) 🏃 Quick setup (essentials)"
    echo "  8) 🔍 Check installed tools"
    echo "  9) 🤖 Install AI tools (MCPs + BMAD)"
    echo "  10) 🎯 Configure Git for product-focused development"
    echo "  0) ❌ Exit"
    
    echo -e "\n${YELLOW}Enter option number:${NC} "
}

# Clone repository
clone_repo() {
    if [[ ! -d "$REPO_DIR" ]]; then
        echo -e "${BLUE}📥 Cloning configuration repository...${NC}"
        git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    else
        echo -e "${BLUE}📥 Updating repository...${NC}"
        cd "$REPO_DIR" && git pull
    fi
}

# Install Rust tools
install_rust_tools() {
    echo -e "${YELLOW}🦀 Installing Rust tools...${NC}"
    
    # Get script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -f "$script_dir/../install/rust-tools.sh" ]]; then
        bash "$script_dir/../install/rust-tools.sh"
    elif [[ -f "$REPO_DIR/scripts/install/rust-tools.sh" ]]; then
        bash "$REPO_DIR/scripts/install/rust-tools.sh"
    else
        # Fallback: download directly
        curl -sSL "$REPO_URL/raw/main/scripts/install/rust-tools.sh" | bash
    fi
}

# Install system tools
install_system_tools() {
    local os="$1"
    local distro="$2"
    
    echo -e "${YELLOW}📦 Installing system tools...${NC}"
    
    case "$os" in
        "macos")
            # Check Homebrew
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Install essentials
            brew install git curl wget fzf tmux neovim
            ;;
            
        "linux"|"wsl")
            case "$distro" in
                "ubuntu"|"debian"|"pop")
                    if [[ -f "$REPO_DIR/linux/post_install.sh" ]]; then
                        bash "$REPO_DIR/linux/post_install.sh"
                    else
                        sudo apt update
                        sudo apt install -y git curl wget build-essential
                    fi
                    ;;
                "fedora"|"rhel")
                    sudo dnf install -y git curl wget gcc make
                    ;;
                "arch"|"manjaro")
                    sudo pacman -Syu --noconfirm git curl wget base-devel
                    ;;
            esac
            ;;
            
        "windows")
            echo -e "${YELLOW}For Windows, use PowerShell as Admin:${NC}"
            echo "  irm $REPO_URL/raw/main/windows/win11.ps1 | iex"
            ;;
    esac
}

# Quick setup
quick_setup() {
    echo -e "${YELLOW}🏃 Running quick setup...${NC}"
    
    # 1. Instalar Rust se não existir
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # 2. Essential tools via cargo
    local essential_tools=("bat" "eza" "fd-find" "ripgrep" "zoxide")
    
    for tool in "${essential_tools[@]}"; do
        if ! cargo install --list | grep -q "^$tool"; then
            cargo install "$tool"
        fi
    done
    
    # 3. Configure minimal zshrc
    if [[ ! -f "$HOME/.zshrc_rust_configured" ]]; then
        echo -e "\n# Rust tools configuration" >> "$HOME/.zshrc"
        echo 'source "$HOME/.cargo/env"' >> "$HOME/.zshrc"
        echo 'eval "$(zoxide init zsh)"' >> "$HOME/.zshrc"
        touch "$HOME/.zshrc_rust_configured"
    fi
    
    echo -e "${GREEN}✅ Quick setup complete!${NC}"
}

# Sync dotfiles
sync_dotfiles() {
    echo -e "${YELLOW}📁 Syncing dotfiles...${NC}"
    
    local files=("zshrc" ".gitconfig" ".tmux.conf")
    
    for file in "${files[@]}"; do
        if [[ -f "$REPO_DIR/$file" ]]; then
            # Fazer backup se existir
            [[ -f "$HOME/.$file" ]] && cp "$HOME/.$file" "$HOME/.$file.bak"
            
            # Copiar novo
            cp "$REPO_DIR/$file" "$HOME/.$file"
            echo -e "${GREEN}✓${NC} $file synced"
        fi
    done
    
    # Add Rust integration to zshrc
    if [[ -f "$REPO_DIR/zshrc_rust_integration.zsh" ]]; then
        echo -e "\n# Rust integration" >> "$HOME/.zshrc"
        cat "$REPO_DIR/zshrc_rust_integration.zsh" >> "$HOME/.zshrc"
    fi
}

# Check tools
check_tools() {
    echo -e "${BLUE}🔍 Checking installed tools...${NC}"
    echo ""
    
    # Rust tools
    local rust_tools=("rustc" "cargo" "bat" "eza" "fd" "rg" "delta" "dust" "bottom" "zoxide")
    echo -e "${YELLOW}Rust Tools:${NC}"
    for tool in "${rust_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool $(command -v $tool)"
        else
            echo -e "  ${RED}✗${NC} $tool"
        fi
    done
    
    echo ""
    
    # System tools
    local sys_tools=("git" "curl" "wget" "tmux" "fzf" "docker" "python3" "node")
    echo -e "${YELLOW}System Tools:${NC}"
    for tool in "${sys_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool"
        else
            echo -e "  ${RED}✗${NC} $tool"
        fi
    done
}

# Install Docker/Podman
install_container_runtime() {
    local os="$1"
    
    echo -e "${YELLOW}🐳 Installing container runtime...${NC}"
    
    case "$os" in
        "macos")
            brew install --cask docker
            echo "Docker Desktop installed. Open the application to start."
            ;;
        "linux"|"wsl")
            # Preferir Podman em Linux
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y podman podman-compose
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y podman podman-compose
            fi
            
            # Create alias docker -> podman
            echo "alias docker='podman'" >> "$HOME/.zshrc"
            echo "alias docker-compose='podman-compose'" >> "$HOME/.zshrc"
            ;;
    esac
}

# Install Python with UV
install_python_uv() {
    echo -e "${YELLOW}🐍 Installing Python with UV...${NC}"
    
    # Install UV
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source "$HOME/.cargo/env"
    fi
    
    # Create default Python environment
    uv venv ~/.venv/default
    
    # Install essential tools
    source ~/.venv/default/bin/activate
    uv pip install ipython jupyter pandas numpy matplotlib seaborn
    
    echo -e "${GREEN}✅ Python configured with UV!${NC}"
    echo "To activate: source ~/.venv/default/bin/activate"
}

# Install AI tools (MCPs + BMAD)
install_ai_tools() {
    echo -e "${YELLOW}🤖 Installing AI tools...${NC}"
    
    # Get script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -f "$script_dir/../install/ai-tools.sh" ]]; then
        bash "$script_dir/../install/ai-tools.sh"
    elif [[ -f "$REPO_DIR/scripts/install/ai-tools.sh" ]]; then
        bash "$REPO_DIR/scripts/install/ai-tools.sh"
    else
        # Fallback: download directly from repository
        echo -e "${BLUE}Downloading AI tools installation script...${NC}"
        curl -sSL "$REPO_URL/raw/main/scripts/install/ai-tools.sh" | bash
    fi
}

# Configure Git for product-focused development
install_product_focused_git() {
    echo -e "${YELLOW}🎯 Configuring Git for product-focused development...${NC}"
    
    # Get script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -f "$script_dir/../install/git-focused.sh" ]]; then
        bash "$script_dir/../install/git-focused.sh"
    elif [[ -f "$REPO_DIR/scripts/install/git-focused.sh" ]]; then
        bash "$REPO_DIR/scripts/install/git-focused.sh"
    else
        # Fallback: download directly from repository
        echo -e "${BLUE}Downloading configuration script...${NC}"
        curl -sSL "$REPO_URL/raw/main/scripts/install/git-focused.sh" | bash
    fi
}

# Main
main() {
    show_banner
    
    # Check requirements unless skipped
    if [[ "$SKIP_REQUIREMENTS" != true ]]; then
        echo -e "${BLUE}Checking system requirements...${NC}"
        if ! ./scripts/utils/check-requirements.sh 2>/dev/null; then
            echo -e "\n${YELLOW}System requirements not met!${NC}"
            echo -e "${YELLOW}Run with --skip-requirements to bypass this check${NC}"
            echo -e "${YELLOW}Or run ./scripts/setup/upgrade-bash.sh to upgrade Bash on macOS${NC}"
            exit 1
        fi
        echo ""
    fi
    
    # Detect system
    local system_info=$(detect_system)
    IFS='|' read -r os distro version arch <<< "$system_info"
    
    # Clone repo
    clone_repo
    
    # Menu loop
    while true; do
        show_menu "$system_info"
        read -r choice
        
        case $choice in
            1) install_rust_tools ;;
            2) install_system_tools "$os" "$distro" ;;
            3) 
                install_system_tools "$os" "$distro"
                install_rust_tools
                sync_dotfiles
                ;;
            4) install_python_uv ;;
            5) install_container_runtime "$os" ;;
            6) sync_dotfiles ;;
            7) quick_setup ;;
            8) check_tools ;;
            9) install_ai_tools ;;
            10) install_product_focused_git ;;
            0) 
                echo -e "${GREEN}👋 Goodbye!${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read -r
    done
}

# Executar
main "$@"

# Built with ❤️ by Bragatte, M.A.S