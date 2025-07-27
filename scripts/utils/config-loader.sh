#!/usr/bin/env bash
# config-loader.sh - Load and parse YAML configuration files
# Provides simple YAML parsing for shell scripts

set -euo pipefail

# Check bash version for associative array support
if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    echo "Error: This script requires Bash 4.0 or higher" >&2
    echo "Your version: $BASH_VERSION" >&2
    echo "" >&2
    echo "To upgrade on macOS:" >&2
    echo "  brew install bash" >&2
    echo "  ./scripts/setup/upgrade-bash.sh" >&2
    exit 1
fi

# Global configuration variables
declare -A CONFIG
CONFIG_FILE=""
CONFIG_LOADED=false

# Default configuration paths
DEFAULT_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/configs/settings"
DEFAULT_CONFIG_FILE="$DEFAULT_CONFIG_DIR/settings.yaml"
DEFAULT_CONFIG_TEMPLATE="$DEFAULT_CONFIG_DIR/settings.yaml.default"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Simple YAML parser for flat and nested structures
# Note: This is a basic parser that handles common cases
parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    local fs=$(echo @|tr @ '\034')
    
    # First remove comments, then parse
    sed 's/#.*$//' $1 | sed -ne "s|^\($s\):|\1|" \
         -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            # Trim whitespace from value
            gsub(/^[ \t]+|[ \t]+$/, "", $3);
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'", vn, $2, $3);
        }
    }'
}

# Load configuration from YAML file
load_config() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    # Check if config file exists, if not use default template
    if [[ ! -f "$config_file" ]]; then
        if [[ -f "$DEFAULT_CONFIG_TEMPLATE" ]]; then
            echo -e "${YELLOW}Config file not found. Using default template.${NC}" >&2
            config_file="$DEFAULT_CONFIG_TEMPLATE"
        else
            echo -e "${RED}Error: No configuration file found at $config_file${NC}" >&2
            return 1
        fi
    fi
    
    CONFIG_FILE="$config_file"
    echo -e "${BLUE}Loading configuration from: $CONFIG_FILE${NC}" >&2
    
    # Parse YAML and load into associative array
    eval $(parse_yaml "$CONFIG_FILE" "CONFIG_")
    
    # Perform variable substitution
    substitute_variables
    
    CONFIG_LOADED=true
    echo -e "${GREEN}Configuration loaded successfully.${NC}" >&2
}

# Substitute environment variables in config values
substitute_variables() {
    local key value new_value
    
    for key in "${!CONFIG_@}"; do
        value="${!key}"
        # Only substitute environment variables, not internal references
        if [[ "$value" =~ \$\{[A-Z_]+.*\} ]]; then
            new_value=$(echo "$value" | envsubst)
            eval "$key=\"$new_value\""
        fi
    done
}

# Get configuration value by key (dot notation)
get_config() {
    local key="$1"
    local default="${2:-}"
    
    # Convert dot notation to underscore notation
    local config_key="CONFIG_${key//./_}"
    
    # Return value or default
    if [[ -v "$config_key" ]]; then
        echo "${!config_key}"
    else
        echo "$default"
    fi
}

# Check if a feature is enabled
is_feature_enabled() {
    local feature="$1"
    
    # First try with .enabled suffix
    local enabled=$(get_config "features.$feature.enabled" "")
    
    # If empty, try without .enabled suffix
    if [[ -z "$enabled" ]]; then
        enabled=$(get_config "features.$feature" "false")
    fi
    
    [[ "$enabled" == "true" ]] || [[ "$enabled" == "yes" ]] || [[ "$enabled" == "1" ]]
}

# Get list values (simple array handling)
get_config_list() {
    local prefix="$1"
    local values=()
    
    # Find all keys with the prefix
    for key in "${!CONFIG_@}"; do
        if [[ "$key" =~ ^CONFIG_${prefix//./_}_[0-9]+$ ]]; then
            values+=("${!key}")
        fi
    done
    
    printf '%s\n' "${values[@]}"
}

# Create default configuration if it doesn't exist
create_default_config() {
    local target="${1:-$DEFAULT_CONFIG_FILE}"
    
    if [[ -f "$target" ]]; then
        echo -e "${YELLOW}Configuration already exists at: $target${NC}"
        return 0
    fi
    
    # Ensure directory exists
    mkdir -p "$(dirname "$target")"
    
    # Copy default template
    if [[ -f "$DEFAULT_CONFIG_TEMPLATE" ]]; then
        cp "$DEFAULT_CONFIG_TEMPLATE" "$target"
        echo -e "${GREEN}Created configuration file at: $target${NC}"
        echo -e "${BLUE}Please edit this file to customize your installation.${NC}"
    else
        echo -e "${RED}Error: Default template not found at $DEFAULT_CONFIG_TEMPLATE${NC}"
        return 1
    fi
}

# Print current configuration (for debugging)
print_config() {
    echo "Current Configuration:"
    echo "====================="
    for key in "${!CONFIG_@}"; do
        echo "$key = ${!key}"
    done | sort | sed 's/CONFIG_/  /'
}

# Validate configuration
validate_config() {
    local errors=0
    
    echo "Validating configuration..."
    
    # Check required fields
    if [[ -z "$(get_config 'user.name')" ]]; then
        echo -e "${RED}Error: user.name is required${NC}"
        ((errors++))
    fi
    
    # Check profile exists
    local profile=$(get_config 'features.shell.profile' 'standard')
    if [[ ! "$profile" =~ ^(minimal|standard|full)$ ]]; then
        echo -e "${RED}Error: Invalid shell profile: $profile${NC}"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}Configuration is valid.${NC}"
        return 0
    else
        echo -e "${RED}Configuration has $errors errors.${NC}"
        return 1
    fi
}

# Export functions for use in other scripts
export -f load_config
export -f get_config
export -f is_feature_enabled
export -f get_config_list
export -f create_default_config
export -f print_config
export -f validate_config