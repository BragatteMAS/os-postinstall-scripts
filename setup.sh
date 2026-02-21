#!/usr/bin/env bash
#===============================================
# os-postinstall-scripts - Setup Entry Point
#===============================================
# Usage: ./setup.sh [options] [action|profile]
#
# Options:
#   -n, --dry-run     Show what would be done without making changes
#   -v, --verbose     Enable debug output with timestamps
#   -y, --unattended  Skip confirmation prompts
#   -h, --help        Show this help message
#
# Actions:
#   dotfiles - Install dotfiles symlinks and zsh plugins
#   unlink   - Remove dotfiles symlinks and restore backups
#
# Profiles: minimal, developer, full
#
# This script detects your platform and runs the appropriate installer.
#
# Environment variables (alternative to flags):
#   DRY_RUN=true    - Show what would be done
#   VERBOSE=true    - Enable debug output
#   UNATTENDED=true - Skip confirmation prompts
#===============================================

set -o pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

# Load configuration
source "${SCRIPT_DIR}/config.sh"

# Load core utilities
source "${CORE_DIR}/logging.sh"
source "${CORE_DIR}/platform.sh"
source "${CORE_DIR}/errors.sh"
source "${CORE_DIR}/progress.sh"

# Setup colors and error handling
setup_colors
setup_error_handling

# Enable cross-process failure tracking via shared file
export FAILURE_LOG="${TEMP_DIR}/failures.log"
touch "$FAILURE_LOG"

# Track worst exit code from child processes
_worst_exit=0

# Override cleanup trap to prevent double summary on normal exit
cleanup() {
    if [[ -z "${_SUMMARY_SHOWN:-}" ]]; then
        if [[ -n "${FAILURE_LOG:-}" && -f "$FAILURE_LOG" && -s "$FAILURE_LOG" ]]; then
            log_warn "Failures detected:"
            while IFS= read -r item; do
                echo "  - $item"
            done < "$FAILURE_LOG"
        else
            show_failure_summary
        fi
    fi
    cleanup_temp_dir
    exit "${_worst_exit:-0}"
}
trap cleanup EXIT INT TERM

#-----------------------------------------------
# Parse CLI flags
#-----------------------------------------------
parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                export DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                export VERBOSE=true
                shift
                ;;
            -y|--unattended)
                export UNATTENDED=true
                export NONINTERACTIVE=true
                shift
                ;;
            -h|--help)
                # Help is handled inside main(), just pass through
                break
                ;;
            -*)
                echo "[ERROR] Unknown option: $1" >&2
                echo "Usage: ./setup.sh [options] [action|profile]" >&2
                echo "Run './setup.sh --help' for details" >&2
                exit 1
                ;;
            *)
                break  # Non-flag argument = action or profile
                ;;
        esac
    done
    # Return remaining args for main()
    REMAINING_ARGS=("$@")
}

#-----------------------------------------------
# Main
#-----------------------------------------------
main() {
    # Start duration timer
    SECONDS=0

    # Handle help flag and special actions before anything else
    case "${1:-}" in
        -h|--help)
            echo "Usage: ./setup.sh [options] [action|profile]"
            echo ""
            echo "Options:"
            echo "  -n, --dry-run     Show what would be done without making changes"
            echo "  -v, --verbose     Enable debug output with timestamps"
            echo "  -y, --unattended  Skip confirmation prompts"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Actions:"
            echo "  dotfiles  Install dotfiles symlinks and zsh plugins"
            echo "  unlink    Remove dotfiles symlinks and restore backups"
            echo ""
            echo "Profiles:"
            echo "  minimal    Essential tools only"
            echo "  developer  Development environment (default)"
            echo "  full       Everything"
            echo ""
            echo "Environment variables (alternative to flags):"
            echo "  DRY_RUN=true    - Show what would be done"
            echo "  VERBOSE=true    - Enable debug output"
            echo "  UNATTENDED=true - Skip confirmation prompts"
            echo ""
            echo "Examples:"
            echo "  ./setup.sh --dry-run developer"
            echo "  ./setup.sh -n -v full"
            echo "  ./setup.sh --unattended minimal"
            exit 0
            ;;
        dotfiles)
            source "${SCRIPT_DIR}/src/install/dotfiles-install.sh"
            install_dotfiles
            exit $?
            ;;
        unlink)
            source "${SCRIPT_DIR}/src/install/dotfiles-install.sh"
            remove_dotfiles
            exit $?
            ;;
    esac

    local profile="${1:-$DEFAULT_PROFILE}"

    log_banner "OS Post-Install Scripts"
    log_info "Profile: $profile"

    # Detect platform
    detect_platform
    log_ok "Detected: ${DETECTED_OS} ${DETECTED_VERSION:-} (${DETECTED_PKG:-unknown})"

    # Run verification sequence (defensive check for future changes)
    verify_all
    if [[ $? -ne 0 ]]; then
        _worst_exit="${EXIT_CRITICAL:-2}"
    fi

    # Dispatch to platform-specific handler
    case "${DETECTED_OS}" in
        linux)
            local linux_main="${SRC_DIR}/platforms/linux/main.sh"
            if [[ -f "$linux_main" ]]; then
                log_info "Running Linux setup..."
                bash "$linux_main" "$profile"
                rc=$?
                [[ $rc -gt $_worst_exit ]] && _worst_exit=$rc
            else
                log_error "Linux platform handler not found: $linux_main"
                _worst_exit="${EXIT_CRITICAL:-2}"
                return 1
            fi
            ;;
        macos)
            local macos_main="${SRC_DIR}/platforms/macos/main.sh"
            if [[ -f "$macos_main" ]]; then
                log_info "Running macOS setup..."
                bash "$macos_main" "$profile"
                rc=$?
                [[ $rc -gt $_worst_exit ]] && _worst_exit=$rc
            else
                log_warn "macOS platform handler not yet implemented"
                log_info "See: .planning/ROADMAP.md Phase 4"
                _worst_exit="${EXIT_CRITICAL:-2}"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported platform: ${DETECTED_OS}"
            _worst_exit="${EXIT_CRITICAL:-2}"
            return 1
            ;;
    esac

    # Offer dotfiles installation (interactive only)
    if [[ "${UNATTENDED:-}" != "true" ]] && [[ -t 0 ]]; then
        echo ""
        read -rp "Configure dotfiles (zshrc, gitconfig, starship)? [y/N] " answer
        if [[ "$answer" =~ ^[yYsS]$ ]]; then
            source "${SCRIPT_DIR}/src/install/dotfiles-install.sh"
            install_dotfiles
        fi
    fi

    # Show completion summary
    show_completion_summary "$profile" "${DETECTED_OS:-unknown}"
    _SUMMARY_SHOWN=1
}

# Parse flags, then run main with remaining arguments
parse_flags "$@"
main "${REMAINING_ARGS[@]}"
