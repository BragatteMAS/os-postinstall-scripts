# 🎯 Product-Focused Commits Guide

> **Principle:** Commits should tell the story of your product, not your tooling.

## 📋 Overview

This guide explains how to maintain a clean commit history focused on product development while keeping all AI tooling, methods, and documentation properly versioned but semantically separated.

## 🏗️ Structure

```
project/
├── src/                    # 🎯 Product code
├── tests/                  # 🎯 Product tests
├── docs/                   # 🎯 User-facing documentation
├── README.md              # 🎯 Product overview
└── .github/               # 🔧 Tooling & methods (filtered from product commits)
    ├── AI_TOOLKIT/        # AI agents, commands, workflows
    ├── PROJECT_DOCS/      # PRD, STORIES, STATUS, ADRs
    └── METHODS/           # CLAUDE.md, development methods
```

## 🚀 Quick Start

### 1. Setup Your Shell

Add to your `.zshrc` or `.bashrc`:

```bash
# Product-focused git aliases
alias glogp="git log --oneline -- ':!.github'"
alias gdiffp="git diff -- ':!.github'"
alias gstatusp="git status -- ':!.github'"
alias gaddp="git add -- ':!.github'"

# Conventional commit shortcuts
alias gcfeat="git commit -m 'feat: '"
alias gcfix="git commit -m 'fix: '"
alias gcchore="git commit -m 'chore(.github): '"
```

### 2. Use Product-Focused Commands

```bash
# See only product changes
gstatusp

# Stage only product files
gaddp .

# View product commit history
glogp

# Diff product changes only
gdiffp
```

## 📝 Commit Conventions

### Product Commits (appear in main history)

| Type | Usage | Example |
|------|-------|---------|
| `feat:` | New features | `feat: add user authentication` |
| `fix:` | Bug fixes | `fix: resolve memory leak in parser` |
| `docs:` | User documentation | `docs: update API reference` |
| `style:` | Formatting (no logic change) | `style: format code with prettier` |
| `refactor:` | Code restructuring | `refactor: extract validation logic` |
| `test:` | Adding/fixing tests | `test: add integration tests for auth` |
| `perf:` | Performance improvements | `perf: optimize database queries` |

### Tooling Commits (hidden in filtered views)

| Type | Usage | Example |
|------|-------|---------|
| `chore(.github):` | AI tooling updates | `chore(.github): update BMAD agents` |
| `chore(.github):` | Method updates | `chore(.github): refine CLAUDE.md` |
| `chore(.github):` | Project docs | `chore(.github): update PRD objectives` |

## 🎯 Workflows

### Daily Development

```bash
# Morning: Check product status
gstatusp
glogp -10  # Last 10 product commits

# Work on feature
gcfeat "add payment processing"

# Update tooling separately
git add STATUS.md
gcchore "update project status"
```

### Code Review

```bash
# Review only product changes in PR
git diff main...feature-branch -- ':!.github'

# Generate product-only patch
git format-patch main --stdout -- ':!.github' > product-changes.patch
```

### Release Notes

```bash
# Generate product changelog
git log --oneline v1.0.0..HEAD -- ':!.github' | grep -E '^[a-f0-9]+ (feat|fix):'

# Count product commits
git rev-list --count HEAD -- ':!.github'
```

## 🔧 Advanced Techniques

### Custom Git Hooks

`.git/hooks/prepare-commit-msg`:
```bash
#!/bin/bash
# Auto-prefix commits touching only .github/
if git diff --cached --name-only | grep -q "^\.github/" && \
   ! git diff --cached --name-only | grep -qv "^\.github/"; then
    sed -i '1s/^/chore(.github): /' "$1"
fi
```

### GitHub Actions

```yaml
name: Validate Product Focus
on: [pull_request]
jobs:
  check-commits:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check commit types
        run: |
          # Ensure .github changes use chore(.github) prefix
          git log --oneline ${{ github.event.pull_request.base.sha }}..${{ github.event.pull_request.head.sha }} \
            -- .github | grep -vE '^[a-f0-9]+ chore\(\.github\):' && exit 1 || exit 0
```

### Git Aliases in `.gitconfig`

```ini
[alias]
    # Product-focused logs
    logp = log --oneline -- ':!.github'
    logpf = log --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%an%C(reset) %s' -- ':!.github'
    
    # Product statistics
    countp = rev-list --count HEAD -- ':!.github'
    contributorsp = shortlog -sn -- ':!.github'
    
    # Product-only branches
    diffp = diff -- ':!.github'
    difftoolp = difftool -- ':!.github'
```

## 📊 Metrics & Reporting

### Product Velocity

```bash
# Commits per day (last 30 days)
git log --since="30 days ago" --oneline -- ':!.github' | wc -l

# Feature vs fix ratio
git log --oneline -- ':!.github' | grep -c "^[a-f0-9]* feat:"
git log --oneline -- ':!.github' | grep -c "^[a-f0-9]* fix:"
```

### Contributor Focus

```bash
# Who's working on product vs tooling
echo "=== Product Contributors ==="
git shortlog -sn -- ':!.github'

echo -e "\n=== Tooling Contributors ==="
git shortlog -sn -- .github
```

## ✅ Best Practices

1. **Atomic Commits**: One logical change per commit
2. **Clear Messages**: Start with verb, explain "why" not "what"
3. **Separate Concerns**: Never mix product and tooling changes
4. **Review Focus**: PRs should be either product OR tooling
5. **Regular Cleanup**: Squash tooling commits before merge if needed

## 🚫 Anti-Patterns

- ❌ `fix: update BMAD config and add user auth`
- ❌ `chore: various updates`
- ❌ `feat: add feature` (too vague)
- ❌ Mixing .github changes with product code

## 🎉 Benefits

1. **Clean History**: `git log` tells product story
2. **Easy Reviews**: Reviewers focus on business logic
3. **Better Metrics**: Accurate velocity tracking
4. **Simpler Releases**: Changelog generation is automatic
5. **Team Clarity**: Clear separation of concerns

---

> **Remember:** The goal is a commit history that reads like a product changelog, not a development diary.