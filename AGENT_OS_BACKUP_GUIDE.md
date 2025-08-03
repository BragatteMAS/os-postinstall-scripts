# 📦 Agent-OS Backup Guide

> **Important:** All essential Agent-OS files are now included in this repository!
> When you clone this repo, you'll have everything needed to restore Agent-OS on a new system.

## 🎯 Essential Files for Backup

When migrating to a new OS or creating a backup, these are the critical Agent-OS files you need to preserve:

### 📁 CRITICAL - Always Backup

These files cannot be easily regenerated and are essential for Agent-OS functionality:

```bash
# Documentation (project knowledge base)
~/.agent-os/documentation/
├── CLAUDE-EXTENDED.mdc      # Complete CLAUDE.md guide
├── prompt-engineering-guide.md
└── epidemiology-stack.md

# Standards (coding and project standards)
~/.agent-os/standards/
├── tech-stack.md            # Technology stack definitions
├── mission.md               # Agent-OS mission
├── BMAD-CLAUDE-FLOW-INTEGRATION.mdc
├── best-practices.md
└── code-style/              # Language-specific style guides

# Templates (reusable templates)
~/.agent-os/templates/
├── ADR.md                   # Architecture Decision Records
├── AGENT_TEMPLATE.md        # Agent creation template
└── [other templates]

# Agents (agent definitions)
~/.agent-os/agents/
└── [all agent definitions]

# Configuration
~/.agent-os/config.yaml      # Main Agent-OS configuration
```

### 📁 OPTIONAL - Auto-Generated

These can be regenerated or are project-specific:

```bash
~/.agent-os/logs/            # Execution logs (not needed)
~/.agent-os/memory/          # Project-specific memories
~/.agent-os/bin/             # Executable scripts (regenerated)
~/.agent-os/hooks/           # Git hooks (can be recreated)
```

## 🚀 Files Already in This Repository

All essential Agent-OS files are stored in `.agent-os/` directory in this repository:

```bash
.agent-os/
├── documentation/        # Complete documentation including CLAUDE-EXTENDED.mdc
├── standards/           # Tech stack, coding standards, best practices
├── templates/           # ADR, Agent templates, and more
├── agents/             # All agent definitions
├── instructions/       # Workflow instructions
└── config.yaml        # Main Agent-OS configuration
```

## 📥 Restore on New OS

After cloning this repository:

```bash
# Clone the repository
git clone https://github.com/BragatteMAS/os-postinstall-scripts.git
cd os-postinstall-scripts

# Copy Agent-OS files to home directory
cp -r .agent-os ~/

# Verify installation
ls -la ~/.agent-os/
```

## 🔄 Alternative: Direct Backup from System

If you need to backup your current system's Agent-OS:

```bash
# Create backup from your system
cp -r ~/.agent-os ./agent-os-backup-$(date +%Y%m%d)

# Or create tarball
tar -czf agent-os-backup-$(date +%Y%m%d).tar.gz ~/.agent-os
```

## 💡 Best Practices

1. **Regular Backups**: Backup after major Agent-OS updates
2. **Version Control**: Consider using git for `.agent-os` directory
3. **Cloud Sync**: Use services like iCloud/Dropbox for automatic backup
4. **Documentation**: Keep this guide with your backups

## 📝 Notes

- The `.agent-os` directory is typically in your home directory (`~`)
- Project-specific configurations override global settings
- Memory files are context-specific and may not be needed in new installations
- Always backup before major OS updates or reinstalls

---

*Last Updated: 2025-08-03*