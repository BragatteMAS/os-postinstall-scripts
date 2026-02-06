# Testing Patterns

**Analysis Date:** 2026-02-04

## Test Framework

**Runner:**
- Manual shell script testing (no Jest, Vitest, or Mocha configured)
- Local development mode: `npm run dev:test`
- Platform simulation: `npm run dev:test:linux`, `npm run dev:test:windows`, `npm run dev:test:macos`
- ShellCheck for static shell script analysis

**Assertion Library:**
- Not applicable - custom shell-based test runners
- ShellCheck provides linting rules

**Run Commands:**
```bash
npm run dev:test                  # Run tests on current platform
npm run dev:test:current          # Alias for current platform
npm run dev:test:linux            # Simulate Linux environment tests
npm run dev:test:windows          # Simulate Windows environment tests
npm run dev:test:macos            # Simulate macOS environment tests
npm run dev:lint                  # Run ShellCheck linting locally
npm run dev:check                 # Check local environment compatibility
npm run dev:setup                 # Install dependencies + setup
```

## Test File Organization

**Location:**
- Tests in `/tests` directory (root level)
- Manual tests: `/tests/manual/`
- Security tests: `/tests/security/`
- Integration tests: `/tests/manual/integration/`
- Smoke tests: `/tests/manual/smoke/`

**Naming:**
- Test files: `*-test.sh`, `test_*.sh`, `run_all_*.sh`
- Integration tests: descriptive names like `accuracy-test.sh`
- Security tests: `test_apt_lock_safety.sh`, `test_apt_timeout_scenarios.sh`

**Structure:**
```
tests/
├── test_harness.sh                      # Core test infrastructure
├── manual/
│   ├── test-config-system.sh
│   ├── test-ai-tools-config.sh
│   ├── smoke/
│   │   └── minimal-base.sh
│   └── integration/
│       └── parser/
│           └── accuracy-test.sh
└── security/
    ├── test_apt_lock_safety.sh
    ├── test_apt_timeout_scenarios.sh
    └── run_all_security_tests.sh
```

## Test Philosophy

**On-Demand Testing:**
- No automated CI/CD on push/PR
- Manual trigger via GitHub Actions only
- Saves resources and avoids unnecessary test runs
- Documented in `.github/TESTING_GUIDELINES.md`

**When Tests are Mandatory:**
1. Major releases (vX.0.0) - Full suite on all platforms
2. Critical script changes - Installation core, OS detection, security
3. Before production releases - Any version being released publicly

**When Tests are Optional:**
1. Minor versions (vX.Y.0) - Developer discretion
2. Patch versions (vX.Y.Z) - Only if touching sensitive areas
3. Documentation changes - Not required

## Test Structure

**Suite Organization (Shell-based):**
```bash
#!/bin/bash
# Header comment with test purpose
set -euo pipefail

# Colors and output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counter and tracking
tests_run=0
tests_passed=0
tests_failed=0

# Test functions
test_feature_name() {
    ((tests_run++))
    echo -n "Testing feature... "

    # Actual test logic
    if condition_is_true; then
        echo -e "${GREEN}✓${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}✗${NC}"
        ((tests_failed++))
    fi
}

# Run all tests
test_feature_name
test_another_feature

# Summary
echo "Tests run: $tests_run, Passed: $tests_passed, Failed: $tests_failed"
```

**Patterns:**
- Functions prefixed with `test_` for clarity
- Counter-based test tracking
- Color-coded output (green for pass, red for fail)
- Summary statistics at end

## Local Development Testing

**Environment Checking:**
- `npm run dev:check` validates local environment setup
- Checks platform detection
- Verifies required tools (brew, git, bash, zsh, etc.)
- Validates project structure
- Confirms development file presence

From `tools/dev/check-environment.js`:
```javascript
// Platform detection
const platform = os.platform();
const platformName = { 'darwin': 'macOS', 'linux': 'Linux', 'win32': 'Windows' }[platform];

// Tool validation
const checks = {
  'darwin': { 'brew': 'which brew', 'git': 'which git' },
  'linux': { 'apt/yum/dnf': '...', 'curl': 'which curl' },
  'win32': { 'powershell': '...', 'winget': 'where winget' }
};
```

## Linting

**ShellCheck Configuration:**
- Tool: ShellCheck (static analysis for shell scripts)
- Run via: `npm run dev:lint` (local) or CI/CD trigger
- No configuration file (uses ShellCheck defaults)

**Linting Script Location:** `tools/dev/lint-scripts.sh`

