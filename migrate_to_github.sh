#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#######################################
# migrate_to_github.sh
# Purpose: Reorganize project structure to centralize AI tools in .github/
# Author: Bragatte, M.A.S
# License: MIT
# Version: 1.0.0
#
# This script migrates BMAD and other AI tooling to .github/ structure
# to keep commits focused on the product, not the methods
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

#######################################
# Show banner
#######################################
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║              📁 Migrate to .github Structure 📁                   ║
║           Keep commits focused on product, not methods            ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#######################################
# Create new directory structure
#######################################
create_github_structure() {
    echo -e "${BLUE}Creating .github structure...${NC}"
    
    # Create main directories
    mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
    mkdir -p .github/AI_TOOLKIT/{agents,commands,templates,workflows,config}
    mkdir -p .github/PROJECT_DOCS/adrs
    
    echo -e "${GREEN}${CHECK} Directory structure created${NC}"
}

#######################################
# Migrate BMAD content
#######################################
migrate_bmad() {
    echo -e "\n${BLUE}Migrating BMAD content...${NC}"
    
    # Check for .bmad-core
    if [[ -d ".bmad-core" ]]; then
        echo -e "${INFO} Found .bmad-core directory"
        
        # Move content preserving git history
        if [[ -d ".bmad-core/agents" ]]; then
            mv .bmad-core/agents/* .github/AI_TOOLKIT/agents/ 2>/dev/null || true
            echo -e "${CHECK} Migrated agents"
        fi
        
        if [[ -d ".bmad-core/workflows" ]]; then
            mv .bmad-core/workflows/* .github/AI_TOOLKIT/workflows/ 2>/dev/null || true
            echo -e "${CHECK} Migrated workflows"
        fi
        
        if [[ -d ".bmad-core/templates" ]]; then
            mv .bmad-core/templates/* .github/AI_TOOLKIT/templates/ 2>/dev/null || true
            echo -e "${CHECK} Migrated templates"
        fi
        
        # Move config files
        find .bmad-core -name "*.yaml" -o -name "*.yml" -o -name "*.json" | while read -r file; do
            mv "$file" .github/AI_TOOLKIT/config/ 2>/dev/null || true
        done
        
        # Move documentation
        if [[ -f ".bmad-core/user-guide.md" ]]; then
            mv .bmad-core/user-guide.md .github/AI_TOOLKIT/BMAD_USER_GUIDE.md
            echo -e "${CHECK} Migrated BMAD user guide"
        fi
        
        # Clean up
        rm -rf .bmad-core
        echo -e "${GREEN}${CHECK} BMAD migration complete${NC}"
    else
        echo -e "${YELLOW}${INFO} No .bmad-core directory found${NC}"
    fi
    
    # Check for old .claude directory
    if [[ -d ".claude" ]]; then
        echo -e "${INFO} Found .claude directory"
        
        if [[ -d ".claude/commands" ]]; then
            mv .claude/commands/* .github/AI_TOOLKIT/commands/ 2>/dev/null || true
            echo -e "${CHECK} Migrated Claude commands"
        fi
        
        rm -rf .claude
    fi
}

#######################################
# Migrate project documentation
#######################################
migrate_project_docs() {
    echo -e "\n${BLUE}Migrating project documentation...${NC}"
    
    # Move existing PROJECT_DOCS content if it exists elsewhere
    local docs_to_move=("PRD.md" "STORIES.md" "STATUS.md" "TESTING.md" "MAINTENANCE.md")
    
    for doc in "${docs_to_move[@]}"; do
        if [[ -f "$doc" ]] && [[ ! -f ".github/PROJECT_DOCS/$doc" ]]; then
            mv "$doc" .github/PROJECT_DOCS/
            echo -e "${CHECK} Moved $doc"
        fi
    done
    
    # Move ADRs if they exist in root
    if [[ -d "adrs" ]] || [[ -d "ADRs" ]] || [[ -d "docs/adrs" ]]; then
        find . -name "ADR-*.md" -not -path "./.github/*" | while read -r adr; do
            mv "$adr" .github/PROJECT_DOCS/adrs/ 2>/dev/null || true
        done
        echo -e "${CHECK} Migrated ADRs"
    fi
}

#######################################
# Setup methods and configurations
#######################################
setup_methods() {
    echo -e "\n${BLUE}Setting up methods and configurations...${NC}"
    
    # Move or link CLAUDE.md
    if [[ -f "CLAUDE.md" ]]; then
        mv CLAUDE.md .github/METHODS/
        # Create symlink in root for backward compatibility
        ln -sf .github/METHODS/CLAUDE.md CLAUDE.md
        echo -e "${CHECK} Moved CLAUDE.md (with symlink)"
    elif [[ -f "$HOME/CLAUDE.md" ]]; then
        # Link to global CLAUDE.md
        ln -sf "$HOME/CLAUDE.md" .github/METHODS/CLAUDE.md
        echo -e "${CHECK} Linked global CLAUDE.md"
    fi
    
    # Same for CLAUDE-EXTENDED.md
    if [[ -f "CLAUDE-EXTENDED.md" ]]; then
        mv CLAUDE-EXTENDED.md .github/METHODS/
        ln -sf .github/METHODS/CLAUDE-EXTENDED.md CLAUDE-EXTENDED.md
        echo -e "${CHECK} Moved CLAUDE-EXTENDED.md (with symlink)"
    elif [[ -f "$HOME/CLAUDE-EXTENDED.md" ]]; then
        ln -sf "$HOME/CLAUDE-EXTENDED.md" .github/METHODS/CLAUDE-EXTENDED.md
        echo -e "${CHECK} Linked global CLAUDE-EXTENDED.md"
    fi
}

#######################################
# Create .gitattributes
#######################################
create_gitattributes() {
    echo -e "\n${BLUE}Creating .gitattributes...${NC}"
    
    # Check if .gitattributes exists
    if [[ -f ".gitattributes" ]]; then
        # Backup existing
        cp .gitattributes .gitattributes.backup
        echo -e "${INFO} Backed up existing .gitattributes"
    fi
    
    # Add our rules
    cat >> .gitattributes << 'EOF'

# AI Tooling and Methods - Mark as generated/documentation
.github/AI_TOOLKIT/** linguist-generated=true
.github/METHODS/** linguist-documentation=true
.github/PROJECT_DOCS/** linguist-documentation=true

# Reduce diff noise for AI tooling
.github/AI_TOOLKIT/** -diff
.github/METHODS/** -diff

# Ensure text files use LF
*.md text eol=lf
*.sh text eol=lf
*.yaml text eol=lf
*.yml text eol=lf
EOF
    
    echo -e "${GREEN}${CHECK} .gitattributes configured${NC}"
}

#######################################
# Create helper scripts
#######################################
create_helper_scripts() {
    echo -e "\n${BLUE}Creating helper scripts...${NC}"
    
    # Create a product-focused git aliases script
    cat > .github/AI_TOOLKIT/config/product-focused-git.sh << 'EOF'
#!/usr/bin/env bash
# Git aliases for product-focused development

# Add to your .gitconfig or source this file

# Log only product changes
alias glogp="git log --oneline -- ':!.github'"

# Diff only product changes  
alias gdiffp="git diff -- ':!.github'"

# Status only product changes
alias gstatusp="git status -- ':!.github'"

# Add only product files
alias gaddp="git add -- ':!.github'"

# Commit with conventional commits
alias gcfeat="git commit -m 'feat: '"
alias gcfix="git commit -m 'fix: '"
alias gcdocs="git commit -m 'docs: '"
alias gcchore="git commit -m 'chore(.github): '"

echo "Product-focused git aliases loaded!"
EOF
    
    chmod +x .github/AI_TOOLKIT/config/product-focused-git.sh
    echo -e "${CHECK} Created product-focused git helper"
}

#######################################
# Create README for .github structure
#######################################
create_github_readme() {
    echo -e "\n${BLUE}Creating .github README...${NC}"
    
    cat > .github/README.md << 'EOF'
# 🔧 Project Tooling & Methods

This directory contains all AI tooling, project documentation, and development methods.
It's intentionally separated from the product code to maintain clean, product-focused commits.

## 📁 Structure

```
.github/
├── AI_TOOLKIT/        # 🤖 AI development tools
│   ├── agents/        # BMAD agents
│   ├── commands/      # Claude commands
│   ├── templates/     # Reusable templates
│   └── workflows/     # Development workflows
│
├── PROJECT_DOCS/      # 📋 Project documentation
│   ├── PRD.md        # Product Requirements
│   ├── STORIES.md    # User Stories
│   ├── STATUS.md     # Project Status
│   └── adrs/         # Architecture Decision Records
│
└── METHODS/           # 📚 Development methods
    ├── CLAUDE.md     # Context Engineering
    └── BMAD.md       # BMAD Method docs
```

## 🎯 Why This Structure?

1. **Clean commits**: Focus on product changes, not tooling
2. **GitHub native**: Automatically collapsed in PRs
3. **Portable**: Easy to copy between projects
4. **Organized**: Clear separation of concerns

## 🚀 Usage

### View only product commits:
```bash
git log --oneline -- ':!.github'
```

### Diff only product changes:
```bash
git diff -- ':!.github'
```

### Commit conventions:
- `feat:` - Product features
- `fix:` - Product bug fixes  
- `chore(.github):` - Tooling updates
EOF
    
    echo -e "${GREEN}${CHECK} Created .github/README.md${NC}"
}

#######################################
# Update BMAD config for new location
#######################################
update_bmad_config() {
    echo -e "\n${BLUE}Updating configurations...${NC}"
    
    # Create BMAD config that points to new location
    cat > .github/AI_TOOLKIT/config/bmad-location.yaml << 'EOF'
# BMAD Location Configuration
# This file tells BMAD tools where to find resources

bmad:
  root: .github/AI_TOOLKIT
  agents: .github/AI_TOOLKIT/agents
  commands: .github/AI_TOOLKIT/commands
  templates: .github/AI_TOOLKIT/templates
  workflows: .github/AI_TOOLKIT/workflows

project_docs:
  root: .github/PROJECT_DOCS
  prd: .github/PROJECT_DOCS/PRD.md
  stories: .github/PROJECT_DOCS/STORIES.md
  status: .github/PROJECT_DOCS/STATUS.md

methods:
  claude: .github/METHODS/CLAUDE.md
  bmad: .github/METHODS/BMAD.md
EOF
    
    echo -e "${GREEN}${CHECK} Configuration updated${NC}"
}

#######################################
# Show summary and next steps
#######################################
show_summary() {
    echo -e "\n${PURPLE}=== Migration Summary ===${NC}\n"
    
    # Count files moved
    local ai_toolkit_count=$(find .github/AI_TOOLKIT -type f 2>/dev/null | wc -l | tr -d ' ')
    local project_docs_count=$(find .github/PROJECT_DOCS -type f 2>/dev/null | wc -l | tr -d ' ')
    local methods_count=$(find .github/METHODS -type f 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "${GREEN}${CHECK} Structure created successfully!${NC}"
    echo -e "  ${INFO} AI Toolkit files: $ai_toolkit_count"
    echo -e "  ${INFO} Project docs: $project_docs_count"
    echo -e "  ${INFO} Methods: $methods_count"
    
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "1. ${ROCKET} Review the migration:"
    echo -e "   ${BLUE}git status${NC}"
    echo -e "   ${BLUE}tree .github${NC}"
    echo ""
    echo -e "2. ${ROCKET} Commit the reorganization:"
    echo -e "   ${BLUE}git add .github${NC}"
    echo -e "   ${BLUE}git commit -m \"chore(.github): reorganize AI tooling structure\"${NC}"
    echo ""
    echo -e "3. ${ROCKET} Update your workflow:"
    echo -e "   - Use ${GREEN}git log -- ':!.github'${NC} to see product commits"
    echo -e "   - Use ${GREEN}git diff -- ':!.github'${NC} for product diffs"
    echo -e "   - Source ${GREEN}.github/AI_TOOLKIT/config/product-focused-git.sh${NC} for aliases"
    echo ""
    echo -e "4. ${ROCKET} Update install scripts:"
    echo -e "   Run ${GREEN}./update_installers_for_github.sh${NC} (will be created next)"
}

#######################################
# Main execution
#######################################
main() {
    show_banner
    
    # Check if in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}${CROSS} Not in a git repository!${NC}"
        echo -e "${INFO} Please run this script from your project root"
        exit 1
    fi
    
    echo -e "${INFO} Starting migration to .github structure..."
    echo -e "${WARNING} This will reorganize your project. Commit current changes first!"
    echo -n "Continue? (y/N): "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Migration cancelled${NC}"
        exit 0
    fi
    
    # Run migration steps
    create_github_structure
    migrate_bmad
    migrate_project_docs
    setup_methods
    create_gitattributes
    create_helper_scripts
    create_github_readme
    update_bmad_config
    
    show_summary
    
    echo -e "\n${GREEN}${CHECK} Migration complete!${NC}"
}

# Run main
main "$@"