#!/usr/bin/env bash
#######################################
# migrate-p10k.sh
# Migrate from Powerlevel10k to Starship
#
# Detects p10k across all known installation methods,
# backs up configs, cleans .zshrc, and offers Starship
# preset selection. Safe by default (deactivate + backup).
#
# Usage:
#   bash migrate-p10k.sh                # detect, backup, deactivate p10k
#   bash migrate-p10k.sh --dry-run      # preview changes (no modifications)
#   bash migrate-p10k.sh --remove       # full cleanup (removes p10k files)
#   bash migrate-p10k.sh -n --remove    # preview full cleanup
#
# From: https://github.com/BragatteMAS/os-postinstall-scripts
#######################################
set -euo pipefail

# ─── Script directory ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# ─── Flags ───────────────────────────────────────────────────────────
DRY_RUN=false
REMOVE_P10K=false

# ─── State ───────────────────────────────────────────────────────────
P10K_FOUND=false
P10K_DIR=""
P10K_CONFIG=""

# ─── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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

# ─── Argument parsing ───────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --remove)
                REMOVE_P10K=true
                shift
                ;;
            --help|-h)
                echo "Usage: bash migrate-p10k.sh [OPTIONS]"
                echo ""
                echo "Migrate from Powerlevel10k to Starship."
                echo ""
                echo "Options:"
                echo "  --dry-run, -n   Preview changes without modifying files"
                echo "  --remove        Remove p10k files (default: deactivate only)"
                echo "  --help, -h      Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run 'bash migrate-p10k.sh --help' for usage"
                exit 1
                ;;
        esac
    done
}

# ─── p10k detection ─────────────────────────────────────────────────
detect_p10k() {
    local found=false

    # Check .zshrc for p10k references
    if [[ -f "${HOME}/.zshrc" ]] && grep -qE 'powerlevel10k|p10k' "${HOME}/.zshrc" 2>/dev/null; then
        found=true
    fi

    # Check all known installation directories
    local -a p10k_paths=(
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        "$HOME/powerlevel10k"
        "$HOME/.zinit/plugins/romkatv---powerlevel10k"
        "$HOME/.zplug/repos/romkatv/powerlevel10k"
        "$HOME/.antigen/bundles/romkatv/powerlevel10k"
        "$HOME/.zim/modules/powerlevel10k"
    )

    # Check Homebrew path if brew is available
    if command -v brew &>/dev/null; then
        local brew_prefix
        brew_prefix="$(brew --prefix 2>/dev/null)" || true
        if [[ -n "$brew_prefix" ]]; then
            p10k_paths+=("${brew_prefix}/opt/powerlevel10k")
        fi
    fi

    for path in "${p10k_paths[@]}"; do
        if [[ -d "$path" ]]; then
            P10K_DIR="$path"
            found=true
            break
        fi
    done

    # Check for .p10k.zsh config file
    if [[ -f "${HOME}/.p10k.zsh" ]]; then
        P10K_CONFIG="${HOME}/.p10k.zsh"
        found=true
    fi

    if [[ "$found" == "true" ]]; then
        P10K_FOUND=true
        return 0
    fi

    return 1
}

# ─── Backup ─────────────────────────────────────────────────────────
backup_p10k() {
    local backup_dir="${HOME}/.p10k-backup.$(date +%Y-%m-%d)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Create backup directory: $backup_dir"
        [[ -n "$P10K_CONFIG" ]] && log_dry "Copy ${P10K_CONFIG} to ${backup_dir}/"
        [[ -f "${HOME}/.zshrc" ]] && log_dry "Copy ${HOME}/.zshrc to ${backup_dir}/"
        [[ -n "$P10K_DIR" ]] && log_dry "Save p10k path to ${backup_dir}/p10k_path.txt"
        return 0
    fi

    mkdir -p "$backup_dir"

    # Copy .p10k.zsh if exists
    if [[ -n "$P10K_CONFIG" && -f "$P10K_CONFIG" ]]; then
        cp "$P10K_CONFIG" "$backup_dir/"
        log_ok "Backed up $(basename "$P10K_CONFIG")"
    fi

    # Copy .zshrc if exists
    if [[ -f "${HOME}/.zshrc" ]]; then
        cp "${HOME}/.zshrc" "$backup_dir/"
        log_ok "Backed up .zshrc"
    fi

    # Save p10k directory path for reference
    if [[ -n "$P10K_DIR" ]]; then
        echo "$P10K_DIR" > "$backup_dir/p10k_path.txt"
    fi

    log_info "Backup saved to $backup_dir"
}

# ─── Clean .zshrc ───────────────────────────────────────────────────
clean_zshrc_p10k() {
    local zshrc="${HOME}/.zshrc"
    [[ -f "$zshrc" ]] || return 0

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Remove p10k-instant-prompt lines from $zshrc"
        log_dry "Remove 'source .p10k.zsh' lines from $zshrc"
        log_dry "Remove 'source powerlevel10k.zsh-theme' lines from $zshrc"
        log_dry "Remove zinit/zplug powerlevel10k lines from $zshrc"
        log_dry "Replace ZSH_THEME=\"powerlevel10k/powerlevel10k\" with \"robbyrussell\" in $zshrc"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"

    # Remove p10k references using temp file (portable, no sed -i)
    # - p10k-instant-prompt block
    # - source .p10k.zsh lines
    # - source powerlevel10k.zsh-theme lines
    # - zinit powerlevel10k lines
    # - zplug powerlevel10k lines
    # Then replace ZSH_THEME with safe default
    grep -v 'p10k-instant-prompt' "$zshrc" \
        | grep -v 'source.*\.p10k\.zsh' \
        | grep -v 'source.*powerlevel10k\.zsh-theme' \
        | grep -v 'zinit.*powerlevel10k' \
        | grep -v 'zplug.*powerlevel10k' \
        | sed 's/ZSH_THEME="powerlevel10k\/powerlevel10k"/ZSH_THEME="robbyrussell"/' \
        > "$tmp"

    mv "$tmp" "$zshrc"
    log_ok "Cleaned p10k references from .zshrc"
}

