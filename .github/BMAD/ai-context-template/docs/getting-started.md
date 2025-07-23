# Getting Started with AI Context Template

Welcome! This guide will help you set up AI context for your project in just a few minutes.

## 🎯 What is AI Context?

AI Context helps AI assistants (like Claude, Copilot, Cursor, ChatGPT) understand your project better by providing:
- Project overview and goals
- Technical stack information
- Coding conventions
- Architecture decisions
- Areas where AI can help most

## 🚀 Quick Start (2 minutes)

### Option 1: Minimal Setup
Perfect if you want to start immediately:

```bash
curl -fsSL https://raw.githubusercontent.com/BragatteMAS/ai-context-template/main/scripts/minimal-setup.sh | bash
```

This creates:
- `.ai/1-QUESTIONS.md` - Quick questionnaire
- `.ai/2-README.md` - Project overview
- `.ai/AI_ASSISTANT.md` - AI instructions

### Option 2: Smart Detection
Automatically detects your AI tools and creates optimized configs:

```bash
curl -fsSL https://raw.githubusercontent.com/BragatteMAS/ai-context-template/main/scripts/smart-ai-detector.sh | bash
```

### Option 3: Interactive Setup
For a guided experience with more options:

```bash
npx create-ai-context
```

## 📝 After Installation

### Step 1: Answer Questions
Open `.ai/1-QUESTIONS.md` and fill in your answers. This takes about 5 minutes and covers:
- What your project does
- Technical stack
- Current challenges
- How AI can help

### Step 2: Customize AI Instructions
Based on your AI tool:
- **Claude**: Edit `.ai/CLAUDE.md`
- **Copilot**: Edit `.github/copilot-instructions.md`
- **Cursor**: Edit `.cursorrules`
- **ChatGPT**: Edit `.ai/OPENAI_CODEX.md`
- **Other**: Edit `.ai/AI_ASSISTANT.md`

### Step 3: Commit and Share
```bash
git add .ai/ .github/ .cursorrules
git commit -m "Add AI context for better assistance"
git push
```

## 🎨 Customization

### Adding More Context
As your project grows, you can add:
- `.ai/ARCHITECTURE.md` - System design details
- `.ai/CONVENTIONS.md` - Coding standards
- `.ai/DEPENDENCIES.md` - External dependencies
- `.ai/API.md` - API documentation

### Project-Specific Rules
Each AI tool has its own format. Examples:

**For Claude (.ai/CLAUDE.md):**
```markdown
## Code Review Guidelines
- Check for security vulnerabilities
- Ensure error handling is comprehensive
- Verify test coverage for new features
```

**For Cursor (.cursorrules):**
```
When refactoring code:
1. Maintain backward compatibility
2. Update tests before changing implementation
3. Use descriptive commit messages
```

## 💡 Best Practices

### DO:
- ✅ Keep context files updated as project evolves
- ✅ Be specific about coding standards
- ✅ Include examples of good code patterns
- ✅ List areas where AI should be cautious

### DON'T:
- ❌ Include sensitive information (passwords, API keys)
- ❌ Make assumptions about AI capabilities
- ❌ Create overly complex rules
- ❌ Forget to update when requirements change

## 🔧 Troubleshooting

### Files not created?
- Check you have `curl` or `wget` installed
- Ensure you have write permissions in current directory
- Try manual setup from templates/ folder

### AI not following instructions?
- Make sure you're using the right config file
- Be more specific in your instructions
- Include examples of desired behavior

### Want to reset?
```bash
rm -rf .ai/ .github/copilot-instructions.md .cursorrules
# Then run setup again
```

## 📚 Next Steps

1. **Explore Templates**: Check `templates/` folder for more options
2. **See Examples**: Look at `examples/` for real implementations
3. **Advanced Setup**: Read about multi-language projects
4. **Team Collaboration**: Share context across your team

## 🤝 Contributing

Found a way to improve AI context? We'd love your contribution!
- Submit issues for problems
- Share your AI config examples
- Propose new templates

---

Remember: **"Adapt what is useful, reject what is useless, and add what is specifically your own."** - Bruce Lee