#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#######################################
# install_product_focused_git.sh
# Purpose: Configure git globally for product-focused development
# Author: BragatteMAS
# License: MIT
# Version: 1.0.0
#
# This script:
# - Sets up global git templates for .github structure
# - Configures git aliases for product-focused commits
# - Installs smart git hooks
# - Works on Linux, macOS, and Windows (Git Bash)
#######################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Icons
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_SOURCE="$SCRIPT_DIR/global-git-templates"

# Detect OS and set paths
detect_os_and_paths() {
    case "$OSTYPE" in
        darwin*)
            OS="macOS"
            CONFIG_DIR="$HOME/.config"
            SHELL_RC="$HOME/.zshrc"
            ;;
        linux*)
            OS="Linux"
            CONFIG_DIR="$HOME/.config"
            # Detect shell
            if [[ "$SHELL" == *"zsh"* ]]; then
                SHELL_RC="$HOME/.zshrc"
            else
                SHELL_RC="$HOME/.bashrc"
            fi
            ;;
        msys*|cygwin*|mingw*)
            OS="Windows"
            CONFIG_DIR="$USERPROFILE/.config"
            SHELL_RC="$HOME/.bashrc"  # Git Bash uses .bashrc
            ;;
        *)
            echo -e "${RED}${CROSS} Unsupported OS: $OSTYPE${NC}"
            exit 1
            ;;
    esac
    
    # Set git templates directory
    GIT_TEMPLATES_DIR="$CONFIG_DIR/git-templates"
}

#######################################
# Show banner
#######################################
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║           🎯 Product-Focused Git Configuration 🎯                 ║
║         Keep commits focused on product, not tooling              ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${INFO} Detected OS: ${GREEN}$OS${NC}"
    echo -e "${INFO} Shell config: ${GREEN}$SHELL_RC${NC}"
    echo -e "${INFO} Git templates: ${GREEN}$GIT_TEMPLATES_DIR${NC}\n"
}