# ─── Remove p10k files ──────────────────────────────────────────────
remove_p10k_files() {
    # Remove p10k installation directory
    if [[ -n "$P10K_DIR" && -d "$P10K_DIR" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "rm -rf $P10K_DIR"
        else
            rm -rf "$P10K_DIR"
            log_ok "Removed $P10K_DIR"
        fi
    fi

    # Remove .p10k.zsh config
    if [[ -f "${HOME}/.p10k.zsh" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "rm ${HOME}/.p10k.zsh"
        else
            rm "${HOME}/.p10k.zsh"
            log_ok "Removed ${HOME}/.p10k.zsh"
        fi
    fi

    # Remove instant prompt cache files
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
    local cache_files
    cache_files=$(find "$cache_dir" -maxdepth 1 -name 'p10k-instant-prompt-*.zsh' 2>/dev/null) || true
    if [[ -n "$cache_files" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "rm ${cache_dir}/p10k-instant-prompt-*.zsh"
        else
            rm -f "${cache_dir}"/p10k-instant-prompt-*.zsh
            log_ok "Removed p10k instant prompt cache"
        fi
    fi
}

# ─── Preset selection ───────────────────────────────────────────────
select_preset() {
    local preset_dir="${SCRIPT_DIR}/presets"

    if [[ ! -d "$preset_dir" ]]; then
        log_warn "Presets directory not found: $preset_dir"
        log_info "You can manually configure Starship: https://starship.rs/config/"
        return 0
    fi

    echo ""
    echo -e "${BOLD}Available Starship presets:${NC}"
    echo "  1) minimal    - Clean, fast, ASCII-safe (recommended)"
    echo "  2) powerline  - Colored segments with arrows (Nerd Font required)"
    echo "  3) p10k-alike - Closest match to p10k Lean style"
    echo ""
    read -rp "Choose preset [1-3, default=1]: " choice
    choice="${choice:-1}"

    local preset_file
    case "$choice" in
        1) preset_file="${preset_dir}/minimal.toml" ;;
        2) preset_file="${preset_dir}/powerline.toml" ;;
        3) preset_file="${preset_dir}/p10k-alike.toml" ;;
        *)
            log_warn "Invalid choice: $choice. Using minimal."
            preset_file="${preset_dir}/minimal.toml"
            ;;
    esac

    if [[ ! -f "$preset_file" ]]; then
        log_error "Preset file not found: $preset_file"
        return 1
    fi

    local config_dir="${HOME}/.config"
    local config_file="${config_dir}/starship.toml"

    # Backup existing starship.toml
    if [[ -f "$config_file" ]]; then
        local backup_file="${config_file}.bak.$(date +%Y-%m-%d)"
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "Backup ${config_file} to ${backup_file}"
        else
            cp "$config_file" "$backup_file"
            log_ok "Backed up existing starship.toml"
        fi
    fi

    # Copy selected preset
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Copy $(basename "$preset_file") to ${config_file}"
    else
        mkdir -p "$config_dir"
        cp "$preset_file" "$config_file"
        log_ok "Installed $(basename "$preset_file") preset"
    fi
}

# ─── Check Starship ─────────────────────────────────────────────────
check_starship() {
    if command -v starship &>/dev/null; then
        log_ok "Starship is installed: $(starship --version 2>/dev/null | head -1)"
    else
        log_warn "Starship is not installed"
        echo ""
        echo "  Install Starship:"
        echo "    brew install starship          # macOS / Homebrew"
        echo "    curl -sS https://starship.rs/install.sh | sh  # any Unix"
        echo ""
    fi
}

# ─── Main ────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}p10k to Starship Migration${NC}"
    echo -e "From: os-postinstall-scripts"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}DRY-RUN MODE — no changes will be made${NC}"
        echo ""
    fi

    # Detect p10k
    if ! detect_p10k; then
        log_info "Powerlevel10k not detected on this system"
        log_info "Nothing to migrate"
        exit 0
    fi

    # Show what was found
    log_info "Powerlevel10k detected:"
    [[ -n "$P10K_DIR" ]] && echo "  Directory: $P10K_DIR"
    [[ -n "$P10K_CONFIG" ]] && echo "  Config:    $P10K_CONFIG"
    echo ""

    # Backup
    backup_p10k

    # Clean .zshrc
    clean_zshrc_p10k

    # Remove or deactivate
    if [[ "$REMOVE_P10K" == "true" ]]; then
        remove_p10k_files
    else
        log_info "p10k deactivated (files preserved). Use --remove for full cleanup"
    fi

    # Check Starship
    check_starship

    # Offer preset selection (only if running interactively)
    if [[ -t 0 ]]; then
        select_preset
    fi

    echo ""
    log_ok "Migration complete!"
    echo ""
    echo -e "  ${BOLD}Restart your terminal${NC} or run: exec \$SHELL"
    echo ""
}

# ─── Entry point ─────────────────────────────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    main "$@"
fi
