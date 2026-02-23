# Shell functions for terminal-setup.sh
# Compatible with both zsh and bash
# Source: https://github.com/BragatteMAS/os-postinstall-scripts

# -----------------------------------------------------------------------------
# Welcome Message
# -----------------------------------------------------------------------------
show_welcome() {
    local current_time
    current_time=$(date +%H:%M)
    local current_dir
    current_dir=$(basename "$PWD")
    local git_branch=""

    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_branch=" | 🌿 $(git branch --show-current 2>/dev/null || echo 'detached')"
    fi

    echo ""
    echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo "┃ 🚀 $current_time | 📁 $current_dir$git_branch"
    echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""
    echo "💡 h (help) | cmd <term> (search aliases)"
    echo "🦀 bat fd rg eza delta z"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

show_welcome_compact() {
    local git_info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_info=" | 🌿 $(git branch --show-current 2>/dev/null || echo 'detached')"
    fi
    echo "🚀 $(date +%H:%M) | 📁 $(basename "$PWD")$git_info"
    echo "💡 h (help) | cmd <term> (search)"
}

alias welcome='show_welcome'
alias welcomec='show_welcome_compact'

# -----------------------------------------------------------------------------
# Help — h [topic]
# Replaces the simpler alias h="history" from aliases.sh
# -----------------------------------------------------------------------------
unalias h 2>/dev/null
h() {
    case "${1:-}" in
        ""|"help")
            echo "⚡ ESSENTIALS"
            echo "NAV:  .. ... .... .....  (up directories)"
            echo "LIST: ls ll la lt        (eza if available)"
            echo "GIT:  gs gd ga gc gp gl glo gb gco gsw gst"
            echo "RUST: bat fd rg eza delta z"
            echo "UTIL: h c path now df du duh ports update cleanup"
            echo ""
            echo "💡 h <topic>: nav | git | tools | util | all"
            ;;
        "nav"|"ls")
            echo "📁 Navigation & Listing:"
            echo "  ..        cd .."
            echo "  ...       cd ../.."
            echo "  ....      cd ../../.."
            echo "  ls        eza (or ls --color)"
            echo "  ll        detailed list with git info"
            echo "  la        show hidden files"
            echo "  lt        tree view (2 levels)"
            ;;
        "git")
            echo "🌿 Git:"
            echo "  gs        git status"
            echo "  gd/gds    git diff / --staged"
            echo "  ga/gap    git add / -p (patch)"
            echo "  gc/gca    git commit / --amend"
            echo "  gp/gpl    git push / pull"
            echo "  gf        git fetch"
            echo "  gl/glo    git log --oneline / --graph --all"
            echo "  gb/gco    git branch / checkout"
            echo "  gsw/gst   git switch / stash"
            ;;
        "tools"|"rust")
            echo "🦀 Modern CLI Tools:"
            echo "  bat       cat with syntax highlighting"
            echo "  fd        find replacement (fast)"
            echo "  rg        grep replacement (ripgrep)"
            echo "  eza       ls replacement (colors, icons, git)"
            echo "  delta     diff with syntax highlighting"
            echo "  z/zi      zoxide — smarter cd (learns your dirs)"
            echo "  starship  cross-shell prompt"
            ;;
        "util")
            echo "🔧 Utilities:"
            echo "  h         this help"
            echo "  c         clear"
            echo "  path      show \$PATH (one per line)"
            echo "  now       current date+time"
            echo "  df/du     disk free/usage"
            echo "  duh       disk usage, 1 level deep"
            echo "  ports     show listening ports"
            echo "  update    system update (brew/apt)"
            echo "  cleanup   remove unused packages"
            ;;
        "all")
            h; echo ""; h nav; echo ""; h git; echo ""; h tools; echo ""; h util
            ;;
        *)
            echo "❓ Unknown topic '$1'"
            echo "💡 h <topic>: nav | git | tools | util | all"
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
    echo "🔍 '$search':"
    alias | grep -i "$search" | sed 's/^/  /' || true
}

# -----------------------------------------------------------------------------
# Auto-show welcome on interactive shell startup
# -----------------------------------------------------------------------------
if [[ $- == *i* ]] && [[ -z "${ZSH_EXECUTION_STRING:-}" ]]; then
    show_welcome
fi
