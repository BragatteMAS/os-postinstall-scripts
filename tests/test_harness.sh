#!/usr/bin/env bash
# Test Harness for OS Post-Install Scripts
# This script verifies basic functionality of the current project structure

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
test_script_exists "config.sh"
test_script_exists "src/install/rust-cli.sh"
test_script_exists "src/install/uv.sh"
test_script_exists "src/install/dev-env.sh"
test_script_exists "src/platforms/linux/main.sh"
test_script_exists "src/platforms/linux/post_install.sh"
test_script_exists "src/platforms/windows/main.ps1"

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
test_script_executable "src/install/rust-cli.sh"
test_script_executable "src/platforms/linux/main.sh"
test_script_executable "src/platforms/linux/post_install.sh"

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
done < <(find . -name "*.sh" -type f -not -path './.git/*' -print0 2>/dev/null)

# Test 4: Check for placeholder URLs
header "Placeholder URL Tests"

if grep -r "SEU_USUARIO" --include="*.sh" . 2>/dev/null | grep -v "test_harness.sh" | grep -q .; then
    fail "Found placeholder URLs (SEU_USUARIO) in scripts"
    echo "  Files with placeholders:"
    grep -r "SEU_USUARIO" --include="*.sh" . 2>/dev/null | grep -v "test_harness.sh" | cut -d: -f1 | sort -u | sed 's/^/    /'
else
    pass "No placeholder URLs found"
fi

# Test 5: Directory structure
header "Directory Structure Tests"

test_directory_exists() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        pass "Directory $dir exists"
    else
        fail "Directory $dir not found"
    fi
}

test_directory_exists "src"
test_directory_exists "src/core"
test_directory_exists "src/install"
test_directory_exists "src/installers"
test_directory_exists "src/platforms"
test_directory_exists "src/platforms/linux"
test_directory_exists "src/platforms/macos"
test_directory_exists "src/platforms/windows"
test_directory_exists "data"
test_directory_exists "data/packages"
test_directory_exists "data/packages/profiles"
test_directory_exists "data/dotfiles"
test_directory_exists "docs"
test_directory_exists "tests"
test_directory_exists "examples"

# Test 6: Documentation files
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
test_file_exists "CONTRIBUTING.md"

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
