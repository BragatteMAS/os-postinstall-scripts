#!/usr/bin/env bash
#===============================================
# os-postinstall-scripts - Setup Entry Point
#===============================================
# Usage: ./setup.sh [action|profile]
#
# Actions:
#   dotfiles - Install dotfiles symlinks and zsh plugins
#   unlink   - Remove dotfiles symlinks and restore backups
#
# Profiles: minimal, developer, full
#
# This script detects your platform and runs the appropriate installer.
#
# Environment variables:
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

# Setup colors and error handling
setup_colors
setup_error_handling

#-----------------------------------------------
# Main
#-----------------------------------------------
main() {
    # Handle help flag and special actions before anything else
    case "${1:-}" in
        -h|--help)
            echo "Usage: ./setup.sh [action|profile]"
            echo ""
            echo "Actions:"
            echo "  dotfiles - Install dotfiles symlinks and zsh plugins"
            echo "  unlink   - Remove dotfiles symlinks and restore backups"
            echo ""
            echo "Profiles:"
            echo "  minimal    - Essential tools only"
            echo "  developer  - Development environment (default)"
            echo "  full       - Everything"
            echo ""
            echo "Environment variables:"
            echo "  DRY_RUN=true    - Show what would be done"
            echo "  VERBOSE=true    - Enable debug output"
            echo "  UNATTENDED=true - Skip confirmation prompts"
            exit 0
            ;;
        dotfiles)
            source "${SCRIPT_DIR}/src/installers/dotfiles-install.sh"
            install_dotfiles
            exit $?
            ;;
        unlink)
            source "${SCRIPT_DIR}/src/installers/dotfiles-install.sh"
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

    # Run verification sequence
    verify_all

    # Dispatch to platform-specific handler
    case "${DETECTED_OS}" in
        linux)
            local linux_main="${SRC_DIR}/platforms/linux/main.sh"
            if [[ -f "$linux_main" ]]; then
                log_info "Running Linux setup..."
                bash "$linux_main" "$profile"
            else
                log_error "Linux platform handler not found: $linux_main"
                return 1
            fi
            ;;
        macos)
            local macos_main="${SRC_DIR}/platforms/macos/main.sh"
            if [[ -f "$macos_main" ]]; then
                log_info "Running macOS setup..."
                bash "$macos_main" "$profile"
            else
                log_warn "macOS platform handler not yet implemented"
                log_info "See: .planning/ROADMAP.md Phase 4"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported platform: ${DETECTED_OS}"
            return 1
            ;;
    esac

    # Show summary
    show_failure_summary
    log_banner "Setup Complete"
}

# Run main with all arguments
main "$@"
