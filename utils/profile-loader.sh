#!/bin/bash
# Profile loader for OS Post-Install Scripts
# Loads and parses YAML profile files for customized installations

set -euo pipefail

# Source logging if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/logging.sh" ]]; then
    # Don't log to file for profile operations
    export LOG_TO_FILE=false
    source "${SCRIPT_DIR}/logging.sh"
else
    # Fallback logging
    log_info() { echo "[INFO] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
fi

# Profile directory
PROFILE_DIR="${PROFILE_DIR:-$(cd "$SCRIPT_DIR/../profiles" && pwd)}"

# List available profiles
list_profiles() {
    log_info "Available profiles:"
    echo
    
    if [[ -d "$PROFILE_DIR" ]]; then
        for profile in "$PROFILE_DIR"/*.yaml "$PROFILE_DIR"/*.yml; do
            if [[ -f "$profile" ]]; then
                local name=$(basename "$profile" | sed 's/\.[ya]ml$//')
                local desc=$(grep -m1 "^description:" "$profile" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
                printf "  %-20s - %s\n" "$name" "${desc:-No description}"
            fi
        done
    else
        log_error "Profile directory not found: $PROFILE_DIR"
        return 1
    fi
    echo
}

# Load a profile
load_profile() {
    local profile_name="$1"
    local profile_file=""
    
    # Check for exact file first
    if [[ -f "$profile_name" ]]; then
        profile_file="$profile_name"
    # Check in profile directory with .yaml
    elif [[ -f "$PROFILE_DIR/${profile_name}.yaml" ]]; then
        profile_file="$PROFILE_DIR/${profile_name}.yaml"
    # Check with .yml
    elif [[ -f "$PROFILE_DIR/${profile_name}.yml" ]]; then
        profile_file="$PROFILE_DIR/${profile_name}.yml"
    else
        log_error "Profile not found: $profile_name"
        list_profiles
        return 1
    fi
    
    log_info "Loading profile: $profile_file"
    
    # Validate profile exists and is readable
    if [[ ! -r "$profile_file" ]]; then
        log_error "Cannot read profile file: $profile_file"
        return 1
    fi
    
    # Export profile path for other scripts
    export ACTIVE_PROFILE="$profile_file"
    export ACTIVE_PROFILE_NAME="$(basename "$profile_file" | sed 's/\.[ya]ml$//')"
    
    log_success "Profile loaded: $ACTIVE_PROFILE_NAME"
    return 0
}

# Parse profile section
# Usage: parse_profile_section "packages.version_control"
parse_profile_section() {
    local section="$1"
    local profile="${ACTIVE_PROFILE:-}"
    
    if [[ -z "$profile" ]]; then
        log_error "No profile loaded"
        return 1
    fi
    
    # Simple YAML parser for array sections
    # This handles the indented list format
    local in_section=false
    local indent_level=0
    local current_path=""
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Calculate indent level
        local stripped="${line#"${line%%[![:space:]]*}"}"
        local current_indent=$(( ${#line} - ${#stripped} ))
        
        # Check if we're entering our section
        if [[ "$line" =~ ^[[:space:]]*${section}:[[:space:]]*$ ]]; then
            in_section=true
            indent_level=$current_indent
            continue
        fi
        
        # If we're in our section
        if [[ "$in_section" == true ]]; then
            # Check if we've left the section (less or equal indentation)
            if [[ $current_indent -le $indent_level ]] && [[ "$line" =~ ^[[:space:]]*[^-] ]]; then
                break
            fi
            
            # Output list items
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
        fi
    done < "$profile"
}

# Get profile metadata
get_profile_metadata() {
    local key="$1"
    local profile="${ACTIVE_PROFILE:-}"
    
    if [[ -z "$profile" ]]; then
        log_error "No profile loaded"
        return 1
    fi
    
    grep -m1 "^${key}:" "$profile" 2>/dev/null | cut -d: -f2- | sed 's/^ *//'
}

# Get all packages from a profile
get_profile_packages() {
    local profile="${ACTIVE_PROFILE:-}"
    
    if [[ -z "$profile" ]]; then
        log_error "No profile loaded"
        return 1
    fi
    
    # Get all package sections
    local sections=$(grep -E "^[[:space:]]{2}[a-z_]+:$" "$profile" | sed 's/://g' | sed 's/^[[:space:]]*//')
    
    for section in $sections; do
        parse_profile_section "packages.$section"
    done
}

# Check if package should be installed
should_install_package() {
    local package="$1"
    local profile="${ACTIVE_PROFILE:-}"
    
    if [[ -z "$profile" ]]; then
        # No profile loaded, install everything
        return 0
    fi
    
    # Check if package is in the profile
    if get_profile_packages | grep -q "^${package}$"; then
        return 0
    else
        return 1
    fi
}

# Show profile details
show_profile_details() {
    local profile_name="${1:-$ACTIVE_PROFILE_NAME}"
    
    if [[ -z "$profile_name" ]]; then
        log_error "No profile specified"
        return 1
    fi
    
    # Load the profile first
    if ! load_profile "$profile_name"; then
        return 1
    fi
    
    echo
    echo "Profile: $ACTIVE_PROFILE_NAME"
    echo "========================================="
    echo "Description: $(get_profile_metadata 'description')"
    echo "Author: $(get_profile_metadata 'author')"
    echo "Version: $(get_profile_metadata 'version')"
    echo
    echo "Packages to install:"
    echo "-------------------"
    
    # Get package categories
    local sections=$(grep -E "^[[:space:]]{2}[a-z_]+:$" "$ACTIVE_PROFILE" | sed 's/://g' | sed 's/^[[:space:]]*//')
    
    for section in $sections; do
        echo
        echo "[$section]"
        parse_profile_section "packages.$section" | while read -r pkg; do
            echo "  - $pkg"
        done
    done
    
    echo
}

# Export functions
export -f list_profiles
export -f load_profile
export -f parse_profile_section
export -f get_profile_metadata
export -f get_profile_packages
export -f should_install_package
export -f show_profile_details