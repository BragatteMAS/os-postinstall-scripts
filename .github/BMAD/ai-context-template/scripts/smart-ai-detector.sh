#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Smart AI Tool Detector
# Automatically detects which AI tools you use and creates appropriate config files

set -e

echo "🔍 Smart AI Tool Detector"
echo "========================"
echo ""

# Initialize variables
DETECTED_TOOLS=()
CLAUDE_DETECTED=false
COPILOT_DETECTED=false
CURSOR_DETECTED=false
CHATGPT_DETECTED=false

# Function to create AI config based on detection
create_ai_config() {
    local tool=$1
    echo "📝 Creating configuration for $tool..."
    
    case $tool in
        "claude")
            mkdir -p .ai
            cat > .ai/CLAUDE.md << 'EOF'
# Claude Assistant Configuration

> 🤖 Optimized for Claude's capabilities and context window

## Context Management

Claude works best with:
- Clear, structured information
- Explicit instructions about desired outcomes
- Context about the current task and its boundaries

## Project Context

[Your project context will go here - fill from 1-QUESTIONS.md]

## Working Instructions

### Claude's Strengths
- Deep reasoning and analysis
- Understanding complex requirements
- Maintaining context over long conversations
- Explaining technical concepts clearly

### Optimal Usage
1. Provide clear context at conversation start
2. Be specific about desired outcomes
3. Ask for explanations when needed
4. Use Claude for complex problem-solving

### Code Style Preferences
- [Your preferences here]

### Project-Specific Guidelines
- [Your guidelines here]

---

💡 **Remember**: Claude can maintain context across long conversations. Feel free to reference earlier parts of our discussion.
EOF
            ;;
            
        "copilot")
            mkdir -p .github
            cat > .github/copilot-instructions.md << 'EOF'
# GitHub Copilot Instructions

## Code Completion Preferences

### Preferred Patterns
- [Your patterns here]

### Naming Conventions
- Variables: [style]
- Functions: [style]
- Classes: [style]

### Comment Style
- Use [inline/block] comments
- Document [when]

### Avoid
- [Patterns to avoid]
- [Anti-patterns]

## Project Context
[Brief project description for Copilot context]
EOF
            ;;
            
        "cursor")
            cat > .cursorrules << 'EOF'
# Cursor AI Rules

You are an AI assistant helping with [project name] development.

## Project Context
[Your project context]

## Code Style
- Language: [primary language]
- Framework: [if applicable]
- Style guide: [link or description]

## Key Principles
1. [Principle 1]
2. [Principle 2]
3. [Principle 3]

## Avoid
- [Thing to avoid 1]
- [Thing to avoid 2]

## Preferred Solutions
When solving problems, prefer:
- [Approach 1]
- [Approach 2]
EOF
            ;;
            
        "chatgpt")
            mkdir -p .ai
            cat > .ai/OPENAI_CODEX.md << 'EOF'
# OpenAI/ChatGPT Configuration

## Model Instructions

You are assisting with development of [project name].

### Project Overview
[Brief description]

### Technical Stack
- Language: [primary]
- Framework: [if any]
- Database: [if any]

### Development Guidelines
1. [Guideline 1]
2. [Guideline 2]
3. [Guideline 3]

### Code Examples
```[language]
// Preferred style example
[code example]
```

### Common Tasks
- [Task 1]: [how to approach]
- [Task 2]: [how to approach]
EOF
            ;;
    esac
}

# Check for Claude usage
echo "🔍 Checking for Claude usage..."
if [[ -f "$HOME/.config/claude/config.json" ]] || \
   [[ -f "$HOME/.claude/config.json" ]] || \
   [[ -d ".ai" && -f ".ai/CLAUDE.md" ]]; then
    CLAUDE_DETECTED=true
    DETECTED_TOOLS+=("claude")
    echo "✅ Claude detected"
fi

# Check for GitHub Copilot
echo "🔍 Checking for GitHub Copilot..."
if [[ -d ".github" ]] || \
   [[ -f ".github/copilot-instructions.md" ]] || \
   git remote -v 2>/dev/null | grep -q "github.com"; then
    COPILOT_DETECTED=true
    DETECTED_TOOLS+=("copilot")
    echo "✅ GitHub Copilot likely in use"
fi

# Check for Cursor
echo "🔍 Checking for Cursor..."
if [[ -f ".cursorrules" ]] || \
   [[ -f "$HOME/.cursor/config.json" ]] || \
   [[ -d "$HOME/.cursor" ]]; then
    CURSOR_DETECTED=true
    DETECTED_TOOLS+=("cursor")
    echo "✅ Cursor detected"
fi

# Check for VSCode with AI extensions
echo "🔍 Checking for VS Code AI extensions..."
if [[ -f ".vscode/settings.json" ]]; then
    if grep -q "github.copilot\|tabnine\|codeium" .vscode/settings.json 2>/dev/null; then
        CHATGPT_DETECTED=true
        DETECTED_TOOLS+=("chatgpt")
        echo "✅ VS Code with AI extensions detected"
    fi
fi

# If no tools detected, ask user
if [ ${#DETECTED_TOOLS[@]} -eq 0 ]; then
    echo ""
    echo "❓ No AI tools automatically detected."
    echo ""
    echo "Which AI tool do you primarily use?"
    echo "1) Claude"
    echo "2) GitHub Copilot"
    echo "3) Cursor"
    echo "4) ChatGPT/GPT-4"
    echo "5) Other/Generic"
    echo ""
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1) DETECTED_TOOLS+=("claude") ;;
        2) DETECTED_TOOLS+=("copilot") ;;
        3) DETECTED_TOOLS+=("cursor") ;;
        4) DETECTED_TOOLS+=("chatgpt") ;;
        5) 
            echo "📝 Creating generic AI configuration..."
            bash $(dirname "$0")/minimal-setup.sh
            exit 0
            ;;
        *) 
            echo "Invalid choice. Creating generic configuration..."
            bash $(dirname "$0")/minimal-setup.sh
            exit 0
            ;;
    esac
fi

# Create configurations for detected tools
echo ""
echo "📦 Creating configurations..."
for tool in "${DETECTED_TOOLS[@]}"; do
    create_ai_config "$tool"
done

# Always create the base files
echo ""
echo "📝 Creating base AI context files..."
bash $(dirname "$0")/minimal-setup.sh

echo ""
echo "✅ Smart setup complete!"
echo ""
echo "📁 Created configurations for:"
for tool in "${DETECTED_TOOLS[@]}"; do
    case $tool in
        "claude") echo "   - Claude (.ai/CLAUDE.md)" ;;
        "copilot") echo "   - GitHub Copilot (.github/copilot-instructions.md)" ;;
        "cursor") echo "   - Cursor (.cursorrules)" ;;
        "chatgpt") echo "   - ChatGPT/OpenAI (.ai/OPENAI_CODEX.md)" ;;
    esac
done
echo ""
echo "📝 Next steps:"
echo "   1. Fill out .ai/1-QUESTIONS.md"
echo "   2. Customize the generated AI config files"
echo "   3. Commit these files to share context with your team"