#!/bin/zsh
# ==============================================================================
# Module: FZF Configuration
# Description: Fuzzy finder setup and key bindings
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ FZF - FUZZY FINDER CONFIGURATION                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

if command -v fzf &> /dev/null; then
    ## FZF default options
    export FZF_DEFAULT_OPTS="
        --height 60%
        --layout=reverse
        --border
        --info=inline
        --multi
        --preview-window=:hidden
        --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
        --bind 'ctrl-/:toggle-preview'
        --bind 'ctrl-a:select-all'
        --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
        --bind 'ctrl-e:execute(echo {+} | xargs -o vim)'
        --bind 'ctrl-v:execute(code {+})'
    "

    ## Use fd if available for better performance
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    ## Load FZF key bindings and completion
    if [[ "$IS_MACOS" == true ]]; then
        # macOS with Homebrew
        [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
        # Alternative Homebrew locations
        [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]] && source /usr/local/opt/fzf/shell/key-bindings.zsh
        [[ -f /usr/local/opt/fzf/shell/completion.zsh ]] && source /usr/local/opt/fzf/shell/completion.zsh
        [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
        [[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && source /opt/homebrew/opt/fzf/shell/completion.zsh
    else
        # Linux
        [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
        [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
        [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
    fi

    ## Custom FZF functions
    
    # Search and edit files
    fe() {
        local files
        IFS=$'\n' files=($(fzf --query="$1" --multi --select-1 --exit-0))
        [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
    }

    # Change directory
    fcd() {
        local dir
        dir=$(fd --type d --hidden --follow --exclude .git 2> /dev/null | fzf +m) && cd "$dir"
    }

    # Kill process
    fkill() {
        local pid
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
        if [ "x$pid" != "x" ]; then
            echo $pid | xargs kill -${1:-9}
        fi
    }

    # Git branch checkout
    fgco() {
        local branches branch
        branches=$(git branch --all | grep -v HEAD) &&
        branch=$(echo "$branches" |
                fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
        git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
    }

    # Search history
    fh() {
        print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
    }

    # Docker containers
    fdocker() {
        local cid
        cid=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')
        [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
    }
fi