#!/usr/bin/env bats
# tests/test-core-errors.bats -- Unit tests for src/core/errors.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Unset source guards so modules re-source in each test subshell
    unset _LOGGING_SOURCED
    unset _ERRORS_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/errors.sh"
    clear_failures

    # Override sleep to avoid real delays in retry_with_backoff tests
    sleep() { :; }
    export -f sleep

    # Use temp file for cross-process failure tracking
    FAILURE_LOG="$(mktemp)"
    export FAILURE_LOG
}

teardown() {
    rm -f "$FAILURE_LOG"
}

@test "record_failure increments failure count" {
    record_failure "test-pkg"
    [ "$(get_failure_count)" -eq 1 ]
}

@test "multiple record_failure increments correctly" {
    record_failure "pkg-1"
    record_failure "pkg-2"
    record_failure "pkg-3"
    [ "$(get_failure_count)" -eq 3 ]
}

@test "clear_failures resets count to zero" {
    record_failure "pkg-a"
    record_failure "pkg-b"
    clear_failures
    [ "$(get_failure_count)" -eq 0 ]
}

@test "show_failure_summary lists failed items" {
    record_failure "pkg-a"
    record_failure "pkg-b"
    local output
    output="$(show_failure_summary 2>&1)"
    [[ "$output" == *"2 item(s) failed"* ]]
    [[ "$output" == *"pkg-a"* ]]
    [[ "$output" == *"pkg-b"* ]]
}

@test "show_failure_summary shows success when no failures" {
    local output
    output="$(show_failure_summary 2>&1)"
    [[ "$output" == *"All operations completed successfully"* ]]
}

@test "retry_with_backoff succeeds on first try" {
    run retry_with_backoff true
    assert_success
}

@test "retry_with_backoff fails after max attempts" {
    run retry_with_backoff false
    assert_failure
}

@test "create_temp_dir creates a directory" {
    create_temp_dir
    [ -d "$TEMP_DIR" ]
    cleanup_temp_dir
}

@test "cleanup_temp_dir removes directory" {
    create_temp_dir
    local saved_path="$TEMP_DIR"
    cleanup_temp_dir
    [ ! -d "$saved_path" ]
}
