#!/bin/bash
set -euo pipefail
IFS=$'\n\t'# auto-generate-from-git.sh - Generate AI context from git history

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔍 Auto-generating AI context from git history${NC}"
echo -e "${BLUE}${'='.repeat(40)}${NC}"
echo ""

# Check if git repo
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    exit 1
fi

# Create .ai directory
mkdir -p .ai

# Function to analyze git history
analyze_git() {
    echo -e "${CYAN}📊 Analyzing repository...${NC}"
    
    # Get basic stats
    FIRST_COMMIT=$(git log --reverse --format="%ai" | head -1)
    TOTAL_COMMITS=$(git rev-list --count HEAD)
    CONTRIBUTORS=$(git shortlog -sn | wc -l)
    BRANCHES=$(git branch -r | wc -l)
    
    # Get most changed files
    HOT_FILES=$(git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10)
    
    # Get recent activity
    RECENT_COMMITS=$(git log --oneline -10)
    
    # Language statistics (if github-linguist available)
    if command -v github-linguist &> /dev/null; then
        LANGUAGES=$(github-linguist --breakdown)
    else
        # Fallback: count by extension
        LANGUAGES=$(find . -type f -name "*.*" | grep -v ".git" | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10)
    fi
}

# Analyze repository
analyze_git

# Generate QUESTIONS.md with auto-filled answers
cat > .ai/1-QUESTIONS.md << EOF
# Project Discovery Questions

> 🤖 Auto-generated from git history analysis

## 🎯 Project Identity

### What does this project do?
*[Auto-detected from README and commits]*
$(if [ -f "README.md" ]; then head -20 README.md | grep -v "^#" | grep -v "^$" | head -5; else echo "No README found - analyze commit messages to determine purpose"; fi)

### Who uses it?
*[Inferred from contributors and activity]*
- Contributors: $CONTRIBUTORS developers
- Repository age: Started on $FIRST_COMMIT
- Activity level: $TOTAL_COMMITS total commits

