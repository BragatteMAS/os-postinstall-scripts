#!/bin/bash
# update-changelog-dates.sh - Update CHANGELOG.md dates dynamically

set -e

# Function to get repository creation date
get_repo_creation_date() {
    if [ -d ".git" ]; then
        # Get the date of the first commit
        first_commit_date=$(git log --reverse --format="%Y-%m-%d" | head -1)
        
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

# Function to update CHANGELOG template
create_changelog_template() {
    cat > CHANGELOG.template.md << 'EOF'
# Changelog

<!-- 
This is a template file. To generate CHANGELOG.md with proper dates, run:
./ai/scripts/update-changelog-dates.sh
-->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - ${RELEASE_DATE}

### Added
- **Section 22: Advanced Enhancements** - 13 major new features:
  - Universal package manager function (`install_tool`)
  - Git credential security setup (`setup_git_credentials`)
  - Configuration backup system with rotation (`backup_configs`)
  - Full WSL (Windows Subsystem for Linux) support
  - Docker/Podman integration with custom aliases
  - Adaptive themes based on system preferences
  - Performance monitoring (`shell_benchmark`)
  - Secure environment variables loading from `.env.local`
  - Lazy loading for nvm and rbenv
  - Built-in documentation system (`zdoc`)
  - Interactive quick menu (`qm`)
  - Automatic SSH agent management
  - Feature flags support via `.zshrc.flags`

- **Enhanced Welcome Message**:
  - Shows current git branch
  - Organized command categories with tree structure
  - Dynamic status indicators (conda env, secure env)
  - Compact version available (`welcomec`)

- **Improved Help System**:
  - `zdoc` - Complete function documentation
  - Better organized help categories
  - `ac rust` - List all Rust tools

### Changed
- Fixed sed alias conflict - renamed to `sdr` for sd (Rust tool)
- Improved help functions to use `\sed` bypassing aliases
- Enhanced `nu_compare` function for better compatibility
- Optimized xargs usage in command tracking to prevent quote errors
- Removed terminal clearing from welcome message
- Removed blocking "Press Enter" prompts
- Quick menu no longer clears screen

### Fixed
- Conda access issues due to syntax errors
- Help system "halp by category" not working
- "xargs: unterminated quote" error in command tracking
- Terminal being cleared unexpectedly
- Incomplete cutt alias definition
- Function syntax errors in nu_compare

### Security
- Added secure credential management for git
- Environment variables now loaded from `.env.local`
- SSH agent automatic management
- Improved security guidelines in documentation

# Add previous versions below as needed
# Example:
# ## [1.0.0] - YYYY-MM-DD
# ### Added
# - Feature list
EOF
}

# Main execution
echo "🔄 Updating CHANGELOG dates..."

# Get dates
INITIAL_DATE=$(get_repo_creation_date)
RELEASE_DATE=$(date +%Y-%m-%d)

# Create template
create_changelog_template

# Generate CHANGELOG.md from template
export INITIAL_DATE RELEASE_DATE
envsubst < CHANGELOG.template.md > CHANGELOG.md

# Clean up template
rm -f CHANGELOG.template.md

echo "✅ CHANGELOG.md updated with dynamic dates:"
echo "   - Initial release: $INITIAL_DATE"
echo "   - Current release: $RELEASE_DATE"