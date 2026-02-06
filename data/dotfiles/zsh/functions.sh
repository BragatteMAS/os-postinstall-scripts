# zsh-specific functions

# mkcd - create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# extract - universal archive extractor
extract() {
    if [[ ! -f "$1" ]]; then
        echo "'$1' is not a valid file"
        return 1
    fi

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1" ;;
        *.rar)     unrar x "$1" ;;
        *)         echo "'$1' cannot be extracted" && return 1 ;;
    esac
}

# take - create directory and cd into it (alias for mkcd)
take() {
    mkcd "$@"
}

# up - go up N directories
up() {
    local d=""
    local n="${1:-1}"
    for ((i = 0; i < n; i++)); do
        d="../$d"
    done
    cd "$d" || return 1
}

# port - show what is running on a port
port() {
    lsof -i ":${1:-80}"
}

# tre - tree with sensible defaults
tre() {
    tree -aC -I '.git|node_modules|.venv|__pycache__' --dirsfirst "$@"
}
