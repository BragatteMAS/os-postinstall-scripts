# Shell functions for terminal-setup.sh
# Requires bash or zsh — not compatible with sh/dash
# Source: https://github.com/BragatteMAS/os-postinstall-scripts

# Guard: skip silently if sourced by sh/dash
[ -z "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ] && return 0 2>/dev/null

# -----------------------------------------------------------------------------
# Emoji Toggle — set TERMINAL_EMOJI=false for ASCII-only output
# Auto-detects: disables emojis if locale lacks UTF-8
# -----------------------------------------------------------------------------
_use_emoji() {
    [[ "${TERMINAL_EMOJI:-}" == "false" ]] && return 1
    [[ "${TERMINAL_EMOJI:-}" == "true" ]] && return 0
    # Auto-detect from locale (check LC_ALL, LC_CTYPE, then LANG)
    local locale_str="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    [[ "$locale_str" == *UTF-8* || "$locale_str" == *utf8* ]]
}

# -----------------------------------------------------------------------------
# Welcome Message — shown once on first session, then via 'welcome'
# -----------------------------------------------------------------------------
show_welcome() {
    local current_time
    current_time=$(date +%H:%M)
    local current_dir
    current_dir=$(basename "$PWD")
    local git_branch=""

    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo 'detached')
        if _use_emoji; then
            git_branch=" | 🌿 $branch"
        else
            git_branch=" | $branch"
        fi
    fi

    if _use_emoji; then
        echo ""
        echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
        echo "┃ 🚀 $current_time | 📁 $current_dir$git_branch"
        echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
        echo ""
        echo "💡 h (help) | cmd <term> (search aliases) | h tools (CLI tools)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo ""
        echo "--- $current_time | $current_dir$git_branch ---"
        echo ""
        echo "h (help) | cmd <term> (search aliases) | h tools (CLI tools)"
        echo "---"
    fi
}

show_welcome_compact() {
    local git_info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo 'detached')
        if _use_emoji; then
            git_info=" | 🌿 $branch"
        else
            git_info=" | $branch"
        fi
    fi
    if _use_emoji; then
        echo "🚀 $(date +%H:%M) | 📁 $(basename "$PWD")$git_info"
    else
        echo "$(date +%H:%M) | $(basename "$PWD")$git_info"
    fi
    echo "h (help) | cmd <term> (search)"
}

alias welcome='show_welcome'
alias welcomec='show_welcome_compact'

