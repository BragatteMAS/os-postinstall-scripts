#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# AI Context Template - Auto-Generate from Git
# Analyzes git history and project structure to auto-generate context

echo "🔍 AI Context Template - Auto-Generate from Git"
echo "=============================================="
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not a git repository!"
    echo "Please run this script from within a git project."
    exit 1
fi

# Create .ai directory
mkdir -p .ai

# Get project info from git
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
FIRST_COMMIT_DATE=$(git log --reverse --format="%ad" --date=short | head -1)
LATEST_COMMIT_DATE=$(git log -1 --format="%ad" --date=short)
CONTRIBUTOR_COUNT=$(git shortlog -sn | wc -l | tr -d ' ')
TOTAL_COMMITS=$(git rev-list --all --count)

# Detect primary language
echo "🔍 Analyzing project structure..."
declare -A LANG_COUNT

# Count files by extension
while IFS= read -r file; do
    ext="${file##*.}"
    case "$ext" in
        js|jsx) ((LANG_COUNT["JavaScript"]++)) ;;
        ts|tsx) ((LANG_COUNT["TypeScript"]++)) ;;
        py) ((LANG_COUNT["Python"]++)) ;;
        go) ((LANG_COUNT["Go"]++)) ;;
        rs) ((LANG_COUNT["Rust"]++)) ;;
        java) ((LANG_COUNT["Java"]++)) ;;
        rb) ((LANG_COUNT["Ruby"]++)) ;;
        php) ((LANG_COUNT["PHP"]++)) ;;
        cs) ((LANG_COUNT["C#"]++)) ;;
        cpp|cc|cxx) ((LANG_COUNT["C++"]++)) ;;
        c) ((LANG_COUNT["C"]++)) ;;
        swift) ((LANG_COUNT["Swift"]++)) ;;
        kt) ((LANG_COUNT["Kotlin"]++)) ;;
    esac
done < <(git ls-files)

# Find primary language
PRIMARY_LANG=""
MAX_COUNT=0
for lang in "${!LANG_COUNT[@]}"; do
    if [[ ${LANG_COUNT[$lang]} -gt $MAX_COUNT ]]; then
        MAX_COUNT=${LANG_COUNT[$lang]}
        PRIMARY_LANG=$lang
    fi
done

# Detect package manager and frameworks
TECH_STACK=""
TEST_CMD=""
BUILD_CMD=""
DEV_CMD=""

if [[ -f "package.json" ]]; then
    TECH_STACK="Node.js"
    TEST_CMD="npm test"
    BUILD_CMD="npm run build"
    DEV_CMD="npm start"
    
    # Check for specific frameworks
    if grep -q "react" package.json 2>/dev/null; then
        TECH_STACK="$TECH_STACK, React"
    fi
    if grep -q "vue" package.json 2>/dev/null; then
        TECH_STACK="$TECH_STACK, Vue"
    fi
    if grep -q "express" package.json 2>/dev/null; then
        TECH_STACK="$TECH_STACK, Express"
    fi
    if grep -q "next" package.json 2>/dev/null; then
        TECH_STACK="$TECH_STACK, Next.js"
    fi
