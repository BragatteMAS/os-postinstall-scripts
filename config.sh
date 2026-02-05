#!/usr/bin/env bash
# config.sh - User configuration for os-postinstall-scripts
# Edit this file to customize your installation

# Prevent multiple sourcing
[[ -n "${_CONFIG_SOURCED:-}" ]] && return 0
readonly _CONFIG_SOURCED=1

#===============================================
# INSTALLATION PROFILE
#===============================================
# Options: minimal, developer, full
# - minimal: Essential system packages only
# - developer: System + development tools (cargo, npm)
# - full: Everything including AI/MCP tools
DEFAULT_PROFILE="${DEFAULT_PROFILE:-developer}"

#===============================================
# BEHAVIOR FLAGS
#===============================================
# Set to "true" to show what would be done without making changes
DRY_RUN="${DRY_RUN:-false}"

# Set to "true" for verbose output with timestamps
VERBOSE="${VERBOSE:-false}"

# Set to "true" to skip confirmation prompts
UNATTENDED="${UNATTENDED:-false}"

#===============================================
# CUSTOMIZATION
#===============================================
# Add packages to this array to install additional packages
# These are appended to the profile's package list
EXTRA_PACKAGES=()

# Skip these packages even if they're in the profile
SKIP_PACKAGES=()

#===============================================
# PATHS (usually no need to change)
#===============================================
# Base directory (auto-detected)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="${SCRIPT_DIR}"
readonly SRC_DIR="${PROJECT_ROOT}/src"
readonly DATA_DIR="${PROJECT_ROOT}/data"
readonly CORE_DIR="${SRC_DIR}/core"

# Export for use by other scripts
export PROJECT_ROOT SRC_DIR DATA_DIR CORE_DIR
export DEFAULT_PROFILE DRY_RUN VERBOSE UNATTENDED
