#!/bin/bash
# utils/package-manager-safety.sh
# Safe APT operations module - implements ADR-005
# 
# This module provides safe wrappers for package manager operations
# to prevent system corruption from forced lock removal
#
# Author: OS Post-Install Scripts Team
# License: GPL v3

set -euo pipefail

# Source logging module if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/logging.sh" ]]; then
    source "${SCRIPT_DIR}/logging.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_warning() { echo "[WARNING] $*" >&2; }
fi

# Constants
readonly APT_LOCK_TIMEOUT=${APT_LOCK_TIMEOUT:-300}  # 5 minutes default
readonly APT_RETRY_COUNT=${APT_RETRY_COUNT:-3}
readonly APT_LOCK_CHECK_INTERVAL=${APT_LOCK_CHECK_INTERVAL:-5}
readonly VALID_PACKAGE_REGEX='^[a-zA-Z0-9._+-]+$'

# Lock files to monitor
readonly APT_LOCK_FILES=(
    "/var/lib/dpkg/lock"
    "/var/lib/dpkg/lock-frontend"
    "/var/cache/apt/archives/lock"
    "/var/lib/apt/lists/lock"
)

# Wait for APT locks to be released
# Returns: 0 on success, 1 on timeout
wait_for_apt() {
    local waited=0
    local any_locked=true
    
    log_info "Checking for APT locks..."
    
    while [[ $any_locked == true ]] && [[ $waited -lt $APT_LOCK_TIMEOUT ]]; do
        any_locked=false
        
        for lock_file in "${APT_LOCK_FILES[@]}"; do
            if fuser "$lock_file" >/dev/null 2>&1; then
                any_locked=true
                log_info "APT lock detected on $lock_file, waiting... ($waited/$APT_LOCK_TIMEOUT seconds)"
                break
            fi
        done
        
        if [[ $any_locked == true ]]; then
            sleep "$APT_LOCK_CHECK_INTERVAL"
            waited=$((waited + APT_LOCK_CHECK_INTERVAL))
        fi
    done
    
    if [[ $waited -ge $APT_LOCK_TIMEOUT ]]; then
        log_error "APT lock timeout after $APT_LOCK_TIMEOUT seconds"
        log_error "Another process may be using the package manager"
        log_error "Please check with: sudo lsof /var/lib/dpkg/lock-frontend"
        return 1
    fi
    
    log_info "APT locks are free, proceeding..."
    return 0
}

# Validate package name to prevent injection
# Args: $1 - package name
# Returns: 0 if valid, 1 if invalid
validate_package_name() {
    local package="$1"
    
    if [[ -z "$package" ]]; then
        log_error "Package name cannot be empty"
        return 1
    fi
    
    if [[ ! "$package" =~ $VALID_PACKAGE_REGEX ]]; then
        log_error "Invalid package name: $package"
        log_error "Package names must contain only letters, numbers, dots, plus, minus, and underscores"
        return 1
    fi
    
    return 0
}

# Update package lists safely
# Returns: 0 on success, 1 on failure
safe_apt_update() {
    local attempt=1
    
    log_info "Updating package lists safely..."
    
    while [[ $attempt -le $APT_RETRY_COUNT ]]; do
        if wait_for_apt; then
            log_info "Attempt $attempt/$APT_RETRY_COUNT: Running apt-get update..."
            
            if sudo apt-get update; then
                log_info "Package lists updated successfully"
                return 0
            else
                log_error "apt-get update failed on attempt $attempt"
            fi
        fi
        
        if [[ $attempt -lt $APT_RETRY_COUNT ]]; then
            log_warning "Retrying in $((attempt * 10)) seconds..."
            sleep $((attempt * 10))
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to update package lists after $APT_RETRY_COUNT attempts"
    return 1
}

# Install package with retry and validation
# Args: $1 - package name
# Returns: 0 on success, 1 on failure
safe_apt_install() {
    local package="$1"
    local attempt=1
    
    # Validate package name first
    if ! validate_package_name "$package"; then
        return 1
    fi
    
    log_info "Installing package: $package"
    
    # Check if already installed
    if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
        log_info "Package $package is already installed"
        return 0
    fi
    
    while [[ $attempt -le $APT_RETRY_COUNT ]]; do
        if wait_for_apt; then
            log_info "Attempt $attempt/$APT_RETRY_COUNT: Installing $package..."
            
            if sudo apt-get install -y "$package"; then
                log_info "Package $package installed successfully"
                log_package_operation "install" "$package" "success"
                return 0
            else
                log_error "Failed to install $package on attempt $attempt"
                log_package_operation "install" "$package" "failed"
            fi
        fi
        
        if [[ $attempt -lt $APT_RETRY_COUNT ]]; then
            log_warning "Retrying in $((attempt * 10)) seconds..."
            sleep $((attempt * 10))
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to install $package after $APT_RETRY_COUNT attempts"
    return 1
}

# Remove package safely
# Args: $1 - package name
# Returns: 0 on success, 1 on failure
safe_apt_remove() {
    local package="$1"
    
    # Validate package name first
    if ! validate_package_name "$package"; then
        return 1
    fi
    
    log_info "Removing package: $package"
    
    # Check if installed
    if ! dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
        log_info "Package $package is not installed"
        return 0
    fi
    
    if wait_for_apt; then
        if sudo apt-get remove -y "$package"; then
            log_info "Package $package removed successfully"
            log_package_operation "remove" "$package" "success"
            return 0
        else
            log_error "Failed to remove $package"
            log_package_operation "remove" "$package" "failed"
            return 1
        fi
    fi
    
    return 1
}

# Install multiple packages
# Args: $@ - package names
# Returns: 0 if all succeed, 1 if any fail
safe_apt_install_multiple() {
    local failed_packages=()
    local package
    
    for package in "$@"; do
        if ! safe_apt_install "$package"; then
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_error "Failed to install packages: ${failed_packages[*]}"
        return 1
    fi
    
    log_info "All packages installed successfully"
    return 0
}

# Log package operations for audit trail
# Args: $1 - operation, $2 - package, $3 - status
log_package_operation() {
    local operation="$1"
    local package="$2"
    local status="$3"
    local log_dir="/var/log/os-postinstall"
    local log_file="$log_dir/package-operations.log"
    
    # Create log directory if it doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        sudo mkdir -p "$log_dir"
        sudo chmod 755 "$log_dir"
    fi
    
    # Log the operation
    echo "$(date -Iseconds)|$USER|$operation|$package|$status" | sudo tee -a "$log_file" >/dev/null
}

# Export functions for use by other scripts
export -f wait_for_apt
export -f validate_package_name
export -f safe_apt_update
export -f safe_apt_install
export -f safe_apt_remove
export -f safe_apt_install_multiple
export -f log_package_operation