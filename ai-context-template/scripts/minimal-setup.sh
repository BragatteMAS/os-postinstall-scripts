#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Minimal AI Context Setup Script
# Creates the bare minimum files needed for AI assistance
# Time: ~2 minutes

set -e

echo "🚀 AI Context Minimal Setup"
echo "=========================="
echo ""

# Create .ai directory
mkdir -p .ai

# Download templates
echo "📥 Downloading templates..."

# Option 1: From GitHub (replace with your repo URL)
BASE_URL="https://raw.githubusercontent.com/BragatteMAS/ai-context-template/main/templates"

# Download 1-QUESTIONS.md
if command -v curl &> /dev/null; then
    curl -fsSL "$BASE_URL/1-QUESTIONS.md" -o .ai/1-QUESTIONS.md
elif command -v wget &> /dev/null; then
    wget -q "$BASE_URL/1-QUESTIONS.md" -O .ai/1-QUESTIONS.md
else
    echo "❌ Error: Neither curl nor wget found. Please install one."
    exit 1
fi

# Download AI_ASSISTANT.md
if command -v curl &> /dev/null; then
    curl -fsSL "$BASE_URL/AI_ASSISTANT.md" -o .ai/AI_ASSISTANT.md
else
    wget -q "$BASE_URL/AI_ASSISTANT.md" -O .ai/AI_ASSISTANT.md
fi

# Create basic 2-README.md
cat > .ai/2-README.md << 'EOF'
# Project Overview for AI Assistants

> 📝 This file will be auto-generated from your answers in 1-QUESTIONS.md

## Quick Start

This project needs AI assistance with:
- [ ] Understanding the codebase structure
- [ ] Following coding conventions
- [ ] Implementing new features
- [ ] Debugging and optimization

## Key Information

Please refer to:
1. `1-QUESTIONS.md` - For project context
2. `AI_ASSISTANT.md` - For working guidelines

---

💡 **Next Step**: Fill out the questions in `1-QUESTIONS.md` to provide context for AI assistants.
EOF

# Update date in AI_ASSISTANT.md
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/\${CURRENT_DATE}/$(date +%Y-%m-%d)/g" .ai/AI_ASSISTANT.md
else
    # Linux
    sed -i "s/\${CURRENT_DATE}/$(date +%Y-%m-%d)/g" .ai/AI_ASSISTANT.md
fi

echo ""
echo "✅ Minimal setup complete!"
echo ""
echo "📁 Created files:"
echo "   .ai/1-QUESTIONS.md    - Project questionnaire"
echo "   .ai/2-README.md       - AI overview (placeholder)"
echo "   .ai/AI_ASSISTANT.md   - AI instructions"
echo ""
echo "📝 Next steps:"
echo "   1. Open .ai/1-QUESTIONS.md and answer the questions"
echo "   2. Customize .ai/AI_ASSISTANT.md with your project specifics"
echo "   3. Your AI assistant will have context to help effectively!"
echo ""
echo "💡 Tip: Add .ai/ to your git repository to share context with your team"