**Local Linting Process:**
```bash
# Check if ShellCheck installed
if ! command -v shellcheck &> /dev/null; then
    echo "❌ ShellCheck is not installed!"
    exit 1
fi

# Run ShellCheck on all scripts
errors=0
warnings=0
find . -name "*.sh" -type f | while read -r script; do
    if output=$(shellcheck "$script" 2>&1); then
        echo -e "${GREEN}✓${NC} $script"
    else
        echo -e "${RED}✗${NC} $script"
        ((errors++)) # Track failures
    fi
done
```

## Test Types

**Local Simulation Tests:**
- File: `tools/dev/test-platform.sh`
- Simulates testing for Linux, Windows, macOS without actual platform
- Checks script syntax: `bash -n script.sh`
- Verifies directory structure
- Validates profile compatibility
- Does NOT execute actual installation

Example from `test-platform.sh`:
```bash
case "$TARGET_PLATFORM" in
    linux)
        # Simulate Linux tests
        bash -n "linux/install/apt.sh" 2>/dev/null && \
            echo -e "${GREEN}✓${NC} APT script syntax OK"
        ;;
    darwin)
        # Simulate macOS tests
        echo -e "${GREEN}✓${NC} git (would check with brew)"
        ;;
esac
```

**Manual/Integration Tests:**
- Located in `/tests/manual/integration/`
- Test specific functionality like parser accuracy
- Verify configuration system behavior
- Check AI tools configuration

**Security Tests:**
- Located in `/tests/security/`
- Test APT lock safety: `test_apt_lock_safety.sh`
- Test APT timeout scenarios: `test_apt_timeout_scenarios.sh`
- Run all security tests: `run_all_security_tests.sh`

**Smoke Tests:**
- Located in `/tests/manual/smoke/`
- Test minimal base functionality: `minimal-base.sh`
- Quick verification of core functionality

## Test Data Management

**Fixtures:**
- Profiles stored in `profiles/` directory as YAML files
- Configuration examples in `configs/` directory
- Embedded test data in test scripts

**Mocking:**
- Environment variable mocking via `cross-env`
- Platform simulation via `OS_TARGET` environment variable
- Mode flags: `TEST_MODE=local`, `CHECK_MODE=local`, `LINT_MODE=local`

## Coverage

**Requirements:** No formal coverage tracking configured

**Scope of Local Testing:**
- Syntax validation only (bash -n, ShellCheck)
- No runtime code coverage metrics
- Behavioral testing requires actual platform execution

**CI/CD Coverage:**
- Manual trigger workflow can run full test suite
- Tests across Ubuntu versions (multiple runners)
- Platform-specific validation

## Local Environment Prerequisites

**Required for Testing:**
- Node.js >= 14.0.0
- npm >= 6.0.0
- ShellCheck (for linting)
- Git
- Bash
- Platform-specific tools (brew for macOS, apt for Linux, etc.)

**Setup:**
```bash
npm run dev:setup          # Installs dependencies
npm run dev:check          # Validates environment
npm run dev:lint           # Lint all scripts locally
npm run dev:test           # Run tests on current platform
```

## GitHub Actions Integration

**Workflow Files Location:** `.github/workflows/`
(Workflows deleted per commit 097234b - "chore: remove CI/CD workflows")

**Testing Guidelines Documentation:**
- Location: `.github/TESTING_GUIDELINES.md`
- Explains when tests are mandatory vs optional
- Shows how to trigger workflows via GitHub CLI or web UI
- Provides manual testing alternatives

**Triggering Tests:**
```bash
# Via GitHub CLI
gh workflow run test-scripts.yml \
  -f reason="Testing before v3.0.0 release" \
  -f confirm_major_change="yes"

# Check status
gh run list --workflow=test-scripts.yml
```

## Best Practices

**Before Committing:**
1. Run `npm run dev:lint` to check shell script syntax
2. Run `npm run dev:check` to verify environment
3. Run `npm run dev:test` for platform-specific tests
4. Test locally before requesting CI/CD execution

**Avoiding False Negatives:**
- Run ShellCheck locally first
- Test scripts with actual bash execution when possible
- Use simulation mode to validate structure

**Documentation:**
- Test failures must be documented in commit messages
- CI/CD trigger reasons recorded in CHANGELOG
- Test results referenced in PR descriptions

## Limitations

**What's NOT Tested:**
- Actual package installations (requires real platform)
- Script execution side effects (requires execution environment)
- Cross-platform compatibility without actual platforms
- Real timing behaviors (simulation only)

**What IS Tested:**
- Syntax validity of shell scripts
- Script structure and completeness
- Configuration validity (YAML/JSON)
- Directory structure presence
- Code linting against ShellCheck rules

---

*Testing analysis: 2026-02-04*
