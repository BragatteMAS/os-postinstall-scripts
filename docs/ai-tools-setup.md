# 🤖 AI Development Tools Setup Guide

This guide details the installation and configuration of AI-assisted development tools for the os-postinstall-scripts project.

## 📋 Table of Contents

- [Overview](#overview)
- [MCPs (Model Context Protocol)](#mcps-model-context-protocol)
- [BMAD Method](#bmad-method)
- [Installation](#installation)
- [Verification](#verification)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The system integrates two main technologies:

1. **MCPs (Model Context Protocol)**: Tools that extend Claude's capabilities
2. **BMAD Method**: AI-optimized project management system

## 🔌 MCPs (Model Context Protocol)

### What are MCPs?

MCPs are local servers that provide extra functionality to Claude, enabling:
- Access to always-updated documentation
- Semantic search in codebases
- Structured reasoning
- Intelligent web requests

### Included MCPs

#### 1. **context7** - Always-Updated Documentation
- Accesses official documentation for any library
- Avoids code based on outdated data
- Usage: Add `use context7` to your prompt

#### 2. **fetch** - Intelligent Web Requests
- Searches and analyzes web content
- Converts HTML to structured markdown
- Processes site information

#### 3. **sequential-thinking** - Structured Reasoning
- Decomposition of complex problems
- Self-correction during reasoning
- Review of previous decisions

#### 4. **serena** - Semantic Code Search
- Massive token savings
- Contextual code understanding
- Efficient navigation in large projects

### claude.json Configuration

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "serena": {
      "command": "/Users/[seu-usuario]/.local/bin/uv",
      "args": ["run", "--directory", "/Users/[your-username]/Documents/GitHub/serena", "serena-mcp-server"]
    }
  }
}
```

## 📚 BMAD Method

### What is BMAD?

BMAD Method v4.31.0 is a project management system that:
- Structures projects for effective AI collaboration
- Defines documentation standards (PRD, STORIES, STATUS)
- Provides specialized agents for different tasks

### BMAD Structure

```
project/
├── .bmad-core/              # Native BMAD (git ignored)
│   ├── agents/              # Specialized agents
│   ├── templates/           # Reusable templates
│   ├── workflows/           # Defined workflows
│   └── config/              # Configurations
├── PRD.md                   # Product Requirements Document
├── STORIES.md               # User Stories
├── STATUS.md                # Project status
└── CLAUDE.md                # Context guide for AI
```

### Available Agents

- **dev.md**: General development
- **test.md**: Test creation
- **doc.md**: Documentation
- **review.md**: Code review

## 🚀 Installation

### Method 1: Via Main Setup

```bash
./setup.sh
# Choose option 9: 🤖 Install AI tools (MCPs + BMAD)
```

### Method 2: Direct Installation

```bash
./install_ai_tools.sh
```

### Method 3: One-liner

```bash
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install_ai_tools.sh | bash
```

## ✅ Verification

### Verify Complete Installation

```bash
./check_ai_tools.sh
```

### Manual Verification

1. **MCPs**: Check if tools with `mcp__` prefix appear in Claude
2. **BMAD**: Check if `.github/AI_TOOLKIT/` exists in new projects
3. **UV**: Run `uv --version`

## 💡 Usage

### Using MCPs in Claude

1. **Context7 for documentation**:
   ```
   How to use React hooks? use context7
   ```

2. **Sequential Thinking for complex problems**:
   ```
   use sequential-thinking to solve this complex algorithm
   ```

3. **Serena for code search**:
   ```
   use serena to find authentication implementations
   ```

### Using BMAD in Projects

1. **Initialize project**:
   ```bash
   bmad init
   ```

2. **Use agents**:
   ```
   @agent:dev implement feature X
   ```

## 🔧 Troubleshooting

### MCPs don't appear in Claude

1. Restart Claude completely
2. Check the claude.json file
3. Run `./check_ai_tools.sh` for diagnostics

### BMAD doesn't work

1. Check if npm is installed
2. Confirm version: `bmad --version`
3. Reinstall: `npm install -g bmad-method@latest`

### Serena doesn't connect

1. Check if UV is installed: `uv --version`
2. Confirm the serena repository clone
3. Test manually: `uv run --directory ~/Documents/GitHub/serena serena-mcp-server`

## 📍 File Locations

- **claude.json**: 
  - macOS: `~/Library/Application Support/Claude/claude.json`
  - Linux: `~/.config/Claude/claude.json`
  - Windows: `%APPDATA%\Claude\claude.json`

- **Serena**: `~/Documents/GitHub/serena`
- **BMAD**: Globally installed via npm

## 🤝 Support

- Issues: [GitHub Issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- Discussions: [GitHub Discussions](https://github.com/BragatteMAS/os-postinstall-scripts/discussions)

---

> 💡 This documentation is part of the os-postinstall-scripts project.
>
> **Built with ❤️ by Bragatte, M.A.S**