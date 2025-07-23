#!/bin/bash
set -euo pipefail
IFS=$'\n\t'# minimal-setup.sh - Ultra-simple AI context setup (2 files only)

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AI Context Minimal Setup${NC}"
echo -e "${BLUE}=========================${NC}"
echo ""

# Create .ai directory
mkdir -p .ai

# Create QUESTIONS.md
cat > .ai/1-QUESTIONS.md << 'EOF'
# Quick Project Assessment

> 💡 **Tip**: Answer these 5 questions to help AI assistants understand your project

## 1. What does this project do?
<!-- One paragraph summary -->
[Your answer here]

## 2. Who uses it?
<!-- Target users, audience, or systems -->
[Your answer here]

## 3. What's the main tech stack?
<!-- Languages, frameworks, databases, tools -->
[Your answer here]

## 4. What's the biggest current challenge?
<!-- Technical debt, bugs, features, performance, etc. -->
[Your answer here]

## 5. How can AI best help you?
<!-- Code review, debugging, documentation, refactoring, etc. -->
[Your answer here]

---

📝 **Next Steps**:
1. Answer the questions above
2. Save this file
3. AI assistants can now understand your project context!

Optional: Run `ai-readme-gen` to auto-generate README from your answers
EOF

# Create minimal README template
cat > .ai/2-README.md << 'EOF'
# Project Overview

> 🤖 This file will be auto-generated from your answers in 1-QUESTIONS.md

## Quick Summary
*[Generated from Question 1]*

## Target Audience  
*[Generated from Question 2]*

## Technology Stack
*[Generated from Question 3]*

## Current Focus
*[Generated from Question 4]*

## AI Assistance Areas
*[Generated from Question 5]*

---

Last updated: $(date +%Y-%m-%d)
EOF

# Create AI Assistant instructions
cat > .ai/AI_ASSISTANT.md << 'EOF'
# AI Assistant Instructions

> 🤖 **START HERE** - Direct instructions for AI assistants

## Quick Context
*[This section will be filled based on your answers in 1-QUESTIONS.md]*

## Key Rules for This Project
1. Always run tests before marking task complete
2. Follow existing code patterns
3. Update documentation when changing functionality

## Essential Commands
```bash
# Development
# [Add your dev command here, e.g., npm start, python app.py]

# Tests  
# [Add your test command here, e.g., npm test, pytest]

# Lint/Format
# [Add your lint command here, e.g., npm run lint, black .]
```

## Project-Specific Guidelines
- [ ] Security: Never commit secrets or API keys
- [ ] Performance: Keep response times under 200ms
- [ ] Style: Follow language-specific conventions
- [ ] Testing: Maintain >80% code coverage

## Common Tasks
| Task | First Step | Success Criteria |
|------|------------|------------------|
| Add Feature | Check similar code | Tests pass |
| Fix Bug | Write failing test | All tests green |
| Refactor | Ensure tests exist | No behavior change |

## Anti-Patterns to Avoid
- 🚫 Don't skip tests
- 🚫 Don't hardcode values
- 🚫 Don't ignore linting errors

---

💡 **Tip**: Customize this file with your project's specific needs!
EOF

# Success message
echo -e "${GREEN}✅ Minimal setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Created 3 essential files:${NC}"
echo "  • .ai/1-QUESTIONS.md - Answer these to describe your project"
echo "  • .ai/2-README.md - Will be auto-generated from your answers"
echo "  • .ai/AI_ASSISTANT.md - AI instructions (customize as needed)"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Answer questions in .ai/1-QUESTIONS.md"
echo "2. Customize .ai/AI_ASSISTANT.md with your project's commands"
echo "3. AI assistants can now understand and help with your project!"
echo ""
echo -e "${BLUE}💡 Want more features later?${NC}"
echo "Run: curl -fsSL https://[your-upgrade-script-url] | bash"