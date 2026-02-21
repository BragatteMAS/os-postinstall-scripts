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

@test "EXIT_SUCCESS constant equals 0" {
    [ "$EXIT_SUCCESS" -eq 0 ]
}

@test "EXIT_PARTIAL_FAILURE constant equals 1" {
    [ "$EXIT_PARTIAL_FAILURE" -eq 1 ]
}

@test "EXIT_CRITICAL constant equals 2" {
    [ "$EXIT_CRITICAL" -eq 2 ]
}

@test "compute_exit_code returns 0 when no failures" {
    clear_failures
    compute_exit_code
    [ $? -eq 0 ]
}

@test "compute_exit_code returns 1 when failures exist" {
    record_failure "test-pkg"
    run compute_exit_code
    [ "$status" -eq 1 ]
}

@test "safe_curl_sh function is exported" {
    declare -F safe_curl_sh
}

@test "safe_curl_sh fails gracefully with no URL" {
    run safe_curl_sh
    assert_failure
}
