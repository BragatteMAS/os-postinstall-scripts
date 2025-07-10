#!/bin/bash
# generate-changelog-date.sh - Generate appropriate date for CHANGELOG.md

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to get repository creation date
get_repo_creation_date() {
    if [ -d ".git" ]; then
        # Get the date of the first commit
        first_commit_date=$(git log --reverse --format="%ai" | head -1 | cut -d' ' -f1)
        
        if [ -z "$first_commit_date" ]; then
            # If no commits yet, use today's date
            echo "$(date +%Y-%m-%d)"
        else
            echo "$first_commit_date"
        fi
    else
        # Not a git repo, use today's date
        echo "$(date +%Y-%m-%d)"
    fi
}

# Function to generate or update CHANGELOG.md
generate_changelog() {
    local changelog_date
    
    if [ -f "CHANGELOG.md" ]; then
        # Check if CHANGELOG has any version entries
        if grep -q "## \[" CHANGELOG.md; then
            echo -e "${YELLOW}CHANGELOG.md already exists with entries${NC}"
            return
        else
            # CHANGELOG exists but no entries, use repo creation date
            changelog_date=$(get_repo_creation_date)
        fi
    else
        # No CHANGELOG, create new with repo creation date
        changelog_date=$(get_repo_creation_date)
    fi
    
    echo -e "${GREEN}Creating CHANGELOG.md with date: $changelog_date${NC}"
    
    cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [Add your new features here]

### Changed
- None yet

### Deprecated
- None yet

### Removed
- None yet

### Fixed
- None yet

### Security
- None yet

# Previous versions would go here
# Example:
# ## [X.Y.Z] - YYYY-MM-DD
# ### Added
# - Features

# Update links as needed:
# [Unreleased]: https://github.com/USERNAME/REPO/compare/vX.Y.Z...HEAD
# [X.Y.Z]: https://github.com/USERNAME/REPO/releases/tag/vX.Y.Z
EOF
}

# Main execution
if [ "$1" == "--check" ]; then
    # Just return the date that would be used
    get_repo_creation_date
else
    # Generate the CHANGELOG
    generate_changelog
fi