# 🏆 Testing Strategy - OS Post-Install Scripts

> **Testing Trophy Approach** adapted for Shell Scripts  
> Focus on **Integration Tests** that verify real-world functionality  
> **v3.2.0 Update:** ALL tests are manual and on-demand - NO automation!

## 🎯 Testing Philosophy

### The Testing Trophy for Shell Scripts

```
       🏆 E2E Tests (5%)
      /  \
     /    \  Integration Tests (70%)
    /      \
   /________\ Unit Tests (20%)
  /__________\ Static Analysis (5%)
```

### Why This Distribution?

1. **Shell scripts are inherently integration-focused** - They orchestrate system tools
2. **Unit testing individual functions is often overkill** - Most functions are simple wrappers
3. **Integration tests catch real issues** - Permission problems, missing dependencies, etc.
4. **E2E tests verify complete workflows** - Full installation scenarios

## 📊 Test Categories

### 1. Static Analysis (5%)
**Tool:** ShellCheck  
**Purpose:** Catch syntax errors and common mistakes

```bash
# Run on all scripts
shellcheck -x linux/**/*.sh
shellcheck -x *.sh

# Key checks:
- Syntax errors
- Undefined variables
- Quoting issues
- Portability problems
```

### 2. Unit Tests (20%)
**Focus:** Core utility functions only  
**Tool:** Bash testing frameworks (bats-core)

```bash
# Example: Testing a version comparison function
test_version_compare() {
    assert_equal "$(version_compare "1.2.3" "1.2.4")" "lt"
    assert_equal "$(version_compare "2.0.0" "1.9.9")" "gt"
    assert_equal "$(version_compare "1.0.0" "1.0.0")" "eq"
}

# What to unit test:
- Version comparisons
- String manipulation utilities
- Path normalization functions
- Pure functions without side effects
```

### 3. Integration Tests (70%) ⭐ PRIMARY FOCUS
**Purpose:** Verify scripts work with real system components  
**Approach:** Test in containers/VMs

```bash
# Example: Test package installation
test_apt_installer() {
    # Setup: Clean container
    docker run -it ubuntu:22.04 bash -c "
        # Copy scripts
        /scripts/linux/install/apt.sh
        
        # Verify packages installed
        which git && which curl && which vim
    "
}

# Key integration test areas:
- Package manager interactions (apt, snap, flatpak)
- File system operations
- Permission handling
- Cross-script dependencies
- Environment detection
```

### 4. E2E Tests (5%)
**Purpose:** Verify complete user journeys  
**Execution:** Full system provisioning

```bash
# Example: Complete developer setup
test_full_developer_setup() {
    # Start with fresh VM
    vagrant up ubuntu-test
    
    # Run main installer
    vagrant ssh -c "cd /vagrant && ./setup.sh --profile developer"
    
    # Verify all tools available
    vagrant ssh -c "
        git --version &&
        docker --version &&
        node --version &&
        python3 --version
    "
}
```

## 🧪 Test Implementation

### Directory Structure
```
tests/
├── static/           # ShellCheck configs
├── unit/            # Unit test files
│   ├── utils.bats
│   └── version.bats
├── integration/     # Integration tests
│   ├── apt/
│   ├── snap/
│   └── zsh/
├── e2e/            # End-to-end scenarios
│   ├── developer-setup/
│   └── minimal-setup/
├── fixtures/       # Test data
└── test_harness.sh # Main test runner
```

### Running Tests (v3.2.0 - MANUAL ONLY)

```bash
# ⚠️ IMPORTANT: All tests are manual and on-demand
# NO automatic execution during installation
# User maintains complete control

# Run all tests manually
make test-manual

# Run specific category
make test-manual-smoke      # 5 minutes
make test-manual-integration # 15 minutes
make test-manual-acceptance  # 30 minutes
make test-manual-security    # 10 minutes

# Run with educational output
TEST_EDUCATION=1 make test-manual

# When to run tests:
# - Before committing: smoke tests (5 min)
# - Before PR: integration tests (15 min)
# - Before release: full suite (90 min)
```

## 🎯 What to Test (Priority Order)

### High Priority (Must Test)
1. **Package installation success**
   - Packages actually get installed
   - Correct versions
   - Dependencies resolved

2. **Error handling**
   - Script fails gracefully
   - Meaningful error messages
   - No system corruption on failure

3. **Cross-platform compatibility**
   - Works on Ubuntu, Mint, Pop!_OS
   - Handles different package managers
   - Path differences

4. **Idempotency**
   - Running twice doesn't break
   - Skips already installed items
   - Maintains system state

### Medium Priority (Should Test)
1. **Performance benchmarks**
   - Installation time limits
   - Resource usage
   - Parallel execution

2. **Configuration validation**
   - Config files created correctly
   - Permissions set properly
   - Symlinks work

3. **User interaction**
   - Prompts work correctly
   - Default selections
   - Ctrl+C handling

### Low Priority (Nice to Have)
1. **Edge cases**
   - Disk full scenarios
   - Network failures
   - Corrupted packages

2. **Cosmetic features**
   - Progress bars accuracy
   - Color output
   - Logging format

## 🚫 What NOT to Test

1. **External tool functionality**
   - Don't test if `git` works correctly
   - Don't test if `docker` runs containers
   - Trust that installed tools work

2. **OS-level operations**
   - Don't test if `apt update` contacts servers
   - Don't test kernel modules
   - Focus on your script logic

