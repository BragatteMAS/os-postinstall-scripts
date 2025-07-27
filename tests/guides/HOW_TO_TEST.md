# 🔧 How to Test - Execution Guide

> **Purpose:** Step-by-step instructions for running manual tests  
> **Time Required:** 5-90 minutes depending on scope  
> **Prerequisites:** Basic shell knowledge, test dependencies (optional)

## 🚀 Quick Start

### 1. Prerequisites Check

```bash
# Check if you have test dependencies (optional but recommended)
which bats || echo "bats not installed - basic tests only"
which docker || echo "docker not installed - no container tests"

# Install test dependencies if wanted
./tests/install-test-deps.sh  # Optional - adds more test capabilities
```

### 2. Choose Your Test Level

| If You Want To...           | Run This Command              | Time  |
|-----------------------------|-----------------------------|-------|
| Quick confidence check      | `make test-manual-smoke`     | 5 min |
| Test specific story         | `make test-story-X.Y`        | 10 min|
| Validate integration        | `make test-manual-integration`| 15 min|
| Full release validation     | `make test-manual-full`      | 90 min|
| Learn while testing         | `TEST_EDUCATION=1 make test-manual-smoke` | +5 min |

## 📋 Detailed Test Execution

### Running Smoke Tests (5 minutes)

```bash
# Basic smoke test
./tests/manual/smoke/minimal-base.sh

# What this tests:
# - Minimal tools install correctly
# - Installation under 15 minutes
# - No errors in output
# - Tools accessible from PATH

# Expected output:
🧪 Starting minimal base installation test...
✅ Checking prerequisites...
✅ Running installer...
✅ Verifying installed tools...
✅ Checking installation time: 12m 34s (PASS)
✅ All smoke tests passed!
```

### Running Story-Specific Tests

#### Story 1.1: Quick Start Installation
```bash
# Test the 15-minute installation goal
./tests/manual/smoke/minimal-base.sh
./tests/manual/integration/installer/progress-test.sh

# Verify:
- ✅ Installation time < 15 minutes
- ✅ Progress bar shows accurate time
- ✅ All tools executable
- ✅ No error messages
```

#### Story 1.6: Technology Detection
```bash
# Test PRD/STORIES parser
./tests/manual/integration/parser/accuracy-test.sh

# Provide test files:
tests/fixtures/sample-prds/python-django-project.md
tests/fixtures/sample-prds/react-typescript-app.md

# Verify:
- ✅ Detects Python, Django, PostgreSQL
- ✅ Confidence scores > 0.8
- ✅ No false positives
- ✅ Handles missing files gracefully
```

#### Story 1.7: Manual Test Documentation
```bash
# Meta-test: Can someone run tests from docs?
./tests/manual/acceptance/test-docs-test.sh

# Give TESTING.md to someone unfamiliar
# Time how long until they run first test
# Should be < 5 minutes
```

### Running Integration Tests (15 minutes)

```bash
# Run all integration tests
./tests/manual/integration/run-all.sh

# Or run specific categories:
./tests/manual/integration/parser/run-all.sh     # Parser tests
./tests/manual/integration/installer/run-all.sh  # Installer tests
./tests/manual/integration/platform/run-all.sh   # Platform tests

# Each test will output:
[TEST NAME]: Starting...
[TEST NAME]: [Step description]
[TEST NAME]: ✅ PASS / ❌ FAIL / ⚠️ WARN
```

### Running Full Validation (90 minutes)

```bash
# Complete pre-release validation
./tests/manual/full-validation.sh

# This runs:
# 1. All smoke tests (5 min)
# 2. All integration tests (15 min)
# 3. All acceptance tests (30 min)
# 4. Performance validation (10 min)
# 5. Security validation (10 min)
# 6. Platform tests (20 min)

# Generates report at:
tests/results/$(date +%Y%m%d-%H%M%S)-validation.txt
```

