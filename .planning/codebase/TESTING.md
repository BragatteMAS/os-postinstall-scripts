# Testing Patterns

**Analysis Date:** 2026-02-08

## Test Framework

**Runner:** Manual shell script testing (no automated framework)
**Linting:** ShellCheck for static analysis

**Run Commands:**
```bash
shellcheck src/**/*.sh          # Lint all source scripts
bash tests/test_harness.sh      # Run test harness
bash tests/test-dotfiles.sh     # Run dotfiles tests
bash tests/test-linux.sh        # Run Linux platform tests
```

## Test File Organization

**Location:** `tests/` directory (root level)

**Current Test Files:**
```
tests/
├── test_harness.sh        # Core test infrastructure (structure, syntax, permissions)
├── test-dotfiles.sh       # Integration tests for src/core/dotfiles.sh
└── test-linux.sh          # Linux platform script validation
```

**Naming:** `test-*.sh` or `test_*.sh`

## Test Philosophy

**Manual Testing:**
- No automated CI/CD pipeline (workflows removed)
- Tests run on-demand by developers
- ShellCheck linting before commits

**When Tests are Mandatory:**
1. Changes to `src/core/` modules
2. Changes to platform orchestrators
3. Before releases

**When Tests are Optional:**
1. Documentation changes
2. Data file updates (package lists)
3. Planning document changes

## Test Structure

**Pattern:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Colors and tracking
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
tests_run=0
tests_passed=0
tests_failed=0

test_feature_name() {
    ((tests_run++))
    echo -n "Testing feature... "
    if condition_is_true; then
        echo -e "${GREEN}PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}FAIL${NC}"
        ((tests_failed++))
    fi
}

# Run tests
test_feature_name

# Summary
echo "Tests: $tests_run | Passed: $tests_passed | Failed: $tests_failed"
```

## Coverage

**Current:** Minimal - 3 test scripts covering:
- Script syntax validation (`bash -n`)
- File structure verification
- Permission checks
- Critical pattern detection (no `rm -rf /`, no hardcoded passwords)
- Dotfiles symlink logic

**Not Tested:**
- Actual package installations (requires real platform)
- Cross-platform execution
- Idempotency (running twice)

## Linting

**ShellCheck:**
- No config file (uses defaults)
- Run locally before commits
- Required in PR template checklist

---

*Testing analysis: 2026-02-08*