### What's the main tech stack?
*[Detected from file extensions and patterns]*
\`\`\`
$LANGUAGES
\`\`\`

### What are the most active areas?
*[Based on commit frequency]*
\`\`\`
$HOT_FILES
\`\`\`

### Recent development focus
*[Last 10 commits]*
\`\`\`
$RECENT_COMMITS
\`\`\`

## 📈 Repository Stats
- First commit: $FIRST_COMMIT
- Total commits: $TOTAL_COMMITS
- Contributors: $CONTRIBUTORS
- Branches: $BRANCHES

---
Auto-generated: $(date)
EOF

# Generate architecture insights
echo -e "\n${CYAN}🏗️ Detecting architecture patterns...${NC}"

# Look for common patterns
PATTERNS=""

# Check for web frameworks
if [ -f "package.json" ]; then
    if grep -q "react" package.json 2>/dev/null; then
        PATTERNS="${PATTERNS}\n- React application detected"
    fi
    if grep -q "express" package.json 2>/dev/null; then
        PATTERNS="${PATTERNS}\n- Express.js backend detected"
    fi
    if grep -q "next" package.json 2>/dev/null; then
        PATTERNS="${PATTERNS}\n- Next.js framework detected"
    fi
fi

if [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then
    if grep -q "django" requirements.txt 2>/dev/null || grep -q "django" Pipfile 2>/dev/null; then
        PATTERNS="${PATTERNS}\n- Django framework detected"
    fi
    if grep -q "flask" requirements.txt 2>/dev/null || grep -q "flask" Pipfile 2>/dev/null; then
        PATTERNS="${PATTERNS}\n- Flask framework detected"
    fi
fi

# Check for databases
if find . -name "*.sql" -o -name "*migrate*" | grep -q .; then
    PATTERNS="${PATTERNS}\n- SQL database usage detected"
fi

if grep -rq "mongodb\|mongoose" . --include="*.js" --include="*.ts" 2>/dev/null; then
    PATTERNS="${PATTERNS}\n- MongoDB usage detected"
fi

# Check for Docker
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    PATTERNS="${PATTERNS}\n- Docker containerization detected"
fi

# Generate architecture overview
cat > .ai/3-ARCHITECTURE.md << EOF
# Architecture Overview

> 🤖 Auto-detected from codebase analysis

## Detected Patterns
$PATTERNS

## Repository Structure
\`\`\`
$(tree -L 2 -I 'node_modules|.git|__pycache__|.pytest_cache|venv|env' 2>/dev/null || find . -type d -name .git -prune -o -type d -print | grep -v node_modules | sort)
\`\`\`

## Key Files
$(find . -name "main.*" -o -name "app.*" -o -name "index.*" -o -name "server.*" | grep -v node_modules | head -10)

## Configuration Files
$(find . -maxdepth 2 -name "*.config.*" -o -name "*.env*" -o -name "*rc" -o -name "*.json" | grep -v node_modules | head -10)

---
Auto-generated: $(date)
EOF

# Generate commit conventions from history
echo -e "\n${CYAN}📝 Analyzing commit patterns...${NC}"

# Analyze commit message patterns
COMMIT_PREFIXES=$(git log --oneline -100 | cut -d' ' -f2- | grep -E "^(feat|fix|docs|style|refactor|test|chore|build|ci|perf):" | cut -d':' -f1 | sort | uniq -c | sort -rn)

cat > .ai/4-CONVENTIONS.md << EOF
# Code Conventions

> 🤖 Auto-detected from git history

## Commit Message Patterns
*Based on last 100 commits*

\`\`\`
$COMMIT_PREFIXES
\`\`\`

## Branch Naming
*Detected branch patterns*
\`\`\`
$(git branch -a | grep -v HEAD | sed 's/.*\///' | grep -E "(feature|bugfix|hotfix|release|develop)" | sort | uniq -c || echo "No clear pattern detected")
\`\`\`

## File Naming Patterns
- Test files: $(find . -name "*test*" -o -name "*spec*" | grep -v node_modules | head -5 | xargs basename | tr '\n' ', ' || echo "No test files found")
- Config files: $(find . -maxdepth 3 -name "*.config.*" | xargs basename | tr '\n' ', ' || echo "Various patterns")

## Code Style Indicators
$(if [ -f ".eslintrc" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then echo "- ESLint configuration found"; fi)
$(if [ -f ".prettierrc" ] || [ -f "prettier.config.js" ]; then echo "- Prettier configuration found"; fi)
$(if [ -f ".editorconfig" ]; then echo "- EditorConfig found"; fi)
$(if [ -f "pyproject.toml" ] || [ -f "setup.cfg" ]; then echo "- Python formatting config found"; fi)

---
Auto-generated: $(date)
EOF

# Generate README summary
cat > .ai/2-README.md << EOF
# AI Context Summary

> 🤖 Auto-generated from repository analysis

## Repository Overview
- **Name**: $(basename $(pwd))
- **Started**: $FIRST_COMMIT
- **Activity**: $TOTAL_COMMITS commits by $CONTRIBUTORS contributors
- **Branches**: $BRANCHES

## Technology Stack
\`\`\`
$LANGUAGES
\`\`\`

## Project Structure
See \`.ai/3-ARCHITECTURE.md\` for detailed structure

## Recent Activity
Last 10 commits show focus on:
\`\`\`
$(git log --oneline -10 | cut -d' ' -f2- | head -5)
...
\`\`\`

## Hot Spots
Most frequently changed files:
\`\`\`
$(echo "$HOT_FILES" | head -5)
\`\`\`

## Quick Links
- [Questions & Answers](.ai/1-QUESTIONS.md)
- [Architecture Overview](.ai/3-ARCHITECTURE.md)
- [Code Conventions](.ai/4-CONVENTIONS.md)

---
Auto-generated: $(date)
EOF

# Success message
echo -e "\n${GREEN}✅ AI context generated successfully!${NC}"
echo -e "\n${YELLOW}📁 Created files:${NC}"
echo "  - .ai/1-QUESTIONS.md (with git analysis)"
echo "  - .ai/2-README.md (summary)"
echo "  - .ai/3-ARCHITECTURE.md (structure detection)"
echo "  - .ai/4-CONVENTIONS.md (pattern analysis)"

echo -e "\n${CYAN}🎯 Next steps:${NC}"
echo "1. Review auto-generated content in .ai/"
echo "2. Fill in any gaps or corrections"
echo "3. Add project-specific details"

echo -e "\n${BLUE}💡 Tips:${NC}"
echo "- Auto-detection is a starting point"
echo "- Human review improves accuracy"
echo "- Update regularly as project evolves"