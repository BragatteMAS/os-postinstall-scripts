#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#######################################
# update_installers_for_github.sh
# Purpose: Update installer scripts to use .github/AI_TOOLKIT structure
# Author: BragatteMAS
# License: MIT
# Version: 1.0.0
#######################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Updating installer scripts for .github structure...${NC}"

#######################################
# Create BMAD installer wrapper
#######################################
create_bmad_installer() {
    cat > install_bmad_github.sh << 'EOF'
#!/usr/bin/env bash
# Install BMAD in .github/AI_TOOLKIT structure

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Installing BMAD in .github/AI_TOOLKIT structure...${NC}"

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    echo "Please run this from your project root"
    exit 1
fi

# Create structure
mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
mkdir -p .github/AI_TOOLKIT/{agents,commands,templates,workflows,config}
mkdir -p .github/PROJECT_DOCS/adrs

# Install BMAD to temporary location
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Install BMAD
if command -v pnpm &> /dev/null; then
    pnpm dlx bmad-method@latest install --full --ide cursor
else
    npx bmad-method@latest install --full --ide cursor
fi

# Move to correct location
cd - > /dev/null
if [[ -d "$TEMP_DIR/.bmad-core" ]]; then
    mv "$TEMP_DIR/.bmad-core"/* .github/AI_TOOLKIT/ 2>/dev/null || true
fi

# Clean up
rm -rf "$TEMP_DIR"

# Create location config
cat > .github/AI_TOOLKIT/config/location.yaml << 'CONFIG'
bmad:
  root: .github/AI_TOOLKIT
  agents: .github/AI_TOOLKIT/agents
  commands: .github/AI_TOOLKIT/commands
CONFIG

# Link CLAUDE.md if exists
if [[ -f "$HOME/CLAUDE.md" ]]; then
    ln -sf "$HOME/CLAUDE.md" .github/METHODS/CLAUDE.md
fi

echo -e "${GREEN}✅ BMAD installed in .github/AI_TOOLKIT${NC}"
echo -e "${YELLOW}📝 Don't forget to run: ./migrate_to_github.sh${NC}"
EOF
    
    chmod +x install_bmad_github.sh
    echo -e "${GREEN}✅ Created install_bmad_github.sh${NC}"
}

#######################################
# Update ai-setup function in zshrc
#######################################
update_zshrc_function() {
    # Create updated function
    cat > ai-setup-github.zsh << 'EOF'
# Updated ai-setup function for .github structure
ai-setup() {
    echo "🤖 Setting up AI tools in .github/AI_TOOLKIT..."
    
    # Check if in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "⚠️  Warning: Not in a git repository. Initialize with 'git init' first? (recommended)"
        echo -n "Continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "❌ Setup cancelled"
            return 1
        fi
    fi
    
    # Create .github structure
    mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
    mkdir -p .github/AI_TOOLKIT/{agents,commands,templates,workflows,config}
    
    # Install BMAD Method to temp location
    local temp_dir=$(mktemp -d)
    (
        cd "$temp_dir"
        if command -v pnpm &> /dev/null; then
            pnpm dlx bmad-method@latest install --full --ide cursor
        else
            npx bmad-method@latest install --full --ide cursor
        fi
    )
    
    # Move to .github/AI_TOOLKIT
    if [[ -d "$temp_dir/.bmad-core" ]]; then
        mv "$temp_dir/.bmad-core"/* .github/AI_TOOLKIT/ 2>/dev/null || true
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Link CLAUDE.md
    if [[ -f "$HOME/CLAUDE.md" ]]; then
        ln -sf "$HOME/CLAUDE.md" .github/METHODS/CLAUDE.md
    fi
    
    # Create .gitattributes if needed
    if ! grep -q ".github/AI_TOOLKIT" .gitattributes 2>/dev/null; then
        echo ".github/AI_TOOLKIT/** linguist-generated=true" >> .gitattributes
        echo ".github/AI_TOOLKIT/** -diff" >> .gitattributes
    fi
    
    echo "✅ AI tools installed in .github/AI_TOOLKIT!"
    echo "💡 Use 'git log -- ':!.github'' to see only product commits"
}

# Product-focused git aliases
alias glogp="git log --oneline -- ':!.github'"
alias gdiffp="git diff -- ':!.github'"
alias gstatusp="git status -- ':!.github'"
alias gaddp="git add -- ':!.github'"
alias gcfeat="git commit -m 'feat: '"
alias gcfix="git commit -m 'fix: '"
alias gcchore="git commit -m 'chore(.github): '"
EOF
    
    echo -e "${GREEN}✅ Created ai-setup-github.zsh${NC}"
    echo -e "${YELLOW}Add this to your .zshrc: source ~/path/to/ai-setup-github.zsh${NC}"
}

#######################################
# Create setup script for new projects
#######################################
create_new_project_setup() {
    cat > setup-ai-project.sh << 'EOF'
#!/usr/bin/env bash
# Quick setup for new AI-enhanced projects

set -euo pipefail

PROJECT_NAME=${1:-my-project}

echo "🚀 Creating new AI-enhanced project: $PROJECT_NAME"

# Create project
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize git
git init

# Create basic structure
mkdir -p src tests docs
touch README.md

# Create .github AI structure
mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
mkdir -p .github/AI_TOOLKIT/{agents,commands,templates,workflows,config}
mkdir -p .github/PROJECT_DOCS/adrs

# Create .gitattributes
cat > .gitattributes << 'GITATTR'
# AI Tooling - mark as generated
.github/AI_TOOLKIT/** linguist-generated=true
.github/METHODS/** linguist-documentation=true
.github/PROJECT_DOCS/** linguist-documentation=true

# Reduce diff noise
.github/AI_TOOLKIT/** -diff
.github/METHODS/** -diff
GITATTR

# Create initial PRD template
cat > .github/PROJECT_DOCS/PRD.md << 'PRD'
# Product Requirements Document

## Project: ${PROJECT_NAME}

### Overview
[Project description]

### Objectives
- [ ] Objective 1
- [ ] Objective 2

### Requirements
#### Functional Requirements
- FR1: [Description]
- FR2: [Description]

#### Non-Functional Requirements
- NFR1: [Description]
- NFR2: [Description]
PRD

# Link CLAUDE.md if available
if [[ -f "$HOME/CLAUDE.md" ]]; then
    ln -sf "$HOME/CLAUDE.md" .github/METHODS/CLAUDE.md
fi

# Create README
cat > README.md << 'README'
# ${PROJECT_NAME}

## Overview
[Project description]

## Getting Started
```bash
# Install dependencies
npm install

# Run tests
npm test

# Start development
npm run dev
```

## Project Structure
```
├── src/           # Source code
├── tests/         # Test files
├── docs/          # User documentation
└── .github/       # AI tooling & project docs
```

## Contributing
See [Contributing Guide](.github/PROJECT_DOCS/CONTRIBUTING.md)
README

echo "✅ Project created successfully!"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. ai-setup  # Install BMAD"
echo "3. Start coding!"
EOF
    
    chmod +x setup-ai-project.sh
    echo -e "${GREEN}✅ Created setup-ai-project.sh${NC}"
}

#######################################
# Main execution
#######################################
main() {
    echo -e "${BLUE}Creating updated installer scripts...${NC}\n"
    
    create_bmad_installer
    update_zshrc_function
    create_new_project_setup
    
    echo -e "\n${GREEN}✅ All scripts updated!${NC}"
    echo -e "\n${YELLOW}Available scripts:${NC}"
    echo -e "  • ${BLUE}install_bmad_github.sh${NC} - Install BMAD in .github structure"
    echo -e "  • ${BLUE}ai-setup-github.zsh${NC} - Updated zsh functions"
    echo -e "  • ${BLUE}setup-ai-project.sh${NC} - Create new AI-enhanced project"
    echo -e "\n${YELLOW}For existing projects:${NC}"
    echo -e "  Run ${GREEN}./migrate_to_github.sh${NC} to reorganize"
}

main "$@"