#######################################
# Install git templates
#######################################
install_git_templates() {
    echo -e "${BLUE}Installing git templates...${NC}"
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Copy templates
    if [[ -d "$TEMPLATES_SOURCE" ]]; then
        # Remove old templates if they exist
        if [[ -d "$GIT_TEMPLATES_DIR" ]]; then
            echo -e "${WARNING} Backing up existing templates to ${GIT_TEMPLATES_DIR}.backup"
            mv "$GIT_TEMPLATES_DIR" "${GIT_TEMPLATES_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Copy new templates
        cp -r "$TEMPLATES_SOURCE" "$GIT_TEMPLATES_DIR"
        echo -e "${CHECK} Git templates installed to $GIT_TEMPLATES_DIR"
    else
        echo -e "${RED}${CROSS} Templates source not found: $TEMPLATES_SOURCE${NC}"
        exit 1
    fi
    
    # Make hooks executable
    if [[ -d "$GIT_TEMPLATES_DIR/hooks" ]]; then
        chmod +x "$GIT_TEMPLATES_DIR/hooks"/* 2>/dev/null || true
    fi
}

#######################################
# Configure git settings
#######################################
configure_git() {
    echo -e "\n${BLUE}Configuring git settings...${NC}"
    
    # Set template directory
    git config --global init.templateDir "$GIT_TEMPLATES_DIR"
    echo -e "${CHECK} Set global template directory"
    
    # Configure product-focused aliases
    echo -e "\n${BLUE}Adding git aliases...${NC}"
    
    # Product-focused viewing aliases
    git config --global alias.logp "log --oneline -- ':!.github'"
    git config --global alias.diffp "diff -- ':!.github'"
    git config --global alias.statusp "status -- ':!.github'"
    git config --global alias.showp "show -- ':!.github'"
    git config --global alias.addp "add -- ':!.github'"
    
    # Extended log formats
    git config --global alias.logpf "log --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%an%C(reset) %s' -- ':!.github'"
    git config --global alias.logpg "log --graph --pretty=format:'%C(yellow)%h%C(reset) -%C(red)%d%C(reset) %s %C(green)(%cr) %C(blue)<%an>%C(reset)' --abbrev-commit -- ':!.github'"
    
    # Statistics
    git config --global alias.countp "rev-list --count HEAD -- ':!.github'"
    git config --global alias.contributorsp "shortlog -sn -- ':!.github'"
    
    # Smart initialization
    git config --global alias.init-product '!git init && mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS} && git add .github && git commit -m "chore(.github): initialize product-focused structure"'
    
    echo -e "${CHECK} Configured product-focused git aliases"
    
    # Set default branch name
    git config --global init.defaultBranch main
    echo -e "${CHECK} Set default branch to 'main'"
}

#######################################
# Create git hooks
#######################################
create_git_hooks() {
    echo -e "\n${BLUE}Creating smart git hooks...${NC}"
    
    local hooks_dir="$GIT_TEMPLATES_DIR/hooks"
    mkdir -p "$hooks_dir"
    
    # Create prepare-commit-msg hook
    cat > "$hooks_dir/prepare-commit-msg" << 'EOF'
#!/usr/bin/env bash
# Auto-prefix commits that only touch .github/ directory

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only process if this is a regular commit (not merge, squash, etc.)
if [ -z "$COMMIT_SOURCE" ]; then
    # Check if only .github files are being committed
    staged_files=$(git diff --cached --name-only)
    github_files=$(git diff --cached --name-only | grep "^\.github/" || true)
    
    if [ -n "$github_files" ] && [ "$staged_files" = "$github_files" ]; then
        # Check if message already has chore(.github) prefix
        first_line=$(head -n1 "$COMMIT_MSG_FILE")
        if [[ ! "$first_line" =~ ^chore\(\.github\): ]]; then
            # Prepend the prefix
            echo "chore(.github): $first_line" > "$COMMIT_MSG_FILE.tmp"
            tail -n +2 "$COMMIT_MSG_FILE" >> "$COMMIT_MSG_FILE.tmp"
            mv "$COMMIT_MSG_FILE.tmp" "$COMMIT_MSG_FILE"
        fi
    fi
fi
EOF
    
    # Create post-commit hook
    cat > "$hooks_dir/post-commit" << 'EOF'
#!/usr/bin/env bash
# Show product vs tooling commit statistics after each commit

# Count commits
total_commits=$(git rev-list --count HEAD 2>/dev/null || echo 0)
product_commits=$(git rev-list --count HEAD -- ':!.github' 2>/dev/null || echo 0)
tooling_commits=$((total_commits - product_commits))

# Calculate percentage
if [ $total_commits -gt 0 ]; then
    product_percent=$((product_commits * 100 / total_commits))
    echo ""
    echo "📊 Commit Statistics:"
    echo "   Product commits: $product_commits ($product_percent%)"
    echo "   Tooling commits: $tooling_commits"
    echo ""
fi
EOF
    
    # Make hooks executable
    chmod +x "$hooks_dir"/*
    echo -e "${CHECK} Created smart git hooks"
}

#######################################
# Add shell functions
#######################################
add_shell_functions() {
    echo -e "\n${BLUE}Adding shell functions...${NC}"
    
    # Check if functions already exist
    if grep -q "# Product-Focused Git Functions" "$SHELL_RC" 2>/dev/null; then
        echo -e "${WARNING} Shell functions already exist in $SHELL_RC"
        return
    fi
    
    # Add functions to shell RC
    cat >> "$SHELL_RC" << 'EOF'

# ──────────────────────────────────────────────────────────────────────────────
# Product-Focused Git Functions
# ──────────────────────────────────────────────────────────────────────────────
## Create new project with product-focused structure
gnew() {
    local project_name="${1:-}"
    
    if [[ -z "$project_name" ]]; then
        echo "Usage: gnew <project-name>"
        return 1
    fi
    
    echo "🚀 Creating new product-focused project: $project_name"
    
    # Create and enter directory
    mkdir -p "$project_name"
    cd "$project_name" || return 1
    
    # Initialize with structure
    git init
    
    # Create initial files if they don't exist from template
    if [[ ! -f "README.md" ]]; then
        echo "# $project_name" > README.md
        echo "" >> README.md
        echo "> Project description" >> README.md
    fi
    
    # Initial commit
    git add .
    git commit -m "feat: initial project setup"
    
    echo "✅ Project created! Structure:"
    tree -L 3 .github 2>/dev/null || ls -la .github/
}

## Initialize existing directory with product-focused structure
ginit() {
    echo "🔧 Initializing product-focused git structure..."
    
    # Initialize git if needed
    if [[ ! -d ".git" ]]; then
        git init
    fi
    
    # Create .github structure if it doesn't exist
    mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
    
    # Run migration if old structure exists
    if [[ -d ".bmad-core" ]] || [[ -d ".claude" ]]; then
        echo "📦 Found old tooling structure, migrating..."
        # Migration logic here
    fi
    
    echo "✅ Product-focused structure ready!"
}

## Check project health and statistics
gcheck() {
    echo "🔍 Checking project structure and statistics..."
    
    # Check if in git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi
    
    # Check structure
    echo ""
    echo "📁 Structure Check:"
    [[ -d ".github/AI_TOOLKIT" ]] && echo "  ✅ AI Toolkit" || echo "  ❌ AI Toolkit"
    [[ -d ".github/PROJECT_DOCS" ]] && echo "  ✅ Project Docs" || echo "  ❌ Project Docs"
    [[ -d ".github/METHODS" ]] && echo "  ✅ Methods" || echo "  ❌ Methods"
    [[ -f ".gitattributes" ]] && echo "  ✅ Git Attributes" || echo "  ❌ Git Attributes"
    
    # Show statistics
    local total_commits=$(git rev-list --count HEAD 2>/dev/null || echo 0)
    local product_commits=$(git rev-list --count HEAD -- ':!.github' 2>/dev/null || echo 0)
    local tooling_commits=$((total_commits - product_commits))
    
    echo ""
    echo "📊 Commit Statistics:"
    echo "  Total commits: $total_commits"
    echo "  Product commits: $product_commits"
    echo "  Tooling commits: $tooling_commits"
    
    if [[ $total_commits -gt 0 ]]; then
        local product_percent=$((product_commits * 100 / total_commits))
        echo "  Product focus: $product_percent%"
    fi
}

## Quick alias for product-focused git status
alias gs='git statusp'
alias gl='git logp'
alias gd='git diffp'

EOF
    
    echo -e "${CHECK} Added shell functions to $SHELL_RC"
    echo -e "${INFO} Run 'source $SHELL_RC' to load them now"
}

#######################################
# Show summary
#######################################
show_summary() {
    echo -e "\n${PURPLE}=== Installation Summary ===${NC}\n"
    
    echo -e "${GREEN}${CHECK} Installation complete!${NC}\n"
    
    echo -e "${YELLOW}What was configured:${NC}"
    echo -e "  ${CHECK} Git templates in: $GIT_TEMPLATES_DIR"
    echo -e "  ${CHECK} Git config: init.templateDir set"
    echo -e "  ${CHECK} Product-focused aliases added"
    echo -e "  ${CHECK} Smart git hooks installed"
    echo -e "  ${CHECK} Shell functions added to: $SHELL_RC"
    
    echo -e "\n${YELLOW}Available commands:${NC}"
    echo -e "  ${BLUE}gnew <name>${NC} - Create new project with structure"
    echo -e "  ${BLUE}ginit${NC} - Initialize structure in existing project"
    echo -e "  ${BLUE}gcheck${NC} - Check project health and stats"
    
    echo -e "\n${YELLOW}Git aliases:${NC}"
    echo -e "  ${BLUE}git logp${NC} - View product commits only"
    echo -e "  ${BLUE}git diffp${NC} - Diff product changes only"
    echo -e "  ${BLUE}git statusp${NC} - Status of product files only"
    
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "  1. ${ROCKET} Reload shell: ${GREEN}source $SHELL_RC${NC}"
    echo -e "  2. ${ROCKET} Try it out: ${GREEN}gnew my-awesome-project${NC}"
    echo -e "  3. ${ROCKET} Check existing project: ${GREEN}cd your-project && gcheck${NC}"
    
    echo -e "\n${INFO} From now on, every ${GREEN}git init${NC} will use this structure!"
}

#######################################
# Main execution
#######################################
main() {
    # Detect OS and set paths
    detect_os_and_paths
    
    # Show banner
    show_banner
    
    # Confirm installation
    echo -n "Install product-focused git configuration? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi
    
    # Run installation steps
    install_git_templates
    configure_git
    create_git_hooks
    add_shell_functions
    
    # Show summary
    show_summary
}

# Run main
main "$@"