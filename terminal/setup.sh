#!/usr/bin/env bash
#######################################
# setup.sh — Terminal Blueprint
# Canonical terminal setup script (SSoT)
#
# Installs modern CLI tools, configures a Starship
# prompt with preset selection, adds productive aliases,
# sets up zsh plugins, and optionally migrates from p10k.
#
# Usage:
#   bash setup.sh                # full install (everything)
#   bash setup.sh --interactive  # wizard mode (choose components)
#   bash setup.sh --dry-run      # preview changes
#   bash setup.sh --migrate      # include p10k migration
#
# From: https://github.com/BragatteMAS/os-postinstall-scripts
#######################################
set -o pipefail

# ─── Script directory ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# ─── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Flags ───────────────────────────────────────────────────────────
DRY_RUN="${DRY_RUN:-false}"
INTERACTIVE=false
DO_MIGRATE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n)      DRY_RUN=true ;;
        --interactive|-i)  INTERACTIVE=true ;;
        --migrate)         DO_MIGRATE=true ;;
    esac
done

# Feature flags (default: install everything except migrate)
DO_FONT=true
DO_TOOLS=true
DO_STARSHIP=true
DO_ALIASES=true
DO_PLUGINS=true

# ─── Logging ─────────────────────────────────────────────────────────
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}  [OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_dry()   { echo -e "${YELLOW}[DRY]${NC}  Would: $*"; }

# ─── DRY_RUN wrapper ────────────────────────────────────────────────
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
    ask "Shell aliases (50+ shortcuts)?" "y"                           || DO_ALIASES=false
    if [[ "$SHELL_NAME" == "zsh" ]]; then
        ask "Zsh plugins (autosuggestions, syntax, completions)?" "y"  || DO_PLUGINS=false
    fi

    # Offer migration if p10k is detected in .zshrc
    if [[ -f "${HOME}/.zshrc" ]] && grep -qE 'powerlevel10k|p10k' "${HOME}/.zshrc" 2>/dev/null; then
        if ask "Migrate from Powerlevel10k?" "y"; then
            DO_MIGRATE=true
        fi
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
        local _missing_cargo=()
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
                _missing_cargo+=("eza")
            fi
        else
            log_ok "eza"
        fi

        # delta — not in apt, install via cargo
        if ! command -v delta &>/dev/null; then
            if command -v cargo &>/dev/null; then
                run cargo install git-delta
            else
                _missing_cargo+=("delta")
            fi
        else
            log_ok "delta"
        fi

        if [[ ${#_missing_cargo[@]} -gt 0 ]]; then
            log_warn "Skipped ${_missing_cargo[*]} — requires Rust (not installed)"
            log_info "Install Rust first: visit https://rustup.rs then re-run this script"
        fi

        # zoxide
        if ! command -v zoxide &>/dev/null; then
            if [[ "${DRY_RUN:-}" == "true" ]]; then
                log_dry "install zoxide via curl|sh"
            else
                curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            fi
        else
            log_ok "zoxide"
        fi

        # starship
        if ! command -v starship &>/dev/null; then
            if [[ "${DRY_RUN:-}" == "true" ]]; then
                log_dry "install starship via curl|sh"
            else
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
        else
            log_ok "starship"
        fi

        # Debian/Ubuntu renames: batcat->bat, fdfind->fd
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            run mkdir -p "$HOME/.local/bin"
            run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
            log_info "Linked batcat -> bat"
        fi
        if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
            run mkdir -p "$HOME/.local/bin"
            run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            log_info "Linked fdfind -> fd"
        fi
    fi
}

# ─── Nerd Font ───────────────────────────────────────────────────────
# Only installs Regular, Bold, Italic, BoldItalic (~10 MB vs ~220 MB full cask)
install_nerd_font() {
    log_info "Installing JetBrainsMono Nerd Font..."

    local font_variants=(
        "JetBrainsMonoNerdFont-Regular.ttf"
        "JetBrainsMonoNerdFont-Bold.ttf"
        "JetBrainsMonoNerdFont-Italic.ttf"
        "JetBrainsMonoNerdFont-BoldItalic.ttf"
    )

    if [[ "$PKG" == "brew" ]]; then
        local font_dir="${HOME}/Library/Fonts"
    elif [[ "$PKG" == "apt" ]]; then
        local font_dir="${HOME}/.local/share/fonts"
    fi

    # Check if already installed
    if [[ -f "${font_dir}/${font_variants[0]}" ]]; then
        log_ok "JetBrainsMono Nerd Font"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    log_info "Downloading from GitHub releases..."
    run curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "${tmp_dir}/JetBrainsMono.zip"
    run mkdir -p "$font_dir"

    # Extract only the 4 variants needed for terminal use
    for variant in "${font_variants[@]}"; do
        run unzip -qo "${tmp_dir}/JetBrainsMono.zip" "$variant" -d "$font_dir"
    done

    # Refresh font cache (Linux only)
    [[ "$PKG" == "apt" ]] && run fc-cache -f

    rm -rf "$tmp_dir"
    log_ok "Nerd Font installed — see post-install instructions at the end"
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

# ─── Preset Selection ────────────────────────────────────────────────
select_preset() {
    local project_config="${SCRIPT_DIR}/../data/dotfiles/starship/starship.toml"
    local preset_dir="${SCRIPT_DIR}/presets"

    echo ""
    echo -e "${BOLD}Available Starship presets:${NC}"
    echo "  1) project    - MAS Oceanic Theme with powerline (recommended)"
    if [[ -d "$preset_dir" ]]; then
        echo "  2) minimal    - Clean, fast, ASCII-safe"
        echo "  3) powerline  - Colored segments with arrows (Nerd Font required)"
        echo "  4) p10k-alike - Closest match to p10k Lean style"
    fi
    echo ""
    read -rp "Choose preset [default=1]: " choice
    choice="${choice:-1}"

    local preset_file
    case "$choice" in
        1) preset_file="$project_config" ;;
        2) preset_file="${preset_dir}/minimal.toml" ;;
        3) preset_file="${preset_dir}/powerline.toml" ;;
        4) preset_file="${preset_dir}/p10k-alike.toml" ;;
        *)
            log_warn "Invalid choice: $choice. Using project config."
            preset_file="$project_config"
            ;;
    esac

    if [[ ! -f "$preset_file" ]]; then
        log_error "Preset file not found: $preset_file"
        return 1
    fi

    local config_dir="${HOME}/.config"
    local config_file="${config_dir}/starship.toml"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Copy $(basename "$preset_file") to ${config_file}"
    else
        mkdir -p "$config_dir"
        cp "$preset_file" "$config_file"
        log_ok "Installed $(basename "$preset_file") preset"
    fi
}

