# Aliases compatible with both zsh and bash
# Requires bash or zsh — not compatible with sh/dash

# Guard: skip silently if sourced by sh/dash
[ -z "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ] && { return 0 2>/dev/null || exit 0; }

# -----------------------------------------------------------------------------
# Navigation
# -----------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# -----------------------------------------------------------------------------
# List (use modern tools if available)
# -----------------------------------------------------------------------------
if command -v eza &>/dev/null; then
    alias ls="eza"
    alias ll="eza -la --git --group-directories-first"
    alias la="eza -a"
    alias lt="eza --tree --level=2"
    alias lta="eza --tree --level=2 -a"
else
    # Fallback to ls with color
    if ls --color=auto /dev/null &>/dev/null; then
        alias ls="ls --color=auto"
    fi
    alias ll="ls -lAh"
    alias la="ls -A"
fi

# -----------------------------------------------------------------------------
# Safety nets (interactive only — bypassed in scripts automatically)
# -----------------------------------------------------------------------------
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -p"

# -----------------------------------------------------------------------------
# Git shortcuts (pattern: g + first letter(s) of subcommand)
# -----------------------------------------------------------------------------
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gds="git diff --staged"
alias ga="git add"
alias gap="git add -p"
alias gc="git commit"
alias gca="git commit --amend"
alias gp="git push"
alias gpl="git pull"
alias gf="git fetch"
alias gl="git log --oneline -20"
alias glo="git log --oneline --graph --all"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gsw="git switch"
alias gst="git stash"

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
alias c="clear"
alias path='echo "$PATH" | tr ":" "\n"'
alias now="date '+%Y-%m-%d %H:%M:%S'"

# Disk usage
alias df="df -h"
alias du="du -h"
alias duh="du -h -d 1"

# Network (platform-aware)
if command -v ss &>/dev/null; then
    alias ports="ss -tulanp"
else
    alias ports="lsof -iTCP -sTCP:LISTEN -nP"
fi

# -----------------------------------------------------------------------------
# System update — bum
# -----------------------------------------------------------------------------
# Every step runs on its own: one failure does not stop the others, and the
# failed steps are listed at the end (exit status 1). Steps are picked by which
# tools exist, not by machine: brew anywhere, apt/yum/pacman outside macOS,
# then the AI coding CLIs already installed, global npm packages and uv tools.
# Windows has the same command in the PowerShell profile (terminal-setup.ps1).
_bum_step() {  # _bum_step <label> <command...>
    local label="$1"; shift
    printf '==> %s\n' "$label"
    "$@" || _bum_failed="${_bum_failed}${_bum_failed:+, }${label}"
}

# npm and corepack follow the node install, so they are left to the package manager.
_bum_npm_globals() {
    npm ls -g --depth=0 --parseable 2>/dev/null \
        | sed -n 's|.*/node_modules/||p' \
        | grep -v -x -e npm -e corepack
}

_bum_npm_update() {
    _bum_npm_globals | xargs npm update -g
}

# Keyword form on purpose: `bum() {` fails to parse in zsh when the user
# already has an alias named bum (PITFALLS 12.17).
function bum {
    local _bum_failed=""

    # System packages
    if command -v brew >/dev/null 2>&1; then
        _bum_step "brew update" brew update
        _bum_step "brew upgrade" brew upgrade
    fi
    if [ "$(uname -s)" != "Darwin" ]; then
        if command -v apt >/dev/null 2>&1; then
            _bum_step "apt update" sudo apt update
            _bum_step "apt upgrade" sudo apt upgrade -y
            _bum_step "apt autoremove" sudo apt autoremove -y
        elif command -v yum >/dev/null 2>&1; then
            _bum_step "yum update" sudo yum update -y
        elif command -v pacman >/dev/null 2>&1; then
            _bum_step "pacman -Syu" sudo pacman -Syu
        fi
    fi

    # AI coding CLIs: only the ones already installed are updated
    if command -v brew >/dev/null 2>&1 && brew list --cask claude-code@latest >/dev/null 2>&1; then
        _bum_step "claude-code" brew upgrade claude-code@latest
    fi
    if command -v bun >/dev/null 2>&1; then
        if command -v opencode >/dev/null 2>&1; then
            _bum_step "opencode-ai" bun i -g opencode-ai@latest
        fi
        if command -v codex >/dev/null 2>&1; then
            _bum_step "@openai/codex" bun i -g @openai/codex@latest
        fi
    fi

    # Global npm packages
    if command -v npm >/dev/null 2>&1 && [ -n "$(_bum_npm_globals)" ]; then
        _bum_step "npm globals" _bum_npm_update
    fi

    # Python CLI tools installed with uv
    if command -v uv >/dev/null 2>&1; then
        _bum_step "uv tools" uv tool upgrade --all
    fi

    # Housekeeping (brew doctor is informational, never counted as a failure)
    if command -v brew >/dev/null 2>&1; then
        _bum_step "brew cleanup" brew cleanup
        printf '==> %s\n' "brew doctor"
        brew doctor 2>&1 | grep -v 'Please note' || true
    fi

    if [ -n "$_bum_failed" ]; then
        echo "bum: failed: $_bum_failed" >&2
        return 1
    fi
    echo "bum: everything updated"
}
