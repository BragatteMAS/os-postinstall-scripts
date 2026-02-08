#!/usr/bin/env bash
#######################################
# terminal-setup.sh
# One-script terminal transformation
#
# Installs modern CLI tools, configures a minimal
# Starship prompt, adds productive aliases, and
# sets up zsh plugins — on any machine with brew or apt.
#
# Usage:
#   bash terminal-setup.sh                # full install (everything)
#   bash terminal-setup.sh --interactive  # wizard mode (choose components)
#   bash terminal-setup.sh --dry-run      # preview changes
#
# From: https://github.com/BragatteMAS/os-postinstall-scripts
#######################################
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

DRY_RUN="${DRY_RUN:-false}"
INTERACTIVE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n)      DRY_RUN=true ;;
        --interactive|-i)  INTERACTIVE=true ;;
    esac
done

# Feature flags (default: install everything)
DO_FONT=true
DO_TOOLS=true
DO_STARSHIP=true
DO_ALIASES=true
DO_PLUGINS=true

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}  [OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_dry()   { echo -e "${YELLOW}[DRY]${NC}  Would: $*"; }

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$*"
    else
        "$@"
    fi
}

# ─── Interactive Wizard ──────────────────────────────────────────────
ask() {
    local prompt="$1" default="${2:-y}"
    local yn
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "  ${BLUE}?${NC} ${prompt} ${BOLD}[Y/n]${NC} ")" yn
        yn="${yn:-y}"
    else
        read -rp "$(echo -e "  ${BLUE}?${NC} ${prompt} ${BOLD}[y/N]${NC} ")" yn
        yn="${yn:-n}"
    fi
    [[ "$yn" =~ ^[Yy] ]]
}

wizard() {
    echo -e "${BOLD}Choose what to install:${NC}"
    echo ""
    ask "Nerd Font (JetBrainsMono)?" "y"                              || DO_FONT=false
    ask "CLI tools (bat, eza, fd, rg, delta, zoxide, starship)?" "y"  || DO_TOOLS=false
    ask "Starship prompt config?" "y"                                  || DO_STARSHIP=false
    ask "Shell aliases (40+ shortcuts)?" "y"                           || DO_ALIASES=false
    if [[ "$SHELL_NAME" == "zsh" ]]; then
        ask "Zsh plugins (autosuggestions, syntax, completions)?" "y"  || DO_PLUGINS=false
    fi
    echo ""
}

# ─── Platform Detection ──────────────────────────────────────────────
detect_platform() {
    case "$(uname -s)" in
        Linux*)  OS="linux" ;;
        Darwin*) OS="macos" ;;
        *)       log_error "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac

    if command -v brew &>/dev/null; then
        PKG="brew"
    elif command -v apt &>/dev/null; then
        PKG="apt"
    else
        log_error "No supported package manager found (brew or apt)"
        exit 1
    fi
}

# ─── Shell Detection ─────────────────────────────────────────────────
detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        SHELL_NAME="zsh"
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_NAME="bash"
        SHELL_RC="$HOME/.bashrc"
    fi
}

# ─── Dependencies ────────────────────────────────────────────────────
ensure_deps() {
    [[ "$PKG" != "apt" ]] && return 0

    local deps=(curl git unzip fontconfig)
    local missing=()

    for dep in "${deps[@]}"; do
        if ! dpkg -l "$dep" &>/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing dependencies: ${missing[*]}"
        run sudo apt update -qq
        run sudo apt install -y "${missing[@]}"
    fi
}

