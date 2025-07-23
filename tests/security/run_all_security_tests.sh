#!/bin/bash
# Run all security tests for OS Post-Install Scripts
# Exit with error if any test fails

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║        OS Post-Install Scripts Security Test Suite     ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Run a test suite
run_test_suite() {
    local test_name="$1"
    local test_script="$2"
    
    ((TOTAL_SUITES++))
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running:${NC} $test_name"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f "$test_script" ]] && [[ -x "$test_script" ]]; then
        if "$test_script"; then
            echo -e "\n${GREEN}✓ Suite Passed:${NC} $test_name"
            ((PASSED_SUITES++))
        else
            echo -e "\n${RED}✗ Suite Failed:${NC} $test_name"
            ((FAILED_SUITES++))
        fi
    else
        echo -e "${RED}✗ Test script not found or not executable:${NC} $test_script"
        ((FAILED_SUITES++))
    fi
}

# Test Suite 1: APT Lock Safety
run_test_suite "APT Lock Safety Tests" "$SCRIPT_DIR/test_apt_lock_safety.sh"

# Test Suite 2: Timeout Scenarios
run_test_suite "APT Timeout Integration Tests" "$SCRIPT_DIR/test_apt_timeout_scenarios.sh"

# Overall Summary
echo -e "\n${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    FINAL SUMMARY                       ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"

echo -e "\nTest Suites Run:    $TOTAL_SUITES"
echo -e "Test Suites Passed: ${GREEN}$PASSED_SUITES${NC}"
echo -e "Test Suites Failed: ${RED}$FAILED_SUITES${NC}"

if [[ $FAILED_SUITES -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All security tests passed! The implementation is secure.${NC}"
    echo -e "${GREEN}APT lock handling meets all security requirements from ADR-005.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Security tests failed! Please fix the issues before release.${NC}"
    echo -e "${RED}The implementation does not meet security requirements.${NC}"
    exit 1
fi