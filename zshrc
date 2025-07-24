#!/bin/zsh
# ==============================================================================
# .zshrc - Universal configuration for scientific research and development
# Compatible with macOS and Linux
# Author: Configuration for epidemiology, genomics and data science
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 1: OPERATING SYSTEM DETECTION                                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true    ## Running on macOS
    IS_LINUX=false
else
    IS_MACOS=false
    IS_LINUX=true    ## Running on Linux
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 2: DEPENDENCY VERIFICATION AND SUGGESTIONS                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
check_dependencies() {
    local missing_tools=()
    local optional_tools=()

    echo "🔍 Checking installed tools..."

    ## Essential tools check
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_tools+=("curl or wget")
    fi

    ## Optional but recommended tools
    local tools_to_check=(
        "fzf:interactive search"
        "eza:modern listing"
        "bat:file viewer with syntax"
        "fd:modern find"
        "rg:ripgrep for search"
        "delta:improved diff"
        "nu:nushell for data"
        "tokei:code statistics"
        "zoxide:smart navigation"
        "sd:modern sed replacement"
        "dust:disk usage analyzer"
        "procs:modern ps"
        "bottom:system monitor"
        "hyperfine:benchmarking tool"
        "lsd:ls alternative"
        "gitui:terminal git UI"
    )

    for tool_info in "${tools_to_check[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info#*:}"
        if ! command -v "$tool" &> /dev/null; then
            optional_tools+=("$tool ($desc)")
        fi
    done

    ## Show results
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "❌ ESSENTIAL tools missing:"
        printf "   - %s\n" "${missing_tools[@]}"
        echo ""
    fi

    if [[ ${#optional_tools[@]} -gt 0 ]]; then
        echo "⚠️  Optional tools not installed:"
        printf "   - %s\n" "${optional_tools[@]}"
        echo ""
        echo "💡 To install recommended tools:"

        if [[ "$IS_MACOS" == true ]]; then
            echo "   macOS (Homebrew):"
            echo "   brew install fzf eza bat fd ripgrep git-delta nushell tokei zoxide"
        else
            echo "   Ubuntu/Debian:"
            echo "   sudo apt install fzf bat fd-find ripgrep git-delta"
            echo "   cargo install eza nu tokei zoxide"
            echo ""
            echo "   Fedora/RHEL:"
            echo "   sudo dnf install fzf bat fd-find ripgrep git-delta"
            echo ""
            echo "   Arch:"
            echo "   sudo pacman -S fzf bat fd ripgrep git-delta nushell tokei zoxide"
        fi
        echo ""
    else
        echo "✅ All recommended tools are installed!"
    fi

    ## Check Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo ""
        echo "📦 Oh My Zsh is not installed!"
        echo "   To install:"
        echo "   sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    fi

    ## Check Conda/Mamba
    if ! command -v conda &> /dev/null; then
        echo ""
        echo "🐍 Conda/Miniconda not found!"
        echo "   To install Miniconda:"
        if [[ "$IS_MACOS" == true ]]; then
            echo "   brew install miniconda"
        else
            if [[ "$(uname -m)" == "arm64" ]] || [[ "$(uname -m)" == "aarch64" ]]; then
                echo "   curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
                echo "   bash Miniconda3-latest-Linux-aarch64.sh"
            else
                echo "   curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
                echo "   bash Miniconda3-latest-Linux-x86_64.sh"
            fi
        fi
    fi
}

## Run verification only on first run or when requested
if [[ ! -f "$HOME/.zshrc_checked" ]] || [[ "$1" == "--check" ]]; then
    check_dependencies
    touch "$HOME/.zshrc_checked"
    echo ""
    echo "💡 To check again: checktools"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 3: INITIAL CONFIGURATION AND PERFORMANCE                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
## Suppress ALL conda/mamba messages from the start
export CONDA_QUIET=true
export MAMBA_NO_BANNER=1
export CONDA_REPORT_ERRORS=false

## Enable Powerlevel10k instant prompt (must be at top for best performance)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 4: MAIN ENVIRONMENT VARIABLES                                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
export ZSH="$HOME/.oh-my-zsh"            ## Oh My Zsh path
export LANG=en_US.UTF-8                  ## UTF-8 encoding for special characters
export LC_ALL=en_US.UTF-8                ## Ensure UTF-8 in all operations
export EDITOR='vim'                      ## Default editor (change to helix if preferred)
export HELIX_RUNTIME=~/src/helix/runtime ## Helix editor runtime

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 5: OPERATING SYSTEM SPECIFIC CONFIGURATION                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if [[ "$IS_MACOS" == true ]]; then
    # ──────────────────────────────────────────────────────────────────────────
    # SECTION 5.1: MACOS CONFIGURATION
    # ──────────────────────────────────────────────────────────────────────────
    ## Homebrew initialization
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    export PATH="/opt/homebrew/bin:$PATH"
    export PATH="/opt/homebrew/sbin:$PATH"

    ## Homebrew Python path
    if [[ -d "/opt/homebrew/opt/python@3.12/bin" ]]; then
        export PATH="/opt/homebrew/opt/python@3.12/bin:$PATH"
    fi

    ## Use GNU sed on macOS
    if command -v gsed &> /dev/null; then
        alias sed='gsed'
    fi
else
    # ──────────────────────────────────────────────────────────────────────────
    # SECTION 5.2: LINUX CONFIGURATION
    # ──────────────────────────────────────────────────────────────────────────
    ## Common Linux paths
    export PATH="/usr/local/bin:$PATH"
    export PATH="$HOME/.local/bin:$PATH"

    ## Linuxbrew if installed
    if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

## Rust/Cargo tools (including uv) - for both macOS and Linux
if [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 6: OH MY ZSH CONFIGURATION                                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
## Theme (will be overridden by Powerlevel10k below)
# ZSH_THEME="robbyrussell"  ## Commented as we use Powerlevel10k

## Plugins - keeping minimal for performance
plugins=(
    git                   ## Essential git shortcuts
)

## Add plugins if installed
if [[ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]]; then
    plugins+=(zsh-autosuggestions)
fi

if [[ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]]; then
    plugins+=(zsh-syntax-highlighting)
fi

## Performance and behavior settings
DISABLE_UNTRACKED_FILES_DIRTY="true"     ## Better performance in large repos
COMPLETION_WAITING_DOTS="true"           ## Visual feedback during completions
HIST_STAMPS="yyyy-mm-dd"                 ## History date format

## Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 7: POWERLEVEL10K - ADVANCED THEME                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
## Detect Powerlevel10k installation
if [[ "$IS_MACOS" == true ]]; then
    P10K_PATH="/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme"
else
    P10K_PATH="/usr/share/powerlevel10k/powerlevel10k.zsh-theme"
fi

if [[ -f "$P10K_PATH" ]]; then
    source "$P10K_PATH"
elif [[ -f "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"
fi

ZSH_THEME="powerlevel10k/powerlevel10k"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 8: FZF - FUZZY FINDER CONFIGURATION                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
## Advanced fzf configuration for maximum productivity
if command -v fzf &> /dev/null; then
    if [[ "$IS_MACOS" == true ]]; then
        source <(fzf --zsh)
    else
        ## Linux may have in different locations
        if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
            source /usr/share/fzf/key-bindings.zsh
        fi
        if [[ -f /usr/share/fzf/completion.zsh ]]; then
            source /usr/share/fzf/completion.zsh
        fi
    fi

    export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --preview-window=right:50%"

    ## Use fd if available, otherwise use find
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}'"
    else
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*"'
        export FZF_ALT_C_OPTS="--preview 'ls -la {}'"
    fi

    ## Preview with bat if available
    if command -v bat &> /dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}'"
    else
        export FZF_CTRL_T_OPTS="--preview 'cat {}'"
    fi
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 9: RUST TOOLS CONFIGURATION                                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
export BAT_THEME="gruvbox-dark"          ## Theme for bat
# export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"  ## Commented - file doesn't exist

## Enhanced cd function with fzf
## Usage: cd [directory] or just cd for interactive selection
fzf_cd() {
    if [[ -n "$1" ]]; then
        builtin cd "$1"
    else
        if command -v fd &> /dev/null && command -v fzf &> /dev/null && command -v eza &> /dev/null; then
            local dir
            dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}') && builtin cd "$dir"
        else
            builtin cd
        fi
    fi
}
## Override cd with our enhanced version
alias cd='fzf_cd'

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 10: HELP AND DOCUMENTATION SYSTEM                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Compact essential list
hal() {
    echo "📋 Essential Commands"
    echo "======================"
    echo ""
    echo "🔍 NAVIGATION (3):"
    echo "  ll    → Detailed list          ltl   → Tree 3 levels"
    echo "  fp    → Preview files (fzf)"
    echo ""
    echo "📊 DATA (3):"
    echo "  nuo   → Table (nushell)        quick_csv → CSV analysis"
    echo "  rgf   → Interactive search"
    echo ""
    echo "🚀 SHORTCUTS (4):"
    echo "  c     → Clear                  z     → Jump (zoxide)"
    echo "  a     → Search alias           pstats → Project stats"
    echo ""
    echo "💻 GIT (2):"
    echo "  gs    → Status                 glog  → Visual log"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    ## Show top 5 most used commands
    if [[ -f "$HOME/.zsh_command_stats" ]]; then
        echo "🔥 TOP 5 MOST USED (last 7 days):"
        cat "$HOME/.zsh_command_stats" | \
        cut -d' ' -f2 | \
        sort | uniq -c | \
        sort -rn | head -5 | \
        awk '{printf "  %d. %-10s (%d times)\n", NR, $2, $1}'
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Type 'halp' for complete help | 'h' to see this again"
}

## Main functions list
hfun() {
    echo "🔧 Main Functions:"
    echo "======================"
    echo ""
    echo "📁 PROJECTS:"
    echo "  init_project name      → Create project structure"
    echo "  create_sci_env name    → Create scientific environment"
    echo "  pstats                 → Project statistics"
    echo ""
    echo "📊 ANALYSIS:"
    echo "  quick_csv file         → Quick CSV analysis"
    echo "  nu_compare a.csv b.csv → Compare datasets"
    echo "  data_explorer          → Interactive explorer"
    echo ""
    echo "🔍 SEARCH:"
    echo "  code_search 'term'     → Search in code"
    echo "  cmd term               → Search commands"
    echo "  rg_fzf                 → Search with preview"
    echo ""
    echo "💾 MAINTENANCE:"
    echo "  backup_notebooks       → Backup notebooks"
    echo "  clean_notebooks        → Clean outputs"
    echo "  bench 'command'        → Benchmark"
}

## Helper function for formatting alias output
format_alias_output() {
    if command -v sd &> /dev/null; then
        # Use sd (Rust tool) syntax
        while read -r line; do
            echo "  $line"
        done
    else
        # Fallback to sed
        sed 's/^/  /'
    fi
}

## Complete help system
halp() {
    local category="$1"

    case "$category" in
        "")
            echo "📚 Complete Help System"
            echo "============================"
            echo ""
            echo "QUICK COMMANDS:"
            echo "  hal     → View alias list"
            echo "  hfun    → View function list"
            echo "  hcheat  → Compact cheatsheet"
            echo ""
            echo "HELP BY CATEGORY:"
            echo "  halp ls        → Listing commands"
            echo "  halp data      → Data analysis"
            echo "  halp git       → Git commands"
            echo "  halp search    → Search and navigation"
            echo ""
            echo "SEARCH:"
            echo "  cmd term       → Search specific command"
            echo ""
            echo "VIEW ALL:"
            echo "  alias          → List all aliases"
            ;;

        "ls"|"list")
            echo "📁 Listing Commands:"
            alias | rg "^(l[a-zA-Z]*|ls|ll|la|lt|lk|lm|lsd|lsf)=" | format_alias_output
            ;;

        "data")
            echo "📊 Data Commands:"
            alias | rg "(nu[a-zA-Z]*|data|csv|explore)=" | format_alias_output
            ;;

        "git")
            echo "🌿 Git Commands:"
            alias | rg "^g[a-zA-Z]*=" | format_alias_output
            ;;

        "search")
            echo "🔍 Search and Navigation:"
            alias | rg "(find|grep|search|rgf|fp|z|code_search)=" | format_alias_output
            ;;

        *)
            echo "❓ Use 'halp' without arguments for options"
            ;;
    esac
}

