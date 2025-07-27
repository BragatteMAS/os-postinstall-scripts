#!/bin/zsh
# ==============================================================================
# Module: Dependency Check
# Description: Verifies installed tools and suggests missing ones
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ DEPENDENCY VERIFICATION AND SUGGESTIONS                                    ║
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
        echo "   Install with:"
        echo '   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    fi
}

## Run check only on interactive shells
if [[ $- == *i* ]] && [[ -z "$DEPENDENCY_CHECK_DONE" ]]; then
    export DEPENDENCY_CHECK_DONE=1
    check_dependencies
fi