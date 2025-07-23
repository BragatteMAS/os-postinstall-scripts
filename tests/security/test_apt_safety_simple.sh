#!/bin/bash
# Simplified security test for APT lock safety
# Works on macOS for CI/CD testing

set -euo pipefail

echo "=== APT Lock Safety Security Tests ==="
echo

# Colors (using printf for better compatibility)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: No force removal commands
echo -n "1. Checking for dangerous lock removal commands... "
if grep -r "sudo rm.*dpkg.*lock" ./linux/ --include="*.sh" 2>/dev/null | grep -v "^#"; then
    printf "${RED}FAIL${NC} - Found dangerous commands\n"
    ((TESTS_FAILED++))
else
    printf "${GREEN}PASS${NC}\n"
    ((TESTS_PASSED++))
fi

# Test 2: Safety module exists
echo -n "2. Checking package-manager-safety.sh exists... "
if [[ -f "./utils/package-manager-safety.sh" ]]; then
    printf "${GREEN}PASS${NC}\n"
    ((TESTS_PASSED++))
else
    printf "${RED}FAIL${NC} - Safety module not found\n"
    ((TESTS_FAILED++))
fi

# Test 3: Logging module exists
echo -n "3. Checking logging.sh exists... "
if [[ -f "./utils/logging.sh" ]]; then
    printf "${GREEN}PASS${NC}\n"
    ((TESTS_PASSED++))
else
    printf "${RED}FAIL${NC} - Logging module not found\n"
    ((TESTS_FAILED++))
fi

# Test 4: APT scripts source safety module
echo -n "4. Checking if APT scripts use safety module... "
missing_safety=0
for script in ./linux/install/apt.sh ./linux/auto/auto_apt.sh ./linux/post_install.sh; do
    if [[ -f "$script" ]]; then
        if ! grep -q "source.*package-manager-safety.sh" "$script"; then
            echo
            echo "   Missing in: $script"
            missing_safety=1
        fi
    fi
done
if [[ $missing_safety -eq 0 ]]; then
    printf "${GREEN}PASS${NC}\n"
    ((TESTS_PASSED++))
else
    printf "${RED}FAIL${NC} - Some scripts don't use safety module\n"
    ((TESTS_FAILED++))
fi

# Test 5: Check for wait_for_apt usage
echo -n "5. Checking for wait_for_apt implementation... "
if grep -q "wait_for_apt" ./utils/package-manager-safety.sh; then
    printf "${GREEN}PASS${NC}\n"
    ((TESTS_PASSED++))
else
    printf "${RED}FAIL${NC} - wait_for_apt not found\n"
    ((TESTS_FAILED++))
fi

# Test 6: Check for package validation
echo -n "6. Checking for package name validation... "
if grep -q "validate_package_name" ./utils/package-manager-safety.sh; then
    printf "${GREEN}PASS${NC}\n"
    ((TESTS_PASSED++))
else
    printf "${RED}FAIL${NC} - Package validation not found\n"
    ((TESTS_FAILED++))
fi

# Summary
echo
echo "=== Test Summary ==="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    printf "${GREEN}All security tests passed!${NC}\n"
    exit 0
else
    printf "${RED}Security tests failed!${NC}\n"
    exit 1
fi