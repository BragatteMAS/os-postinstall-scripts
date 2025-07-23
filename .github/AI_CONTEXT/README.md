# AI Context Directory

This directory contains context and configuration for various AI assistants to better understand and work with this project.

## Structure

```
AI_CONTEXT/
├── CLAUDE.md           # Main context document for Claude and other AIs
├── CLAUDE-EXTENDED.md  # Extended reference guide
├── claude/             # Claude-specific settings
├── legacy/             # Historical AI context from .ai directory
└── README.md           # This file
```

## Supported AI Assistants

This context is designed to work with:
- **Claude** (Anthropic) - Primary AI with CLAUDE.md
- **GitHub Copilot** - Via code comments and patterns
- **Gemini** (Google) - Can use CLAUDE.md as reference
- **Codex** (OpenAI) - Can use CLAUDE.md as reference
- **Cursor AI** - Via .cursorrules or CLAUDE.md
- **Windsurf** - Via project context

## Usage

### For Claude
Claude automatically reads CLAUDE.md when working in this repository. The document provides:
- Project conventions and standards
- Coding patterns by language
- Documentation requirements
- Testing strategies

### For Other AIs
When using other AI assistants:
1. Reference CLAUDE.md for project standards
2. Point the AI to this directory for context
3. Use the documented patterns and conventions

## Key Documents

- **CLAUDE.md**: Main guidelines and principles
- **CLAUDE-EXTENDED.md**: Detailed examples and extended documentation
- **legacy/**: Contains previous AI context documentation that may still be relevant

## Updates

These documents should be reviewed and updated:
- Monthly or with each major/minor release
- When project conventions change
- When new patterns are established

See [STATUS.md](../PROJECT_DOCS/STATUS.md) for document update tracking.