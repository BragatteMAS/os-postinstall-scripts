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
# System update — sysup (primary), bum/upall (secondary)
# -----------------------------------------------------------------------------
# AI coding CLIs: only the ones already installed are updated. Each step is
# independent and never aborts sysup; failures are listed at the end.
_sysup_ai_tools() {
    local failed=""
    if command -v brew &>/dev/null && brew list --cask claude-code@latest &>/dev/null; then
        brew upgrade claude-code@latest || failed="$failed claude-code"
    fi
    if command -v bun &>/dev/null; then
        if command -v opencode &>/dev/null; then
            bun i -g opencode-ai@latest || failed="$failed opencode-ai"
        fi
        if command -v codex &>/dev/null; then
            bun i -g @openai/codex@latest || failed="$failed @openai/codex"
        fi
    fi
    [ -z "$failed" ] || echo "sysup: failed to update:$failed (rerun the command by hand)" >&2
    return 0
}

if command -v brew &>/dev/null; then
    sysup() { brew update && brew upgrade && _sysup_ai_tools && brew cleanup && { brew doctor 2>&1 | grep -v 'Please note' || true; }; }
elif command -v apt &>/dev/null; then
    sysup() { sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && _sysup_ai_tools; }
elif command -v yum &>/dev/null; then
    sysup() { sudo yum update -y && _sysup_ai_tools; }
elif command -v pacman &>/dev/null; then
    sysup() { sudo pacman -Syu && _sysup_ai_tools; }
fi
bum() { sysup "$@"; }
upall() { sysup "$@"; }