## Super compact cheatsheet
hcheat() {
    echo "⚡ QUICK CHEATSHEET:"
    echo "===================="
    echo "LIST: ls, ll, la, lt, lk(size), lm(date)"
    echo "DATA: nuo(table), nuc(stats), quick_csv, explore"
    echo "GIT:  gs(status), glog, gdiff"
    echo "FIND: rgf, fp(preview), z(jump)"
    echo "PROJ: init_project, pstats, create_sci_env"
}

## Main shortcut - avoids conflict with -h
h() {
    hal
}

## Function to search commands
cmd() {
    local search="$1"
    if [[ -z "$search" ]]; then
        echo "Usage: cmd <term>"
        echo "Example: cmd csv"
        return 1
    fi

    echo "🔍 Searching '$search':"
    echo "====================="
    echo "Aliases:"
    alias | rg -i "$search" | format_alias_output || echo "  None found"
    echo ""
    echo "Functions:"
    print -l ${(ok)functions} | rg -i "$search" | format_alias_output || echo "  None found"
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 11: ALIASES - ORGANIZED BY CATEGORY                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.1: Navigation and Listing
# ──────────────────────────────────────────────────────────────────────────────
## Check if eza is installed
if command -v eza &> /dev/null; then
    ## Note: cd is handled by fzf_cd function, not aliased
    alias ls='eza --icons --group-directories-first --color=always'             ## Modern ls with icons
    alias ll='eza -lah --icons --group-directories-first --color=always --git'  ## Detailed list with Git
    alias la='eza -a --icons --group-directories-first --color=always'          ## Show hidden files
    alias lt='eza --tree --level=2 --icons --color=always'                      ## Directory tree
    alias ltl='eza --tree --level=3 --icons --color=always -la'                 ## Detailed tree
    alias lk='eza -lah --icons --sort=size --reverse --color=always'            ## Sort by size
    alias lm='eza -lah --icons --sort=modified --reverse --color=always'        ## Sort by modification
    alias lsd='eza -D --icons --color=always'                                   ## Directories only
    alias lsf='eza -f --icons --color=always'                                   ## Files only
elif command -v lsd &> /dev/null; then
    ## Fallback to lsd (another modern ls replacement)
    alias ls='lsd --group-directories-first'
    alias ll='lsd -lah --group-directories-first'
    alias la='lsd -a --group-directories-first'
    alias lt='lsd --tree --depth 2'
    alias ltl='lsd --tree --depth 3 -la'
    alias lk='lsd -lah --sort size --reverse'
    alias lm='lsd -lah --sort time --reverse'
    alias lsd='lsd -d */'  ## Directories only
    alias lsf='lsd -f'     ## Files only
else
    ## Fallback to traditional ls
    alias ll='ls -lah'                           ## Detailed list
    alias la='ls -A'                             ## Show hidden
    alias lt='tree -L 2' 2>/dev/null || alias lt='find . -maxdepth 2 -type d'
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.2: Data Science Aliases
# ──────────────────────────────────────────────────────────────────────────────
if command -v eza &> /dev/null; then
    alias lpy='eza -lah --icons --color=always | rg "\.(py|ipynb)$"'       ## Python files
    alias lr='eza -lah --icons --color=always | rg "\.(R|Rmd|r)$"'         ## R files
    alias ldata='eza -lah --icons --sort=size --reverse | rg "\.(csv|xlsx|json|parquet|feather|tsv|h5|hdf5)$"'  ## Data files
else
    alias lpy='ls -lah | rg "\.(py|ipynb)$"'
    alias lr='ls -lah | rg "\.(R|Rmd|r)$"'
    alias ldata='ls -lah | rg "\.(csv|xlsx|json|parquet|feather|tsv|h5|hdf5)$"'
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.3: Modern Rust Tools (if installed)
# ──────────────────────────────────────────────────────────────────────────────
command -v bat &> /dev/null && alias cat='bat --style=plain' || alias cat='cat'
command -v bat &> /dev/null && alias catp='bat --style=full'
command -v fd &> /dev/null && alias find='fd' || alias find='find'
## Note: We use rg directly instead of aliasing grep
command -v procs &> /dev/null && alias ps='procs' && alias pst='procs --tree'
command -v dust &> /dev/null && alias du='dust' || alias du='du -h'
command -v sd &> /dev/null && alias sdr='sd'  ## sdr for "sed replacement" - different syntax!
command -v delta &> /dev/null && alias diff='delta' || alias diff='diff --color=auto'
command -v bottom &> /dev/null && alias top='bottom' && alias htop='bottom'
command -v btm &> /dev/null && alias btm='btm --basic'  ## Simpler bottom interface

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.4: Terminal Utilities
# ──────────────────────────────────────────────────────────────────────────────
alias c='clear'                          ## Clear screen
alias cl='clear && ls'                   ## Clear and list files

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.5: Data Processing
# ──────────────────────────────────────────────────────────────────────────────
alias cutt="cut -d' '"  ## Cut with space delimiter

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.6: Conda/Mamba Management
# ──────────────────────────────────────────────────────────────────────────────
alias condaon='conda config --set auto_activate_base True'   ## Auto-activate base
alias condaoff='conda config --set auto_activate_base False' ## Disable auto-activate
alias baseoff='conda deactivate'                            ## Deactivate environment
alias base='conda activate base'                             ## Activate base environment

## Personal conda environments - add your own below
## HERE: Add your custom conda environments
alias mon='conda activate mon'                               ## Monitoring environment
alias saved='conda activate saved'                           ## Saved project environment

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.7: Development and Git
# ──────────────────────────────────────────────────────────────────────────────
alias gs='git status -sb'                        ## Git status summary
alias glog='git log --oneline --graph --decorate --all'  ## Visual Git log
command -v delta &> /dev/null && alias gdiff='git diff | delta' || alias gdiff='git diff --color=always'
alias sm='snakemake'                             ## Snakemake shortcut

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.8: Package Manager
# ──────────────────────────────────────────────────────────────────────────────
if [[ "$IS_MACOS" == true ]]; then
    alias bum="brew update && brew upgrade && brew cleanup && brew doctor 2>&1 | rg -v 'Please note' && echo '✅ Homebrew updated!'"
    alias brewdeps='brew deps --tree --installed'   ## View dependencies
else
    ## Detect package manager on Linux
    if command -v apt &> /dev/null; then
        alias bum="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && echo '✅ System updated!'"
    elif command -v yum &> /dev/null; then
        alias bum="sudo yum update -y && echo '✅ System updated!'"
    elif command -v pacman &> /dev/null; then
        alias bum="sudo pacman -Syu && echo '✅ System updated!'"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.9: Scientific Productivity
# ──────────────────────────────────────────────────────────────────────────────
alias jl='jupyter lab'                           ## Launch Jupyter Lab
alias jn='jupyter notebook'                      ## Launch Jupyter Notebook
alias ipy='ipython'                              ## Interactive Python shell
alias R='R --quiet'                              ## R without startup messages

## Python package management - prefer uv over pip
if command -v uv &> /dev/null; then
    ## Core uv aliases
    alias pip='uv pip'                           ## Use uv for pip operations
    alias pipi='uv pip install'                  ## Quick install
    alias pipu='uv pip install --upgrade'        ## Quick upgrade
    alias pipr='uv pip install -r requirements.txt'  ## Install from requirements
    alias venv='uv venv'                         ## Create virtual environment with uv
    alias sync='uv pip sync requirements.txt'    ## Sync dependencies

    ## Additional uv commands
    alias uvup='uv self update'                  ## Update uv itself
    alias uvlock='uv pip compile requirements.in -o requirements.txt'  ## Generate locked requirements
    alias uvsync='uv pip sync'                   ## Sync without specifying file
    alias uvtree='uv pip tree'                   ## Show dependency tree
    alias uvfreeze='uv pip freeze'               ## List installed packages

    ## Python project management with uv
    alias pyinit='uv venv && source .venv/bin/activate && uv pip install -e .'  ## Initialize Python project
    alias pydev='uv pip install -e ".[dev]"'    ## Install dev dependencies
    alias pytest='uv run pytest'                 ## Run pytest with uv
    alias pyruff='uv run ruff check .'          ## Run ruff linter
    alias pyformat='uv run ruff format .'       ## Format code with ruff

    ## Function to create Python project with uv
    uv_init_project() {
        local project_name="${1:-my_project}"
        echo "🐍 Creating Python project with uv: $project_name"

        mkdir -p "$project_name"
        cd "$project_name"

        ## Create virtual environment
        uv venv

        ## Create pyproject.toml
        cat > pyproject.toml << 'EOF'
[project]
name = "PROJECT_NAME"
version = "0.1.0"
description = "A Python project"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "ruff>=0.1.0",
    "mypy>=1.0",
    "ipython>=8.0",
]

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
EOF

        ## Replace PROJECT_NAME
        if command -v sd &> /dev/null; then
            sd "PROJECT_NAME" "$project_name" pyproject.toml
        else
            sed -i.bak "s/PROJECT_NAME/$project_name/g" pyproject.toml && rm pyproject.toml.bak
        fi

        ## Create source directory
        mkdir -p "src/$project_name"
        echo "# $project_name" > "src/$project_name/__init__.py"

        ## Create .gitignore
        cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.venv/
venv/
ENV/
env/

# Distribution
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Testing
.tox/
.coverage
.coverage.*
.cache
.pytest_cache/
htmlcov/

# IDE
.idea/
.vscode/
*.swp
*.swo
.DS_Store

# MyPy
.mypy_cache/
.dmypy.json
dmypy.json
EOF

        echo "✅ Project created! Next steps:"
        echo "1. Activate environment: source .venv/bin/activate"
        echo "2. Install dev dependencies: uv pip install -e '.[dev]'"
        echo "3. Start coding in src/$project_name/"
    }
    alias pyproject='uv_init_project'

