#!/bin/zsh
# ==============================================================================
# Module: Advanced Functions
# Description: Utility functions for productivity and development
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ ADVANCED FUNCTIONS                                                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *.xz)        unxz "$1"       ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

## Create directory and cd into it
mkcd() {
    mkdir -p "$@" && cd "$_"
}

## Backup file with timestamp
backup() {
    if [[ -e "$1" ]]; then
        cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backup created: $1.backup.$(date +%Y%m%d_%H%M%S)"
    else
        echo "File not found: $1"
    fi
}

## Find and replace in files
replace() {
    if [[ $# -lt 3 ]]; then
        echo "Usage: replace <find> <replace> <file-pattern>"
        return 1
    fi
    
    local find_text="$1"
    local replace_text="$2"
    local file_pattern="$3"
    
    if command -v sd &> /dev/null; then
        fd "$file_pattern" -x sd "$find_text" "$replace_text" {}
    else
        find . -name "$file_pattern" -type f -exec sed -i '' "s/$find_text/$replace_text/g" {} +
    fi
}

## Show directory tree with limit
tre() {
    tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

## Calculator
calc() {
    echo "$*" | bc -l
}

## Weather
weather() {
    local location="${1:-}"
    curl -s "wttr.in/${location}?format=3"
}

## Quick HTTP server
serve() {
    local port="${1:-8000}"
    if command -v python3 &> /dev/null; then
        python3 -m http.server "$port"
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer "$port"
    else
        echo "Python not found"
    fi
}

## Show PATH entries
path() {
    echo -e ${PATH//:/\\n} | nl
}

## Get current IP addresses
myip() {
    echo "Local IP(s):"
    if [[ "$IS_MACOS" == true ]]; then
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    else
        ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
    fi
    echo ""
    echo "Public IP:"
    curl -s https://api.ipify.org
    echo ""
}

## Port usage
port() {
    if [[ -z "$1" ]]; then
        echo "Usage: port <port-number>"
        return 1
    fi
    
    if [[ "$IS_MACOS" == true ]]; then
        lsof -nP -i4TCP:"$1" | grep LISTEN
    else
        sudo lsof -i -P -n | grep ":$1"
    fi
}

## System information
sysinfo() {
    echo "System Information"
    echo "=================="
    echo "Hostname:     $(hostname)"
    echo "OS:           $(uname -s)"
    echo "Kernel:       $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU:          $(sysctl -n hw.ncpu 2>/dev/null || nproc) cores"
    echo "Memory:       $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
    echo "Disk:         $(df -h / | awk 'NR==2 {print $4 " free of " $2}')"
    echo "Uptime:       $(uptime | sed 's/.*up //' | sed 's/,.*//')"
}

## Quick note taking
note() {
    local note_dir="$HOME/notes"
    mkdir -p "$note_dir"
    
    if [[ $# -eq 0 ]]; then
        # List notes
        ls -la "$note_dir"
    else
        # Create/edit note
        local note_name="$1"
        local note_file="$note_dir/${note_name}.md"
        ${EDITOR:-vim} "$note_file"
    fi
}

## Search notes
notes() {
    local search_term="$1"
    if [[ -z "$search_term" ]]; then
        echo "Usage: notes <search-term>"
        return 1
    fi
    
    grep -r "$search_term" "$HOME/notes" 2>/dev/null | sed 's|.*/||' | sed 's|:| → |'
}