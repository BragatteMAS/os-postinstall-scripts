#!/usr/bin/env bash
# ==============================================================================
# Rust-First Development Environment Setup
# Agnóstico: macOS e Linux
# ==============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detectar SO
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
echo -e "${BLUE}📦 Sistema: $OS | Arquitetura: $ARCH${NC}"
echo ""

# ==============================================================================
# SEÇÃO 1: Instalação do Rust
# ==============================================================================
install_rust() {
    if command -v rustc &> /dev/null; then
        echo -e "${GREEN}✓ Rust já instalado: $(rustc --version)${NC}"
    else
        echo -e "${YELLOW}📦 Instalando Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Instalar componentes essenciais
    rustup component add rust-analyzer clippy rustfmt
}

# ==============================================================================
# SEÇÃO 2: Ferramentas Rust Essenciais
# ==============================================================================
RUST_TOOLS=(
    # Ferramentas de terminal
    "bat:cat com syntax highlighting"
    "eza:ls moderno com ícones"
    "fd-find:find mais rápido"
    "ripgrep:grep ultrarrápido"
    "git-delta:diff melhorado"
    "dust:du com visualização em árvore"
    "bottom:monitor de sistema"
    "procs:ps moderno"
    "sd:sed mais simples"
    "tokei:estatísticas de código"
    "zoxide:cd inteligente"
    "hyperfine:benchmarking"
    "gitui:interface git no terminal"
    "lsd:outro ls moderno"
    
    # Ferramentas de desenvolvimento
    "cargo-watch:auto-reload para projetos"
    "cargo-edit:adicionar deps facilmente"
    "cargo-update:atualizar ferramentas cargo"
    "cargo-audit:verificar vulnerabilidades"
    "cargo-expand:expandir macros"
    "cargo-outdated:verificar deps desatualizadas"
    "bacon:executor de tarefas Rust"
    
    # Ferramentas de dados
    "xsv:manipulação de CSV"
    "jql:consultas JSON"
    "htmlq:como jq mas para HTML"
    
    # Shell e utilitários
    "starship:prompt customizável"
    "nu:shell orientado a dados"
    "helix:editor modal moderno"
    "zellij:multiplexador de terminal"
    "atuin:histórico de shell melhorado"
)

install_rust_tools() {
    echo -e "${YELLOW}📦 Instalando ferramentas Rust...${NC}"
    
    # Tentar usar cargo-binstall primeiro (mais rápido)
    if ! command -v cargo-binstall &> /dev/null; then
        echo -e "${YELLOW}📦 Instalando cargo-binstall para downloads mais rápidos...${NC}"
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    fi
    
    for tool_info in "${RUST_TOOLS[@]}"; do
        IFS=':' read -r tool description <<< "$tool_info"
        
        # Verificar se já está instalado
        if command -v "${tool%%-*}" &> /dev/null || cargo install --list | grep -q "^$tool"; then
            echo -e "${GREEN}✓ $tool já instalado${NC}"
        else
            echo -e "${YELLOW}📦 Instalando $tool - $description${NC}"
            
            # Usar binstall se disponível, senão cargo install
            if command -v cargo-binstall &> /dev/null; then
                cargo binstall -y "$tool" || cargo install "$tool"
            else
                cargo install "$tool"
            fi
        fi
    done
}

# ==============================================================================
# SEÇÃO 3: Instalação Agnóstica de Dependências
# ==============================================================================
install_system_deps() {
    echo -e "${YELLOW}📦 Instalando dependências do sistema...${NC}"
    
    case "$OS" in
        "macos")
            # Instalar Homebrew se necessário
            if ! command -v brew &> /dev/null; then
                echo -e "${YELLOW}📦 Instalando Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Dependências via Homebrew
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
            echo -e "${RED}⚠️  Sistema não reconhecido. Instale manualmente: git, curl, wget, build tools${NC}"
            ;;
    esac
}

# ==============================================================================
# SEÇÃO 4: Python com UV
# ==============================================================================
install_uv() {
    if command -v uv &> /dev/null; then
        echo -e "${GREEN}✓ UV já instalado: $(uv --version)${NC}"
    else
        echo -e "${YELLOW}📦 Instalando UV (gerenciador Python ultrarrápido)...${NC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
}