# -----------------------------------------------------------------------------
# Help — h [topic]
# -----------------------------------------------------------------------------
h() {
    local _e=""
    _use_emoji && _e=1

    case "${1:-}" in
        ""|"help")
            [[ -n "$_e" ]] && echo "⚡ ESSENTIALS" || echo "ESSENTIALS"
            echo "NAV:  .. ... .... .....  (up directories)"
            echo "LIST: ls ll la lt        (eza if available)"
            echo "GIT:  gs gd ga gc gp gl glo gb gco gcb gsw gst"
            echo "FIND: preview (fzf)  aliases (search)  cmd <term>"
            echo "TOOL: bat fd rg fzf eza delta z    (h tools)"
            echo "UTIL: h c path now df du duh ports sysup mkcd"
            echo ""
            [[ -n "$_e" ]] && echo "💡 h <topic>: nav | git | find | tools | util | all" \
                           || echo "h <topic>: nav | git | find | tools | util | all"
            ;;
        "find"|"search")
            [[ -n "$_e" ]] && echo "🔍 Search & Preview:" || echo "Search & Preview:"
            echo "  preview   fzf file preview (with bat)"
            echo "  aliases   search aliases with fzf"
            echo "  cmd <t>   search aliases by keyword"
            echo "  rg <t>    search file contents (ripgrep)"
            echo "  fd <t>    find files by name"
            echo "  z <dir>   jump to directory (zoxide)"
            ;;
        "nav"|"ls")
            [[ -n "$_e" ]] && echo "📁 Navigation & Listing:" || echo "Navigation & Listing:"
            echo "  ..        cd .."
            echo "  ...       cd ../.."
            echo "  ....      cd ../../.."
            echo "  ls        eza (or ls --color)"
            echo "  ll        detailed list with git info"
            echo "  la        show hidden files"
            echo "  lt        tree view (2 levels)"
            echo "  mkcd <d>  create directory and cd into it"
            ;;
        "git")
            [[ -n "$_e" ]] && echo "🌿 Git:" || echo "Git:"
            echo "  gs        git status"
            echo "  gd/gds    git diff / --staged"
            echo "  ga/gap    git add / -p (patch)"
            echo "  gc/gca    git commit / --amend"
            echo "  gp/gpl    git push / pull"
            echo "  gf        git fetch"
            echo "  gl/glo    git log --oneline / --graph --all"
            echo "  gb/gco    git branch / checkout"
            echo "  gcb <b>   git checkout -b (new branch)"
            echo "  gsw/gst   git switch / stash"
            ;;
        "tools"|"rust")
            [[ -n "$_e" ]] && echo "🦀 Modern CLI Tools:" || echo "Modern CLI Tools:"
            echo "  bat       cat with syntax highlighting"
            echo "  fd        find replacement (fast)"
            echo "  rg        grep replacement (ripgrep)"
            echo "  eza       ls replacement (colors, icons, git)"
            echo "  delta     diff with syntax highlighting"
            echo "  z/zi      zoxide — smarter cd (learns your dirs)"
            echo "  starship  cross-shell prompt"
            ;;
        "util")
            [[ -n "$_e" ]] && echo "🔧 Utilities:" || echo "Utilities:"
            echo "  h         this help"
            echo "  c         clear"
            echo "  path      show \$PATH (one per line)"
            echo "  now       current date+time"
            echo "  df/du     disk free/usage"
            echo "  duh       disk usage, 1 level deep"
            echo "  ports     show listening ports"
            echo "  sysup     full system update (brew/apt/yum/pacman)"
            echo "  mkcd <d>  mkdir + cd in one step"
            ;;
        "all")
            h; echo ""; h nav; echo ""; h git; echo ""; h find; echo ""; h tools; echo ""; h util
            ;;
        *)
            [[ -n "$_e" ]] && echo "❓ Unknown topic '$1'" || echo "Unknown topic '$1'"
            [[ -n "$_e" ]] && echo "💡 h <topic>: nav | git | tools | util | all" \
                           || echo "h <topic>: nav | git | tools | util | all"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Search aliases and functions by keyword
# -----------------------------------------------------------------------------
cmd() {
    local search="$1"
    if [[ -z "$search" ]]; then
        echo "Usage: cmd <term>  (e.g. cmd git, cmd ls)"
        return 1
    fi
    if _use_emoji; then
        echo "🔍 '$search':"
    else
        echo "Search '$search':"
    fi
    alias | sed 's/^alias //' | grep -i "$search" | sed 's/^/  /' || true
}

# -----------------------------------------------------------------------------
# File preview with fzf + bat (requires fzf)
# -----------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
    preview() {
        local preview_cmd="bat --color=always --style=numbers --line-range=:500 {}"
        command -v bat &>/dev/null || preview_cmd="cat {}"
        fzf --preview "$preview_cmd" "$@"
    }
    aliases() { alias | fzf; }
    # Legacy names for muscle memory
    alias fp='preview'
    alias af='aliases'
fi

# -----------------------------------------------------------------------------
# mkcd — create directory and cd into it
# -----------------------------------------------------------------------------
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# -----------------------------------------------------------------------------
# Auto-show welcome on first interactive session only
# Subsequent sessions: silent. Type 'welcome' anytime.
# -----------------------------------------------------------------------------
if [[ $- == *i* ]] && [[ -z "${ZSH_EXECUTION_STRING:-}" ]]; then
    _welcome_marker="${HOME}/.config/shell/.welcome_shown"
    if [[ ! -f "$_welcome_marker" ]]; then
        show_welcome
        mkdir -p "${HOME}/.config/shell" 2>/dev/null
        touch "$_welcome_marker"
    fi
    unset _welcome_marker
fi
