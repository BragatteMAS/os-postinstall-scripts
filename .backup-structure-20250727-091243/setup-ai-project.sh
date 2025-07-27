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
