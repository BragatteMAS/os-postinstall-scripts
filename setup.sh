#!/usr/bin/env bash
# ==============================================================================
# Setup Universal - Ponto de entrada único para todos os sistemas
# Compatível com: macOS, Linux, WSL, e até Windows (via Git Bash)
# Author: Bragatte, M.A.S
# ==============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuração
REPO_URL="${REPO_URL:-https://github.com/BragatteMAS/os-postinstall-scripts}"
REPO_DIR="$HOME/.config/linux-postinstall"
DEFAULT_PROFILE="${DEFAULT_PROFILE:-developer-standard}"
USE_PROFILE=false

# Parse arguments
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
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --profile=NAME    Use specific installation profile"
            echo "  --minimal         Use minimal installation profile"
            echo "  --help            Show this help"
            exit 0
            ;;
    esac
done

# Banner
show_banner() {
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║          🚀 Setup Universal de Desenvolvimento 🚀             ║
    ║                    Rust-First & Agnóstico                     ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
}

# Detectar sistema
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
    
    echo -e "\n${BLUE}Sistema Detectado:${NC}"
    echo -e "  OS: ${GREEN}$os${NC}"
    [[ -n "$distro" ]] && echo -e "  Distro: ${GREEN}$distro $version${NC}"
    echo -e "  Arch: ${GREEN}$arch${NC}"
    
    echo -e "\n${PURPLE}Opções de Instalação:${NC}"
    echo "  1) 🦀 Instalar apenas ferramentas Rust"
    echo "  2) 📦 Instalar ferramentas do sistema (apt/brew/etc)"
    echo "  3) 🔧 Configuração completa (Rust + Sistema + Configs)"
    echo "  4) 🐍 Instalar Python com UV"
    echo "  5) 🐳 Instalar Docker/Podman"
    echo "  6) 📁 Sincronizar dotfiles"
    echo "  7) 🏃 Setup rápido (essenciais)"
    echo "  8) 🔍 Verificar ferramentas instaladas"
    echo "  9) 🤖 Instalar ferramentas de IA (MCPs + BMAD)"
    echo "  10) 🎯 Configurar Git para desenvolvimento focado no produto"
    echo "  0) ❌ Sair"
    
    echo -e "\n${YELLOW}Digite o número da opção:${NC} "
}

# Clonar repositório
clone_repo() {
    if [[ ! -d "$REPO_DIR" ]]; then
        echo -e "${BLUE}📥 Clonando repositório de configurações...${NC}"
        git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    else
        echo -e "${BLUE}📥 Atualizando repositório...${NC}"
        cd "$REPO_DIR" && git pull
    fi
}

# Instalar Rust tools
install_rust_tools() {
    echo -e "${YELLOW}🦀 Instalando ferramentas Rust...${NC}"
    
    if [[ -f "$REPO_DIR/install_rust_tools.sh" ]]; then
        bash "$REPO_DIR/install_rust_tools.sh"
    else
        # Fallback: baixar direto
        curl -sSL "$REPO_URL/raw/main/install_rust_tools.sh" | bash
    fi
}

# Instalar ferramentas do sistema
install_system_tools() {
    local os="$1"
    local distro="$2"
    
    echo -e "${YELLOW}📦 Instalando ferramentas do sistema...${NC}"
    
    case "$os" in
        "macos")
            # Verificar Homebrew
            if ! command -v brew &> /dev/null; then
                echo "Instalando Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Instalar essenciais
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
            echo -e "${YELLOW}Para Windows, use o PowerShell como Admin:${NC}"
            echo "  irm $REPO_URL/raw/main/windows/win11.ps1 | iex"
            ;;
    esac
}

# Setup rápido
quick_setup() {
    echo -e "${YELLOW}🏃 Executando setup rápido...${NC}"
    
    # 1. Instalar Rust se não existir
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # 2. Ferramentas essenciais via cargo
    local essential_tools=("bat" "eza" "fd-find" "ripgrep" "zoxide")
    
    for tool in "${essential_tools[@]}"; do
        if ! cargo install --list | grep -q "^$tool"; then
            cargo install "$tool"
        fi
    done
    
    # 3. Configurar zshrc mínimo
    if [[ ! -f "$HOME/.zshrc_rust_configured" ]]; then
        echo -e "\n# Rust tools configuration" >> "$HOME/.zshrc"
        echo 'source "$HOME/.cargo/env"' >> "$HOME/.zshrc"
        echo 'eval "$(zoxide init zsh)"' >> "$HOME/.zshrc"
        touch "$HOME/.zshrc_rust_configured"
    fi
    
    echo -e "${GREEN}✅ Setup rápido completo!${NC}"
}

