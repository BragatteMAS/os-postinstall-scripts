# 🔧 Project Tooling & Methods

> This directory contains AI tooling, project documentation, and development methods.
> It's intentionally separated from product code to maintain clean, focused commits.

## 📁 Directory Structure

```
.github/
├── AI_TOOLKIT/          # 🤖 AI development tools
│   ├── agents/          # AI agents for development tasks
│   ├── commands/        # Custom commands and scripts
│   ├── templates/       # Reusable templates
│   ├── workflows/       # Development workflows
│   └── config/          # Configuration files
│
├── PROJECT_DOCS/        # 📋 Project documentation
│   ├── PRD.md          # Product Requirements Document
│   ├── STORIES.md      # User stories and features
│   ├── STATUS.md       # Current project status
│   ├── ROADMAP.md      # Future plans and milestones
│   └── adrs/           # Architecture Decision Records
│
└── METHODS/            # 📚 Development methodologies
    ├── CLAUDE.md       # AI context engineering guide
    └── CONTRIBUTING.md # Contribution guidelines
```

## 🎯 Purpose

This structure enables:
- **Clean commit history** - Focus on product changes
- **Organized tooling** - Everything in one place
- **Easy portability** - Copy `.github/` to any project
- **GitHub integration** - Automatically recognized

## 🚀 Usage Tips

### View only product commits:
```bash
git log --oneline -- ':!.github'
```

### Work with AI tooling:
```bash
# Update AI agents
cd .github/AI_TOOLKIT/agents
# Make changes...
git add .
git commit -m "chore(.github): update AI agents"
```

### Track project progress:
- Update `PROJECT_DOCS/STATUS.md` regularly
- Keep `PROJECT_DOCS/ROADMAP.md` current
- Document decisions in `PROJECT_DOCS/adrs/`

## 📝 Best Practices

1. **Prefix tooling commits**: Use `chore(.github):` prefix
2. **Keep docs updated**: Especially STATUS.md
3. **Document decisions**: Use ADRs for important choices
4. **Reuse templates**: Build a library in `AI_TOOLKIT/templates/`

---

> 💡 **Tip**: This structure is automatically created by the global git template.
> To update the template, see the os-postinstall-scripts repository.