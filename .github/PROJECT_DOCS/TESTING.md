# 🏆 Testing Strategy - OS Post-Install Scripts

> **Testing Trophy Approach** adapted for Shell Scripts  
> Focus on **Integration Tests** that verify real-world functionality

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

### Running Tests

```bash
# Run all tests
make test

# Run specific category
make test-static
make test-unit
make test-integration
make test-e2e

# Run with coverage
make test-coverage
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

## 🔄 CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Test Scripts

on: [push, pull_request]

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ShellCheck
        run: make test-static

  integration-tests:
    strategy:
      matrix:
        os: [ubuntu-20.04, ubuntu-22.04]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v3
      - name: Run integration tests
        run: make test-integration

  e2e-tests:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v3
      - name: Run E2E tests
        run: make test-e2e
```

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

## 🎯 Quick Start

```bash
# Install test dependencies
./tests/install-test-deps.sh

# Run all tests
./tests/test_harness.sh

# Run specific test file
bats tests/integration/apt.bats

# Run with verbose output
./tests/test_harness.sh -v

# Generate coverage report
./tests/coverage.sh
```

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