# Sincronizar dotfiles
sync_dotfiles() {
    echo -e "${YELLOW}📁 Sincronizando dotfiles...${NC}"
    
    local files=("zshrc" ".gitconfig" ".tmux.conf")
    
    for file in "${files[@]}"; do
        if [[ -f "$REPO_DIR/$file" ]]; then
            # Fazer backup se existir
            [[ -f "$HOME/.$file" ]] && cp "$HOME/.$file" "$HOME/.$file.bak"
            
            # Copiar novo
            cp "$REPO_DIR/$file" "$HOME/.$file"
            echo -e "${GREEN}✓${NC} $file sincronizado"
        fi
    done
    
    # Adicionar integração Rust ao zshrc
    if [[ -f "$REPO_DIR/zshrc_rust_integration.zsh" ]]; then
        echo -e "\n# Rust integration" >> "$HOME/.zshrc"
        cat "$REPO_DIR/zshrc_rust_integration.zsh" >> "$HOME/.zshrc"
    fi
}

# Verificar ferramentas
check_tools() {
    echo -e "${BLUE}🔍 Verificando ferramentas instaladas...${NC}"
    echo ""
    
    # Rust tools
    local rust_tools=("rustc" "cargo" "bat" "eza" "fd" "rg" "delta" "dust" "bottom" "zoxide")
    echo -e "${YELLOW}Ferramentas Rust:${NC}"
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
    echo -e "${YELLOW}Ferramentas do Sistema:${NC}"
    for tool in "${sys_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool"
        else
            echo -e "  ${RED}✗${NC} $tool"
        fi
    done
}

# Instalar Docker/Podman
install_container_runtime() {
    local os="$1"
    
    echo -e "${YELLOW}🐳 Instalando runtime de containers...${NC}"
    
    case "$os" in
        "macos")
            brew install --cask docker
            echo "Docker Desktop instalado. Abra o aplicativo para iniciar."
            ;;
        "linux"|"wsl")
            # Preferir Podman em Linux
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y podman podman-compose
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y podman podman-compose
            fi
            
            # Criar alias docker -> podman
            echo "alias docker='podman'" >> "$HOME/.zshrc"
            echo "alias docker-compose='podman-compose'" >> "$HOME/.zshrc"
            ;;
    esac
}

# Instalar Python com UV
install_python_uv() {
    echo -e "${YELLOW}🐍 Instalando Python com UV...${NC}"
    
    # Instalar UV
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source "$HOME/.cargo/env"
    fi
    
    # Criar ambiente Python padrão
    uv venv ~/.venv/default
    
    # Instalar ferramentas essenciais
    source ~/.venv/default/bin/activate
    uv pip install ipython jupyter pandas numpy matplotlib seaborn
    
    echo -e "${GREEN}✅ Python configurado com UV!${NC}"
    echo "Para ativar: source ~/.venv/default/bin/activate"
}

# Instalar ferramentas de IA (MCPs + BMAD)
install_ai_tools() {
    echo -e "${YELLOW}🤖 Instalando ferramentas de IA...${NC}"
    
    # Verificar se o script existe localmente
    if [[ -f "$REPO_DIR/install_ai_tools.sh" ]]; then
        bash "$REPO_DIR/install_ai_tools.sh"
    elif [[ -f "./install_ai_tools.sh" ]]; then
        bash "./install_ai_tools.sh"
    else
        # Fallback: baixar direto do repositório
        echo -e "${BLUE}Baixando script de instalação de AI tools...${NC}"
        curl -sSL "$REPO_URL/raw/main/install_ai_tools.sh" | bash
    fi
}

# Configurar Git para desenvolvimento focado no produto
install_product_focused_git() {
    echo -e "${YELLOW}🎯 Configurando Git para desenvolvimento focado no produto...${NC}"
    
    # Verificar se o script existe localmente
    if [[ -f "$REPO_DIR/install_product_focused_git.sh" ]]; then
        bash "$REPO_DIR/install_product_focused_git.sh"
    elif [[ -f "./install_product_focused_git.sh" ]]; then
        bash "./install_product_focused_git.sh"
    else
        # Fallback: baixar direto do repositório
        echo -e "${BLUE}Baixando script de configuração...${NC}"
        curl -sSL "$REPO_URL/raw/main/install_product_focused_git.sh" | bash
    fi
}

# Main
main() {
    show_banner
    
    # Detectar sistema
    local system_info=$(detect_system)
    IFS='|' read -r os distro version arch <<< "$system_info"
    
    # Clonar repo
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
                echo -e "${GREEN}👋 Até logo!${NC}"
                break
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Pressione Enter para continuar...${NC}"
        read -r
    done
}

# Executar
main "$@"

# Built with ❤️ by Bragatte, M.A.S