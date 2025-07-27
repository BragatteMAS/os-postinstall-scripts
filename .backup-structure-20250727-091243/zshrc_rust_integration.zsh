# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ RUST TOOLS AUTO-DETECTION AND INTEGRATION                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
# Adicionar esta seção ao seu .zshrc após a seção de aliases

# ──────────────────────────────────────────────────────────────────────────────
# Auto-instalação de ferramentas Rust faltantes
# ──────────────────────────────────────────────────────────────────────────────
check_and_suggest_rust_tool() {
    local tool="$1"
    local cargo_name="${2:-$1}"
    local description="$3"
    
    if ! command -v "$tool" &> /dev/null; then
        # Adicionar à lista de ferramentas sugeridas
        MISSING_RUST_TOOLS+=("$cargo_name:$description")
    fi
}

# Verificar ferramentas Rust na inicialização
check_rust_tools() {
    local MISSING_RUST_TOOLS=()
    
    # Ferramentas essenciais
    check_and_suggest_rust_tool "bat" "bat" "cat com syntax highlighting"
    check_and_suggest_rust_tool "eza" "eza" "ls moderno com ícones"
    check_and_suggest_rust_tool "fd" "fd-find" "find mais rápido"
    check_and_suggest_rust_tool "rg" "ripgrep" "grep ultrarrápido"
    check_and_suggest_rust_tool "delta" "git-delta" "diff melhorado para git"
    check_and_suggest_rust_tool "dust" "du-dust" "du com visualização em árvore"
    check_and_suggest_rust_tool "zoxide" "zoxide" "cd inteligente com IA"
    check_and_suggest_rust_tool "starship" "starship" "prompt customizável"
    
    # Se houver ferramentas faltando, sugerir instalação
    if [[ ${#MISSING_RUST_TOOLS[@]} -gt 0 ]]; then
        # Criar arquivo de sugestões se não existir
        if [[ ! -f "$HOME/.rust_tools_suggested" ]]; then
            echo "🦀 Ferramentas Rust recomendadas não instaladas:"
            printf "   %s\n" "${MISSING_RUST_TOOLS[@]}" | column -t -s':'
            echo ""
            echo "💡 Para instalar todas de uma vez:"
            echo "   curl -sSL https://raw.githubusercontent.com/SEU_USUARIO/Linux_posintall_script/main/install_rust_tools.sh | bash"
            echo ""
            echo "   Ou individualmente com cargo:"
            for tool in "${MISSING_RUST_TOOLS[@]}"; do
                echo "   cargo install ${tool%%:*}"
            done
            
            # Marcar como sugerido
            touch "$HOME/.rust_tools_suggested"
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Função de bootstrap rápido do repositório
# ──────────────────────────────────────────────────────────────────────────────
rust_env_setup() {
    local repo_url="${1:-https://github.com/SEU_USUARIO/Linux_posintall_script}"
    
    echo "🚀 Configurando ambiente Rust do repositório..."
    
    # Criar diretório temporário
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Clonar apenas o necessário
    git clone --depth 1 --filter=blob:none --sparse "$repo_url" setup_temp
    cd setup_temp
    git sparse-checkout set install_rust_tools.sh zshrc
    
    # Executar instalação
    if [[ -f "install_rust_tools.sh" ]]; then
        bash install_rust_tools.sh
    fi
    
    # Limpar
    cd "$HOME"
    rm -rf "$temp_dir"
    
    echo "✅ Ambiente configurado! Reinicie o shell."
}

# ──────────────────────────────────────────────────────────────────────────────
# Aliases inteligentes com fallback automático
# ──────────────────────────────────────────────────────────────────────────────
# Esta função cria aliases que usam Rust tools se disponíveis, senão usa o padrão
setup_smart_rust_aliases() {
    # Listagem de arquivos
    if command -v eza &> /dev/null; then
        alias ls='eza --icons --group-directories-first'
        alias ll='eza -la --icons --git --header'
        alias tree='eza --tree --icons'
    elif command -v lsd &> /dev/null; then
        alias ls='lsd --group-directories-first'
        alias ll='lsd -la --header'
        alias tree='lsd --tree'
    fi
    
    # Visualização de arquivos
    if command -v bat &> /dev/null; then
        alias cat='bat --style=plain'
        alias less='bat --style=plain --paging=always'
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    fi
    
    # Busca
    if command -v rg &> /dev/null; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    elif command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    fi
    
    # Git
    if command -v delta &> /dev/null; then
        export GIT_PAGER='delta'
        git config --global core.pager delta
        git config --global interactive.diffFilter 'delta --color-only'
    fi
    
    # Navegação
    if command -v zoxide &> /dev/null; then
        eval "$(zoxide init zsh)"
        alias cd='z'  # Sobrescrever cd com zoxide
    fi
    
    # Monitoramento
    if command -v bottom &> /dev/null; then
        alias top='bottom'
        alias htop='bottom'
    elif command -v btm &> /dev/null; then
        alias top='btm'
        alias htop='btm'
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Instalador universal via alias
# ──────────────────────────────────────────────────────────────────────────────
universal_install() {
    local tool="$1"
    
    echo "🔍 Procurando melhor método para instalar $tool..."
    
    # 1. Tentar cargo primeiro (funciona em qualquer lugar)
    if command -v cargo &> /dev/null; then
        # Mapear nomes conhecidos
        case "$tool" in
            "eza") cargo install eza ;;
            "bat") cargo install bat ;;
            "fd") cargo install fd-find ;;
            "rg"|"ripgrep") cargo install ripgrep ;;
            "delta") cargo install git-delta ;;
            "dust") cargo install du-dust ;;
            "bottom"|"btm") cargo install bottom ;;
            "zoxide"|"z") cargo install zoxide ;;
            *) cargo install "$tool" ;;
        esac
        return $?
    fi
    
    # 2. Detectar gerenciador de pacotes do sistema
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install "$tool"
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y "$tool"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$tool"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "$tool"
    else
        echo "❌ Nenhum gerenciador de pacotes encontrado"
        echo "💡 Instale o Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi
}

