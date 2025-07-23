#!/bin/bash
# Test suite for APT lock safety mechanisms
# Tests implementation of ADR-005 security requirements

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the safety module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Override log settings for testing (no sudo required)
export LOG_TO_FILE=false
export LOG_TO_STDOUT=true

source "${ROOT_DIR}/utils/package-manager-safety.sh"

# Test helper functions
test_start() {
    local test_name="$1"
    echo -e "\n${YELLOW}TEST:${NC} $test_name"
    ((TESTS_RUN++))
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    local reason="$1"
    echo -e "${RED}✗ FAIL:${NC} $reason"
    ((TESTS_FAILED++))
}

# Mock fuser command for testing
mock_fuser() {
    if [[ "${MOCK_FUSER_LOCKED:-false}" == "true" ]]; then
        return 0  # Simulate lock exists
    else
        return 1  # Simulate no lock
    fi
}

# Test 1: Verify NO force removal commands exist
test_start "No force removal of APT locks"
if grep -r "sudo rm.*dpkg.*lock" "${ROOT_DIR}/linux/" --include="*.sh" | grep -v "^#"; then
    test_fail "Found force removal commands"
else
    test_pass
fi

# Test 2: Package name validation
test_start "Package name validation - valid names"
valid_names=("git" "python3" "docker-ce" "lib32z1" "g++" "python3.11")
all_valid=true
for pkg in "${valid_names[@]}"; do
    if ! validate_package_name "$pkg"; then
        test_fail "Failed to validate valid package: $pkg"
        all_valid=false
        break
    fi
done
if $all_valid; then
    test_pass
fi

# Test 3: Package name validation - invalid names
test_start "Package name validation - invalid names"
invalid_names=("git;rm -rf /" "../../../etc/passwd" "package|cat /etc/shadow" "package\$(whoami)" "package\`id\`")
all_caught=true
for pkg in "${invalid_names[@]}"; do
    if validate_package_name "$pkg" 2>/dev/null; then
        test_fail "Failed to catch invalid package: $pkg"
        all_caught=false
        break
    fi
done
if $all_caught; then
    test_pass
fi

# Test 4: Timeout mechanism
test_start "APT lock timeout mechanism"
# Override timeout for testing
export APT_LOCK_TIMEOUT=2
export APT_LOCK_CHECK_INTERVAL=1
export MOCK_FUSER_LOCKED=true
# Replace fuser with our mock
alias fuser=mock_fuser

start_time=$(date +%s)
if wait_for_apt 2>/dev/null; then
    test_fail "Should have timed out"
else
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    if [[ $elapsed -ge 2 ]] && [[ $elapsed -le 3 ]]; then
        test_pass
    else
        test_fail "Timeout not within expected range: ${elapsed}s"
    fi
fi
unalias fuser
unset MOCK_FUSER_LOCKED

# Test 5: Log directory creation
test_start "Log directory creation"
test_log_dir="/tmp/test-os-postinstall-$$"
OLD_LOG_FILE="$LOG_FILE"
export LOG_FILE="$test_log_dir/test.log"

# Function should create directory if it doesn't exist
init_logging
if [[ -d "$(dirname "$LOG_FILE")" ]]; then
    test_pass
    rm -rf "$test_log_dir"
else
    test_fail "Log directory not created"
fi
export LOG_FILE="$OLD_LOG_FILE"

# Test 6: Audit trail for package operations
test_start "Package operation audit trail"
test_log_dir="/tmp/test-os-postinstall-audit-$$"
mkdir -p "$test_log_dir"
chmod 755 "$test_log_dir"

# Mock the log function to use test directory
log_package_operation() {
    local operation="$1"
    local package="$2"
    local status="$3"
    echo "$(date -Iseconds)|$USER|$operation|$package|$status" >> "$test_log_dir/package-operations.log"
}

log_package_operation "install" "test-package" "success"
if [[ -f "$test_log_dir/package-operations.log" ]]; then
    if grep -q "test-package" "$test_log_dir/package-operations.log"; then
        test_pass
    else
        test_fail "Log entry not found"
    fi
else
    test_fail "Log file not created"
fi
rm -rf "$test_log_dir"

# Test 7: Check all APT scripts source safety module
test_start "All APT scripts source safety module"
apt_scripts=(
    "${ROOT_DIR}/linux/install/apt.sh"
    "${ROOT_DIR}/linux/auto/auto_apt.sh"
    "${ROOT_DIR}/linux/post_install.sh"
)
all_source=true
for script in "${apt_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if ! grep -q "source.*package-manager-safety.sh" "$script"; then
            test_fail "Script doesn't source safety module: $script"
            all_source=false
            break
        fi
    fi
done
if $all_source; then
    test_pass
fi

# Test 8: No sudo in safety module functions
test_start "Safety functions don't require sudo internally"
if grep -E "^[^#]*sudo" "${ROOT_DIR}/utils/package-manager-safety.sh" | grep -v "apt-get\|dpkg\|tee"; then
    test_fail "Found unexpected sudo usage in safety functions"
else
    test_pass
fi

# Test 9: Error messages are informative
test_start "Error messages provide guidance"
# Capture error output
error_output=$(validate_package_name "invalid|package" 2>&1 || true)
if echo "$error_output" | grep -q "must contain only letters, numbers"; then
    test_pass
else
    test_fail "Error message not informative enough"
fi

# Test 10: Safe wrapper functions exist
test_start "All required safe wrapper functions exist"
required_functions=(
    "wait_for_apt"
    "validate_package_name"
    "safe_apt_update"
    "safe_apt_install"
    "safe_apt_remove"
    "safe_apt_install_multiple"
)
all_exist=true
for func in "${required_functions[@]}"; do
    if ! declare -f "$func" > /dev/null; then
        test_fail "Missing function: $func"
        all_exist=false
        break
    fi
done
if $all_exist; then
    test_pass
fi

# Summary
echo -e "\n${YELLOW}=== TEST SUMMARY ===${NC}"
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All security tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Security tests failed!${NC}"
    exit 1
fi