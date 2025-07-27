#!/bin/zsh
# ==============================================================================
# Module: Basic Aliases
# Description: Essential aliases for daily use
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ BASIC ALIASES                                                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

## List aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -lhat'  ## List by time
alias lS='ls -lahS'  ## List by size

## Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

## Convenience aliases
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias timestamp='date +%s'

## Clear and reload
alias c='clear'
alias cls='clear'
alias reload='source ~/.zshrc'
alias zshconfig='${EDITOR} ~/.zshrc'

## Make commands human-readable
alias df='df -h'
alias du='du -h'
alias free='free -h'

## Process management
alias psa='ps aux'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'

## Network
alias ports='netstat -tulanp'
alias listening='lsof -P -i -n'
alias ipinfo='curl ipinfo.io'
alias myip='curl -s ifconfig.me'

## System info
alias meminfo='free -h -l -t'
alias cpuinfo='lscpu'
alias diskinfo='df -h'

## Clipboard (cross-platform)
if [[ "$IS_MACOS" == true ]]; then
    alias pbcopy='pbcopy'
    alias pbpaste='pbpaste'
else
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi