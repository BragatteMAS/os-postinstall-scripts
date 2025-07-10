#!/bin/bash
set -euo pipefail
IFS=$'\n\t'# smart-ai-detector.sh - Detects AI assistant and creates appropriate config

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🤖 AI Assistant Smart Detector${NC}"
echo -e "${BLUE}==============================${NC}"
echo ""

# Function to detect AI assistant from environment
detect_ai_assistant() {
    local detected=""
    
    # Check for Cursor
    if [ -f ".cursorrules" ] || [ -n "$CURSOR_EDITOR" ]; then
        detected="cursor"
        echo -e "${GREEN}✓ Detected: Cursor${NC}"
        return
    fi
    
    # Check for GitHub Copilot
    if [ -f ".github/copilot-instructions.md" ] || [ -d ".github" ]; then
        detected="copilot"
        echo -e "${GREEN}✓ Detected: GitHub workspace (Copilot likely)${NC}"
        return
    fi
    
    # Check for VS Code with extensions
    if [ -d ".vscode" ]; then
        if [ -f ".vscode/extensions.json" ]; then
            if grep -q "github.copilot" .vscode/extensions.json 2>/dev/null; then
                detected="copilot"
                echo -e "${GREEN}✓ Detected: VS Code with Copilot${NC}"
                return
            fi
        fi
    fi
    
    # Check from user's command history
    if command -v history &> /dev/null; then
        if history | grep -q "claude\|anthropic" 2>/dev/null; then
            detected="claude"
            echo -e "${GREEN}✓ Detected: Claude usage in history${NC}"
            return
        fi
    fi
    
    # If no detection, ask user
    if [ -z "$detected" ]; then
        echo -e "${YELLOW}Could not auto-detect AI assistant.${NC}"
        echo ""
        echo "Which AI assistant do you primarily use?"
        echo "1) Claude (Anthropic)"
        echo "2) GitHub Copilot"
        echo "3) Cursor"
        echo "4) ChatGPT/OpenAI"
        echo "5) Gemini"
        echo "6) Multiple/Other"
        echo ""
        read -p "Select (1-6): " choice
        
        case $choice in
            1) detected="claude" ;;
            2) detected="copilot" ;;
            3) detected="cursor" ;;
            4) detected="openai" ;;
            5) detected="gemini" ;;
            6) detected="generic" ;;
            *) detected="generic" ;;
        esac
    fi
    
    echo "$detected"
}

# Function to create Claude-specific config
create_claude_config() {
    cat > .ai/CLAUDE.md << 'EOF'
# Claude-Specific Instructions

> 🤖 **Optimized for Claude (Anthropic)**

## Your Identity
You are Claude, an AI assistant by Anthropic, helping with [PROJECT_NAME].

## Claude-Specific Strengths to Leverage
1. **Deep Analysis**: Use your reasoning capabilities for complex problems
2. **Long Context**: Handle large files and maintain context across conversations
3. **Structured Thinking**: Break down problems systematically
4. **Detailed Explanations**: Provide thorough explanations when needed
5. **Code Understanding**: Analyze code patterns and suggest improvements

## Project Context
[AUTO-FILLED from 1-QUESTIONS.md]

## Communication Style
- Be concise by default, detailed when asked
- Use structured responses (bullet points, numbered lists)
- Acknowledge uncertainty when appropriate
- Suggest alternatives when relevant

## Task Approach
1. **Understand First**: Analyze the full context before acting
2. **Plan Then Execute**: Outline approach before implementation
3. **Validate Thoroughly**: Check edge cases and error handling
4. **Document Clearly**: Explain non-obvious decisions

## Project-Specific Rules
[TO BE CUSTOMIZED]

## Common Commands
```bash
# Development
[DEV_COMMAND]

# Testing (ALWAYS run before completing)
[TEST_COMMAND]

# Linting
[LINT_COMMAND]
```

## Error Handling Approach
- Anticipate common errors
- Provide helpful error messages
- Suggest recovery strategies
- Log appropriately

## Code Review Checklist
- [ ] Follows project conventions
- [ ] Includes appropriate tests
- [ ] Handles errors gracefully
- [ ] Performance considered
- [ ] Security reviewed
- [ ] Documentation updated
EOF
    echo -e "${GREEN}✓ Created .ai/CLAUDE.md${NC}"
}

