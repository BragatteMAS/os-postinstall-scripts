# 📦 Agent-OS Backup Guide

> **Important:** This guide helps you backup essential Agent-OS files for new OS installations

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

## 🚀 Quick Backup Command

To backup all essential Agent-OS files:

```bash
# Create backup directory
mkdir -p ~/agent-os-backup

# Copy essential files
cp -r ~/.agent-os/documentation ~/agent-os-backup/
cp -r ~/.agent-os/standards ~/agent-os-backup/
cp -r ~/.agent-os/templates ~/agent-os-backup/
cp -r ~/.agent-os/agents ~/agent-os-backup/
cp ~/.agent-os/config.yaml ~/agent-os-backup/

# Create tarball
tar -czf ~/agent-os-backup-$(date +%Y%m%d).tar.gz ~/agent-os-backup
```

## 📥 Restore on New OS

```bash
# Extract backup
tar -xzf agent-os-backup-YYYYMMDD.tar.gz

# Copy to .agent-os directory
cp -r ~/agent-os-backup/* ~/.agent-os/

# Verify installation
ls -la ~/.agent-os/
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