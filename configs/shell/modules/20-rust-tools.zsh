#!/bin/zsh
# ==============================================================================
# Module: Rust Tools
# Description: Modern CLI tools written in Rust
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ RUST TOOLS CONFIGURATION                                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Rust environment
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

## eza (modern ls) - https://github.com/eza-community/eza
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first'
    alias la='eza -a --icons'
    alias l='eza -F --icons'
    alias lt='eza -lah --sort=modified --icons'
    alias tree='eza --tree --icons'
    alias ltree='eza --tree --level=2 --icons'
fi

## bat (better cat) - https://github.com/sharkdp/bat
if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'
    alias catn='bat --style=numbers'
    alias catf='bat --style=full'
    export BAT_THEME="OneHalfDark"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

## fd (modern find) - https://github.com/sharkdp/fd
if command -v fd &> /dev/null; then
    alias find='fd'
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

## ripgrep (rg - modern grep) - https://github.com/BurntSushi/ripgrep
if command -v rg &> /dev/null; then
    alias grep='rg'
    alias rgf='rg --files-with-matches'
    alias rgi='rg --ignore-case'
    alias rgv='rg --invert-match'
    export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
fi

## delta (better diff) - https://github.com/dandavison/delta
if command -v delta &> /dev/null; then
    export GIT_PAGER='delta'
    alias diff='delta'
fi

## zoxide (smart cd) - https://github.com/ajeetdsouza/zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd='z'
    alias cdi='zi'  ## Interactive selection
fi

## dust (du alternative) - https://github.com/bootandy/dust
if command -v dust &> /dev/null; then
    alias du='dust'
    alias dud='dust -d 1'
    alias dus='dust -s'
fi

## bottom (system monitor) - https://github.com/ClementTsang/bottom
if command -v btm &> /dev/null; then
    alias top='btm'
    alias htop='btm'
fi

## procs (modern ps) - https://github.com/dalance/procs
if command -v procs &> /dev/null; then
    alias ps='procs'
    alias pst='procs --tree'
    alias psw='procs --watch'
fi

## tokei (code statistics) - https://github.com/XAMPPRocky/tokei
if command -v tokei &> /dev/null; then
    alias loc='tokei'
    alias lines='tokei'
fi

## sd (modern sed) - https://github.com/chmln/sd
if command -v sd &> /dev/null; then
    # sd doesn't need an alias, but here for reference
    # Usage: sd 'find' 'replace' file
fi

## hyperfine (benchmarking) - https://github.com/sharkdp/hyperfine
if command -v hyperfine &> /dev/null; then
    alias bench='hyperfine'
    alias benchmark='hyperfine'
fi

## gitui (terminal UI for git) - https://github.com/extrawurst/gitui
if command -v gitui &> /dev/null; then
    alias gg='gitui'
    alias gui='gitui'
fi

## starship prompt - https://starship.rs
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi