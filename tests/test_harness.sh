#!/usr/bin/env bash
# Test Harness for OS Post-Install Scripts
# This script verifies basic functionality before and after reorganization

set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
declare -i PASSED=0
declare -i FAILED=0
declare -i SKIPPED=0

# Test functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=$((FAILED + 1))
}

skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Test 1: Check if main scripts exist
header "Script Existence Tests"

test_script_exists() {
    local script="$1"
    if [[ -f "$script" ]]; then
        pass "$script exists"
    else
        fail "$script not found"
    fi
}

test_script_exists "setup.sh"
test_script_exists "install_rust_tools.sh"
test_script_exists "linux/post_install.sh"
test_script_exists "windows/win11.ps1"
test_script_exists "zshrc"

# Test 2: Check script permissions
header "Script Permission Tests"

test_script_executable() {
    local script="$1"
    if [[ -f "$script" && -x "$script" ]]; then
        pass "$script is executable"
    elif [[ -f "$script" ]]; then
        fail "$script exists but not executable"
    else
        skip "$script not found"
    fi
}

test_script_executable "setup.sh"
test_script_executable "install_rust_tools.sh"
test_script_executable "linux/post_install.sh"
test_script_executable "linux/auto/auto_apt.sh"
test_script_executable "linux/auto/auto_flat.sh"
test_script_executable "linux/auto/auto_snap.sh"

# Test 3: Check for shell script issues
header "Shell Script Quality Tests"

test_script_shebang() {
    local script="$1"
    if [[ -f "$script" ]]; then
        if head -1 "$script" | grep -q "^#!"; then
            pass "$script has shebang"
        else
            fail "$script missing shebang"
        fi
    else
        skip "$script not found"
    fi
}

# Test all .sh files for shebangs
while IFS= read -r -d '' script; do
    test_script_shebang "$script"
done < <(find . -name "*.sh" -type f -print0 2>/dev/null)

# Test 4: Check for placeholder URLs
header "Placeholder URL Tests"

if grep -r "SEU_USUARIO" --include="*.sh" . 2>/dev/null | grep -q .; then
    fail "Found placeholder URLs (SEU_USUARIO) in scripts"
    echo "  Files with placeholders:"
    grep -r "SEU_USUARIO" --include="*.sh" . 2>/dev/null | cut -d: -f1 | sort -u | sed 's/^/    /'
else
    pass "No placeholder URLs found"
fi

# Test 5: Check Makefile targets
header "Makefile Tests"

test_makefile_target() {
    local target="$1"
    if make -n "$target" &>/dev/null; then
        pass "Makefile target '$target' exists"
    else
        fail "Makefile target '$target' not found"
    fi
}

test_makefile_target "help"
test_makefile_target "setup"
test_makefile_target "test"
test_makefile_target "clean"

# Test 6: Directory structure
header "Directory Structure Tests"

test_directory_exists() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        pass "Directory $dir exists"
    else
        fail "Directory $dir not found"
    fi
}

test_directory_exists "linux"
test_directory_exists "linux/auto"
test_directory_exists "linux/distros"
test_directory_exists "windows"
test_directory_exists ".ai"
test_directory_exists "docs"

# Test 7: Documentation files
header "Documentation Tests"

test_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        pass "$file exists"
    else
        fail "$file not found"
    fi
}

test_file_exists "README.md"
test_file_exists "CHANGELOG.md"
test_file_exists "LICENSE"
test_file_exists ".gitignore"

# Summary
header "Test Summary"
echo "Passed:  $PASSED"
echo "Failed:  $FAILED"
echo "Skipped: $SKIPPED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi