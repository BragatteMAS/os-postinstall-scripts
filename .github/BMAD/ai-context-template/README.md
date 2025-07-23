# AI Context Template 🤖

> **Get started in 5 minutes** - Help AI assistants understand your project instantly

A lightweight, easy-to-use template system that helps AI assistants (Claude, GitHub Copilot, Cursor, ChatGPT, etc.) work more effectively with your codebase.

## ✨ Key Features

- **🚀 5-minute setup** - Start with just 3 essential files
- **🤖 Works with any AI** - Claude, Copilot, Cursor, ChatGPT, and more
- **📈 Grows with your project** - Add complexity only when needed
- **🔍 Smart AI detection** - Automatically configures for your AI tool
- **📝 No lock-in** - Just markdown files, remove anytime

## 🎯 Quick Start

### Option 1: Minimal Setup (2 minutes)
```bash
# Creates 3 essential files in .ai/ directory
curl -fsSL https://raw.githubusercontent.com/yourusername/ai-context-template/main/scripts/minimal-setup.sh | bash
```

### Option 2: Smart Setup (3 minutes)
```bash
# Auto-detects your AI tool and creates optimized config
curl -fsSL https://raw.githubusercontent.com/yourusername/ai-context-template/main/scripts/smart-ai-detector.sh | bash
```

### Option 3: Interactive Setup (5 minutes)
```bash
# Interactive wizard
npx create-ai-context

# Or with node
node scripts/interactive-setup.js
```

### Option 4: Auto-Generate from Git
```bash
# Analyzes your git history and creates context
curl -fsSL https://raw.githubusercontent.com/yourusername/ai-context-template/main/scripts/auto-generate-from-git.sh | bash
```

## 📁 What Gets Created

### Basic Setup (Start Here)
```
.ai/
├── 1-QUESTIONS.md      # Answer 5 simple questions
├── 2-README.md         # Project overview for AI
└── AI_ASSISTANT.md     # Instructions for AI
```

### With AI Detection
Depending on your AI tool, also creates:
- **Claude**: `.ai/CLAUDE.md`
- **Cursor**: `.cursorrules`
- **GitHub Copilot**: `.github/copilot-instructions.md`
- **ChatGPT**: `.ai/OPENAI_CODEX.md`

## 🔄 Progressive Adoption

| Time | Files | Benefit |
|------|-------|---------|
| Day 1 | 3 files | AI understands your project |
| Week 1 | Add ARCHITECTURE.md | AI knows system design |
| Month 1 | Add CONVENTIONS.md | Consistent code style |
| As needed | Add more templates | Handle complex needs |

## 📚 Templates Included

### Essential Templates
- `1-QUESTIONS.md` - Project discovery questions
- `2-README.md` - AI-focused project overview
- `AI_ASSISTANT.md` - Generic AI instructions

### AI-Specific Templates
- `CLAUDE.md` - Optimized for Claude's strengths
- `.cursorrules` - Cursor IDE configuration
- `copilot-instructions.md` - GitHub Copilot setup

### Advanced Templates
- `ARCHITECTURE.md` - System design documentation
- `CONVENTIONS.md` - Coding standards
- `DEPENDENCIES.md` - External dependencies
- `ERROR-PATTERNS.md` - Common issues catalog

## 🛠️ Scripts

### `minimal-setup.sh`
Creates the 3 essential files to get started quickly.

### `smart-ai-detector.sh`
Detects which AI tool you use and creates optimized configuration:
- Checks for `.cursorrules`, `.github/copilot-instructions.md`
- Looks for AI-related VSCode extensions
- Checks environment variables
- Falls back to asking user

### `interactive-setup.js`
Node.js wizard that guides you through setup:
- Asks about your project
- Captures key commands
- Creates customized templates

### `auto-generate-from-git.sh`
Analyzes your repository to pre-fill templates:
- Detects primary language
- Finds tech stack
- Extracts project statistics
- Identifies active areas

## 💡 Usage Examples

### For a New Project
```bash
# 1. Run minimal setup
./scripts/minimal-setup.sh

# 2. Answer questions in .ai/1-QUESTIONS.md

# 3. Start coding with AI assistance!
```

### For an Existing Project
```bash
# 1. Auto-generate from git
./scripts/auto-generate-from-git.sh

# 2. Review and complete generated files

# 3. AI now understands your project!
```

### For Specific AI Tools
```bash
# Auto-detect and configure
./scripts/smart-ai-detector.sh

# Creates optimal config for your AI
```

## 📊 Benefits

### For Developers
- ✅ AI gives better suggestions
- ✅ Fewer repeated explanations
- ✅ Consistent code generation
- ✅ Faster development

### For Teams
- ✅ Shared understanding
- ✅ Onboarding documentation
- ✅ Consistent standards
- ✅ Knowledge preservation

## 🤔 FAQ

### Do I need all the templates?
No! Start with just 3 files. Add more only when you need them.

### Will this work with my AI tool?
Yes! The templates work with any AI that can read text.

### Can I customize the templates?
Absolutely! They're just markdown files - edit as needed.

### Is this only for new projects?
No, it works great with existing projects too. Use the auto-generate script.

### How often should I update these files?
Update `1-QUESTIONS.md` when major things change. Other files can be updated as needed.

## 🚀 Getting Started

1. **Choose a setup method** from Quick Start above
2. **Fill out the questions** in `.ai/1-QUESTIONS.md`
3. **Customize the AI instructions** for your project
4. **Start using AI** - it now understands your project!

## 📝 License

MIT - Use freely in your projects

## 🙏 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

---

Created with ❤️ to make AI-assisted development easier for everyone.