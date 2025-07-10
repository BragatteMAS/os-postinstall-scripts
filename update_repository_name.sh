#!/usr/bin/env bash

# Script to update repository name references after GitHub rename
# Usage: ./update_repository_name.sh

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

# Old and new repository names
readonly OLD_NAME="os-postinstall-scripts"
readonly NEW_NAME="os-postinstall-scripts"
readonly GITHUB_USER="BragatteMAS"

echo -e "${GREEN}Repository Name Update Script${NC}"
echo "================================="
echo "This script will update all references from '$OLD_NAME' to '$NEW_NAME'"
echo

# Function to update files
update_files() {
    echo -e "${YELLOW}Updating file references...${NC}"
    
    # Find all text files and update references
    find . -type f \( -name "*.md" -o -name "*.sh" -o -name "*.ps1" -o -name "*.txt" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" \) \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./dist/*" \
        -exec grep -l "$OLD_NAME" {} \; | while read -r file; do
        
        echo "Updating: $file"
        # Use different sed syntax for macOS vs Linux
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/$OLD_NAME/$NEW_NAME/g" "$file"
        else
            sed -i "s/$OLD_NAME/$NEW_NAME/g" "$file"
        fi
    done
}

# Function to update git remote
update_git_remote() {
    echo -e "${YELLOW}Updating git remote URL...${NC}"
    
    # Get current remote URL
    current_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ -n "$current_url" ]]; then
        # Update the remote URL
        new_url="https://github.com/${GITHUB_USER}/${NEW_NAME}.git"
        git remote set-url origin "$new_url"
        echo -e "${GREEN}Updated git remote to: $new_url${NC}"
    else
        echo -e "${RED}No git remote found${NC}"
    fi
}

# Function to show affected files
show_affected_files() {
    echo -e "${YELLOW}Files that will be updated:${NC}"
    grep -r "$OLD_NAME" . \
        --include="*.md" \
        --include="*.sh" \
        --include="*.ps1" \
        --include="*.txt" \
        --include="*.yml" \
        --include="*.yaml" \
        --include="*.json" \
        --exclude-dir=.git \
        --exclude-dir=node_modules \
        --exclude-dir=dist \
        -l 2>/dev/null || echo "No files found with old repository name"
}

# Main execution
main() {
    echo "Scanning for files containing '$OLD_NAME'..."
    echo
    
    show_affected_files
    echo
    
    read -r -p "Do you want to proceed with the update? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            update_files
            update_git_remote
            
            echo
            echo -e "${GREEN}✅ Repository name update complete!${NC}"
            echo
            echo "Next steps:"
            echo "1. Go to GitHub Settings > Repository name"
            echo "2. Change from '$OLD_NAME' to '$NEW_NAME'"
            echo "3. Commit and push these changes:"
            echo "   git add -A"
            echo "   git commit -m 'Update repository name to $NEW_NAME'"
            echo "   git push origin main"
            ;;
        *)
            echo -e "${YELLOW}Update cancelled${NC}"
            exit 0
            ;;
    esac
}

# Run main function
main