alias install='universal_install'
alias irust='check_rust_tools'  # Verificar ferramentas Rust

# ──────────────────────────────────────────────────────────────────────────────
# Executar verificações na inicialização
# ──────────────────────────────────────────────────────────────────────────────
# Verificar apenas uma vez por sessão
if [[ -z "$RUST_TOOLS_CHECKED" ]]; then
    setup_smart_rust_aliases
    export RUST_TOOLS_CHECKED=1
    
    # Verificar ferramentas apenas se não foi feito hoje
    if [[ ! -f "$HOME/.rust_tools_checked" ]] || [[ $(find "$HOME/.rust_tools_checked" -mtime +1 2>/dev/null) ]]; then
        check_rust_tools
        touch "$HOME/.rust_tools_checked"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# Comando para setup completo em novo ambiente
# ──────────────────────────────────────────────────────────────────────────────
new_machine_setup() {
    echo "🚀 Configurando novo ambiente de desenvolvimento..."
    echo ""
    echo "Este comando irá:"
    echo "  1. Instalar Rust e cargo"
    echo "  2. Instalar todas as ferramentas Rust recomendadas"
    echo "  3. Configurar seu shell (zsh)"
    echo "  4. Instalar Python com UV"
    echo ""
    read -p "Continuar? (s/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        # Baixar e executar o script do seu repo
        curl -sSL "https://raw.githubusercontent.com/SEU_USUARIO/Linux_posintall_script/main/install_rust_tools.sh" | bash
        
        # Copiar configurações
        echo "📁 Clonando configurações..."
        git clone https://github.com/SEU_USUARIO/Linux_posintall_script.git "$HOME/.config/dev-setup"
        
        # Aplicar zshrc
        if [[ -f "$HOME/.config/dev-setup/zshrc" ]]; then
            cp "$HOME/.config/dev-setup/zshrc" "$HOME/.zshrc"
            echo "✅ zshrc atualizado"
        fi
        
        echo "✅ Setup completo! Reinicie seu terminal."
    fi
}

alias newsetup='new_machine_setup'
alias rustsetup='rust_env_setup'