# ─── CLI Tools ────────────────────────────────────────────────────────
install_tools() {
    log_info "Installing modern CLI tools..."

    if [[ "$PKG" == "brew" ]]; then
        local pkgs=(bat eza fd ripgrep git-delta zoxide starship)
        for pkg in "${pkgs[@]}"; do
            if brew list "$pkg" &>/dev/null; then
                log_ok "$pkg"
            else
                run brew install "$pkg"
            fi
        done
    elif [[ "$PKG" == "apt" ]]; then
        local apt_pkgs=(bat fd-find ripgrep)
        run sudo apt update -qq
        for pkg in "${apt_pkgs[@]}"; do
            if dpkg -l "$pkg" &>/dev/null 2>&1; then
                log_ok "$pkg"
            else
                run sudo apt install -y "$pkg"
            fi
        done

        # eza — not in apt, install via cargo
        if ! command -v eza &>/dev/null; then
            if command -v cargo &>/dev/null; then
                run cargo install eza
            else
                log_warn "eza: needs cargo (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)"
            fi
        else
            log_ok "eza"
        fi

        # delta — not in apt, install via cargo
        if ! command -v delta &>/dev/null; then
            if command -v cargo &>/dev/null; then
                run cargo install git-delta
            else
                log_warn "delta: needs cargo"
            fi
        else
            log_ok "delta"
        fi

        # zoxide
        if ! command -v zoxide &>/dev/null; then
            run curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        else
            log_ok "zoxide"
        fi

        # starship
        if ! command -v starship &>/dev/null; then
            run curl -sS https://starship.rs/install.sh | sh -s -- -y
        else
            log_ok "starship"
        fi

        # Debian/Ubuntu renames: batcat→bat, fdfind→fd
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            run mkdir -p "$HOME/.local/bin"
            run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
            log_info "Linked batcat → bat"
        fi
        if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
            run mkdir -p "$HOME/.local/bin"
            run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            log_info "Linked fdfind → fd"
        fi
    fi
}

# ─── Nerd Font ───────────────────────────────────────────────────────
install_nerd_font() {
    log_info "Installing JetBrainsMono Nerd Font..."

    if [[ "$PKG" == "brew" ]]; then
        if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
            log_ok "JetBrainsMono Nerd Font"
        else
            run brew install --cask font-jetbrains-mono-nerd-font
        fi
    elif [[ "$PKG" == "apt" ]]; then
        local font_dir="${HOME}/.local/share/fonts"
        if fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
            log_ok "JetBrainsMono Nerd Font"
        else
            local tmp_dir
            tmp_dir=$(mktemp -d)
            log_info "Downloading from GitHub releases..."
            run curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "${tmp_dir}/JetBrainsMono.zip"
            run mkdir -p "$font_dir"
            run unzip -qo "${tmp_dir}/JetBrainsMono.zip" -d "$font_dir"
            run fc-cache -f
            rm -rf "$tmp_dir"
        fi
    fi

    log_warn "Set your terminal font to 'JetBrainsMono Nerd Font' in terminal preferences"
}

# ─── Zsh Plugins ──────────────────────────────────────────────────────
install_zsh_plugins() {
    [[ "$SHELL_NAME" != "zsh" ]] && return 0

    log_info "Installing zsh plugins..."
    local plugin_dir="${HOME}/.zsh"
    run mkdir -p "$plugin_dir"

    local plugin_names="zsh-autosuggestions zsh-completions zsh-syntax-highlighting"
    local plugin_urls="https://github.com/zsh-users/zsh-autosuggestions https://github.com/zsh-users/zsh-completions https://github.com/zsh-users/zsh-syntax-highlighting"

    local i=1
    for name in $plugin_names; do
        local url
        url=$(echo "$plugin_urls" | cut -d' ' -f"$i")
        if [[ -d "${plugin_dir}/${name}" ]]; then
            log_ok "$name"
        else
            run git clone --depth=1 "$url" "${plugin_dir}/${name}"
        fi
        i=$((i + 1))
    done
}

