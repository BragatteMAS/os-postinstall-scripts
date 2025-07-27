# ✅ QA Checklist - OS Post-Install Scripts v3.2.0

> **QA Agent:** Lisa | **Created:** 2025-07-27  
> **Purpose:** Pre-release manual validation checklist  
> **Time Required:** ~90 minutes full validation

## 🚀 Pre-Release Validation Checklist

### 📋 Quick Validation (15 minutes)

- [ ] **Code Quality**
  - [ ] ShellCheck passes on all scripts
  - [ ] No hardcoded paths or credentials
  - [ ] All scripts have proper error handling
  - [ ] Documentation is up to date

- [ ] **Basic Functionality**
  - [ ] Minimal base installs without errors
  - [ ] Help/usage messages are clear
  - [ ] Version numbers updated correctly
  - [ ] CHANGELOG.md reflects all changes

### 🔍 Story Validation (45 minutes)

#### Story 1.1: Quick Start Installation
- [ ] Installation completes in < 15 minutes
- [ ] All minimal tools are installed
- [ ] Progress indicators show time remaining
- [ ] No error messages during installation
- [ ] Tools are accessible from PATH

#### Story 1.6: PRD/STORIES Technology Detection
- [ ] Parser correctly identifies technologies
- [ ] Fuzzy matching works for variations
- [ ] Confidence scores are reasonable (>0.7)
- [ ] No false positives on common words
- [ ] Handles missing files gracefully

#### Story 1.7: Manual Test Execution
- [ ] Test documentation is clear
- [ ] Test scripts run without modification
- [ ] Expected outputs match actual
- [ ] Educational mode provides value
- [ ] NO automatic test execution

#### Story 4.2: Deprecate Profile System
- [ ] Profile commands show deprecation warning
- [ ] Migration guide link works
- [ ] Old functionality still works
- [ ] New recommendation system suggested
- [ ] No profile references in new code

#### Story 5.1: BMAD Agent Integration
- [ ] Agent hooks are implemented
- [ ] Suggestions are clearly marked
- [ ] User can override suggestions
- [ ] Educational documentation exists
- [ ] Agents don't block progress

### 🏃 Performance Validation (15 minutes)

- [ ] **Installation Times**
  - [ ] Minimal base: < 15 minutes
  - [ ] With recommendations: < 30 minutes
  - [ ] Progress estimates accurate (±2 min)
  - [ ] Parallel execution reduces time

- [ ] **Resource Usage**
  - [ ] Memory usage reasonable
  - [ ] Disk space requirements documented
  - [ ] Network bandwidth efficient
  - [ ] CPU usage acceptable

### 🔒 Security Validation (10 minutes)

- [ ] **APT Lock Safety**
  - [ ] NO force removal of lock files
  - [ ] Wait mechanism works correctly
  - [ ] Timeout after 5 minutes
  - [ ] Clear error messages

- [ ] **Input Validation**
  - [ ] Package names validated
  - [ ] Path traversal prevented
  - [ ] Command injection blocked
  - [ ] User input sanitized

- [ ] **Permissions**
  - [ ] Scripts don't run as root unnecessarily
  - [ ] File permissions set correctly
  - [ ] No world-writable files created
  - [ ] Sudo used appropriately

### 🌍 Platform Validation (15 minutes)

#### Linux (Ubuntu/Debian)
- [ ] Ubuntu 22.04 LTS tested
- [ ] Ubuntu 24.04 LTS tested
- [ ] Debian 12 tested
- [ ] Package manager detection works
- [ ] All tools install correctly

#### macOS
- [ ] macOS Sonoma (14.x) tested
- [ ] macOS Sequoia (15.x) tested
- [ ] Homebrew integration works
- [ ] Path setup correct
- [ ] No Linux-specific commands

#### Windows
- [ ] Limitations clearly documented
- [ ] Basic winget support verified
- [ ] WSL2 recommendation present
- [ ] No complex scripting attempted
- [ ] Manual steps documented

### 🎯 User Acceptance Criteria (10 minutes)

- [ ] **New User Experience**
  - [ ] Can follow quick start guide
  - [ ] Understands what's being installed
  - [ ] Knows how to verify success
  - [ ] Can run manual tests

- [ ] **Existing User Upgrade**
  - [ ] Upgrade path is clear
  - [ ] No breaking changes
  - [ ] Profile deprecation understood
  - [ ] Data preserved

- [ ] **Documentation Quality**
  - [ ] README is comprehensive
  - [ ] Examples are accurate
  - [ ] Troubleshooting section helpful
  - [ ] Links all work

## 📝 Test Execution Record

```markdown
## Test Run: [DATE]
**Version:** v3.2.0-[rc/final]
**Tester:** @[username]
**Platform:** [OS and version]
**Total Time:** [actual time]

### Results Summary
- Quick Validation: ✅ PASS / ⚠️ WARN / ❌ FAIL
- Story Validation: ✅ PASS / ⚠️ WARN / ❌ FAIL
- Performance: ✅ PASS / ⚠️ WARN / ❌ FAIL
- Security: ✅ PASS / ⚠️ WARN / ❌ FAIL
- Platform: ✅ PASS / ⚠️ WARN / ❌ FAIL
- User Acceptance: ✅ PASS / ⚠️ WARN / ❌ FAIL

### Issues Found
1. [Issue description, severity, story affected]
2. [Issue description, severity, story affected]

### Recommendations
- [Any improvements or concerns]
- [Suggested priority fixes]

### Sign-off
- [ ] Ready for release
- [ ] Needs fixes (see issues)
- [ ] Major blocker found
```

## 🚫 Release Blockers

These MUST be resolved before release:

1. **Security Issues**
   - Any command injection vulnerability
   - Unsafe file operations
   - Credential exposure

2. **Data Loss Risks**
   - Accidental file deletion
   - Configuration corruption
   - Backup failure

3. **Critical Functionality**
   - Minimal base fails to install
   - Parser crashes on valid input
   - Progress indicators broken

4. **Performance Regression**
   - Installation > 20 minutes
   - Recommendations > 35 minutes
   - Significant slowdown from v3.1.0

## 📊 Quality Metrics

### Target Metrics
- **First-Run Success Rate:** > 95%
- **Test Documentation Clarity:** Users run tests without help
- **Performance Target:** 15-minute minimal install
- **Platform Coverage:** Linux 100%, macOS 80%, Windows documented
- **Security Validation:** All checks pass

### Actual Metrics (Fill during testing)
- **First-Run Success Rate:** ____%
- **Test Documentation Clarity:** ____%
- **Average Install Time:** ____ minutes
- **Platform Tests Passed:** Linux ___/5, macOS ___/5, Windows ___/5
- **Security Checks:** ___/12 passed

## 🎬 Final Sign-off

### Release Readiness Assessment

- [ ] All checklist items completed
- [ ] No critical issues remain
- [ ] Performance meets targets
- [ ] Documentation is accurate
- [ ] Manual tests documented
- [ ] Version numbers updated
- [ ] CHANGELOG complete

### QA Sign-off

```
QA Engineer: _______________________
Date: _____________________________
Version: __________________________
Status: [ ] Approved [ ] Rejected [ ] Conditional

Notes:
________________________________
________________________________
________________________________
```

---

> **Remember:** This checklist ensures quality through manual verification.  
> **Philosophy:** Trust your testing, but verify when it matters.  
> **Goal:** Ship with confidence, knowing you've validated what users care about.