# ==============================================================================
# SEÇÃO 5: Configurações Portáveis
# ==============================================================================
setup_portable_configs() {
    echo -e "${YELLOW}📝 Criando configurações portáveis...${NC}"
    
    # Criar diretório de configurações
    mkdir -p "$HOME/.config/portable-dev"
    
    # Arquivo de detecção de ferramentas
    cat > "$HOME/.config/portable-dev/detect_tools.sh" << 'EOF'
#!/usr/bin/env bash
# Detecta ferramentas instaladas e configura aliases apropriados

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

# Sistema de detecção com fallbacks
detect_and_alias "bat" "cat" "cat"
detect_and_alias "eza" "ls" "ls"
detect_and_alias "fd" "find" "find"
detect_and_alias "rg" "grep" "grep"
detect_and_alias "dust" "du" "du"
detect_and_alias "procs" "ps" "ps"
detect_and_alias "sd" "sed" "sed"
detect_and_alias "bottom" "top" "top"
detect_and_alias "delta" "diff" "diff"

# Exportar variáveis baseadas nas ferramentas disponíveis
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
# SEÇÃO 6: Script de Bootstrap Remoto
# ==============================================================================
create_bootstrap_script() {
    echo -e "${YELLOW}📝 Criando script de bootstrap...${NC}"
    
    cat > "$HOME/.config/portable-dev/bootstrap.sh" << 'EOF'
#!/usr/bin/env bash
# Bootstrap rápido para novos ambientes
# Uso: curl -sSL https://seu-repo/bootstrap.sh | bash

echo "🚀 Bootstrapping Rust development environment..."

# Clonar repositório de configurações
if [[ -n "$1" ]]; then
    REPO_URL="$1"
else
    read -p "Digite a URL do seu repositório de configurações: " REPO_URL
fi

# Criar diretório temporário
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clonar repo
git clone "$REPO_URL" config-repo || {
    echo "Erro ao clonar repositório"
    exit 1
}

# Executar instalação
cd config-repo
if [[ -f "install_rust_tools.sh" ]]; then
    bash install_rust_tools.sh
fi

# Copiar configurações
[[ -f "zshrc" ]] && cp zshrc "$HOME/.zshrc"
[[ -f ".gitconfig" ]] && cp .gitconfig "$HOME/.gitconfig"

# Limpar
cd /
rm -rf "$TEMP_DIR"

echo "✅ Bootstrap completo! Reinicie o shell."
EOF
    
    chmod +x "$HOME/.config/portable-dev/bootstrap.sh"
}

# ==============================================================================
# SEÇÃO 7: Aliases Inteligentes para o zshrc
# ==============================================================================
create_smart_aliases() {
    echo -e "${YELLOW}📝 Criando sistema de aliases inteligentes...${NC}"
    
    cat > "$HOME/.config/portable-dev/smart_aliases.zsh" << 'EOF'
# Sistema de aliases inteligentes com detecção automática

# Função helper para criar aliases condicionais
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

# Terminal & Navegação
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

# Git com delta
if command -v delta &> /dev/null; then
    alias gdiff='git diff | delta'
else
    alias gdiff='git diff --color'
fi

# Função universal de instalação
install_tool() {
    local tool="$1"
    
    # Primeiro tentar via cargo
    if command -v cargo &> /dev/null; then
        echo "🦀 Instalando $tool via cargo..."
        cargo install "$tool"
        return
    fi
    
    # Detectar gerenciador de pacotes
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install "$tool"
    elif command -v apt &> /dev/null; then
        sudo apt install -y "$tool"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$tool"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "$tool"
    else
        echo "❌ Instale manualmente: $tool"
    fi
}

# Quick setup em novo ambiente
quick_setup() {
    echo "🚀 Quick Rust environment setup..."
    
    # Instalar Rust se necessário
    if ! command -v cargo &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Instalar ferramentas essenciais
    local essential_tools=("bat" "eza" "fd-find" "ripgrep" "zoxide" "starship")
    
    for tool in "${essential_tools[@]}"; do
        if ! command -v "${tool%%-*}" &> /dev/null; then
            cargo install "$tool"
        fi
    done
    
    echo "✅ Ambiente básico configurado!"
}
EOF
}

# ==============================================================================
# EXECUÇÃO PRINCIPAL
# ==============================================================================
main() {
    echo -e "${BLUE}🦀 Iniciando configuração Rust-first...${NC}"
    
    # Etapas de instalação
    install_system_deps
    install_rust
    install_rust_tools
    install_uv
    setup_portable_configs
    create_bootstrap_script
    create_smart_aliases
    
    # Criar comando de instalação rápida
    echo -e "${YELLOW}📝 Criando comando de instalação rápida...${NC}"
    cat > "$HOME/.config/portable-dev/quick_install.sh" << 'EOF'
#!/usr/bin/env bash
# Instalação rápida via curl
curl -sSL https://raw.githubusercontent.com/BragatteMAS/SEU_REPO/main/install_rust_tools.sh | bash
EOF
    
    echo -e "${GREEN}✅ Configuração completa!${NC}"
    echo -e "${BLUE}📋 Próximos passos:${NC}"
    echo "1. Source seu .zshrc: source ~/.zshrc"
    echo "2. Para novo PC: curl -sSL [seu-repo]/install_rust_tools.sh | bash"
    echo "3. Use 'quick_setup' para instalação mínima"
    echo "4. Use 'install_tool <nome>' para instalar ferramentas"
}

# Executar
main "$@"