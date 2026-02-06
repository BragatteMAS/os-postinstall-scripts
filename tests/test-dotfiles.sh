#!/usr/bin/env bash
#######################################
# Script: test-dotfiles.sh
# Description: Integration tests for src/core/dotfiles.sh
# Author: Bragatte
# Date: 2026-02-06
#######################################

set -u  # Exit on undefined variable

#######################################
# Test Setup
#######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

# Create unique test directory
TEST_DIR="/tmp/test-dotfiles-$$"
TEST_HOME="${TEST_DIR}/home"
TEST_SOURCE="${TEST_DIR}/data/dotfiles"
TEST_BACKUP="${TEST_HOME}/.dotfiles-backup"

# Track test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Cleanup on exit
#######################################
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}
trap cleanup EXIT INT TERM

#######################################
# Test helpers
#######################################
setup_test_env() {
    # Create test directory structure
    mkdir -p "$TEST_HOME"
    mkdir -p "$TEST_SOURCE/git"
    mkdir -p "$TEST_SOURCE/zsh"

    # Override HOME for tests
    export HOME="$TEST_HOME"
    export BACKUP_DIR="${TEST_HOME}/.dotfiles-backup"
    export MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"

    # Create test source files
    echo "# gitconfig content" > "${TEST_SOURCE}/git/gitconfig"
    echo "# gitignore content" > "${TEST_SOURCE}/git/gitignore"
    echo "# zshrc content" > "${TEST_SOURCE}/zsh/zshrc"
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"

    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo "[PASS] ${msg}"
        return 0
    else
        ((TESTS_FAILED++))
        echo "[FAIL] ${msg}"
        echo "  Expected: ${expected}"
        echo "  Actual:   ${actual}"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File should exist: ${file}}"

    ((TESTS_RUN++))
    if [[ -e "$file" ]]; then
        ((TESTS_PASSED++))
        echo "[PASS] ${msg}"
        return 0
    else
        ((TESTS_FAILED++))
        echo "[FAIL] ${msg}"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local msg="${2:-File should not exist: ${file}}"

    ((TESTS_RUN++))
    if [[ ! -e "$file" ]]; then
        ((TESTS_PASSED++))
        echo "[PASS] ${msg}"
        return 0
    else
        ((TESTS_FAILED++))
        echo "[FAIL] ${msg}"
        return 1
    fi
}

assert_symlink() {
    local link="$1"
    local target="$2"
    local msg="${3:-${link} should be symlink to ${target}}"

    ((TESTS_RUN++))
    if [[ -L "$link" ]]; then
        local actual_target
        actual_target=$(readlink "$link")
        if [[ "$actual_target" == "$target" ]]; then
            ((TESTS_PASSED++))
            echo "[PASS] ${msg}"
            return 0
        else
            ((TESTS_FAILED++))
            echo "[FAIL] ${msg}"
            echo "  Expected target: ${target}"
            echo "  Actual target:   ${actual_target}"
            return 1
        fi
    else
        ((TESTS_FAILED++))
        echo "[FAIL] ${msg}"
        echo "  Not a symlink"
        return 1
    fi
}

assert_not_symlink() {
    local file="$1"
    local msg="${2:-${file} should not be a symlink}"

    ((TESTS_RUN++))
    if [[ ! -L "$file" && -e "$file" ]]; then
        ((TESTS_PASSED++))
        echo "[PASS] ${msg}"
        return 0
    else
        ((TESTS_FAILED++))
        echo "[FAIL] ${msg}"
        return 1
    fi
}

#######################################
# Test Cases
#######################################

test_path_to_backup_name_simple() {
    echo ""
    echo "=== Test: path_to_backup_name simple file ==="
    local result
    result=$(path_to_backup_name "${HOME}/.zshrc")

    # Should be: zshrc.bak.YYYY-MM-DD
    local expected="zshrc.bak.$(date +%Y-%m-%d)"
    assert_eq "$expected" "$result" "~/.zshrc converts to zshrc.bak.DATE"
}

test_path_to_backup_name_nested() {
    echo ""
    echo "=== Test: path_to_backup_name nested path ==="
    local result
    result=$(path_to_backup_name "${HOME}/.config/git/ignore")

    # Should be: config-git-ignore.bak.YYYY-MM-DD
    local expected="config-git-ignore.bak.$(date +%Y-%m-%d)"
    assert_eq "$expected" "$result" "~/.config/git/ignore converts to config-git-ignore.bak.DATE"
}

test_create_symlink_basic() {
    echo ""
    echo "=== Test: create_dotfile_symlink basic ==="

    local source="${TEST_SOURCE}/zsh/zshrc"
    local target="${HOME}/.zshrc"

    create_dotfile_symlink "$source" "$target"
    assert_symlink "$target" "$source" "Created symlink ~/.zshrc"
}

test_create_symlink_creates_parent_dir() {
    echo ""
    echo "=== Test: create_dotfile_symlink creates parent directory ==="

    local source="${TEST_SOURCE}/git/gitignore"
    local target="${HOME}/.config/git/ignore"

    # Parent dir should not exist yet
    assert_file_not_exists "${HOME}/.config" "Parent dir should not exist initially"

    create_dotfile_symlink "$source" "$target"

    assert_file_exists "${HOME}/.config/git" "Parent directory created"
    assert_symlink "$target" "$source" "Symlink created in nested path"
}

