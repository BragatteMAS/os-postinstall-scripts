# Aliases compatible with both zsh and bash

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
    alias ll="eza -la --git"
    alias la="eza -a"
    alias lt="eza --tree --level=2"
    alias lta="eza --tree --level=2 -a"
else
    # Fallback to ls with color
    if ls --color=auto &>/dev/null 2>&1; then
        alias ls="ls --color=auto"
    fi
    alias ll="ls -lAh"
    alias la="ls -A"
fi

# -----------------------------------------------------------------------------
# Safety nets
# -----------------------------------------------------------------------------
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -pv"

# -----------------------------------------------------------------------------
# Git shortcuts
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
alias gsw="git switch"
alias gst="git stash"

# -----------------------------------------------------------------------------
# Modern tool replacements (if available)
# -----------------------------------------------------------------------------
command -v bat &>/dev/null && alias cat="bat --paging=never"
command -v fd &>/dev/null && alias find="fd"
command -v rg &>/dev/null && alias grep="rg"
command -v delta &>/dev/null && alias diff="delta"

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
alias h="history"
alias c="clear"
alias path='echo $PATH | tr ":" "\n"'
alias now="date '+%Y-%m-%d %H:%M:%S'"

# Disk usage
alias df="df -h"
alias du="du -h"
alias duh="du -h -d 1"

# Network
alias ip="ip -c"
alias ports="ss -tulanp"

# -----------------------------------------------------------------------------
# System-specific (Ubuntu/Debian)
# -----------------------------------------------------------------------------
if command -v apt &>/dev/null; then
    alias update="sudo apt update && sudo apt upgrade -y"
    alias cleanup="sudo apt autoremove -y && sudo apt autoclean"
fi
