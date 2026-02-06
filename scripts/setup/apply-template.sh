#!/usr/bin/env bash
#######################################
# Script: apply-template.sh
# Description: Applies pre-configured templates for roles/use cases
# Author: Bragatte
# Date: 2025-02-05
#######################################

set -euo pipefail
IFS=$'\n\t'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source logging utilities (SSoT)
source "$SCRIPT_DIR/../utils/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

# Configuration
TEMPLATES_DIR="$REPO_ROOT/configs/templates"
CONFIG_DIR="$REPO_ROOT/configs/settings"
BACKUP_DIR="$HOME/.config/os-postinstall/backups"

#######################################
# Display usage information
#######################################
usage() {
    cat << EOF
Usage: $(basename "$0") [TEMPLATE] [OPTIONS]

Apply pre-configured templates for specific roles and use cases

TEMPLATES:
    data-scientist    - Python, R, Julia, ML/AI tools, Jupyter
    web-developer     - Node.js, React, Vue, Angular, web tools
    devops-engineer   - Kubernetes, Docker, Terraform, cloud tools
    ai-researcher     - LLMs, MCPs, research tools, BMAD Method
    minimal           - Essential tools only
    
    list              - List all available templates

OPTIONS:
    --backup          Create backup before applying template
    --merge           Merge with existing configuration (default: replace)
    --dry-run         Show what would be changed without applying
    -f, --force       Apply without confirmation
    -h, --help        Display this help message

EXAMPLES:
    # Apply data scientist template
    $(basename "$0") data-scientist
    
    # Apply with backup and merge
    $(basename "$0") web-developer --backup --merge
    
    # See what would change without applying
    $(basename "$0") devops-engineer --dry-run

EOF
}

#######################################
# List available templates
#######################################
list_templates() {
    echo "Available templates:"
    echo "==================="
    
    if [[ -d "$TEMPLATES_DIR" ]]; then
        for template in "$TEMPLATES_DIR"/*.yaml; do
            if [[ -f "$template" ]]; then
                local name=$(basename "$template" .yaml)
                local description=""
                
                # Extract description from comment
                if description=$(grep -m1 "^# .*Configuration Template" "$template" 2>/dev/null); then
                    description=$(echo "$description" | sed 's/^# *//' | sed 's/ Configuration Template$//')
                fi
                
                printf "  %-20s %s\n" "$name" "$description"
            fi
        done
    else
        echo "No templates directory found: $TEMPLATES_DIR"
    fi
}

#######################################
# Validate template exists
#######################################
validate_template() {
    local template="$1"
    local template_file="$TEMPLATES_DIR/${template}.yaml"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template"
        echo ""
        echo "Available templates:"
        list_templates
        exit 1
    fi
    
    log_info "Found template: $template_file"
}

#######################################
# Create backup of current configuration
#######################################
create_backup() {
    local config_file="$CONFIG_DIR/settings.yaml"
    
    if [[ -f "$config_file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/settings.yaml.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file"
        log_success "Backup created: $backup_file"
    fi
}

#######################################
# Merge configurations using yq
#######################################
merge_configs() {
    local template_file="$1"
    local config_file="$CONFIG_DIR/settings.yaml"
    local temp_file=$(mktemp)
    
    log_info "Merging template with existing configuration..."
    
    if command -v yq &> /dev/null; then
        # Use yq for proper YAML merging
        yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
            "$config_file" "$template_file" > "$temp_file"
        mv "$temp_file" "$config_file"
    else
        # Fallback: simple concatenation (not ideal)
        log_warning "yq not found, using simple merge"
        {
            echo "# Merged configuration - $(date)"
            cat "$config_file"
            echo ""
            echo "# Template additions:"
            cat "$template_file"
        } > "$temp_file"
        mv "$temp_file" "$config_file"
    fi
}

#######################################
# Apply template
#######################################
apply_template() {
    local template="$1"
    local template_file="$TEMPLATES_DIR/${template}.yaml"
    local config_file="$CONFIG_DIR/settings.yaml"
    local backup="${2:-false}"
    local merge="${3:-false}"
    local dry_run="${4:-false}"
    
    log_info "Applying template: $template"
    
    if [[ "$dry_run" == true ]]; then
        echo ""
        echo "=== DRY RUN - Changes that would be made ==="
        echo ""
        echo "Template file: $template_file"
        echo "Target file: $config_file"
        echo "Operation: $([ "$merge" = true ] && echo "merge" || echo "replace")"
        echo "Backup: $([ "$backup" = true ] && echo "yes" || echo "no")"
        echo ""
        echo "Template content preview:"
        head -n 20 "$template_file"
        echo "..."
        return 0
    fi
    
    # Create backup if requested
    if [[ "$backup" == true ]]; then
        create_backup
    fi
    
    # Ensure config directory exists
    mkdir -p "$CONFIG_DIR"
    
    if [[ "$merge" == true ]] && [[ -f "$config_file" ]]; then
        merge_configs "$template_file"
    else
        # Replace configuration
        cp "$template_file" "$config_file"
    fi
    
    log_success "Template applied successfully!"
}

#######################################
# Show template preview
#######################################
show_preview() {
    local template="$1"
    local template_file="$TEMPLATES_DIR/${template}.yaml"
    
    echo ""
    echo "=== Template Preview: $template ==="
    echo ""
    
    # Show key sections
    if command -v yq &> /dev/null; then
        echo "Shell Profile:"
        yq e '.features.shell.profile // "not specified"' "$template_file"
        echo ""
        
        echo "Enabled Modules:"
        yq e '.features.shell.modules | keys | .[]' "$template_file" 2>/dev/null || echo "none specified"
        echo ""
        
        echo "Tools to Install:"
        yq e '.features.tools | keys | .[]' "$template_file" 2>/dev/null || echo "none specified"
        echo ""
    else
        # Fallback: show file content
        head -n 30 "$template_file"
        echo "..."
    fi
}

#######################################
# Install template dependencies
#######################################
install_dependencies() {
    local template="$1"
    
    log_info "Installing dependencies for template: $template"
    
    # Run the unattended installer with the applied configuration
    "$REPO_ROOT/scripts/setup/unattended-install.sh" --config "$CONFIG_DIR/settings.yaml" -y
}

#######################################
# Main function
#######################################
main() {
    local template=""
    local backup=false
    local merge=false
    local dry_run=false
    local force=false
    local install_deps=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --backup)
                backup=true
                shift
                ;;
            --merge)
                merge=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --install)
                install_deps=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            list)
                list_templates
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                template="$1"
                shift
                ;;
        esac
    done
    
    # Validate template
    if [[ -z "$template" ]]; then
        echo "Error: Template name required"
        echo ""
        usage
        exit 1
    fi
    
    validate_template "$template"
    
    # Show preview
    show_preview "$template"
    
    # Confirm application
    if [[ "$force" == false ]] && [[ "$dry_run" == false ]]; then
        echo ""
        read -p "Apply this template? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Template application cancelled"
            exit 0
        fi
    fi
    
    # Apply template
    apply_template "$template" "$backup" "$merge" "$dry_run"
    
    # Install dependencies if requested
    if [[ "$install_deps" == true ]] && [[ "$dry_run" == false ]]; then
        echo ""
        read -p "Install dependencies now? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies "$template"
        fi
    fi
    
    # Show next steps
    if [[ "$dry_run" == false ]]; then
        echo ""
        echo "🎉 Template applied successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Review the configuration: $CONFIG_DIR/settings.yaml"
        echo "2. Run the installer: ./scripts/setup/unattended-install.sh -y"
        echo "3. Or install specific components manually"
    fi
}

# Run main function
main "$@"