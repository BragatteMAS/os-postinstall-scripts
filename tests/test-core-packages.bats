#!/usr/bin/env bats
# tests/test-core-packages.bats -- Unit tests for src/core/packages.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Set DATA_DIR to fixtures BEFORE sourcing packages.sh
    export DATA_DIR="${BATS_TEST_DIRNAME}/fixtures"
    # Unset source guards so modules re-source in each test subshell
    unset _LOGGING_SOURCED
    unset _PACKAGES_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/packages.sh"
}

@test "load_packages fails with no argument" {
    run load_packages
    assert_failure
}

@test "load_packages fails with nonexistent file" {
    run load_packages "nonexistent.txt"
    assert_failure
}

@test "load_packages reads packages from fixture file" {
    load_packages "test-apt.txt"
    [ "${#PACKAGES[@]}" -eq 4 ]
}

@test "load_packages skips comments and blank lines" {
    load_packages "with-comments.txt"
    [ "${#PACKAGES[@]}" -eq 3 ]
    # Verify no entry starts with #
    for pkg in "${PACKAGES[@]}"; do
        [[ "$pkg" != \#* ]]
    done
}

@test "get_packages_for_manager fails with no argument" {
    run get_packages_for_manager
    assert_failure
}

@test "get_packages_for_manager fails for unknown manager" {
    run get_packages_for_manager "nonexistent"
    assert_failure
}

@test "PACKAGES array is reset on each load_packages call" {
    load_packages "test-apt.txt"
    [ "${#PACKAGES[@]}" -eq 4 ]
    load_packages "with-comments.txt"
    [ "${#PACKAGES[@]}" -eq 3 ]
}