# Function to create Cursor-specific config
create_cursor_config() {
    cat > .cursorrules << 'EOF'
# Cursor AI Rules

You are an AI programming assistant helping with [PROJECT_NAME].

## Project Context
[AUTO-FILLED from 1-QUESTIONS.md]

## Rules
1. Follow existing code patterns
2. Write tests for new features
3. Use meaningful variable names
4. Keep functions small and focused
5. Document complex logic

## Style Guidelines
- Indentation: [SPACES/TABS]
- Line length: [80/100/120]
- Naming: [camelCase/snake_case]

## Preferred Patterns
[PROJECT_PATTERNS]

## Avoid
- Global variables
- Deep nesting
- Commented-out code
- Console logs in production

## Commands
Test: [TEST_COMMAND]
Build: [BUILD_COMMAND]
Lint: [LINT_COMMAND]
EOF
    echo -e "${GREEN}✓ Created .cursorrules${NC}"
}

# Function to create GitHub Copilot config
create_copilot_config() {
    mkdir -p .github
    cat > .github/copilot-instructions.md << 'EOF'
# GitHub Copilot Instructions

## Code Style Preferences
- Prefer async/await over callbacks
- Use functional programming where appropriate
- Include error handling in all functions
- Add JSDoc/docstring comments

## Project Patterns
[AUTO-FILLED from project analysis]

## Naming Conventions
- Variables: camelCase
- Functions: camelCase
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE

## Testing
- Write tests alongside implementation
- Aim for 80%+ coverage
- Test edge cases

## Security
- Never hardcode secrets
- Validate all inputs
- Use parameterized queries
- Follow OWASP guidelines

## Performance
- Optimize for readability first
- Profile before optimizing
- Consider caching strategies
- Use appropriate data structures
EOF
    echo -e "${GREEN}✓ Created .github/copilot-instructions.md${NC}"
}

# Function to create generic AI config
create_generic_config() {
    cat > .ai/AI_ASSISTANT.md << 'EOF'
# AI Assistant Instructions

> 🤖 **Universal AI Assistant Configuration**

## Project Overview
[AUTO-FILLED from 1-QUESTIONS.md]

## Key Guidelines
1. **Code Quality**: Maintain high standards
2. **Testing**: Always include tests
3. **Documentation**: Update docs with code
4. **Security**: Follow best practices
5. **Performance**: Consider efficiency

## Development Workflow
1. Understand the requirement
2. Check existing patterns
3. Implement solution
4. Write/update tests
5. Update documentation

## Essential Commands
```bash
# Development
[DEV_COMMAND]

# Testing
[TEST_COMMAND]

# Build
[BUILD_COMMAND]

# Lint
[LINT_COMMAND]
```

## Project Conventions
[TO BE FILLED based on project]

## Common Tasks
| Task | Approach | Validation |
|------|----------|------------|
| New Feature | Follow existing patterns | Tests pass |
| Bug Fix | Write failing test first | All tests pass |
| Refactor | Ensure tests exist | No behavior change |

## Important Notes
[PROJECT_SPECIFIC_NOTES]
EOF
    echo -e "${GREEN}✓ Created .ai/AI_ASSISTANT.md${NC}"
}

# Main execution
detected_ai=$(detect_ai_assistant)

echo ""
echo -e "${CYAN}Creating configuration for: ${detected_ai}${NC}"
echo ""

# Create appropriate config based on detection
case $detected_ai in
    "claude")
        create_claude_config
        ;;
    "cursor")
        create_cursor_config
        ;;
    "copilot")
        create_copilot_config
        ;;
    "openai")
        create_generic_config
        mv .ai/AI_ASSISTANT.md .ai/OPENAI_CODEX.md
        echo -e "${YELLOW}📝 Renamed to .ai/OPENAI_CODEX.md${NC}"
        ;;
    "gemini")
        create_generic_config
        mv .ai/AI_ASSISTANT.md .ai/GEMINI_CONTEXT.md
        echo -e "${YELLOW}📝 Renamed to .ai/GEMINI_CONTEXT.md${NC}"
        ;;
    *)
        create_generic_config
        ;;
esac

echo ""
echo -e "${GREEN}✅ AI configuration created successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the generated configuration"
echo "2. Fill in [PLACEHOLDER] values with your project specifics"
echo "3. Customize rules based on your preferences"
echo ""
echo -e "${BLUE}💡 Tip:${NC} The configuration will be automatically detected by your AI assistant!"