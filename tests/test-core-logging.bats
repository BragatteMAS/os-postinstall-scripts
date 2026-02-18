#!/usr/bin/env bats
# tests/test-core-logging.bats -- Unit tests for src/core/logging.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Unset source guard so logging.sh re-sources in each test subshell
    unset _LOGGING_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
}

@test "log_ok outputs [OK] prefix" {
    run log_ok "test message"
    assert_success
    assert_output --partial "[OK]"
    assert_output --partial "test message"
}

@test "log_error outputs [ERROR] prefix" {
    run log_error "bad thing"
    assert_success
    assert_output --partial "[ERROR]"
    assert_output --partial "bad thing"
}

@test "log_warn outputs [WARN] prefix" {
    run log_warn "careful"
    assert_success
    assert_output --partial "[WARN]"
    assert_output --partial "careful"
}

@test "log_info outputs [INFO] prefix" {
    run log_info "something"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "something"
}

@test "log_debug is silent when VERBOSE is not true" {
    unset VERBOSE
    run log_debug "hidden"
    assert_success
    assert_output ""
}

@test "log_debug outputs when VERBOSE=true" {
    export VERBOSE=true
    run log_debug "visible"
    assert_success
    assert_output --partial "[DEBUG]"
    assert_output --partial "visible"
}

@test "log_debug is silent when VERBOSE=false" {
    export VERBOSE=false
    run log_debug "hidden"
    assert_success
    assert_output ""
}

@test "setup_colors respects NO_COLOR" {
    export NO_COLOR=1
    setup_colors
    [ -z "$RED" ]
    [ -z "$GREEN" ]
    [ -z "$NC" ]
}

@test "backward compat aliases work" {
    run log "via alias"
    assert_success
    assert_output --partial "[INFO]"

    run log_success "via success"
    assert_success
    assert_output --partial "[OK]"
}

@test "log_banner includes name and version" {
    run log_banner "MyScript" "1.0"
    assert_success
    assert_output --partial "MyScript"
    assert_output --partial "v1.0"
}