else
    alias pipi='pip install'                     ## Fallback to regular pip
    alias pipu='pip install --upgrade'
    alias pipr='pip install -r requirements.txt'

    ## Suggest uv installation
    alias pip='echo "💡 Install uv for 10-100x faster pip operations: curl -LsSf https://astral.sh/uv/install.sh | sh" && pip'
fi

## Python aliases - ensure python3 is used
if ! command -v python &> /dev/null && command -v python3 &> /dev/null; then
    alias python='python3'
    alias pip='pip3'
fi
alias py='python'                                ## Quick Python alias

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 11.10: Nushell for Data Analysis (if installed)
# ──────────────────────────────────────────────────────────────────────────────
if command -v nu &> /dev/null; then
    alias nuo='nu_open'                              ## View file as table in Nu
    alias nuc='nu_csv'                               ## CSV statistics with Nu
    alias nuq='nu_query'                             ## SQL-like queries on files
    alias nus='nu'                                   ## Interactive Nushell
    alias nustats='nu_project_stats'                 ## Advanced project statistics
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 12: ADVANCED FUNCTIONS FOR RESEARCH                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Função para criar ambiente conda/mamba para projetos
create_sci_env() {
    local env_name=${1:-"sci_env"}
    local python_version=${2:-"3.11"}

    echo "🔬 Criando ambiente científico: $env_name com Python $python_version"

    ## Check for faster alternatives
    if command -v pixi &> /dev/null; then
        echo "📦 Using pixi (fastest option)..."
        pixi init "$env_name"
        cd "$env_name"
        pixi add python="$python_version" numpy pandas scipy matplotlib seaborn jupyterlab scikit-learn plotly dash ipywidgets
    elif command -v mamba &> /dev/null; then
        echo "📦 Using mamba..."
        mamba create -n "$env_name" python="$python_version" \
            numpy pandas scipy matplotlib seaborn jupyterlab \
            scikit-learn plotly dash ipywidgets -y
    else
        echo "📦 Using conda..."
        conda create -n "$env_name" python="$python_version" \
            numpy pandas scipy matplotlib seaborn jupyterlab \
            scikit-learn plotly dash ipywidgets -y
    fi

    echo "✅ Ambiente criado! Ative com: conda activate $env_name"

    ## If uv is available, suggest using it for additional packages
    if command -v uv &> /dev/null; then
        echo "💡 Tip: Use 'uv pip install' for faster package installation"
    fi
}

## Função para análise rápida de CSV
quick_csv() {
    if [[ -z "$1" ]]; then
        echo "Uso: quick_csv arquivo.csv"
        return 1
    fi

    echo "📊 Análise rápida de $1:"
    echo "Linhas: $(wc -l < "$1")"
    echo "Colunas: $(head -1 "$1" | tr ',' '\n' | wc -l)"
    echo -e "\n📋 Primeiras 5 linhas:"
    head -5 "$1" | column -t -s','
    echo -e "\n📋 Headers:"
    head -1 "$1" | tr ',' '\n' | nl
}

## Função para buscar em arquivos de código
code_search() {
    local pattern="$1"
    local file_type="${2:-*}"

    echo "🔍 Buscando '$pattern' em arquivos $file_type:"
    ## Always use rg since it's a required tool
    rg --type "$file_type" "$pattern" --stats
}

## Busca interativa com ripgrep + fzf
if command -v rg &> /dev/null && command -v fzf &> /dev/null; then
    rg_fzf() {
        local pattern="${1:-.}"
        if command -v bat &> /dev/null; then
            rg --line-number --no-heading --color=always "$pattern" | \
            fzf --ansi --preview 'bat --style=numbers --color=always --highlight-line {1} {1} 2>/dev/null || cat {1}' \
                --preview-window 'right:50%:+{2}+3/2'
        else
            rg --line-number --no-heading --color=always "$pattern" | fzf --ansi
        fi
    }
    alias rgf='rg_fzf'                       ## Busca interativa em código
fi

