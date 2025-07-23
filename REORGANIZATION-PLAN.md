# 🔄 Repository Reorganization Plan

> **Goal:** Transform repository structure to be user-journey focused, making it intuitive for our target audience

## 🎯 Target Audience Personas

1. **Quick Start Developer** - "I just want my dev environment NOW"
2. **DevOps Engineer** - "I need to deploy this on 50 machines"
3. **Curious Student** - "I want to understand what this does"
4. **Contributor** - "I want to add support for my favorite tool"

## 📊 Current Problems

1. **Too many files in root** - Overwhelming first impression
2. **Mixed contexts** - BMAD/AI stuff mixed with user scripts
3. **Unclear entry points** - Where do I start?
4. **Hidden gems** - Great features buried in subdirectories

## 🎨 Proposed New Structure

```
os-postinstall-scripts/
├── 🚀 START-HERE.md          # Big, friendly entry point
├── README.md                  # Clean overview
├── LICENSE
│
├── 📦 install/               # What users came for
│   ├── quick-start.sh        # One-command magic
│   ├── linux/
│   │   ├── ubuntu.sh
│   │   ├── fedora.sh
│   │   └── arch.sh
│   ├── windows/
│   │   └── win11.ps1
│   └── mac/
│       └── setup.sh
│
├── 🎨 profiles/              # Pre-configured setups
│   ├── developer-minimal.yaml
│   ├── developer-full.yaml
│   ├── devops.yaml
│   ├── data-scientist.yaml
│   └── student.yaml
│
├── 📚 docs/                  # User-focused docs
│   ├── getting-started/
│   │   ├── README.md
│   │   ├── first-time-users.md
│   │   ├── what-gets-installed.md
│   │   └── customization.md
│   ├── guides/
│   │   ├── create-your-profile.md
│   │   ├── add-new-tool.md
│   │   └── troubleshooting.md
│   └── advanced/
│       ├── architecture.md
│       ├── security.md
│       └── contributing.md
│
├── 🧩 modules/               # Reusable components
│   ├── core/
│   │   ├── package-managers/
│   │   ├── shell-setup/
│   │   └── development-tools/
│   └── utils/
│       ├── logging.sh
│       └── package-manager-safety.sh
│
├── 🧪 tests/                 # Quality assurance
│   ├── security/
│   ├── integration/
│   └── README.md
│
├── 🤖 .ai/                   # AI/Development context
│   ├── CLAUDE.md
│   ├── context/
│   │   ├── PRD.md
│   │   ├── STORIES.md
│   │   └── adrs/
│   └── bmad/
│
├── 📋 .project/              # Project meta
│   ├── CHANGELOG.md
│   ├── ROADMAP.md
│   ├── STATUS.md
│   └── CONTRIBUTING.md
│
└── 🗑️ .archive/              # Old stuff, hidden
    ├── legacy-scripts/
    └── deprecated/
```

## 🔄 Migration Steps

### Phase 1: Create New Structure
```bash
# Create user-focused directories
mkdir -p profiles docs/getting-started docs/guides docs/advanced
mkdir -p modules/core/{package-managers,shell-setup,development-tools}
mkdir -p .ai/context .project .archive

# Create START-HERE.md
cat > START-HERE.md << 'EOF'
# 🚀 Start Here!

Welcome! Let's get your machine set up in minutes.

## Quick Start (I trust you, just do it!)
```bash
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install/quick-start.sh | bash
```

## Careful Start (Let me see what this does)
```bash
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts
./install/quick-start.sh --dry-run  # See what would happen
./install/quick-start.sh             # Do it for real
```

## Custom Start (I know what I want)
1. Check out our [profiles](profiles/) - pick one or create your own
2. Run: `./install/quick-start.sh --profile developer-minimal`

## Manual Start (I want control)
See our [step-by-step guide](docs/getting-started/first-time-users.md)

---
🤔 Questions? Check [FAQ](docs/getting-started/README.md) | 🐛 Issues? See [Troubleshooting](docs/guides/troubleshooting.md)
EOF
```

### Phase 2: Move Files

```bash
# Move user-facing scripts
mv linux/install/* modules/core/package-managers/
mv linux/main.sh install/linux/menu.sh
mv setup.sh install/quick-start.sh

# Move documentation
mv PRD.md STORIES.md TESTING.md STATUS.md .ai/context/
mv CHANGELOG.md ROADMAP.md CONTRIBUTING.md .project/
mv CLAUDE*.md .ai/
mv docs/adrs .ai/context/

# Move BMAD stuff (out of user's way)
mv bmad-* .ai/bmad/
mv expansion-packs .ai/

# Archive old stuff
mv *_global* .archive/
mv *.bak .archive/
```

### Phase 3: Create User-Friendly Files

1. **Simplified README.md** - Focus on what users care about
2. **Profile examples** - Show don't tell
3. **Visual guides** - Screenshots/diagrams
4. **Quick reference card** - Common commands

## 📈 Success Metrics

1. **First-time user** can start in < 30 seconds
2. **Power user** can find advanced features easily  
3. **Contributor** knows exactly where to add code
4. **Root directory** has < 10 visible items

## 🎯 Key Principles

1. **Progressive Disclosure** - Simple first, complex later
2. **Convention over Configuration** - Smart defaults
3. **User Journey Focus** - Every file has a clear audience
4. **Hide the Plumbing** - Implementation details in subdirs

## 🚦 Decision Points

1. **Should we hide dot directories by default?** 
   - Yes, reduces cognitive load
   
2. **Should profiles be YAML or shell scripts?**
   - YAML for clarity, convert to shell internally

3. **How much backward compatibility?**
   - Full - old paths redirect to new

4. **Where do tests live?**
   - Top level `tests/` - quality is not hidden

## 📝 Next Steps

1. Review and approve this plan
2. Create migration script
3. Test with fresh clone
4. Update all documentation
5. Create redirects for old paths
6. Tag as v2.4.0-beta

---

**Remember:** A confused user is a lost user. Make their journey obvious!