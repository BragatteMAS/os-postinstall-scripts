# 🕐 When to Test - Decision Flowchart

> **Purpose:** Help you decide when manual testing adds value  
> **Philosophy:** Test when YOU need confidence, not because a system demands it

## 🎯 Quick Decision Tree

```
┌─────────────────────────┐
│   What's your situation? │
└─────────────┬───────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌──────────────┐  ┌──────────────┐
│ Making Changes│  │ Using System │
└──────┬───────┘  └──────┬───────┘
       │                 │
       ▼                 ▼
   See Below         See Below
```

## 🔧 When Making Changes

### Before Committing (5 minutes)
**Run smoke tests when:**
- ✅ You modified core installation logic
- ✅ You changed minimal base definition
- ✅ You updated package lists
- ✅ You're feeling uncertain about changes

**Skip smoke tests when:**
- ❌ Only documentation changes
- ❌ Only comment updates
- ❌ Fixing typos
- ❌ You're confident in the change

### Before Pull Request (15 minutes)
**Run integration tests when:**
- ✅ Multiple files changed
- ✅ New features added
- ✅ Refactoring done
- ✅ Cross-component changes

**Skip integration tests when:**
- ❌ Single, isolated change
- ❌ Documentation only PR
- ❌ Emergency hotfix (test after)

### Before Release (90 minutes)
**Always run full suite for:**
- ✅ Any version bump
- ✅ Release candidates
- ✅ After merging multiple PRs
- ✅ Monthly validation

## 👤 When Using the System

### After Fresh Install
**Test when:**
- ✅ First time using the scripts
- ✅ Installing on new platform
- ✅ Something seems wrong
- ✅ You want to learn how it works

### After Problems
**Test when:**
- ✅ Installation failed
- ✅ Tool not found after install
- ✅ Unexpected behavior
- ✅ Before reporting issue

### For Learning
**Test when:**
- ✅ You're curious how things work
- ✅ Want to understand the system
- ✅ Planning to contribute
- ✅ Teaching someone else

## 📊 Test Selection Guide

### Time Available vs Confidence Needed

| Time Available | Low Confidence | Medium Confidence | High Confidence |
|----------------|----------------|-------------------|-----------------|
| 5 minutes      | Smoke tests    | Smoke tests       | Skip            |
| 15 minutes     | Integration    | Smoke tests       | Skip            |
| 30 minutes     | Acceptance     | Integration       | Smoke           |
| 90 minutes     | Full suite     | Acceptance        | Integration     |

### By Story/Feature

| Working On              | Minimum Tests      | Recommended        |
|------------------------|--------------------|--------------------|
| Story 1.1 (Quick Start)| minimal-base.sh    | + progress-test.sh |
| Story 1.6 (Parser)     | accuracy-test.sh   | + fuzzy-match.sh   |
| Story 1.7 (Testing)    | test-docs-test.sh  | + all guides       |
| Story 4.2 (Deprecate)  | deprecation-test.sh| + migration flow   |
| Security Fixes         | security suite     | + integration      |
| Performance            | 15-minute-test.sh  | + parallel-test.sh |

## 🎯 Quick Test Commands

```bash
# "I just made a small change" (5 min)
./tests/manual/smoke/minimal-base.sh

# "I'm about to submit a PR" (15 min)
./tests/manual/integration/run-all.sh

# "We're about to release" (90 min)
./tests/manual/full-validation.sh

# "Something seems broken" (varies)
./tests/manual/troubleshoot.sh [issue-type]

# "I want to understand this" (educational)
TEST_EDUCATION=1 ./tests/manual/smoke/minimal-base.sh
```

## 📈 Testing Patterns

### Daily Development
```
Morning: Start coding
  ↓
Make changes
  ↓
Feeling good? → Commit
Feeling unsure? → Run smoke tests (5 min) → Commit
```

### Feature Development
```
Plan feature
  ↓
Implement
  ↓
Run story-specific tests (10 min)
  ↓
Run integration tests (15 min)
  ↓
Submit PR
```

### Release Preparation
```
Feature freeze
  ↓
Run full validation (90 min)
  ↓
Fix any issues
  ↓
Run affected tests (varies)
  ↓
Final validation
  ↓
Ship it! 🚀
```

## 🤔 Still Unsure?

### Ask yourself:
1. **What would break if this was wrong?**
   - Nothing → Skip tests
   - Minor inconvenience → Smoke tests
   - User frustration → Integration tests
   - System corruption → Full suite

2. **How confident am I?**
   - Very confident → Skip tests
   - Mostly confident → Quick smoke test
   - Somewhat worried → Integration tests
   - Very worried → Full validation

3. **Who will this affect?**
   - Just me → Test if you want
   - My team → Run integration tests
   - All users → Full validation
   - Production systems → Complete suite

## 💡 Golden Rules

1. **Test anxiety? Run tests.** - 5 minutes of testing beats hours of debugging
2. **Feeling good? Ship it.** - Don't over-test when confident
3. **User reported issue?** - Always test the fix
4. **Big changes?** - Test proportionally
5. **Documentation only?** - No tests needed

---

> **Remember:** Testing is a tool for confidence, not a checkbox to tick.  
> **Trust yourself:** You know when something needs verification.  
> **Be pragmatic:** Perfect test coverage < shipping working software.