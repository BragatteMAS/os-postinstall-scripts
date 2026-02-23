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
    alias ll="eza -la --git --group-directories-first"
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
# Modern tool shortcuts (safe — don't shadow POSIX commands)
# -----------------------------------------------------------------------------
command -v bat &>/dev/null && alias cat="bat --paging=never --plain"
command -v delta &>/dev/null && alias diff="delta"

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
alias c="clear"
alias path='echo $PATH | tr ":" "\n"'
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
# System update — bum (Brew/apt Update Manager)
# -----------------------------------------------------------------------------
if command -v brew &>/dev/null; then
    alias bum="brew update && brew upgrade && brew cleanup && brew doctor 2>&1 | grep -v 'Please note'"
elif command -v apt &>/dev/null; then
    alias bum="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
elif command -v yum &>/dev/null; then
    alias bum="sudo yum update -y"
elif command -v pacman &>/dev/null; then
    alias bum="sudo pacman -Syu"
fi
