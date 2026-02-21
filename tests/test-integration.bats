#!/usr/bin/env bats
# tests/test-integration.bats -- Integration tests for setup.sh CLI behavior

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    SETUP_SH="${BATS_TEST_DIRNAME}/../setup.sh"
}

@test "setup.sh --help shows usage" {
    run bash "$SETUP_SH" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "--dry-run"
}

@test "setup.sh --dry-run developer completes" {
    run bash "$SETUP_SH" --dry-run developer
    assert_success
    assert_output --partial "DRY RUN"
}

@test "setup.sh --dry-run minimal completes" {
    run bash "$SETUP_SH" --dry-run minimal
    assert_success
    assert_output --partial "DRY RUN"
}

@test "setup.sh --dry-run full completes" {
    run bash "$SETUP_SH" --dry-run full
    assert_success
    assert_output --partial "DRY RUN"
}

@test "setup.sh --dry-run shows detected platform" {
    run bash "$SETUP_SH" --dry-run developer
    assert_output --partial "Detected:"
}

@test "setup.sh unknown flag shows error and exits non-zero" {
    run bash "$SETUP_SH" --invalid-flag
    assert_failure
    assert_output --partial "Unknown option"
    assert_output --partial "--invalid-flag"
}

@test "setup.sh default profile is developer" {
    run bash "$SETUP_SH" --dry-run
    assert_success
    assert_output --partial "developer"
}

@test "setup.sh --dry-run shows completion summary" {
    run bash "$SETUP_SH" --dry-run developer
    assert_output --partial "Complete"
}