elif [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
    TECH_STACK="Python"
    TEST_CMD="python -m pytest"
    BUILD_CMD="python setup.py build"
    DEV_CMD="python main.py"
    
    if [[ -f "requirements.txt" ]]; then
        if grep -q "django" requirements.txt 2>/dev/null; then
            TECH_STACK="$TECH_STACK, Django"
            DEV_CMD="python manage.py runserver"
        fi
        if grep -q "flask" requirements.txt 2>/dev/null; then
            TECH_STACK="$TECH_STACK, Flask"
        fi
    fi
elif [[ -f "go.mod" ]]; then
    TECH_STACK="Go"
    TEST_CMD="go test ./..."
    BUILD_CMD="go build"
    DEV_CMD="go run ."
elif [[ -f "Cargo.toml" ]]; then
    TECH_STACK="Rust"
    TEST_CMD="cargo test"
    BUILD_CMD="cargo build --release"
    DEV_CMD="cargo run"
fi

# Get recent activity
RECENT_FILES=$(git log -20 --name-only --pretty=format: | sort | uniq -c | sort -rn | head -10 | awk '{print $2}')

# Analyze commit patterns
COMMIT_TYPES=$(git log --oneline -100 | cut -d' ' -f2- | grep -E "^(feat|fix|docs|style|refactor|test|chore)" | cut -d':' -f1 | sort | uniq -c | sort -rn)

# Generate 1-QUESTIONS.md
echo "📝 Generating 1-QUESTIONS.md..."
cat > .ai/1-QUESTIONS.md << EOF
# Project Discovery Questions

> 🤖 Auto-generated from git history on $(date +%Y-%m-%d)

## 🎯 Project Identity

### What exactly are we building?
**Answer**: ${PROJECT_NAME} - [Please provide a one paragraph description]

### What problem does this solve?
**Answer**: [Auto-detection found ${PRIMARY_LANG} project with ${TOTAL_COMMITS} commits. Please describe the problem being solved]

### What makes this solution unique?
**Answer**: [Please describe key differentiators]

## 👥 Users & Stakeholders

### Primary Users
- **Role/Title**: [To be filled]
- **Technical Level**: [Based on complexity, appears to be for Intermediate/Advanced users]
- **Main Goals**: [To be filled]
- **Pain Points**: [To be filled]
- **Success Criteria**: [To be filled]

## 🛠️ Technical Approach

### Current Tech Stack
**Answer**: ${PRIMARY_LANG}${TECH_STACK:+, $TECH_STACK}

### Why this tech stack?
**Answer**: [Please explain technology choices]

### What are the non-negotiables?
**Answer**: [Technical requirements that cannot be compromised]

## 📊 Success Metrics

### How do we measure success?
- **Quantitative**: [To be filled]
- **Qualitative**: [To be filled]

### What's the MVP?
**Answer**: [Minimum features for first release]

## 🚀 Project Lifecycle

### Current Status
- **Phase**: Active Development
- **First Commit**: ${FIRST_COMMIT_DATE}
- **Latest Activity**: ${LATEST_COMMIT_DATE}
- **Contributors**: ${CONTRIBUTOR_COUNT}
- **Total Commits**: ${TOTAL_COMMITS}

### Development Activity
Most active files:
$(echo "$RECENT_FILES" | head -5 | sed 's/^/- /')

### Next Milestones
1. **Next Week**: [To be filled]
2. **Next Month**: [To be filled]
3. **Next Quarter**: [To be filled]

## 🔄 Development Process

### How do we work?
- **Methodology**: [Detected conventional commits. Using Agile?]
- **Team Size**: ${CONTRIBUTOR_COUNT} contributors
- **Release Cycle**: [To be filled]

### Commit Patterns
${COMMIT_TYPES:-No conventional commits detected}

## Essential Commands
- **Test**: ${TEST_CMD:-[Please specify test command]}
- **Build**: ${BUILD_CMD:-[Please specify build command]}
- **Dev**: ${DEV_CMD:-[Please specify dev command]}
EOF

# Generate 2-README.md
echo "📝 Generating 2-README.md..."
cat > .ai/2-README.md << EOF
# ${PROJECT_NAME} - AI Context

> 🤖 Auto-generated from git analysis on $(date +%Y-%m-%d)

## Project Summary
${PROJECT_NAME} is a ${PRIMARY_LANG} project that has been in development since ${FIRST_COMMIT_DATE}.

## Technical Stack
- Primary Language: ${PRIMARY_LANG}
${TECH_STACK:+- Frameworks/Tools: $TECH_STACK}

## Project Statistics
- Age: Since ${FIRST_COMMIT_DATE}
- Contributors: ${CONTRIBUTOR_COUNT}
- Total Commits: ${TOTAL_COMMITS}
- Last Updated: ${LATEST_COMMIT_DATE}

## How AI Can Help
Based on the project structure, AI can assist with:
- Code generation in ${PRIMARY_LANG}
- Test writing and coverage improvement
- Documentation updates
- Code review and best practices
- Performance optimization suggestions

## Key Commands
\`\`\`bash
# Development
${DEV_CMD:-# Please specify dev command}

# Testing
${TEST_CMD:-# Please specify test command}

# Build
${BUILD_CMD:-# Please specify build command}
\`\`\`

## Active Development Areas
Recent activity in:
$(echo "$RECENT_FILES" | head -5 | sed 's/^/- /')
EOF

# Generate basic AI_ASSISTANT.md
echo "📝 Generating AI_ASSISTANT.md..."
cat > .ai/AI_ASSISTANT.md << EOF
# AI Assistant Instructions

> 🤖 Auto-generated configuration for ${PROJECT_NAME}

## Project Context
You are helping with ${PROJECT_NAME}, a ${PRIMARY_LANG} project${TECH_STACK:+ using $TECH_STACK}.

## Development History
- Started: ${FIRST_COMMIT_DATE}
- Contributors: ${CONTRIBUTOR_COUNT}
- Commits: ${TOTAL_COMMITS}
- Last Update: ${LATEST_COMMIT_DATE}

## Essential Commands
\`\`\`bash
# Development
${DEV_CMD:-# Please configure dev command}

# Tests (ALWAYS RUN BEFORE COMPLETING)
${TEST_CMD:-# Please configure test command}

# Build
${BUILD_CMD:-# Please configure build command}
\`\`\`

## Code Patterns
Based on git history, this project follows:
$(if [[ -n "$COMMIT_TYPES" ]]; then
    echo "- Conventional commits (feat, fix, docs, etc.)"
else
    echo "- Standard commit messages"
fi)

## Active Files
Pay special attention to these frequently modified files:
$(echo "$RECENT_FILES" | head -5 | sed 's/^/- /')

## Project Rules
1. Follow existing ${PRIMARY_LANG} patterns in the codebase
2. Maintain consistent code style
3. Write tests for new features
4. Update documentation when needed

## Quality Standards
- Test all changes
- Follow existing patterns
- Consider performance
- Ensure security best practices
EOF

# Detect and suggest AI tool
echo ""
echo "🤖 Detecting AI tool usage..."
bash "$(dirname "$0")/smart-ai-detector.sh"

echo ""
echo "✅ Auto-generation complete!"
echo ""
echo "📁 Created files:"
echo "   - .ai/1-QUESTIONS.md (partially filled)"
echo "   - .ai/2-README.md (auto-generated overview)"
echo "   - .ai/AI_ASSISTANT.md (basic configuration)"
echo ""
echo "📋 Next steps:"
echo "1. Review and complete the [To be filled] sections in .ai/1-QUESTIONS.md"
echo "2. Verify the auto-detected information is accurate"
echo "3. Run the smart AI detector if you want AI-specific config"
echo ""
echo "💡 Tip: The more complete your answers, the better AI can assist you!"