# ─── Starship Config ─────────────────────────────────────────────────
setup_starship() {
    log_info "Configuring starship prompt..."
    local config_dir="${HOME}/.config"
    local config_file="${config_dir}/starship.toml"

    run mkdir -p "$config_dir"

    if [[ -f "$config_file" ]]; then
        log_warn "Backing up existing starship.toml → ${config_file}.bak"
        run cp "$config_file" "${config_file}.bak"
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        cat > "$config_file" << 'EOF'
"$schema" = "https://starship.rs/config-schema.json"

format = """
$directory\
$git_branch\
$git_status\
$cmd_duration\
$line_break\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold purple"

[git_status]
format = "[$all_status$ahead_behind]($style) "
style = "bold red"

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "
style = "bold yellow"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[package]
disabled = true
[nodejs]
disabled = true
[python]
disabled = true
[rust]
disabled = true
[golang]
disabled = true
[java]
disabled = true
[ruby]
disabled = true
[php]
disabled = true
[docker_context]
disabled = true
[kubernetes]
disabled = true
[aws]
disabled = true
[gcloud]
disabled = true
[azure]
disabled = true
EOF
    else
        log_dry "Write starship.toml to $config_file"
    fi
}

# ─── Shell RC ─────────────────────────────────────────────────────────
setup_shell() {
    log_info "Configuring $SHELL_NAME ($SHELL_RC)..."

    local marker="# --- terminal-setup.sh ---"

    if [[ -f "$SHELL_RC" ]] && grep -q "$marker" "$SHELL_RC"; then
        log_ok "Already configured in $SHELL_RC"
        return 0
    fi

    if [[ -f "$SHELL_RC" ]]; then
        run cp "$SHELL_RC" "${SHELL_RC}.bak"
        log_info "Backed up → ${SHELL_RC}.bak"
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        echo "" >> "$SHELL_RC"
        echo "# --- terminal-setup.sh ---" >> "$SHELL_RC"

        # Aliases block (only if user opted in)
        if [[ "$DO_ALIASES" == "true" ]]; then
            cat >> "$SHELL_RC" << 'EOF'

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# List (modern tools with fallback)
if command -v eza &>/dev/null; then
    alias ls="eza"
    alias ll="eza -la --git --group-directories-first"
    alias la="eza -a"
    alias lt="eza --tree --level=2"
else
    alias ll="ls -lAh"
    alias la="ls -A"
fi

# Safety nets
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -pv"

# Git shortcuts
alias g="git"
alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline -20"
alias glo="git log --oneline --graph --all"
alias gb="git branch"

# Modern tool replacements (if available)
command -v bat &>/dev/null && alias cat="bat --paging=never"
command -v fd &>/dev/null && alias find="fd"
command -v rg &>/dev/null && alias grep="rg"
command -v delta &>/dev/null && alias diff="delta"

# Utilities
alias h="history"
alias c="clear"
alias path='echo $PATH | tr ":" "\n"'
alias df="df -h"
alias du="du -h"

# Network (platform-aware)
if command -v ss &>/dev/null; then
    alias ports="ss -tulanp"
else
    alias ports="lsof -iTCP -sTCP:LISTEN -nP"
fi

# Package manager
if command -v apt &>/dev/null; then
    alias update="sudo apt update && sudo apt upgrade"
    alias cleanup="sudo apt autoremove && sudo apt autoclean"
elif command -v brew &>/dev/null; then
    alias update="brew update && brew upgrade"
    alias cleanup="brew cleanup"
fi
EOF
        fi

        # Dynamic lines (need variable interpolation — written separately)
        cat >> "$SHELL_RC" <<DYNAMIC

# zsh plugins
[[ -f "\$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "\$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -d "\$HOME/.zsh/zsh-completions/src" ]] && fpath=("\$HOME/.zsh/zsh-completions/src" \$fpath)
[[ -f "\$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "\$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# zoxide (smarter cd)
command -v zoxide &>/dev/null && eval "\$(zoxide init ${SHELL_NAME})"

# Starship prompt
command -v starship &>/dev/null && eval "\$(starship init ${SHELL_NAME})"
# --- end terminal-setup.sh ---
DYNAMIC
    else
        log_dry "Append aliases + plugins + starship init to $SHELL_RC"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}Terminal Setup${NC} — from os-postinstall-scripts"
    echo -e "https://github.com/BragatteMAS/os-postinstall-scripts"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}DRY-RUN MODE — no changes will be made${NC}"
        echo ""
    fi

    detect_platform
    detect_shell
    log_ok "Detected: $OS ($PKG) — $SHELL_NAME"

    ensure_deps

    if [[ "$INTERACTIVE" == "true" ]]; then wizard; fi

    if [[ "$DO_FONT" == "true" ]];     then install_nerd_font; fi
    if [[ "$DO_TOOLS" == "true" ]];    then install_tools; fi
    if [[ "$DO_PLUGINS" == "true" ]];  then install_zsh_plugins; fi
    if [[ "$DO_STARSHIP" == "true" ]]; then setup_starship; fi
    setup_shell

    echo ""
    log_ok "Done! Restart your terminal or run: exec \$SHELL"
    if [[ "$DO_FONT" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}IMPORTANT:${NC} Set your terminal font to ${BOLD}JetBrainsMono Nerd Font${NC}"
        echo -e "           in your terminal preferences for icons to display correctly."
    fi
    echo ""
}

main "$@"
