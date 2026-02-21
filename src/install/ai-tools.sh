#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: ai-tools.sh
# Description: Cross-platform AI tools installer with prefix-based dispatch
#              Handles npm: (CLI tools), curl: (ollama), and skips npx:/uv:/bare entries
# Author: Bragatte
# Date: 2026-02-06
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

#######################################
# Source core utilities (src/install/ is sibling to src/core/)
#######################################
CORE_DIR="${SCRIPT_DIR}/../core"

source "${CORE_DIR}/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${CORE_DIR}/idempotent.sh" || {
    log_error "Failed to load idempotent.sh"
    exit 1
}

source "${CORE_DIR}/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

source "${CORE_DIR}/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

source "${CORE_DIR}/interactive.sh" || {
    log_error "Failed to load interactive.sh"
    exit 1
}

#######################################
# install_ai_tool()
# Install a single AI tool based on its prefix
#
# Args: $1 = entry from ai-tools.txt (e.g., "npm:@anthropic-ai/claude-code")
# Returns: 0 on success/skip, 1 on failure
#######################################
install_ai_tool() {
    local entry="${1:-}"

    # No prefix (bare word like "uv") — skip silently
    if [[ "$entry" != *":"* ]]; then
        log_debug "Skipping unprefixed entry: $entry"
        return 0
    fi

    local prefix="${entry%%:*}"
    local tool="${entry#*:}"

    case "$prefix" in
        npm)
            # Check Node.js availability first
            if ! command -v node &>/dev/null; then
                log_warn "Node.js not found, skipping npm tool: $tool"
                return 1
            fi

            # Extract binary name from npm package for idempotent check
            local bin_name
            bin_name=$(basename "$tool")

            # Check if already installed globally
            if npm list -g "$tool" &>/dev/null; then
                log_debug "Already installed: $tool"
                return 0
            fi

            if [[ "${DRY_RUN:-}" == "true" ]]; then
                log_info "[DRY_RUN] Would npm install -g: $tool"
                return 0
            fi

            log_info "Installing npm tool: $tool"
            if npm install -g "$tool"; then
                log_ok "Installed: $tool"
                return 0
            else
                log_warn "Failed to install: $tool"
                return 1
            fi
            ;;

        curl)
            case "$tool" in
                ollama)
                    # Idempotent check
                    if command -v ollama &>/dev/null; then
                        log_debug "Already installed: ollama"
                        return 0
                    fi

                    if [[ "${DRY_RUN:-}" == "true" ]]; then
                        log_info "[DRY_RUN] Would curl-install: ollama"
                        return 0
                    fi

                    log_info "Installing ollama via official install script..."
                    if curl -fsSL https://ollama.com/install.sh | sh; then
                        log_ok "Installed: ollama"
                        return 0
                    else
                        log_warn "Failed to install: ollama"
                        return 1
                    fi
                    ;;
                *)
                    log_debug "Skipping unknown curl tool: $tool"
                    return 0
                    ;;
            esac
            ;;

        npx|uv)
            log_debug "Skipping $prefix tool (runs on demand): $tool"
            return 0
            ;;

        *)
            log_debug "Skipping unknown prefix: $prefix for $tool"
            return 0
            ;;
    esac
}

#######################################
# offer_ollama_model()
# Offer to download a base model in interactive mode
#######################################
offer_ollama_model() {
    # Skip in non-interactive mode
    if [[ "${NONINTERACTIVE:-}" == "true" || ! -t 0 ]]; then
        return 0
    fi

    # Check if ollama is available
    if ! command -v ollama &>/dev/null; then
        return 0
    fi

    echo ""
    echo "Download a base model for Ollama?"
    echo "  1) llama3.2 (lightweight)"
    echo "  2) Skip"
    read -rp "Select [1-2]: " choice

    case "$choice" in
        1)
            log_info "Downloading llama3.2 model..."
            if ollama pull llama3.2; then
                log_ok "Model downloaded: llama3.2"
            else
                log_warn "Failed to download llama3.2 model"
            fi
            ;;
        *)
            log_debug "Skipping model download"
            ;;
    esac
}

#######################################
# show_ai_summary()
# Display API key configuration info
#######################################
show_ai_summary() {
    echo ""
    log_info "Configure API keys for AI tools:"
    log_info "  ANTHROPIC_API_KEY - for Claude Code"
    log_info "  OPENAI_API_KEY   - for Codex"
    log_info "  GEMINI_API_KEY   - for Gemini CLI"
    echo ""
}

#######################################
# Cleanup and failure tracking
#######################################
declare -a FAILED_ITEMS=()

cleanup() {
    local exit_code=$?
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed tools: ${FAILED_ITEMS[*]}"
    fi
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit $exit_code
}
trap cleanup EXIT INT TERM

#######################################
# Main
#######################################
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then

    log_banner "AI Coding Tools"

    # Interactive selection
    show_category_menu "AI Coding Tools" "claude-code, codex, gemini-cli, ollama"
    menu_choice=$?

    case "$menu_choice" in
        2)
            log_info "Skipping AI tools installation"
            show_ai_summary
            exit 0
            ;;
    esac

    # Load packages from ai-tools.txt
    if ! load_packages "ai-tools.txt"; then
        log_error "Failed to load ai-tools.txt"
        exit 0
    fi

    log_debug "Loaded ${#PACKAGES[@]} entries from ai-tools.txt"

    # Build list of installable entries (npm: and curl: only)
    declare -a installable=()
    for entry in "${PACKAGES[@]}"; do
        if [[ "$entry" == npm:* || "$entry" == curl:* ]]; then
            installable+=("$entry")
        fi
    done

    # Determine which entries to install
    declare -a to_install=()

    if [[ $menu_choice -eq 0 ]]; then
        # Install all installable entries
        to_install=("${installable[@]}")
    elif [[ $menu_choice -eq 1 ]]; then
        # Choose individually (only installable entries shown)
        for entry in "${installable[@]}"; do
            local_name="${entry#*:}"
            if ask_tool "$local_name"; then
                to_install+=("$entry")
            fi
        done
    fi

    # Install selected entries
    local installed_count=0
    local failed_count=0

    for entry in "${to_install[@]}"; do
        if install_ai_tool "$entry"; then
            installed_count=$((installed_count + 1))
        else
            record_failure "$entry"
            failed_count=$((failed_count + 1))
        fi
    done

    # Offer ollama model download
    offer_ollama_model

    # Show API key info
    show_ai_summary

    # Final summary
    if [[ $failed_count -gt 0 ]]; then
        log_warn "Completed with ${failed_count} failures"
    else
        log_ok "AI tools installation complete"
    fi

    # Always exit 0 (per Phase 1 decision)
    exit 0

fi