## Função para criar estrutura de projeto científico
init_project() {
    local project_name=${1:-"new_project"}

    echo "🚀 Criando projeto: $project_name"
    mkdir -p "$project_name"/{data/{raw,processed,external},notebooks,src,results/{figures,tables},docs}

    # Cria README.md
    cat > "$project_name/README.md" << EOF
# $project_name

## Estrutura do Projeto
- \`data/\`: Dados do projeto
  - \`raw/\`: Dados brutos (não modificar)
  - \`processed/\`: Dados processados
  - \`external/\`: Dados externos
- \`notebooks/\`: Jupyter notebooks
- \`src/\`: Código fonte
- \`results/\`: Resultados
  - \`figures/\`: Gráficos e visualizações
  - \`tables/\`: Tabelas
- \`docs/\`: Documentação

## Como usar
1. Ative o ambiente: \`conda activate sci_env\`
2. Instale dependências: \`pip install -r requirements.txt\`

## Autores
- $(git config user.name || echo "Seu Nome")

## Data de criação
$(date +%Y-%m-%d)
EOF

    # Cria .gitignore
    cat > "$project_name/.gitignore" << EOF
# Data
data/raw/*
data/processed/*
!data/raw/.gitkeep
!data/processed/.gitkeep

# Python
__pycache__/
*.py[cod]
*$py.class
.ipynb_checkpoints/
*.ipynb_checkpoints

# Environment
.env
venv/
env/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Results
results/figures/*
results/tables/*
!results/figures/.gitkeep
!results/tables/.gitkeep
EOF

    # Cria arquivos .gitkeep
    touch "$project_name"/data/{raw,processed,external}/.gitkeep
    touch "$project_name"/results/{figures,tables}/.gitkeep

    echo "✅ Projeto $project_name criado com sucesso!"
    cd "$project_name"
}

## Estatísticas do projeto
project_stats() {
    echo "📊 Estatísticas do Projeto:"
    echo "=========================="

    # Verifica ferramentas disponíveis
    if command -v tokei &> /dev/null; then
        tokei
    elif command -v cloc &> /dev/null; then
        cloc .
    else
        echo "📁 Contando arquivos manualmente..."
        if command -v fd &> /dev/null; then
            echo "Python: $(fd -e py | wc -l) arquivos"
            echo "R: $(fd -e R -e Rmd | wc -l) arquivos"
            echo "Notebooks: $(fd -e ipynb | wc -l) arquivos"
        else
            echo "Python: $(find . -name "*.py" | wc -l) arquivos"
            echo "R: $(find . -name "*.R" -o -name "*.Rmd" | wc -l) arquivos"
            echo "Notebooks: $(find . -name "*.ipynb" | wc -l) arquivos"
        fi
    fi

    echo -e "\n📁 Maiores arquivos:"
    if command -v fd &> /dev/null; then
        fd -t f -x ls -lh {} | sort -k5 -hr | head -10
    else
        find . -type f -exec ls -lh {} \; | sort -k5 -hr | head -10
    fi

    echo -e "\n🔍 TODOs/FIXMEs:"
    ## Always use rg for better performance
    rg "TODO|FIXME" --count-matches 2>/dev/null | sort -nr || echo "Nenhum TODO/FIXME encontrado"
}
alias pstats='project_stats'

## Benchmark de scripts
bench() {
    if [[ -z "$1" ]]; then
        echo "Uso: bench 'comando'"
        return 1
    fi

    if command -v hyperfine &> /dev/null; then
        hyperfine --warmup 3 "$@"
    else
        echo "⚠️  hyperfine não instalado. Usando time..."
        time "$@"
    fi
}

## Preview de arquivos com bat e fzf
if command -v fd &> /dev/null && command -v fzf &> /dev/null; then
    fzf_preview() {
        if command -v bat &> /dev/null; then
            fd --type f | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}'
        else
            fd --type f | fzf --preview 'cat {}'
        fi
    }
    alias fp='fzf_preview'
fi

## Função para backup rápido de notebooks
backup_notebooks() {
    local backup_dir="notebooks_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    echo "💾 Fazendo backup de notebooks..."
    find . -name "*.ipynb" -not -path "*/\.*" -exec cp {} "$backup_dir/" \;

    local count=$(ls -1 "$backup_dir"/*.ipynb 2>/dev/null | wc -l)
    echo "✅ $count notebooks salvos em $backup_dir"
}

## Função para limpar outputs de notebooks
clean_notebooks() {
    echo "🧹 Limpando outputs dos notebooks..."
    if command -v jupyter &> /dev/null; then
        find . -name "*.ipynb" -exec jupyter nbconvert --clear-output --inplace {} \;
        echo "✅ Notebooks limpos!"
    else
        echo "⚠️  Jupyter não instalado"
    fi
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 13: ZOXIDE - SMART CD                                             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias z='__zoxide_z'      ## Use the actual zoxide function
    alias zi='__zoxide_zi'    ## Interactive selection with fzf
    alias zq='zoxide query'   ## Query zoxide database
    alias za='zoxide add'     ## Manually add directory
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 14: NUSHELL - DATA ANALYSIS INTEGRATION                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if command -v nu &> /dev/null; then
    ## Função para abrir arquivos de dados no Nushell com tabela formatada
    nu_open() {
        if [[ -z "$1" ]]; then
            echo "Uso: nu_open arquivo.csv"
            return 1
        fi
        nu -c "open '$1' | table -e"
    }

    ## Análise estatística rápida de CSV
    nu_csv() {
        if [[ -z "$1" ]]; then
            echo "Uso: nu_csv arquivo.csv"
            return 1
        fi

        ## Use simpler nushell syntax to avoid parsing issues
        nu -c "open '$1' | describe"
    }

    ## Query SQL-like em arquivos de dados
    nu_query() {
        local file="$1"
        local query="$2"

        if [[ -z "$file" ]] || [[ -z "$query" ]]; then
            echo "Uso: nu_query arquivo.csv 'where coluna > 100 | sort-by valor'"
            return 1
        fi

        nu -c "open '$file' | $query | table -e"
    }

    ## Estatísticas avançadas do projeto usando Nushell
    nu_project_stats() {
        nu -c '
            print "📊 Estatísticas do Projeto (Nushell)"
            print "===================================="

            print "📁 Arquivos por extensão:"
            ls **/* | where type == "file" |
            group-by { |it| $it.name | path parse | get extension } |
            transpose extension count |
            update count { |it| $it.count | length } |
            sort-by count -r |
            first 10 |
            table
        '
    }

    ## Explorador interativo de dados
    data_explorer() {
        local file="${1:-.}"

        echo "📊 Abrindo explorador de dados..."
        echo "💡 Dica: Use 'q' ou 'Ctrl+C' para sair"
        echo ""

        if [[ -f "$file" ]]; then
            nu -c "open '$file' | explore"
        else
            nu -c "ls '$file' | where type == 'file' and name =~ '\\.(csv|json|xlsx|parquet)$' | explore"
        fi
    }
    alias explore='data_explorer'             ## Explora dados interativamente

    ## Comparar CSVs lado a lado
    nu_compare() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Uso: nu_compare arquivo1.csv arquivo2.csv"
            return 1
        fi

        echo "📊 Comparando arquivos:"
        echo "Arquivo 1: $1"
        echo "Arquivo 2: $2"
        echo ""
        nu -c "open '$1' | table -e"
        echo ""
        echo "---"
        echo ""
        nu -c "open '$2' | table -e"
    }
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 15: MINIMALIST ALIAS SEARCH SYSTEM                                ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Busca simples e direta
a() {
    if [[ -z "$1" ]]; then
        # Sem argumento - mostra ajuda rápida
        echo "📋 Uso: a <termo>"
        echo "Exemplos:"
        echo "  a ls    → comandos de listagem"
        echo "  a git   → comandos git"
        echo "  a csv   → comandos para CSV"
        echo "  a py    → comandos Python"
        echo ""
        echo "💡 Dica: af para busca interativa"
    else
        # Com argumento - busca
        local count=$(alias | rg -ci "$1")
        if [[ $count -eq 0 ]]; then
            echo "❌ Nenhum alias com '$1'"
        else
            echo "🔍 $count aliases com '$1':"
            echo ""
            alias | rg -i "$1" | sort | while IFS='=' read -r name cmd; do
                # Formata saída
                printf "  %-15s → %s\n" "$name" "${cmd:0:60}..."
            done
        fi
    fi
}

## Busca interativa com fzf (mais poderosa)
if command -v fzf &> /dev/null; then
    alias af='alias | fzf --preview "echo {} | cut -d= -f2-" --preview-window=down:3:wrap'
fi

## Lista rápida por categoria
ac() {
    case "$1" in
        "nav"|"ls")
            echo "🔍 Navegação:"
            alias | rg "^(ls|ll|la|lt|lk|lm|cd|z)=" | format_alias_output
            ;;
        "git")
            echo "🌿 Git:"
            alias | rg "^g[a-zA-Z]*=" | format_alias_output
            ;;
        "py"|"python")
            echo "🐍 Python/Conda:"
            alias | rg "(py|conda|base|jl|jn|uv|pip)" | format_alias_output
            ;;
        "data")
            echo "📊 Dados:"
            alias | rg "(csv|data|nu)" | format_alias_output
            ;;
        "rust")
            echo "🦀 Rust Tools:"
            alias | rg "(bat|catp|fd|rg|rgf|fp|delta|dust|sdr|procs|pst|bottom|btm|htop|lsd|gitui|tokei|hyperfine|z|zi|zq|za)" | format_alias_output
            ;;
        *)
            echo "📋 Categorias: nav | git | py | data | rust"
            ;;
    esac
}

## Mostra apenas nomes dos aliases (super minimalista)
an() {
    echo "📋 Todos os aliases:"
    alias | cut -d'=' -f1 | sort | column
}

## Adiciona ao sistema de ajuda existente
alias ahelp='echo "🔍 Busca de Aliases:"; echo "  a termo → buscar"; echo "  af → interativo"; echo "  ac cat → por categoria"; echo "  an → só nomes"'

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 16: CONDA INITIALIZATION                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
## Detecta instalação do conda/miniconda
CONDA_PATH=""
if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
    CONDA_PATH="$HOME/miniconda3"
elif [[ -f "$HOME/anaconda3/bin/conda" ]]; then
    CONDA_PATH="$HOME/anaconda3"
elif [[ -f "/opt/conda/bin/conda" ]]; then
    CONDA_PATH="/opt/conda"
elif [[ -f "/usr/local/conda/bin/conda" ]]; then
    CONDA_PATH="/usr/local/conda"
fi

if [[ -n "$CONDA_PATH" ]]; then
    ## Silencia mensagens do conda/mamba
    __conda_setup="$("$CONDA_PATH/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup" &>/dev/null
    else
        if [ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]; then
            . "$CONDA_PATH/etc/profile.d/conda.sh" &>/dev/null
        else
            export PATH="$CONDA_PATH/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 17: MAMBA INITIALIZATION                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if [[ -n "$CONDA_PATH" ]] && [[ -f "$CONDA_PATH/bin/mamba" ]]; then
    export MAMBA_EXE="$CONDA_PATH/bin/mamba"
    export MAMBA_ROOT_PREFIX="$CONDA_PATH"

    ## Silencia output do mamba completamente
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup" &>/dev/null 2>&1
    fi
    unset __mamba_setup

    ## Alias mamba silencioso
    alias mamba="$MAMBA_EXE 2>/dev/null"
    alias micromamba="$MAMBA_EXE 2>/dev/null"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 18: JULIAUP INITIALIZATION                                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if [[ -d "$HOME/.juliaup/bin" ]]; then
    path=("$HOME/.juliaup/bin" $path)
    export PATH
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 19: LOCAL ENVIRONMENT                                             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if [ -f "$HOME/.local/bin/env" ]; then
  . "$HOME/.local/bin/env"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 20: WINDSURF PATH (macOS)                                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
if [[ "$IS_MACOS" == true ]] && [[ -d "$HOME/.codeium/windsurf/bin" ]]; then
    export PATH="$HOME/.codeium/windsurf/bin:$PATH"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 21: FINAL CONFIGURATIONS                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
## Desativa auto-ativação do conda base e suprime mensagens
if command -v conda &> /dev/null; then
    {
        conda config --set auto_activate_base false
        conda config --set notify_outdated_conda false
        conda config --set report_errors false
        conda config --set verbosity 0
    } &>/dev/null 2>&1 || true
fi

## CONFIGURAÇÃO PARA MOSTRAR "base" EM VEZ DE "miniconda3"
export CONDA_PROMPT_MODIFIER="(base) "
export POWERLEVEL9K_ANACONDA_CONTENT_EXPANSION='${CONDA_DEFAULT_ENV}'
export POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION=false

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 21.1: Command Tracking System
# ──────────────────────────────────────────────────────────────────────────────
## Track command usage for statistics
track_command() {
    local cmd="$1"
    local stats_file="$HOME/.zsh_command_stats"

    ## Add current command with timestamp
    echo "$(date +%s) $cmd" >> "$stats_file"

    ## Keep only last 7 days of data
    if [[ -f "$stats_file" ]]; then
        local temp_file="$stats_file.tmp"
        local cutoff_date

        ## Calculate cutoff date (7 days ago)
        if [[ "$IS_MACOS" == true ]]; then
            cutoff_date=$(date -v-7d +%s)
        else
            cutoff_date=$(date -d "7 days ago" +%s)
        fi

        ## Filter old entries
        touch "$temp_file"
        while IFS=' ' read -r timestamp command; do
            # Validate timestamp is a number
            if [[ -n "$timestamp" ]] && [[ "$timestamp" =~ ^[0-9]+$ ]]; then
                # Use arithmetic comparison
                if (( timestamp >= cutoff_date )); then
                    echo "$timestamp $command" >> "$temp_file"
                fi
            fi
        done < "$stats_file"

        mv "$temp_file" "$stats_file"
    fi
}

## Hook into precmd to track commands
precmd_track_commands() {
    local last_cmd=$(fc -ln -1 2>/dev/null)
    ## Trim leading/trailing whitespace using zsh parameter expansion
    last_cmd="${last_cmd#"${last_cmd%%[![:space:]]*}"}"
    last_cmd="${last_cmd%"${last_cmd##*[![:space:]]}"}"

    ## Only track if command is not empty and not a duplicate
    if [[ -n "$last_cmd" ]] && [[ "$last_cmd" != "$LAST_TRACKED_CMD" ]]; then
        ## Extract just the command name (first word)
        local cmd_name="${last_cmd%% *}"

        ## Track specific commands we're interested in
        case "$cmd_name" in
            ll|ltl|fp|rgf|c|z|a|pstats|gs|glog|quick_csv)
                track_command "$cmd_name"
                ;;
        esac

        export LAST_TRACKED_CMD="$last_cmd"
    fi
}

## Add to precmd hooks
precmd_functions+=(precmd_track_commands)

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 21.2: Welcome Message
# ──────────────────────────────────────────────────────────────────────────────
## Show welcome message
show_welcome() {
    local current_time=$(date +%H:%M)
    local current_dir=$(basename "$PWD")
    local git_branch=""

    ## Get git branch if in a git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_branch=" | 🌿 $(git branch --show-current 2>/dev/null || echo 'detached')"
    fi

    echo ""
    echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo "┃ 🚀 $current_time | 📁 $current_dir$git_branch"
    echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""
    echo "🎯 QUICK ACCESS:"
    echo "├─ 📋 Help:     h (essential) | halp [category] | hfun (functions) | zdoc (docs)"
    echo "├─ 🔍 Search:   a <term> (aliases) | cmd <term> (commands) | rgf (files) | fp (preview)"
    echo "├─ 📊 Data:     quick_csv | nu_open | explore | pstats (project stats)"
    echo "├─ 🚀 Project:  init_project | create_sci_env | backup_configs | qm (quick menu)"
    echo "├─ 🤖 Claude:   cc (claude-code) | ci (claude-init) | cs (claude-status)"
    echo "└─ 💻 System:   bum (update) | checktools | shell_benchmark | c (clear)"
    echo ""
    echo "🦀 RUST TOOLS: bat (cat) | fd (find) | rg (grep) | eza (ls) | delta (diff) | z (cd)"
    echo ""

    ## Show conda environment if active
    if [[ -n "$CONDA_DEFAULT_ENV" ]] && [[ "$CONDA_DEFAULT_ENV" != "base" ]]; then
        echo "🐍 Active environment: $CONDA_DEFAULT_ENV"
        echo ""
    fi

    ## Show if new functions are available
    if [[ -f "$HOME/.env.local" ]]; then
        echo "🔐 Secure environment loaded (.env.local)"
    fi

    echo "💡 Type 'halp' for categories | 'ac rust' for Rust tools | 'qm' for menu"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

## Call welcome message (disabled for non-interactive shells)
[[ $- == *i* ]] && [[ ! "$ZSH_EXECUTION_STRING" ]] && show_welcome

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 21.3: Tool Check Function
# ──────────────────────────────────────────────────────────────────────────────
## Compact welcome message
show_welcome_compact() {
    local git_info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_info=" | 🌿 $(git branch --show-current 2>/dev/null || echo 'detached')"
    fi

    echo "🚀 $(date +%H:%M) | 📁 $(basename "$PWD")$git_info"
    echo "💡 h→help | halp→full help | a→search | qm→menu | zdoc→docs | c→clear"
}

## Function to check tools anytime
alias checktools='source ~/.zshrc --check'
alias welcome='show_welcome'
alias welcomec='show_welcome_compact'

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 22: ADVANCED ENHANCEMENTS                                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.1: Universal Package Manager
# ──────────────────────────────────────────────────────────────────────────────
## Universal install function that detects the appropriate package manager
install_tool() {
    local tool="$1"
    local cargo_name="${2:-$1}"  ## Optional different name for cargo

    if [[ -z "$tool" ]]; then
        echo "Usage: install_tool <package_name> [cargo_name]"
        return 1
    fi

    echo "🔍 Detecting package manager for $tool..."

    if [[ "$IS_MACOS" == true ]] && command -v brew &> /dev/null; then
        echo "📦 Using Homebrew..."
        brew install "$tool"
    elif command -v apt &> /dev/null; then
        echo "📦 Using APT..."
        sudo apt update && sudo apt install -y "$tool"
    elif command -v dnf &> /dev/null; then
        echo "📦 Using DNF..."
        sudo dnf install -y "$tool"
    elif command -v pacman &> /dev/null; then
        echo "📦 Using Pacman..."
        sudo pacman -S --noconfirm "$tool"
    elif command -v zypper &> /dev/null; then
        echo "📦 Using Zypper..."
        sudo zypper install -y "$tool"
    elif command -v cargo &> /dev/null; then
        echo "📦 Falling back to Cargo..."
        cargo install "$cargo_name"
    else
        echo "❌ No supported package manager found!"
        echo "💡 Try installing with: cargo install $cargo_name"
        return 1
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.2: Git Credential Security
# ──────────────────────────────────────────────────────────────────────────────
## Setup secure git credential storage
setup_git_credentials() {
    echo "🔐 Setting up secure Git credentials..."

    if [[ "$IS_MACOS" == true ]]; then
        git config --global credential.helper osxkeychain
        echo "✅ Using macOS Keychain"
    elif command -v git-credential-manager &> /dev/null; then
        git config --global credential.helper manager
        echo "✅ Using Git Credential Manager"
    elif [[ -n "$WSL_DISTRO_NAME" ]]; then
        git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
        echo "✅ Using Windows Credential Manager via WSL"
    else
        git config --global credential.helper cache --timeout=3600
        echo "⚠️  Using cache helper (1 hour timeout)"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.3: Configuration Backup System
# ──────────────────────────────────────────────────────────────────────────────
## Backup important configuration files
backup_configs() {
    local backup_base="$HOME/.config_backups"
    local backup_dir="$backup_base/$(date +%Y%m%d_%H%M%S)"

    echo "💾 Creating configuration backup..."
    mkdir -p "$backup_dir"

    ## List of files to backup
    local config_files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.gitconfig"
        "$HOME/.p10k.zsh"
        "$HOME/.ssh/config"
        "$HOME/.config/helix/config.toml"
        "$HOME/.config/bat/config"
        "$HOME/.ripgreprc"
    )

    local backed_up=0
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$backup_dir/" 2>/dev/null && ((backed_up++))
        fi
    done

    ## Create manifest
    echo "Backup created: $(date)" > "$backup_dir/MANIFEST.txt"
    echo "Files backed up: $backed_up" >> "$backup_dir/MANIFEST.txt"

    ## Cleanup old backups (keep last 10)
    if command -v fd &> /dev/null; then
        fd . "$backup_base" --type d --max-depth 1 | sort -r | tail -n +11 | xargs -r rm -rf
    else
        ls -1dt "$backup_base"/*/ 2>/dev/null | tail -n +11 | xargs -r rm -rf
    fi

    echo "✅ Backed up $backed_up files to $backup_dir"
}

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.4: WSL (Windows Subsystem for Linux) Support
# ──────────────────────────────────────────────────────────────────────────────
## Detect and configure WSL environment
if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "$WSL_DISTRO_NAME" ]]; then
    export IS_WSL=true

    ## Set browser for WSL
    export BROWSER="wslview"

    ## Windows paths
    export WINDOWS_HOME="/mnt/c/Users/$(whoami)"

    ## Clipboard integration
    alias pbcopy="clip.exe"
    alias pbpaste="powershell.exe -command 'Get-Clipboard' | sed 's/\r$//'"

    ## Open Windows Explorer
    alias explorer="explorer.exe ."
    alias open="wslview"

    ## VS Code integration
    if command -v code &> /dev/null; then
        export EDITOR="code --wait"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.5: Docker/Podman Integration
# ──────────────────────────────────────────────────────────────────────────────
## Docker aliases and functions
if command -v docker &> /dev/null; then
    ## Better docker ps output
    alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"'
    alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"'

    ## Container management
    alias dstart='docker start'
    alias dstop='docker stop'
    alias drm='docker rm'
    alias dexec='docker exec -it'
    alias dlogs='docker logs -f'

    ## Image management
    alias dimages='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"'
    alias dpull='docker pull'
    alias dbuild='docker build'

    ## Cleanup commands
    alias dclean='docker system prune -af --volumes'
    alias dcleanc='docker container prune -f'
    alias dcleani='docker image prune -af'

    ## Docker compose
    if command -v docker-compose &> /dev/null; then
        alias dc='docker-compose'
        alias dcu='docker-compose up -d'
        alias dcd='docker-compose down'
        alias dcl='docker-compose logs -f'
    fi

    ## Quick container shell
    dsh() {
        local container="${1:-}"
        if [[ -z "$container" ]]; then
            echo "Usage: dsh <container_name>"
            return 1
        fi
        docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
    }
elif command -v podman &> /dev/null; then
    ## Podman as docker alias
    alias docker='podman'
    alias docker-compose='podman-compose'

    ## Same aliases for podman
    alias dps='podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"'
    alias dpsa='podman ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"'
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.6: Adaptive Themes
# ──────────────────────────────────────────────────────────────────────────────
## Auto-adjust themes based on system dark/light mode
update_theme_mode() {
    if [[ "$IS_MACOS" == true ]]; then
        if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q "Dark"; then
            export THEME_MODE="dark"
            export BAT_THEME="gruvbox-dark"
            export DELTA_THEME="gruvbox-dark"
        else
            export THEME_MODE="light"
            export BAT_THEME="gruvbox-light"
            export DELTA_THEME="gruvbox-light"
        fi
    elif [[ -f "$HOME/.theme_mode" ]]; then
        export THEME_MODE=$(cat "$HOME/.theme_mode")
        if [[ "$THEME_MODE" == "dark" ]]; then
            export BAT_THEME="gruvbox-dark"
            export DELTA_THEME="gruvbox-dark"
        else
            export BAT_THEME="gruvbox-light"
            export DELTA_THEME="gruvbox-light"
        fi
    fi
}

## Update theme on shell start
update_theme_mode

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.7: Performance Monitoring
# ──────────────────────────────────────────────────────────────────────────────
## Benchmark shell startup time
shell_benchmark() {
    echo "⏱️  Benchmarking shell startup time..."

    if command -v hyperfine &> /dev/null; then
        hyperfine --warmup 3 --min-runs 10 'zsh -i -c exit'
    else
        echo "Running 10 iterations..."
        local total=0
        for i in {1..10}; do
            local start=$(date +%s.%N)
            zsh -i -c exit
            local end=$(date +%s.%N)
            local duration=$(echo "$end - $start" | bc)
            total=$(echo "$total + $duration" | bc)
            echo "  Run $i: ${duration}s"
        done
        local average=$(echo "scale=3; $total / 10" | bc)
        echo "Average: ${average}s"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.8: Sensitive Environment Variables
# ──────────────────────────────────────────────────────────────────────────────
## Load sensitive environment variables from secure file
if [[ -f "$HOME/.env.local" ]]; then
    ## Ensure file has restricted permissions
    chmod 600 "$HOME/.env.local" 2>/dev/null
    source "$HOME/.env.local"
fi

## Template for .env.local (create if doesn't exist)
if [[ ! -f "$HOME/.env.local" ]]; then
    cat > "$HOME/.env.local.template" << 'EOF'
# Sensitive Environment Variables Template
# Copy to ~/.env.local and fill with your values

# API Keys
# export OPENAI_API_KEY="your-key-here"
# export GITHUB_TOKEN="your-token-here"
# export AWS_ACCESS_KEY_ID="your-key-here"
# export AWS_SECRET_ACCESS_KEY="your-secret-here"

# Database URLs
# export DATABASE_URL="postgresql://user:pass@host:port/db"
# export REDIS_URL="redis://localhost:6379"

# Other Secrets
# export SECRET_KEY="your-secret-key"
# export ENCRYPTION_KEY="your-encryption-key"
EOF
    echo "💡 Created ~/.env.local.template - copy and customize for your secrets"
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.9: Lazy Loading for Heavy Tools
# ──────────────────────────────────────────────────────────────────────────────
## Lazy load nvm (Node Version Manager)
if [[ -d "$HOME/.nvm" ]]; then
    lazy_load_nvm() {
        unset -f node npm npx nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    }

    ## Create placeholder functions
    node() { lazy_load_nvm && node "$@"; }
    npm() { lazy_load_nvm && npm "$@"; }
    npx() { lazy_load_nvm && npx "$@"; }
    nvm() { lazy_load_nvm && nvm "$@"; }
fi

## Lazy load rbenv (Ruby Version Manager)
if [[ -d "$HOME/.rbenv" ]]; then
    lazy_load_rbenv() {
        unset -f ruby gem bundle rbenv
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
    }

    ruby() { lazy_load_rbenv && ruby "$@"; }
    gem() { lazy_load_rbenv && gem "$@"; }
    bundle() { lazy_load_rbenv && bundle "$@"; }
    rbenv() { lazy_load_rbenv && rbenv "$@"; }
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.10: Documentation System
# ──────────────────────────────────────────────────────────────────────────────
## Generate documentation for custom functions
zdoc() {
    echo "📚 Custom Functions Documentation"
    echo "================================="
    echo ""
    echo "🔧 Available Functions:"
    echo ""

    ## System Functions
    echo "📦 System Management:"
    echo "  install_tool <pkg> [cargo_name]  → Universal package installer"
    echo "  backup_configs                   → Backup configuration files"
    echo "  shell_benchmark                  → Benchmark shell startup time"
    echo "  setup_git_credentials            → Configure git credential helper"
    echo ""

    ## Development Functions
    echo "💻 Development:"
    echo "  create_sci_env [name] [version]  → Create scientific Python environment"
    echo "  init_project [name]              → Initialize project structure"
    echo "  bench <command>                  → Benchmark command execution"
    echo ""

    ## Data Functions
    echo "📊 Data Analysis:"
    echo "  quick_csv <file>                 → Quick CSV analysis"
    echo "  nu_open <file>                   → Open in Nushell"
    echo "  nu_compare <file1> <file2>       → Compare two CSVs"
    echo ""

    ## Container Functions
    if command -v docker &> /dev/null || command -v podman &> /dev/null; then
        echo "🐳 Container Management:"
        echo "  dsh <container>                  → Shell into container"
        echo "  dps                              → Pretty container list"
        echo "  dclean                           → Clean all Docker resources"
        echo ""
    fi

    ## Help Functions
    echo "❓ Help & Discovery:"
    echo "  h / hal                          → Essential commands"
    echo "  halp [category]                  → Help by category"
    echo "  hfun                             → List main functions"
    echo "  zdoc                             → This documentation"
    echo "  qm                               → Quick menu (if enabled)"
    echo ""

    echo "💡 Use 'type <function_name>' to see implementation"
}

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.11: Quick Menu System
# ──────────────────────────────────────────────────────────────────────────────
## Interactive menu for common tasks
quick_menu() {
    echo ""
    echo "🚀 Quick Actions Menu"
    echo "===================="
    echo ""
    echo "Select an option (enter number):"

    local options=(
        "Update System"
        "Check Tools"
        "Backup Configs"
        "Shell Benchmark"
        "Git Credentials Setup"
        "Docker Cleanup"
        "Show Documentation"
        "Exit"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Update System")
                if alias bum &>/dev/null; then
                    bum
                else
                    echo "❌ Update command not configured"
                fi
                ;;
            "Check Tools") checktools ;;
            "Backup Configs") backup_configs ;;
            "Shell Benchmark") shell_benchmark ;;
            "Git Credentials Setup") setup_git_credentials ;;
            "Docker Cleanup")
                if command -v docker &> /dev/null; then
                    dclean
                else
                    echo "❌ Docker not installed"
                fi
                ;;
            "Show Documentation") zdoc ;;
            "Exit") break ;;
            *) echo "Invalid option" ;;
        esac

        if [[ "$opt" != "Exit" ]] && [[ -n "$opt" ]]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✅ Task completed. Select another option or 8 to exit:"
        fi
    done
}
alias qm='quick_menu'

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.12: SSH Agent Management
# ──────────────────────────────────────────────────────────────────────────────
## Auto-start SSH agent if not running
if [[ -z "$SSH_AUTH_SOCK" ]] && [[ ! "$IS_WSL" == true ]]; then
    ## Check for existing ssh-agent
    if [[ -f "$HOME/.ssh-agent-info" ]]; then
        source "$HOME/.ssh-agent-info" > /dev/null
        ## Test if agent is still running
        ssh-add -l &>/dev/null || {
            eval "$(ssh-agent -s)" > /dev/null
            echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$HOME/.ssh-agent-info"
            echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$HOME/.ssh-agent-info"
        }
    else
        eval "$(ssh-agent -s)" > /dev/null
        echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$HOME/.ssh-agent-info"
        echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$HOME/.ssh-agent-info"
    fi

    ## Auto-add SSH keys
    local ssh_keys=(
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ecdsa"
    )

    for key in "${ssh_keys[@]}"; do
        if [[ -f "$key" ]]; then
            ssh-add -l | grep -q "$(ssh-keygen -lf "$key" | awk '{print $2}')" || ssh-add "$key" 2>/dev/null
        fi
    done
fi

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.13: Feature Flags
# ──────────────────────────────────────────────────────────────────────────────
## Allow users to disable specific features
## Create ~/.zshrc.flags to customize
if [[ -f "$HOME/.zshrc.flags" ]]; then
    source "$HOME/.zshrc.flags"
fi

## Default flags (can be overridden in .zshrc.flags)
: ${ENABLE_WELCOME_MESSAGE:=true}
: ${ENABLE_COMMAND_TRACKING:=true}
: ${ENABLE_AUTO_SSH_AGENT:=true}
: ${ENABLE_LAZY_LOADING:=true}
: ${ENABLE_QUICK_MENU:=true}

## Apply flags
[[ "$ENABLE_WELCOME_MESSAGE" != "true" ]] && unset -f show_welcome
[[ "$ENABLE_COMMAND_TRACKING" != "true" ]] && precmd_functions=(${precmd_functions:#precmd_track_commands})
[[ "$ENABLE_QUICK_MENU" != "true" ]] && unalias qm 2>/dev/null

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.14: Fast Package Managers (uv for Python, bun for JS)
# ──────────────────────────────────────────────────────────────────────────────
## Install uv if not present
install_uv() {
    if command -v uv &> /dev/null; then
        echo "✅ uv is already installed: $(uv --version)"
        return 0
    fi

    echo "🚀 Installing uv - Extremely fast Python package installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    ## Add to PATH if needed
    if [[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    echo "✅ uv installed successfully!"
    echo "💡 Restart your shell or run: source ~/.zshrc"
}

## Check uv on first Python command
_check_uv_once() {
    if [[ -z "$UV_CHECKED" ]] && ! command -v uv &> /dev/null; then
        echo "💡 Speed up Python package management 10-100x with uv!"
        echo "   Run: install_uv"
        export UV_CHECKED=1
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# SECTION 22.15: AI Development Tools
# ──────────────────────────────────────────────────────────────────────────────
## Claude Code - Anthropic's AI coding assistant
## Smart function that tries bunx -> npx -> npm in order
claude-code() {
    # Try bunx first (fastest)
    if command -v bunx &> /dev/null; then
        bunx @anthropic-ai/claude-code "$@"
    # Fallback to npx
    elif command -v npx &> /dev/null; then
        npx @anthropic-ai/claude-code "$@"
    # Final fallback to npm
    elif command -v npm &> /dev/null; then
        npm exec -- @anthropic-ai/claude-code "$@"
    else
        echo "❌ Error: No package manager found (bunx, npx, or npm)"
        echo "💡 Install Node.js or Bun to use claude-code"
        return 1
    fi
}
alias cc='claude-code'  ## Short alias for convenience

# ──────────────────────────────────────────────────────────────────────────────
# AI Tools Setup Functions (MCPs + BMAD)
# ──────────────────────────────────────────────────────────────────────────────
## Check AI tools installation status
ai-check() {
    local check_script="$HOME/Documents/GitHub/os-postinstall-scripts/check_ai_tools.sh"
    
    if [[ -x "$check_script" ]]; then
        "$check_script"
    else
        echo "❌ AI tools check script not found at: $check_script"
        echo "💡 Clone the repo: git clone https://github.com/BragatteMAS/os-postinstall-scripts"
        return 1
    fi
}

## Install BMAD in current project
ai-setup() {
    echo "🤖 Setting up AI tools for current project..."
    
    # Check if in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "⚠️  Warning: Not in a git repository. Initialize with 'git init' first? (recommended)"
        echo -n "Continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "❌ Setup cancelled"
            return 1
        fi
    fi
    
    # Install BMAD Method
    echo "📦 Installing BMAD Method..."
    if command -v pnpm &> /dev/null; then
        pnpm dlx bmad-method@latest install --full --ide cursor
    else
        npx bmad-method@latest install --full --ide cursor
    fi
    
    # Check result
    if [[ -d ".claude" ]]; then
        echo "✅ BMAD Method installed successfully!"
        echo "💡 Available commands in Claude:"
        echo "   /generate-prp - Generate detailed specifications"
        echo "   /execute-prp - Execute with validation"
        echo "   /validate-patterns - Check project patterns"
    else
        echo "❌ BMAD installation may have failed. Check the output above."
    fi
}

## Quick install MCPs globally (one time only)
ai-install-mcps() {
    local install_script="$HOME/Documents/GitHub/os-postinstall-scripts/install_ai_tools.sh"
    
    if [[ -x "$install_script" ]]; then
        echo "🚀 Installing AI tools (MCPs + BMAD)..."
        "$install_script"
    else
        echo "📥 Downloading and running AI tools installer..."
        curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install_ai_tools.sh | bash
    fi
}

## Update BMAD in current project
ai-update() {
    if [[ ! -d ".claude" ]]; then
        echo "❌ No BMAD installation found in current directory"
        echo "💡 Run 'ai-setup' first to install BMAD"
        return 1
    fi
    
    echo "🔄 Updating BMAD Method..."
    if command -v pnpm &> /dev/null; then
        pnpm dlx bmad-method@latest update
    else
        npx bmad-method@latest update
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Product-Focused Git Aliases
# ──────────────────────────────────────────────────────────────────────────────
## Keep commits focused on product, not tooling
alias glogp="git log --oneline -- ':!.github'"        ## Git log excluding .github
alias gdiffp="git diff -- ':!.github'"                ## Git diff excluding .github
alias gstatusp="git status -- ':!.github'"            ## Git status excluding .github
alias gaddp="git add -- ':!.github'"                  ## Git add excluding .github
alias gshowp="git show -- ':!.github'"                ## Git show excluding .github

## Conventional commit aliases for clean history
alias gcfeat="git commit -m 'feat: '"                 ## Commit new feature
alias gcfix="git commit -m 'fix: '"                   ## Commit bug fix
alias gcdocs="git commit -m 'docs: '"                 ## Commit documentation
alias gcstyle="git commit -m 'style: '"               ## Commit formatting
alias gcrefactor="git commit -m 'refactor: '"         ## Commit refactoring
alias gctest="git commit -m 'test: '"                 ## Commit tests
alias gcchore="git commit -m 'chore(.github): '"      ## Commit tooling/methods

# ──────────────────────────────────────────────────────────────────────────────
# CLAUDE.md - Configuração Global para IA
# ──────────────────────────────────────────────────────────────────────────────
claude_init() {
    local claude_global="~/CLAUDE.md"
    local claude_local="./CLAUDE.md"
    
    # Verificar se o arquivo global existe
    if [[ ! -f "$claude_global" ]]; then
        echo "❌ CLAUDE.md global não encontrado em: $claude_global"
        return 1
    fi
    
    # Verificar se já existe um CLAUDE.md local
    if [[ -e "$claude_local" ]]; then
        echo "⚠️  CLAUDE.md já existe neste diretório!"
        echo -n "Deseja substituir? (s/N): "
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            echo "❌ Operação cancelada"
            return 1
        fi
        rm -f "$claude_local"
    fi
    
    # Criar symlink
    ln -s "$claude_global" "$claude_local"
    
    # Verificar se foi criado com sucesso
    if [[ -L "$claude_local" ]]; then
        echo "✅ CLAUDE.md linkado com sucesso!"
        echo "📍 Fonte: $claude_global"
        echo "🔗 Link: $claude_local"
        
        # Mostrar versão atual
        local version=$(grep "Versão:" "$claude_local" | head -1)
        [[ -n "$version" ]] && echo "📋 $version"
    else
        echo "❌ Erro ao criar symlink"
        return 1
    fi
}

# Alias simples para uso rápido
alias claude-init='claude_init'
alias ci='claude_init'

# Função para verificar status do CLAUDE.md no diretório atual
claude_status() {
    if [[ -L "./CLAUDE.md" ]]; then
        echo "✅ CLAUDE.md está linkado"
        echo "📍 Aponta para: $(readlink ./CLAUDE.md)"
        
        # Verificar se o arquivo de destino existe
        if [[ -f "./CLAUDE.md" ]]; then
            echo "✅ Arquivo de destino existe"
            local version=$(grep "Versão:" "./CLAUDE.md" | head -1)
            [[ -n "$version" ]] && echo "📋 $version"
        else
            echo "❌ Arquivo de destino não encontrado!"
        fi
    elif [[ -f "./CLAUDE.md" ]]; then
        echo "📄 CLAUDE.md existe mas não é um symlink"
        local version=$(grep "Versão:" "./CLAUDE.md" | head -1)
        [[ -n "$version" ]] && echo "📋 $version"
    else
        echo "❌ CLAUDE.md não encontrado neste diretório"
        echo "💡 Use 'ci' ou 'claude-init' para linkar o arquivo global"
    fi
}

alias claude-status='claude_status'
alias cs='claude_status'

# End of zshrc enhancements
# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ SECTION 23: RUST TOOLS AUTO-DETECTION AND INTEGRATION                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ──────────────────────────────────────────────────────────────────────────────
# Auto-instalação de ferramentas Rust faltantes
# ──────────────────────────────────────────────────────────────────────────────
check_and_suggest_rust_tool() {
    local tool="$1"
    local cargo_name="${2:-$1}"
    local description="$3"

    if ! command -v "$tool" &> /dev/null; then
        # Adicionar à lista de ferramentas sugeridas
        MISSING_RUST_TOOLS+=("$cargo_name:$description")
    fi
}

# Verificar ferramentas Rust na inicialização
check_rust_tools() {
    local MISSING_RUST_TOOLS=()

    # Ferramentas essenciais
    check_and_suggest_rust_tool "bat" "bat" "cat com syntax highlighting"
    check_and_suggest_rust_tool "eza" "eza" "ls moderno com ícones"
    check_and_suggest_rust_tool "fd" "fd-find" "find mais rápido"
    check_and_suggest_rust_tool "rg" "ripgrep" "grep ultrarrápido"
    check_and_suggest_rust_tool "delta" "git-delta" "diff melhorado para git"
    check_and_suggest_rust_tool "dust" "du-dust" "du com visualização em árvore"
    check_and_suggest_rust_tool "zoxide" "zoxide" "cd inteligente com IA"
    check_and_suggest_rust_tool "starship" "starship" "prompt customizável"

    # Se houver ferramentas faltando, sugerir instalação
    if [[ ${#MISSING_RUST_TOOLS[@]} -gt 0 ]]; then
        # Criar arquivo de sugestões se não existir
        if [[ ! -f "$HOME/.rust_tools_suggested" ]]; then
            echo "🦀 Ferramentas Rust recomendadas não instaladas:"
            printf "   %s\n" "${MISSING_RUST_TOOLS[@]}" | column -t -s':'
            echo ""
            echo "💡 Para instalar todas de uma vez:"
            echo "   curl -sSL https://raw.githubusercontent.com/SEU_USUARIO/Linux_posintall_script/main/install_rust_tools.sh | bash"
            echo ""
            echo "   Ou individualmente com cargo:"
            for tool in "${MISSING_RUST_TOOLS[@]}"; do
                echo "   cargo install ${tool%%:*}"
            done

            # Marcar como sugerido
            touch "$HOME/.rust_tools_suggested"
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Função de bootstrap rápido do repositório
# ──────────────────────────────────────────────────────────────────────────────
rust_env_setup() {
    local repo_url="${1:-https://github.com/SEU_USUARIO/Linux_posintall_script}"

    echo "🚀 Configurando ambiente Rust do repositório..."

    # Criar diretório temporário
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Clonar apenas o necessário
    git clone --depth 1 --filter=blob:none --sparse "$repo_url" setup_temp
    cd setup_temp
    git sparse-checkout set install_rust_tools.sh zshrc

    # Executar instalação
    if [[ -f "install_rust_tools.sh" ]]; then
        bash install_rust_tools.sh
    fi

    # Limpar
    cd "$HOME"
    rm -rf "$temp_dir"

    echo "✅ Ambiente configurado! Reinicie o shell."
}

# ──────────────────────────────────────────────────────────────────────────────
# Aliases inteligentes com fallback automático
# ──────────────────────────────────────────────────────────────────────────────
# Esta função cria aliases que usam Rust tools se disponíveis, senão usa o padrão
setup_smart_rust_aliases() {
    # Listagem de arquivos
    if command -v eza &> /dev/null; then
        alias ls='eza --icons --group-directories-first'
        alias ll='eza -la --icons --git --header'
        alias tree='eza --tree --icons'
    elif command -v lsd &> /dev/null; then
        alias ls='lsd --group-directories-first'
        alias ll='lsd -la --header'
        alias tree='lsd --tree'
    fi

    # Visualização de arquivos
    if command -v bat &> /dev/null; then
        alias cat='bat --style=plain'
        alias less='bat --style=plain --paging=always'
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    fi

    # Busca
    if command -v rg &> /dev/null; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    elif command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    fi

    # Git
    if command -v delta &> /dev/null; then
        export GIT_PAGER='delta'
        git config --global core.pager delta
        git config --global interactive.diffFilter 'delta --color-only'
    fi

    # Navegação
    if command -v zoxide &> /dev/null; then
        eval "$(zoxide init zsh)"
        alias cd='z'  # Sobrescrever cd com zoxide
    fi

    # Monitoramento
    if command -v bottom &> /dev/null; then
        alias top='bottom'
        alias htop='bottom'
    elif command -v btm &> /dev/null; then
        alias top='btm'
        alias htop='btm'
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Instalador universal via alias
# ──────────────────────────────────────────────────────────────────────────────
universal_install() {
    local tool="$1"

    echo "🔍 Procurando melhor método para instalar $tool..."

    # 1. Tentar cargo primeiro (funciona em qualquer lugar)
    if command -v cargo &> /dev/null; then
        # Mapear nomes conhecidos
        case "$tool" in
            "eza") cargo install eza ;;
            "bat") cargo install bat ;;
            "fd") cargo install fd-find ;;
            "rg"|"ripgrep") cargo install ripgrep ;;
            "delta") cargo install git-delta ;;
            "dust") cargo install du-dust ;;
            "bottom"|"btm") cargo install bottom ;;
            "zoxide"|"z") cargo install zoxide ;;
            *) cargo install "$tool" ;;
        esac
        return $?
    fi

    # 2. Detectar gerenciador de pacotes do sistema
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install "$tool"
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y "$tool"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$tool"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "$tool"
    else
        echo "❌ Nenhum gerenciador de pacotes encontrado"
        echo "💡 Instale o Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi
}

alias install='universal_install'
alias irust='check_rust_tools'  # Verificar ferramentas Rust

# ──────────────────────────────────────────────────────────────────────────────
# Executar verificações na inicialização
# ──────────────────────────────────────────────────────────────────────────────
# Verificar apenas uma vez por sessão
if [[ -z "$RUST_TOOLS_CHECKED" ]]; then
    setup_smart_rust_aliases
    export RUST_TOOLS_CHECKED=1

    # Verificar ferramentas apenas se não foi feito hoje
    if [[ ! -f "$HOME/.rust_tools_checked" ]] || [[ $(find "$HOME/.rust_tools_checked" -mtime +1 2>/dev/null) ]]; then
        check_rust_tools
        touch "$HOME/.rust_tools_checked"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# Comando para setup completo em novo ambiente
# ──────────────────────────────────────────────────────────────────────────────
new_machine_setup() {
    echo "🚀 Configurando novo ambiente de desenvolvimento..."
    echo ""
    echo "Este comando irá:"
    echo "  1. Instalar Rust e cargo"
    echo "  2. Instalar todas as ferramentas Rust recomendadas"
    echo "  3. Configurar seu shell (zsh)"ltl
    echo "  4. Instalar Python com UV"
    echo ""
    read -p "Continuar? (s/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        # Baixar e executar o script do seu repo
        curl -sSL "https://raw.githubusercontent.com/SEU_USUARIO/Linux_posintall_script/main/install_rust_tools.sh" | bash

        # Copiar configurações
        echo "📁 Clonando configurações..."
        git clone https://github.com/SEU_USUARIO/Linux_posintall_script.git "$HOME/.config/dev-setup"

        # Aplicar zshrc
        if [[ -f "$HOME/.config/dev-setup/zshrc" ]]; then
            cp "$HOME/.config/dev-setup/zshrc" "$HOME/.zshrc"
            echo "✅ zshrc atualizado"
        fi

        echo "✅ Setup completo! Reinicie seu terminal."
    fi
}

alias newsetup='new_machine_setup'
alias rustsetup='rust_env_setup'
