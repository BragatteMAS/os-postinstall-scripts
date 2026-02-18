#!/usr/bin/env bats
# tests/test-core-idempotent.bats -- Unit tests for src/core/idempotent.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Unset source guard so idempotent.sh re-sources in each test subshell
    unset _IDEMPOTENT_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/idempotent.sh"
    TEST_TEMP="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "is_installed returns 0 for bash" {
    run is_installed bash
    assert_success
}

@test "is_installed returns 1 for nonexistent command" {
    run is_installed "definitely_not_a_real_command_xyz"
    assert_failure
}

@test "is_installed returns 1 for empty argument" {
    run is_installed ""
    assert_failure
}

@test "ensure_line_in_file adds line to new file" {
    run ensure_line_in_file "hello world" "${TEST_TEMP}/test.txt"
    assert_success
    [ "$(grep -c 'hello world' "${TEST_TEMP}/test.txt")" -eq 1 ]
}

@test "ensure_line_in_file is idempotent" {
    ensure_line_in_file "hello" "${TEST_TEMP}/test.txt"
    ensure_line_in_file "hello" "${TEST_TEMP}/test.txt"
    [ "$(grep -c 'hello' "${TEST_TEMP}/test.txt")" -eq 1 ]
}

@test "ensure_dir creates directory" {
    run ensure_dir "${TEST_TEMP}/newdir/sub"
    assert_success
    [ -d "${TEST_TEMP}/newdir/sub" ]
}

@test "ensure_symlink creates symlink" {
    local source_file="${TEST_TEMP}/source.txt"
    local target_link="${TEST_TEMP}/target.txt"
    echo "content" > "$source_file"
    run ensure_symlink "$source_file" "$target_link"
    assert_success
    [ -L "$target_link" ]
}

@test "add_to_path adds new path" {
    local saved_path="$PATH"
    add_to_path "/test/new/path"
    [[ ":$PATH:" == *":/test/new/path:"* ]]
    export PATH="$saved_path"
}

@test "add_to_path is idempotent" {
    local saved_path="$PATH"
    add_to_path "/test/idem/path"
    local path_after_first="$PATH"
    add_to_path "/test/idem/path"
    [ "$PATH" = "$path_after_first" ]
    export PATH="$saved_path"
}

@test "backup_if_exists creates backup of existing file" {
    local file="${TEST_TEMP}/myfile.txt"
    echo "original" > "$file"
    run backup_if_exists "$file"
    assert_success
    # Check for .bak.* file
    local bak_count
    bak_count=$(ls "${TEST_TEMP}"/myfile.txt.bak.* 2>/dev/null | wc -l)
    [ "$bak_count" -ge 1 ]
}

@test "backup_if_exists returns 0 for nonexistent file" {
    run backup_if_exists "${TEST_TEMP}/nope.txt"
    assert_success
}
