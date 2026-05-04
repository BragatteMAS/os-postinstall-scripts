# Shell functions for terminal-setup.sh
# Requires bash or zsh — not compatible with sh/dash
# Source: https://github.com/BragatteMAS/os-postinstall-scripts

# Guard: skip silently if sourced by sh/dash
[ -z "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ] && { return 0 2>/dev/null || exit 0; }

# -----------------------------------------------------------------------------
# Emoji Toggle — set TERMINAL_EMOJI=false for ASCII-only output
# Auto-detects: disables emojis if locale lacks UTF-8
# -----------------------------------------------------------------------------
_use_emoji() {
    [[ "${TERMINAL_EMOJI:-}" == "false" ]] && return 1
    [[ "${TERMINAL_EMOJI:-}" == "true" ]] && return 0
    # Auto-detect from locale (check LC_ALL, LC_CTYPE, then LANG)
    local locale_str="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    [[ "$locale_str" == *UTF-8* || "$locale_str" == *utf8* ]]
}

# -----------------------------------------------------------------------------
# Welcome Message — shown once on first session, hint on subsequent
# -----------------------------------------------------------------------------
show_welcome() {
    local current_time
    current_time=$(date +%H:%M)
    local current_dir
    current_dir=$(basename "$PWD")
    local git_branch=""

    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo 'detached')
        if _use_emoji; then
            git_branch=" | 🌿 $branch"
        else
            git_branch=" | @$branch"
        fi
    fi

    if _use_emoji; then
        echo ""
        echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
        echo "┃ 🚀 $current_time | 📁 $current_dir$git_branch"
        echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
        echo ""
        echo "💡 h (help) | h <term> (search) | cmd <term> (find aliases)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo ""
        echo "=== $current_time | $current_dir$git_branch ==="
        echo ""
        echo "h (help) | h <term> (search) | cmd <term> (find aliases)"
        echo "==="
    fi
}

show_welcome_compact() {
    local git_info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo 'detached')
        if _use_emoji; then
            git_info=" | 🌿 $branch"
        else
            git_info=" | @$branch"
        fi
    fi
    if _use_emoji; then
        echo "🚀 $(date +%H:%M) | 📁 $(basename "$PWD")$git_info"
    else
        echo "$(date +%H:%M) | $(basename "$PWD")$git_info"
    fi
    echo "h (help) | h <term> (search) | cmd <term> (find aliases)"
}

alias welcome='show_welcome'
alias welcomec='show_welcome_compact'

# -----------------------------------------------------------------------------
# CSV-driven tool catalog (Onda 5)
# Reads data/packages.csv (symlinked to ~/.config/os-postinstall/packages.csv
# by dotfiles-install.sh). Powers `h rust-*` and `h <toolname>` lookups.
# -----------------------------------------------------------------------------
_OS_POSTINSTALL_CSV="${OS_POSTINSTALL_CSV:-$HOME/.config/os-postinstall/packages.csv}"

_h_csv_category() {
    if [[ ! -f "$_OS_POSTINSTALL_CSV" ]]; then
        echo "  (CSV not installed at $_OS_POSTINSTALL_CSV)"
        echo "  Run: ./setup.sh dotfiles  to create the symlink"
        return 1
    fi
    LC_ALL=C awk -F',' -v cat="$1" '
        /^#/ { next }
        NR==1 || $1=="category" { next }
        $1 == cat {
            bin = ($5 == "" ? $2 : $5)
            printf "  %-15s %s\n", bin, $7
        }
    ' "$_OS_POSTINSTALL_CSV"
}

