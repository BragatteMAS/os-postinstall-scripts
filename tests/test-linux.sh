#!/usr/bin/env bash
#######################################
# Script: test-linux.sh
# Description: Tests for Linux platform scripts (Phase 5)
# Validates syntax, critical patterns, and anti-patterns
# Author: Bragatte
# Date: 2026-02-06
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
echo "  Linux Platform Tests (Phase 5)"
echo "========================================="
echo ""

#######################################
# 1. Syntax validation (bash -n)
#######################################
echo "--- Syntax Checks ---"

assert_pass "apt.sh syntax" bash -n src/platforms/linux/install/apt.sh
assert_pass "flatpak.sh syntax" bash -n src/platforms/linux/install/flatpak.sh
assert_pass "snap.sh syntax" bash -n src/platforms/linux/install/snap.sh
assert_pass "linux main.sh syntax" bash -n src/platforms/linux/main.sh
assert_pass "rust-cli.sh syntax" bash -n src/install/rust-cli.sh
assert_pass "dev-env.sh syntax" bash -n src/install/dev-env.sh
assert_pass "fnm.sh syntax" bash -n src/install/fnm.sh
assert_pass "uv.sh syntax" bash -n src/install/uv.sh
assert_pass "ai-tools.sh syntax" bash -n src/install/ai-tools.sh
assert_pass "interactive.sh syntax" bash -n src/core/interactive.sh

echo ""

#######################################
# 2. Content validation (critical patterns)
#######################################
echo "--- Content Checks ---"

assert_pass "APT lock handling" grep -q "DPkg::Lock::Timeout" src/platforms/linux/install/apt.sh
assert_pass "LINUX_DIR used" grep -q "LINUX_DIR" src/platforms/linux/main.sh
assert_pass "retry logic" grep -q "retry_with_backoff" src/platforms/linux/install/apt.sh
assert_pass "Flathub remote" grep -q "flathub" src/platforms/linux/install/flatpak.sh
assert_pass "classic confinement" grep -q "classic" src/platforms/linux/install/snap.sh
assert_pass "platform branching" grep -q "DETECTED_OS" src/install/rust-cli.sh
assert_pass "fnm URL" grep -q "fnm.vercel.app" src/install/fnm.sh
assert_pass "uv URL" grep -q "astral.sh" src/install/uv.sh
assert_pass "npm install" grep -q "npm install -g" src/install/ai-tools.sh

echo ""

#######################################
# 3. Anti-pattern checks (must NOT contain)
#######################################
echo "--- Anti-pattern Checks ---"

# assert_fail: grep must NOT match (command failing = test passing)
assert_fail "no set -e in apt" grep -qP "^\s*set\s+-e" src/platforms/linux/install/apt.sh
assert_fail "no set -e in flatpak" grep -qP "^\s*set\s+-e" src/platforms/linux/install/flatpak.sh
assert_fail "no set -e in snap" grep -qP "^\s*set\s+-e" src/platforms/linux/install/snap.sh
assert_fail "no autoclean in apt" grep -q "autoclean" src/platforms/linux/install/apt.sh
assert_fail "no SCRIPT_DIR= in main" grep -q "^SCRIPT_DIR=" src/platforms/linux/main.sh

echo ""

#######################################
# Summary
#######################################
echo "========================================="
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_TOTAL total"
echo "========================================="
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
