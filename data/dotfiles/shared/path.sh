# PATH management with duplicate prevention
# Sourced by both zsh and bash

# Add to PATH with duplicate prevention
add_to_path() {
    local new_path="$1"
    [[ -z "$new_path" ]] && return 1
    [[ ! -d "$new_path" ]] && return 1
    case ":$PATH:" in
        *":$new_path:"*) return 0 ;;
    esac
    export PATH="$new_path:$PATH"
}

# Add to end of PATH (lower priority)
add_to_path_end() {
    local new_path="$1"
    [[ -z "$new_path" ]] && return 1
    [[ ! -d "$new_path" ]] && return 1
    case ":$PATH:" in
        *":$new_path:"*) return 0 ;;
    esac
    export PATH="$PATH:$new_path"
}

# Common paths (higher priority first)
[[ -d "$HOME/.local/bin" ]] && add_to_path "$HOME/.local/bin"
[[ -d "$HOME/.cargo/bin" ]] && add_to_path "$HOME/.cargo/bin"
[[ -d "$HOME/go/bin" ]] && add_to_path "$HOME/go/bin"
[[ -d "$HOME/.bun/bin" ]] && add_to_path "$HOME/.bun/bin"

# Homebrew (macOS)
[[ -d "/opt/homebrew/bin" ]] && add_to_path "/opt/homebrew/bin"
[[ -d "/usr/local/bin" ]] && add_to_path "/usr/local/bin"