## 🎓 Educational Mode

### Learning While Testing

```bash
# Enable educational output
export TEST_EDUCATION=1

# Run any test
./tests/manual/smoke/minimal-base.sh

# Additional output includes:
📚 EDUCATION MODE ENABLED

📖 What this test verifies:
   - Explanation of test purpose
   - Why this matters
   - What you're learning

🔍 Behind the scenes:
   - Commands being run
   - What to look for
   - Common issues

💡 Tips:
   - How to debug failures
   - Performance optimization
   - Security considerations
```

## 🔍 Interpreting Results

### Success Output
```bash
✅ Test passed
✅ All assertions met
✅ Performance within targets
⏱️ Completed in 4m 32s
```

### Warning Output
```bash
⚠️ Test passed with warnings
⚠️ Performance slightly over target (16m vs 15m)
⚠️ Consider investigating but not blocking
```

### Failure Output
```bash
❌ Test failed
❌ Expected: git installed
❌ Actual: git not found in PATH
❌ See troubleshooting guide
```

## 🛠️ Recording Results

### After Each Test Run

```bash
# Record your results
./tests/manual/record-results.sh

# Interactive prompts:
Test suite run: [smoke/integration/full]
Platform: [Linux/macOS/Windows]
Version tested: [auto-detected]
Overall result: [PASS/FAIL/WARN]
Notes: [any observations]

# Creates timestamped file:
tests/results/20250727-143022-results.txt
```

### Results Format
```
Test Run: 2025-07-27 14:30:22
Version: v3.2.0-dev
Platform: Ubuntu 22.04
Tester: @username
Suite: integration

Results:
- Parser accuracy: PASS (2m 10s)
- Installer progress: PASS (4m 22s)
- Platform detection: PASS (1m 05s)
- Deprecation warnings: PASS (0m 45s)

Total Time: 8m 32s
Overall: PASS

Notes:
- Parser very accurate on test cases
- Progress bar slightly optimistic (-1m)
- No issues found
```

## 🐛 Troubleshooting Common Issues

### Test Won't Run
```bash
# Check permissions
chmod +x tests/manual/**/*.sh

# Check working directory
pwd  # Should be project root

# Check shell
echo $SHELL  # Should be bash or zsh
```

### Test Fails Unexpectedly
```bash
# Run with debug output
DEBUG=1 ./tests/manual/smoke/minimal-base.sh

# Check prerequisites
./tests/check-prerequisites.sh

# Run in isolated environment
./tests/manual/run-in-container.sh [test-name]
```

### Platform-Specific Issues
```bash
# Linux: Check package manager
which apt || which yum || which dnf

# macOS: Check Homebrew
brew --version || echo "Homebrew required"

# Windows: Document manual steps
echo "See tests/windows-manual-steps.md"
```

## 📊 Test Metrics

### What to Measure
- **Execution Time**: Did test complete in estimated time?
- **Success Rate**: How many tests passed first try?
- **Clarity**: Could you run test without help?
- **Value**: Did test catch real issues?

### How to Report
```bash
# After testing session
make test-report

# Generates:
Test Session Summary
====================
Date: 2025-07-27
Total Tests Run: 15
Passed: 14
Failed: 0
Warnings: 1
Total Time: 32 minutes

Recommendations:
- Progress estimates could be more conservative
- All critical functionality working
- Ready for release: YES
```

## 💡 Pro Tips

1. **Start Small**: Run smoke tests first, expand if needed
2. **Use Tab Completion**: Most test scripts support it
3. **Read Output Carefully**: Tests explain what they're doing
4. **Save Results**: Always record for future reference
5. **Test Changed Areas**: Focus on what you modified
6. **Trust Your Judgment**: Skip tests that don't apply

---

> **Remember:** These tests are your safety net, not your burden.  
> **Goal:** Run tests that give you confidence to ship.  
> **Philosophy:** Manual control means you test what matters when it matters.