# ─── Offer p10k Migration ────────────────────────────────────────────
# Runs migrate-p10k.sh as SUBPROCESS (not source). Zero coupling.
offer_migration() {
    local migrate_script="${SCRIPT_DIR}/migrate-p10k.sh"

    if [[ ! -f "$migrate_script" ]]; then
        log_warn "migrate-p10k.sh not found at ${migrate_script}"
        log_info "Skipping migration"
        return 0
    fi

    # Check for p10k references in .zshrc
    if [[ ! -f "${HOME}/.zshrc" ]] || ! grep -qE 'powerlevel10k|p10k' "${HOME}/.zshrc" 2>/dev/null; then
        log_info "No Powerlevel10k references found in .zshrc"
        log_info "Skipping migration"
        return 0
    fi

    # Interactive: ask before migrating
    if [[ "$INTERACTIVE" == "true" ]]; then
        if ! ask "Powerlevel10k detected. Run migration now?" "y"; then
            log_info "Migration skipped"
            return 0
        fi
    fi

    log_info "Running p10k migration..."
    bash "${SCRIPT_DIR}/migrate-p10k.sh" $( [[ "$DRY_RUN" == "true" ]] && echo "--dry-run" )
}

# ─── Starship Config ─────────────────────────────────────────────────
setup_starship() {
    log_info "Configuring starship prompt..."
    local config_dir="${HOME}/.config"
    local config_file="${config_dir}/starship.toml"
    local project_config="${SCRIPT_DIR}/../data/dotfiles/starship/starship.toml"

    run mkdir -p "$config_dir"

    # Backup existing config before any write
    if [[ -f "$config_file" ]]; then
        local backup_file="${config_file}.bak.$(date +%Y-%m-%d)"
        log_warn "Backing up existing starship.toml -> ${backup_file}"
        run cp "$config_file" "$backup_file"
    fi

    if [[ "$INTERACTIVE" == "true" ]]; then
        select_preset
    else
        # Non-interactive: use project config (SSoT)
        if [[ -f "$project_config" ]]; then
            run cp "$project_config" "$config_file"
            log_ok "Installed project starship config"
        else
            log_warn "Project starship.toml not found, skipping"
        fi
    fi

    # Copy all presets locally for easy switching later
    local preset_dir="${SCRIPT_DIR}/presets"
    local local_presets="${HOME}/.config/starship/presets"
    if [[ -d "$preset_dir" ]]; then
        run mkdir -p "$local_presets"
        run cp "${preset_dir}"/*.toml "$local_presets/" 2>/dev/null
        if [[ -f "$project_config" ]]; then
            run cp "$project_config" "${local_presets}/project.toml"
        fi
        log_ok "Presets saved to ${local_presets}/ — switch with: cp ~/.config/starship/presets/<name>.toml ~/.config/starship.toml"
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
        run cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%Y-%m-%d)"
        log_info "Backed up -> ${SHELL_RC}.bak.$(date +%Y-%m-%d)"
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        echo "" >> "$SHELL_RC"
        echo "# --- terminal-setup.sh ---" >> "$SHELL_RC"

        # Aliases (copy from SSoT, source from shell RC)
        if [[ "$DO_ALIASES" == "true" ]]; then
            local aliases_src="${SCRIPT_DIR}/../data/dotfiles/shared/aliases.sh"
            local aliases_dst="${HOME}/.config/shell/aliases.sh"

            if [[ -f "$aliases_src" ]]; then
                run mkdir -p "${HOME}/.config/shell"
                run cp "$aliases_src" "$aliases_dst"
                log_ok "Copied aliases.sh to ${aliases_dst}"
                echo "" >> "$SHELL_RC"
                echo "# Aliases (managed by terminal-setup.sh)" >> "$SHELL_RC"
                echo '[[ -f "${HOME}/.config/shell/aliases.sh" ]] && source "${HOME}/.config/shell/aliases.sh"' >> "$SHELL_RC"
            else
                log_warn "aliases.sh not found at ${aliases_src} — skipping aliases"
            fi
        fi

        # Functions: welcome, h(), cmd() (copy from SSoT, source from shell RC)
        if [[ "$DO_ALIASES" == "true" ]]; then
            local functions_src="${SCRIPT_DIR}/../data/dotfiles/shared/functions.sh"
            local functions_dst="${HOME}/.config/shell/functions.sh"

            if [[ -f "$functions_src" ]]; then
                run mkdir -p "${HOME}/.config/shell"
                run cp "$functions_src" "$functions_dst"
                log_ok "Copied functions.sh to ${functions_dst}"
                echo "" >> "$SHELL_RC"
                echo "# Functions: welcome, help, search (managed by terminal-setup.sh)" >> "$SHELL_RC"
                echo '[[ -f "${HOME}/.config/shell/functions.sh" ]] && source "${HOME}/.config/shell/functions.sh"' >> "$SHELL_RC"
            else
                log_warn "functions.sh not found at ${functions_src} — skipping functions"
            fi
        fi

        # Plugins (only if user opted in)
        if [[ "$DO_PLUGINS" == "true" && "$SHELL_NAME" == "zsh" ]]; then
            cat >> "$SHELL_RC" <<'PLUGINS'

# zsh plugins
[[ -f "${HOME}/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "${HOME}/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -d "${HOME}/.zsh/zsh-completions/src" ]] && fpath=("${HOME}/.zsh/zsh-completions/src" $fpath)
[[ -f "${HOME}/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "${HOME}/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
PLUGINS
        fi

        # Zoxide (only if tools were installed)
        if [[ "$DO_TOOLS" == "true" ]]; then
            cat >> "$SHELL_RC" <<ZOXIDE

# zoxide (smarter cd)
command -v zoxide &>/dev/null && eval "\$(zoxide init ${SHELL_NAME})"
ZOXIDE
        fi

        # Starship prompt (only if user opted in)
        if [[ "$DO_STARSHIP" == "true" ]]; then
            cat >> "$SHELL_RC" <<STARSHIP

# Starship prompt
command -v starship &>/dev/null && eval "\$(starship init ${SHELL_NAME})"
STARSHIP
        fi

        echo "# --- end terminal-setup.sh ---" >> "$SHELL_RC"
    else
        log_dry "Append aliases + functions + plugins + starship init to $SHELL_RC"
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

    # Migration (subprocess, not source)
    if [[ "$DO_MIGRATE" == "true" ]]; then offer_migration; fi

    if [[ "$DO_FONT" == "true" ]];     then install_nerd_font; fi
    if [[ "$DO_TOOLS" == "true" ]];    then install_tools; fi
    if [[ "$DO_PLUGINS" == "true" ]];  then install_zsh_plugins; fi
    if [[ "$DO_STARSHIP" == "true" ]]; then setup_starship; fi
    setup_shell

    echo ""
    echo -e "  ${GREEN}${BOLD}Done!${NC} Restart your terminal to apply."
    echo ""
    if [[ "$DO_FONT" == "true" ]]; then
        echo -e "  ${YELLOW}Font${NC}  Set ${BOLD}JetBrainsMono Nerd Font${NC} in your terminal:"
        case "${TERM_PROGRAM:-}" in
            iTerm.app)      echo -e "        iTerm2 > Settings > Profiles > Text > Font" ;;
            Apple_Terminal) echo -e "        Terminal.app > Settings > Profiles > Font" ;;
            WarpTerminal)   echo -e "        Warp > Settings > Appearance > Font" ;;
            vscode)         echo -e "        VS Code > terminal.integrated.fontFamily" ;;
            *)              echo -e "        Open your terminal preferences > Font" ;;
        esac
        echo ""
    fi
    if [[ "$DO_STARSHIP" == "true" ]]; then
        echo -e "  ${BLUE}Theme${NC} Switch anytime:"
        echo -e "        cp ~/.config/starship/presets/${BOLD}<name>${NC}.toml ~/.config/starship.toml"
        echo -e "        Available: project, minimal, powerline, p10k-alike"
        echo ""
    fi
}

# ─── Entry point ─────────────────────────────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