# -----------------------------------------------------------------------------
# Help — h [topic]
# -----------------------------------------------------------------------------
h() {
    local _e=""
    _use_emoji && _e=1

    case "${1:-}" in
        ""|"help")
            [[ -n "$_e" ]] && echo "⚡ QUICK REFERENCE" || echo "QUICK REFERENCE"
            echo ""
            echo "NAV:  .. ... ....    mkcd <dir>    yazi (file manager)"
            echo "LIST: ls ll la lt lta (eza if installed)"
            echo ""
            echo "GIT:  gs gd ga gc gp gpl gl glo gb gco gcb gsw gst"
            echo "      (pattern: g + first letters — h git for details)"
            echo ""
            echo "FIND: preview (fzf+bat)  aliases (fzf)  cmd <term>"
            echo "TOOL: bat fd rg eza delta z yazi starship  (h tools)"
            echo "AI:   claude codex gemini copilot opencode ollama  (h ai)"
            echo "UTIL: c path now df duh ports sysup welcome"
            echo "SAFE: rm/cp/mv confirm before overwrite"
            echo ""
            [[ -n "$_e" ]] && echo "💡 h <word>    try: h nav  h ai  h fzf  h commit  h all" \
                           || echo "h <word>    try: h nav  h ai  h fzf  h commit  h all"
            ;;
        "find"|"search")
            [[ -n "$_e" ]] && echo "🔍 Search & Preview:" || echo "Search & Preview:"
            echo "  preview         open fzf file browser with bat preview"
            echo "                  → browse files, Enter to select"
            echo "  aliases         browse all aliases with fzf"
            echo "  cmd <term>      search aliases + functions by keyword"
            echo "                  → cmd git  cmd update  cmd sysup"
            echo "  rg <term>       search inside files (ripgrep)"
            echo "                  → rg TODO  rg -i 'error' logs/"
            echo "  fd <pattern>    find files by name"
            echo "                  → fd '.py'  fd -e sh  fd config"
            echo "  z <dir>         jump to frequent dir (zoxide)"
            echo "                  → z proj  z doc  zi (interactive)"
            echo ""
            echo "  Requires: fzf (preview/aliases), bat (preview highlighting)"
            ;;
        "nav"|"ls")
            [[ -n "$_e" ]] && echo "📁 Navigation & Listing:" || echo "Navigation & Listing:"
            echo "  .. / ... / .... / .....  go up 1–4 directories"
            echo "  ls               list files (eza if installed)"
            echo "  ll               detailed list with git info"
            echo "  la               show hidden files"
            echo "  lt               tree view (2 levels)"
            echo "  lta              tree with hidden files"
            echo "  mkcd <dir>       create directory and cd into it"
            echo "                   → mkcd my-project"
            echo "  yazi             terminal file manager (browse, preview, open)"
            echo "                   → yazi  yazi ~/Documents"
            ;;
        "git")
            [[ -n "$_e" ]] && echo "🌿 Git Shortcuts:" || echo "Git Shortcuts:"
            echo "  g                git (bare)"
            echo "  gs / gd / gds    status / diff / diff staged"
            echo "  ga / gap         add / add -p (pick hunks)"
            echo "  gc / gca         commit / commit --amend"
            echo "  gp / gpl / gf    push / pull / fetch"
            echo "  gl / glo         log oneline / graph all branches"
            echo "  gb / gco / gcb   branch / checkout / new branch"
            echo "  gsw / gst        switch / stash"
            echo ""
            echo "  Pattern: g + first letters of git subcommand"
            echo "  Example: gcb feature/login → git checkout -b feature/login"
            ;;
        "tools"|"rust"|"cli")
            [[ -n "$_e" ]] && echo "🦀 Modern CLI Tools (Rust) — sub-topics:" || echo "Modern CLI Tools (Rust) — sub-topics:"
            echo "  h rust-cli      Modern Unix replacements (bat, eza, fd, rg, ...)"
            echo "  h rust-dev      Dev tools (cargo extensions, ast-grep, ruff, ...)"
            echo "  h rust-data     Data wrangling (qsv, jaq, jql, ...)"
            echo "  h rust-tui      TUI applications (helix, yazi, zellij, ...)"
            echo "  h rust-shell    Shell integrations (starship, atuin, nu, ...)"
            echo ""
            echo "  Quick: bat>cat  fd>find  rg>grep  eza>ls  delta>diff  z>cd"
            echo "  Lookup any tool: h <name>     (e.g. h ast-grep, h ouch, h atuin)"
            ;;
        "rust-cli")
            [[ -n "$_e" ]] && echo "🦀 Modern Unix replacements:" || echo "Modern Unix replacements:"
            _h_csv_category rust-cli
            ;;
        "rust-dev")
            [[ -n "$_e" ]] && echo "🦀 Rust dev tools (cargo extensions + AI-friendly):" || echo "Rust dev tools:"
            _h_csv_category rust-dev
            ;;
        "rust-data")
            [[ -n "$_e" ]] && echo "🦀 Rust data wrangling tools:" || echo "Rust data tools:"
            _h_csv_category rust-data
            ;;
        "rust-tui")
            [[ -n "$_e" ]] && echo "🦀 Rust TUI applications:" || echo "Rust TUI apps:"
            _h_csv_category rust-tui
            ;;
        "rust-shell")
            [[ -n "$_e" ]] && echo "🦀 Rust shell integrations:" || echo "Rust shell:"
            _h_csv_category rust-shell
            ;;
        "util")
            [[ -n "$_e" ]] && echo "🔧 Utilities:" || echo "Utilities:"
            echo "  h <word>      help + search (h nav  h fzf  h commit  h all)"
            echo "  welcome       show full greeting message"
            echo "  c             clear screen"
            echo "  path          show \$PATH entries (one per line)"
            echo "  now           current date+time (YYYY-MM-DD HH:MM:SS)"
            echo "  df / du       disk free / disk usage"
            echo "  duh           disk usage this dir (1 level deep)"
            echo "  ports         show listening network ports"
            echo "  sysup         full system update (brew/apt/yum/pacman)"
            echo "                aliases: bum, upall"
            echo ""
            echo "  Safety: rm/cp/mv ask before overwrite (-i)"
            echo "  Emoji: export TERMINAL_EMOJI=false for ASCII mode"
            ;;
        "ai"|"llm")
            [[ -n "$_e" ]] && echo "🤖 AI Tools & MCPs:" || echo "AI Tools & MCPs:"
            echo "  claude            Anthropic Claude Code CLI (npm)"
            echo "  codex             OpenAI Codex CLI (npm)"
            echo "  gemini            Google Gemini CLI (npm)"
            echo "  copilot           GitHub Copilot CLI (npm)"
            echo "  opencode          OpenCode open-source alt (bun)"
            echo "  ollama            Local LLM runtime"
            echo "  claude-monitor    Token + cost monitor (ccm/cmonitor)"
            echo "  specify           specify-cli (project specs)"
            echo "  markitdown        Convert files to markdown for LLM context (uv)"
            echo ""
            echo "  MCPs (Model Context Protocol) — managed via mcpl:"
            echo "    mcpl list                 show configured MCPs"
            echo "    mcpl install <server>     add MCP server"
            echo "    mcpl call <s> <t> <args>  invoke MCP tool directly"
            echo "    mcpl inspect <s> <t>      view tool schema"
            echo ""
            echo "  Common MCPs: context7, fetch, supabase, serena,"
            echo "    sequential-thinking, kubb, markitdown, playwright,"
            echo "    browsermcp, firecrawl, convex, obsidian, digitalocean,"
            echo "    shadcn-ui, excalidraw, notebooklm"
            ;;
        "all")
            h; echo ""; h nav; echo ""; h git; echo ""; h find; echo ""; h tools; echo ""; h ai; echo ""; h util
            ;;
        *)
            # Try CSV lookup first (h <toolname> → catalog entry)
            if [[ -f "$_OS_POSTINSTALL_CSV" ]]; then
                local _csv_match
                _csv_match=$(LC_ALL=C awk -F',' -v name="$1" '
                    /^#/ { next }
                    NR==1 || $1=="category" { next }
                    $2 == name {
                        printf "  category:    %s\n", $1
                        printf "  brew:        %s\n", ($3 == "" ? "—" : $3)
                        printf "  cargo:       %s\n", ($4 == "" ? "—" : $4)
                        printf "  binary:      %s\n", ($5 == "" ? $2 : $5)
                        printf "  prefer:      %s\n", $6
                        printf "  description: %s\n", $7
                        found=1
                    }
                    END { exit !found }
                ' "$_OS_POSTINSTALL_CSV")
                if [[ -n "$_csv_match" ]]; then
                    [[ -n "$_e" ]] && echo "📦 $1:" || echo "$1:"
                    echo "$_csv_match"
                    return 0
                fi
            fi
            # Fallback: search across all help topics
            local _results
            _results=$(
                { h nav; h git; h find; h tools; h ai; h util; } 2>&1 \
                | grep -Fi "${1}" || true
            )
            if [[ -n "$_results" ]]; then
                [[ -n "$_e" ]] && echo "🔍 '$1':" || echo "'$1':"
                echo "$_results"
            else
                [[ -n "$_e" ]] && echo "❓ No match for '$1'" || echo "No match for '$1'"
                [[ -n "$_e" ]] && echo "💡 h <topic>: nav | git | find | tools | ai | util | all" \
                               || echo "h <topic>: nav | git | find | tools | ai | util | all"
                [[ -n "$_e" ]] && echo "💡 h <name>: any tool from packages.csv (rust-*)" \
                               || echo "h <name>: any tool from packages.csv (rust-*)"
            fi
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Search aliases AND functions by keyword
# -----------------------------------------------------------------------------
cmd() {
    local search="$1"
    if [[ -z "$search" ]]; then
        echo "Usage: cmd <term>  (e.g. cmd git, cmd sysup)"
        return 1
    fi
    if _use_emoji; then
        echo "🔍 '$search':"
    else
        echo "Search '$search':"
    fi
    # Search aliases (normalize bash/zsh output)
    alias | sed 's/^alias //' | grep -Fi "$search" | sed 's/^/  /' || true
    # Search functions (cross-shell, hide private _functions)
    { declare -F 2>/dev/null || typeset +f 2>/dev/null; } \
        | sed 's/^declare -f //' | grep -v '^_' \
        | grep -Fi "$search" | sed 's/^/  fn: /' || true
}

# -----------------------------------------------------------------------------
# File preview with fzf + bat (requires fzf)
# -----------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
    preview() {
        local preview_cmd="bat --color=always --style=numbers --line-range=:500 {}"
        command -v bat &>/dev/null || preview_cmd="cat {}"
        fzf --preview "$preview_cmd" "$@"
    }
    aliases() { alias | fzf; }
fi

# -----------------------------------------------------------------------------
# mkcd — create directory and cd into it (must be sourced, not executed)
# -----------------------------------------------------------------------------
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# -----------------------------------------------------------------------------
# Auto-show welcome on first interactive session
# Subsequent sessions: subtle hint. Type 'welcome' for full greeting.
# -----------------------------------------------------------------------------
if [[ $- == *i* ]] && [[ -z "${ZSH_EXECUTION_STRING:-}" ]]; then
    _welcome_marker="${HOME}/.config/shell/.welcome_shown"
    if [[ ! -f "$_welcome_marker" ]]; then
        show_welcome
        mkdir -p "${HOME}/.config/shell" 2>/dev/null
        touch "$_welcome_marker"
    else
        # Subsequent sessions: one-line reminder
        if _use_emoji; then
            echo "💡 h (help) | welcome (greeting)"
        else
            echo "h (help) | welcome (greeting)"
        fi
    fi
    unset _welcome_marker
fi