test_backup_existing_file() {
    echo ""
    echo "=== Test: backup existing file before symlink ==="

    local source="${TEST_SOURCE}/git/gitconfig"
    local target="${HOME}/.gitconfig"

    # Create existing file (not a symlink)
    echo "original content" > "$target"

    create_dotfile_symlink "$source" "$target"

    # Should have created backup
    assert_file_exists "$BACKUP_DIR" "Backup directory created"

    # Check manifest has entry
    ((TESTS_RUN++))
    if grep -q ".gitconfig" "$MANIFEST_FILE" 2>/dev/null; then
        ((TESTS_PASSED++))
        echo "[PASS] Backup appears in manifest"
    else
        ((TESTS_FAILED++))
        echo "[FAIL] Backup should appear in manifest"
    fi

    # Symlink should now exist
    assert_symlink "$target" "$source" "Symlink replaces original file"

    # Backup file should exist with correct naming pattern
    ((TESTS_RUN++))
    local backup_pattern="gitconfig.bak.$(date +%Y-%m-%d)"
    if ls "$BACKUP_DIR" | grep -q "$backup_pattern"; then
        ((TESTS_PASSED++))
        echo "[PASS] Backup file has correct naming pattern"
    else
        ((TESTS_FAILED++))
        echo "[FAIL] Backup file should match pattern: ${backup_pattern}"
        echo "  Found: $(ls "$BACKUP_DIR")"
    fi
}

test_replace_existing_symlink_no_backup() {
    echo ""
    echo "=== Test: replace existing symlink without backup ==="

    local source1="${TEST_SOURCE}/git/gitconfig"
    local source2="${TEST_SOURCE}/zsh/zshrc"
    local target="${HOME}/.test-symlink"

    # Create initial symlink
    ln -sf "$source1" "$target"
    assert_symlink "$target" "$source1" "Initial symlink created"

    # Count backups before
    local backup_count_before=0
    [[ -d "$BACKUP_DIR" ]] && backup_count_before=$(ls "$BACKUP_DIR" 2>/dev/null | wc -l | tr -d ' ')

    # Replace with new symlink
    create_dotfile_symlink "$source2" "$target"

    # Count backups after
    local backup_count_after=0
    [[ -d "$BACKUP_DIR" ]] && backup_count_after=$(ls "$BACKUP_DIR" 2>/dev/null | wc -l | tr -d ' ')

    # Should not have created new backup
    assert_eq "$backup_count_before" "$backup_count_after" "No new backup for symlink replacement"

    # Should point to new source
    assert_symlink "$target" "$source2" "Symlink updated to new source"
}

test_dry_run_no_modifications() {
    echo ""
    echo "=== Test: DRY_RUN doesn't modify files ==="

    local source="${TEST_SOURCE}/git/gitconfig"
    local target="${HOME}/.dry-run-test"

    # Enable DRY_RUN
    export DRY_RUN=true

    create_dotfile_symlink "$source" "$target"

    # Should NOT have created symlink
    assert_file_not_exists "$target" "DRY_RUN: symlink not created"

    # Disable DRY_RUN
    unset DRY_RUN
}

test_unlink_and_restore() {
    echo ""
    echo "=== Test: unlink_dotfiles removes symlink and restores backup ==="

    local source="${TEST_SOURCE}/zsh/zshrc"
    local target="${HOME}/.test-unlink"

    # Create original file
    echo "original content for unlink test" > "$target"
    local original_content
    original_content=$(cat "$target")

    # Create symlink (which backs up original)
    create_dotfile_symlink "$source" "$target"
    assert_symlink "$target" "$source" "Symlink created"

    # Unlink
    unlink_dotfiles "$target"

    # After unlink, file should exist as a restored regular file (not symlink)
    ((TESTS_RUN++))
    if [[ -f "$target" && ! -L "$target" ]]; then
        local restored_content
        restored_content=$(cat "$target")
        if [[ "$restored_content" == "$original_content" ]]; then
            ((TESTS_PASSED++))
            echo "[PASS] Original content restored after unlink"
        else
            ((TESTS_FAILED++))
            echo "[FAIL] Content should match original after restore"
        fi
    elif [[ -L "$target" ]]; then
        ((TESTS_FAILED++))
        echo "[FAIL] Should not be a symlink after unlink"
    else
        ((TESTS_FAILED++))
        echo "[FAIL] File should exist after restore"
    fi
}

#######################################
# Run all tests
#######################################
main() {
    echo "========================================"
    echo "Dotfiles Integration Tests"
    echo "========================================"
    echo "Test directory: ${TEST_DIR}"
    echo ""

    # Setup
    setup_test_env

    # Source the module under test
    source "${PROJECT_ROOT}/src/core/dotfiles.sh"

    # Run tests
    test_path_to_backup_name_simple
    test_path_to_backup_name_nested
    test_create_symlink_basic
    test_create_symlink_creates_parent_dir
    test_backup_existing_file
    test_replace_existing_symlink_no_backup
    test_dry_run_no_modifications
    test_unlink_and_restore

    # Summary
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Total:  ${TESTS_RUN}"
    echo "Passed: ${TESTS_PASSED}"
    echo "Failed: ${TESTS_FAILED}"
    echo "========================================"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