3. **Implementation details**
   - Don't test private functions
   - Don't test intermediate states
   - Test observable behavior

## 📝 Writing Good Tests

### Integration Test Template
```bash
#!/usr/bin/env bats

setup() {
    # Create test environment
    TEST_DIR="$(mktemp -d)"
    cp -r "$BATS_TEST_DIRNAME/../linux" "$TEST_DIR/"
}

teardown() {
    # Cleanup
    rm -rf "$TEST_DIR"
}

@test "apt installer handles locked dpkg" {
    # Simulate locked dpkg
    touch "$TEST_DIR/var/lib/dpkg/lock"
    
    # Run installer
    run "$TEST_DIR/linux/install/apt.sh"
    
    # Should wait and retry
    assert_success
    assert_output --partial "Waiting for apt lock"
}

@test "installer is idempotent" {
    # Run twice
    run "$TEST_DIR/linux/install/apt.sh"
    assert_success
    
    run "$TEST_DIR/linux/install/apt.sh"
    assert_success
    assert_output --partial "already installed"
}
```

### Best Practices
1. **Test names describe behavior**
   - ✅ "handles missing dependencies gracefully"
   - ❌ "test function X"

2. **Each test is independent**
   - Full setup/teardown
   - No shared state
   - Can run in any order

3. **Fast feedback**
   - Use containers over VMs when possible
   - Parallel execution
   - Skip slow tests in CI (mark as @slow)

4. **Clear assertions**
   ```bash
   # Good
   assert_output --partial "Successfully installed git"
   
   # Bad
   [[ $? -eq 0 ]]  # What does success mean here?
   ```

## 🔄 CI/CD Integration (v3.2.0)

### GitHub Actions Workflow - NO TEST AUTOMATION
```yaml
name: Code Quality Checks

on: [push, pull_request]

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ShellCheck (linting only)
        run: make lint
      # NO automated test execution

  documentation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Verify test documentation
        run: |
          # Check that manual test guides exist
          test -f TESTING_STRATEGY_v3.2.0.md
          test -f tests/guides/WHEN_TO_TEST.md
          test -f tests/guides/HOW_TO_TEST.md
      # NO test execution - only verify docs exist
```

### Manual Testing Requirements

**Before Release:**
1. Developer runs full test suite locally (~90 minutes)
2. Records results in `tests/results/`
3. Includes test report in PR
4. Reviewer may run subset of tests
5. NO automated gates based on tests

## 📊 Test Metrics

### Coverage Goals
- **Overall:** 80%+
- **Critical paths:** 95%+ (package installation, error handling)
- **Utilities:** 70%+
- **Interactive features:** 60%+

### Performance Benchmarks
- Unit tests: < 1 second
- Integration tests: < 5 minutes total
- E2E tests: < 15 minutes per scenario
- Full test suite: < 30 minutes

## 🛠️ Testing Tools

### Required
- **ShellCheck** - Static analysis
- **bats-core** - Bash testing framework
- **Docker** - Integration test environments
- **GitHub Actions** - CI/CD

### Optional
- **Vagrant** - Full VM testing
- **kcov** - Code coverage for bash
- **parallel** - Speed up test execution

## 🎯 Quick Start (v3.2.0 - Manual Testing)

```bash
# Install test dependencies (optional, for local testing)
./tests/install-test-deps.sh

# ⚠️ ALL TESTS ARE MANUAL - Run when YOU choose

# Quick confidence check (5 min)
./tests/manual/smoke/minimal-base.sh

# Story-specific tests
./tests/manual/run-story-tests.sh 1.1  # Test quick start
./tests/manual/run-story-tests.sh 1.6  # Test parser

# Full validation (90 min)
./tests/manual/full-validation.sh

# With educational output
TEST_EDUCATION=1 ./tests/manual/smoke/minimal-base.sh

# Record your results
./tests/manual/record-results.sh
```

## 📚 v3.2.0 Testing Philosophy

### Why Manual Testing?

1. **User Control**: You decide when to verify
2. **System Safety**: No automated scripts modifying your system
3. **Learning Opportunity**: Understand what's being tested
4. **Flexibility**: Skip tests that don't apply to you
5. **Trust Building**: See exactly what's happening

### When to Test?

- **Feeling Uncertain?** Run smoke tests (5 min)
- **Made Big Changes?** Run integration tests (15 min)
- **Before Release?** Run full suite (90 min)
- **User Reported Issue?** Run specific test
- **Just Curious?** Run with education mode

### Testing Guides

- See `TESTING_STRATEGY_v3.2.0.md` for complete v3.2.0 test plans
- See `tests/guides/WHEN_TO_TEST.md` for decision flowchart
- See `tests/guides/HOW_TO_TEST.md` for execution instructions
- See `QA_CHECKLIST.md` for release validation

## 🔍 Debugging Failed Tests

1. **Run test in isolation**
   ```bash
   bats tests/integration/failing_test.bats --verbose
   ```

2. **Add debug output**
   ```bash
   @test "my test" {
       echo "Debug: var=$var" >&3  # Prints even on success
       run my_command
       echo "Output: $output" >&3
       echo "Status: $status" >&3
   }
   ```

3. **Interactive debugging**
   ```bash
   # Drop into shell at failure point
   BATS_DEBUG=1 bats tests/integration/failing_test.bats
   ```

---

> **Remember:** Good tests give confidence to refactor. Poor tests slow development.  
> **Focus on:** Integration tests that catch real issues users would face.