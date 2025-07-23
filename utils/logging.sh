#!/bin/bash
# utils/logging.sh
# Centralized logging module for OS Post-Install Scripts
#
# Provides consistent logging across all scripts with:
# - Multiple log levels (INFO, WARNING, ERROR, DEBUG)
# - Colored output for terminals
# - File logging support
# - Timestamp formatting
#
# Author: OS Post-Install Scripts Team
# License: GPL v3

set -euo pipefail

# Default log settings
LOG_LEVEL=${LOG_LEVEL:-"INFO"}
LOG_FILE=${LOG_FILE:-"/var/log/os-postinstall/install.log"}
LOG_TO_FILE=${LOG_TO_FILE:-true}
LOG_TO_STDOUT=${LOG_TO_STDOUT:-true}
LOG_USE_COLOR=${LOG_USE_COLOR:-true}

# Color codes
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_GRAY='\033[0;90m'

# Log level values for comparison
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARNING"]=2
    ["ERROR"]=3
)

# Initialize logging
init_logging() {
    # Create log directory if logging to file
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        local log_dir
        log_dir="$(dirname "$LOG_FILE")"
        
        if [[ ! -d "$log_dir" ]]; then
            sudo mkdir -p "$log_dir"
            sudo chmod 755 "$log_dir"
        fi
        
        # Create log file if it doesn't exist
        if [[ ! -f "$LOG_FILE" ]]; then
            sudo touch "$LOG_FILE"
            sudo chmod 644 "$LOG_FILE"
        fi
    fi
    
    # Detect if output is a terminal for color support
    if [[ ! -t 1 ]] || [[ ! -t 2 ]]; then
        LOG_USE_COLOR=false
    fi
}

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Check if we should log at this level
should_log() {
    local msg_level=$1
    local current_level=${LOG_LEVELS[$LOG_LEVEL]:-1}
    local message_level=${LOG_LEVELS[$msg_level]:-1}
    
    [[ $message_level -ge $current_level ]]
}

# Core logging function
log_message() {
    local level=$1
    local message=$2
    local color=${3:-$COLOR_RESET}
    
    # Check if we should log this message
    if ! should_log "$level"; then
        return 0
    fi
    
    local timestamp
    timestamp=$(get_timestamp)
    
    # Format message
    local formatted_msg="[$timestamp] [$level] $message"
    
    # Log to stdout/stderr
    if [[ "$LOG_TO_STDOUT" == "true" ]]; then
        if [[ "$LOG_USE_COLOR" == "true" && -n "$color" ]]; then
            if [[ "$level" == "ERROR" ]]; then
                echo -e "${color}${formatted_msg}${COLOR_RESET}" >&2
            else
                echo -e "${color}${formatted_msg}${COLOR_RESET}"
            fi
        else
            if [[ "$level" == "ERROR" ]]; then
                echo "$formatted_msg" >&2
            else
                echo "$formatted_msg"
            fi
        fi
    fi
    
    # Log to file
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        echo "$formatted_msg" | sudo tee -a "$LOG_FILE" >/dev/null
    fi
}

# Convenience logging functions
log_debug() {
    log_message "DEBUG" "$*" "$COLOR_GRAY"
}

log_info() {
    log_message "INFO" "$*" "$COLOR_BLUE"
}

log_success() {
    log_message "INFO" "✓ $*" "$COLOR_GREEN"
}

log_warning() {
    log_message "WARNING" "⚠ $*" "$COLOR_YELLOW"
}

log_error() {
    log_message "ERROR" "✗ $*" "$COLOR_RED"
}

# Log a section header
log_section() {
    local title=$1
    local border_char=${2:-"="}
    local border_length=${3:-60}
    
    local border
    border=$(printf '%*s' "$border_length" | tr ' ' "$border_char")
    
    log_info ""
    log_info "$border"
    log_info "$title"
    log_info "$border"
    log_info ""
}

# Log command execution
log_command() {
    local cmd=$1
    log_debug "Executing: $cmd"
}

# Log file operations
log_file_operation() {
    local operation=$1
    local file=$2
    local status=${3:-"success"}
    
    case $operation in
        "create")
            if [[ "$status" == "success" ]]; then
                log_success "Created file: $file"
            else
                log_error "Failed to create file: $file"
            fi
            ;;
        "modify")
            if [[ "$status" == "success" ]]; then
                log_info "Modified file: $file"
            else
                log_error "Failed to modify file: $file"
            fi
            ;;
        "delete")
            if [[ "$status" == "success" ]]; then
                log_info "Deleted file: $file"
            else
                log_error "Failed to delete file: $file"
            fi
            ;;
        *)
            log_warning "Unknown file operation: $operation on $file"
            ;;
    esac
}

# Progress logging
log_progress() {
    local current=$1
    local total=$2
    local task=${3:-"Processing"}
    
    local percentage=$((current * 100 / total))
    log_info "$task: $current/$total ($percentage%)"
}

# Initialize logging on source
init_logging

# Export all functions
export -f get_timestamp
export -f should_log
export -f log_message
export -f log_debug
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_section
export -f log_command
export -f log_file_operation
export -f log_progress