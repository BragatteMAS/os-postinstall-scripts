# AI Context Template 🤖

> **Transform how AI understands your code in 5 minutes**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![npm version](https://img.shields.io/npm/v/create-ai-context.svg)](https://www.npmjs.com/package/create-ai-context)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

> "Adapt what is useful, reject what is useless, and add what is specifically your own."  
> _Bruce Lee_

## 🎯 What is This?

AI Context Template helps AI assistants (Claude, Copilot, Cursor, ChatGPT) work more effectively with your code by providing structured context about your project. No more repeating the same explanations every time!

## 🚀 Quick Start (2 minutes)

### Option 1: One-Line Install
```bash
curl -fsSL https://raw.githubusercontent.com/BragatteMAS/ai-context-template/main/install.sh | bash
```

### Option 2: NPM/Yarn
```bash
npx create-ai-context
# or
yarn create ai-context
```

### Option 3: Manual Setup
```bash
git clone https://github.com/BragatteMAS/ai-context-template.git
cd ai-context-template
./install.sh
```

## 📁 What You Get

```
your-project/
├── .ai/
│   ├── 1-QUESTIONS.md      # Answer these first (5 min)
│   ├── 2-README.md         # Auto-generated overview
│   └── AI_ASSISTANT.md     # Instructions for AI
│
├── .github/
│   └── copilot-instructions.md  # If using GitHub Copilot
│
└── .cursorrules            # If using Cursor
```

## 🤖 Supported AI Tools

| AI Tool | Config File | Auto-Detection |
|---------|------------|----------------|
| Claude | `.ai/CLAUDE.md` | ✅ |
| GitHub Copilot | `.github/copilot-instructions.md` | ✅ |
| Cursor | `.cursorrules` | ✅ |
| ChatGPT | `.ai/OPENAI_CODEX.md` | ✅ |
| Gemini | `.ai/GEMINI_CONTEXT.md` | Manual |
| Others | `.ai/AI_ASSISTANT.md` | Default |

## 📚 Features

### 🎯 Smart Detection
Automatically detects which AI tools you use and creates optimized configurations.

### 📝 Progressive Enhancement
Start with 3 files, add more as your project grows.

### 🔧 Zero Dependencies
Pure bash scripts, works everywhere.

### 🌍 Universal
Works with any programming language or framework.

## 💡 Example Use Cases

### For a New Project
```bash
mkdir my-awesome-project
cd my-awesome-project
npx create-ai-context
# Answer questions → Start coding with AI
```

### For an Existing Project
```bash
cd existing-project
curl -fsSL https://bit.ly/ai-context | bash
# Choose "From Git History" → Auto-generates context
```

### For Teams
```bash
# One person runs setup
npx create-ai-context

# Commit and share
git add .ai/ .github/ .cursorrules
git commit -m "Add AI context for better assistance"
git push

# Team gets instant context!
```

## 📊 Setup Options

### 🚀 Minimal (2 min)
Creates just 3 essential files

### 🔍 Smart (3 min)
Auto-detects your AI tools

### 💬 Interactive (5 min)
Guided wizard with options

### 📊 From Git (5 min)
Analyzes your repository

## 🛠️ Advanced Usage

### Custom Templates
Add your own templates:
```bash
.ai/
├── API.md           # API documentation
├── TESTING.md       # Test guidelines
├── SECURITY.md      # Security rules
└── PERFORMANCE.md   # Performance tips
```

### CI/CD Integration
```yaml
# .github/workflows/ai-context.yml
on: [push]
jobs:
  update-context:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: npx create-ai-context --update
```

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md).

### Ways to Contribute
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve templates
- 🌍 Add translations
- ⭐ Star the repo!

## 📈 Roadmap

- [ ] Web UI for configuration
- [ ] VS Code extension
- [ ] More AI tool support
- [ ] Team collaboration features
- [ ] Analytics dashboard

## 🙏 Acknowledgments

Created by [@BragatteMAS](https://github.com/BragatteMAS)

Inspired by the need for better AI-human collaboration in software development.

## 📝 License

MIT License - use freely, adapt wisely, share generously.

---

<p align="center">
  <b>🌟 If this helps your AI coding experience, please star the repo! 🌟</b>
</p>

<p align="center">
  Made with ❤️ for developers who believe in augmented intelligence
</p>