#!/usr/bin/env bash
#######################################
# Script: test-macos.sh
# Description: Tests for macOS platform scripts
# Validates syntax, critical patterns, and anti-patterns
# Author: Bragatte
# Date: 2026-02-08
#######################################

# Test runner setup
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

assert_pass() {
    local test_name="$1"; shift
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if "$@" 2>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] $test_name"
    fi
}

# assert_fail: command must FAIL for test to pass (anti-pattern check)
assert_fail() {
    local test_name="$1"; shift
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if "$@" 2>/dev/null; then
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] $test_name"
    else
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] $test_name"
    fi
}

echo "========================================="
echo "  macOS Platform Tests"
echo "========================================="
echo ""

#######################################
# 1. Syntax validation (bash -n)
#######################################
echo "--- Syntax Checks ---"

assert_pass "homebrew.sh syntax" bash -n src/platforms/macos/install/homebrew.sh
assert_pass "brew.sh syntax" bash -n src/platforms/macos/install/brew.sh
assert_pass "brew-cask.sh syntax" bash -n src/platforms/macos/install/brew-cask.sh
assert_pass "macos main.sh syntax" bash -n src/platforms/macos/main.sh

echo ""

#######################################
# 2. Content validation (critical patterns)
#######################################
echo "--- Content Checks ---"

assert_pass "MACOS_DIR used in main.sh" grep -q "MACOS_DIR" src/platforms/macos/main.sh
assert_pass "get_brew_prefix in homebrew.sh" grep -q "get_brew_prefix" src/platforms/macos/install/homebrew.sh
assert_pass "is_brew_installed in brew.sh" grep -q "is_brew_installed" src/platforms/macos/install/brew.sh
assert_pass "_is_cask_installed in brew-cask.sh" grep -q "_is_cask_installed" src/platforms/macos/install/brew-cask.sh
assert_pass "DRY_RUN guard in homebrew.sh" grep -q "DRY_RUN" src/platforms/macos/install/homebrew.sh
assert_pass "FAILURE_LOG in homebrew.sh" grep -q "FAILURE_LOG" src/platforms/macos/install/homebrew.sh
assert_pass "exit 1 in homebrew.sh" grep -q "exit 1" src/platforms/macos/install/homebrew.sh
assert_pass "FAILURE_LOG in main.sh" grep -q "FAILURE_LOG" src/platforms/macos/main.sh
assert_pass "show_dry_run_banner in main.sh" grep -q "show_dry_run_banner" src/platforms/macos/main.sh

echo ""

#######################################
# 3. Anti-pattern checks (must NOT contain)
#######################################
echo "--- Anti-pattern Checks ---"

# assert_fail: grep must NOT match (command failing = test passing)
# Note: Using grep -E for POSIX compatibility (macOS BSD grep lacks -P)
assert_fail "no set -e in homebrew.sh" grep -qE "^[[:space:]]*set[[:space:]]+-e" src/platforms/macos/install/homebrew.sh
assert_fail "no set -e in brew.sh" grep -qE "^[[:space:]]*set[[:space:]]+-e" src/platforms/macos/install/brew.sh
assert_fail "no SCRIPT_DIR= in main.sh" grep -q "^SCRIPT_DIR=" src/platforms/macos/main.sh

echo ""

#######################################
# Summary
#######################################
echo "========================================="
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_TOTAL total"
echo "========================================="
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
