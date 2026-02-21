#!/usr/bin/env bats
# tests/test-core-interactive.bats -- Unit tests for src/core/interactive.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    unset _INTERACTIVE_SOURCED _LOGGING_SOURCED

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/interactive.sh"
}

# ── show_category_menu ────────────────────────────────────────────

@test "show_category_menu returns 0 with NONINTERACTIVE=true" {
    NONINTERACTIVE=true
    run show_category_menu "DevTools" "dev tools"
    assert_success
}

@test "show_category_menu returns 0 when stdin not TTY" {
    unset NONINTERACTIVE
    run show_category_menu "DevTools"
    assert_success
}

@test "show_category_menu returns 0 with default category name" {
    NONINTERACTIVE=true
    run show_category_menu
    assert_success
}

# ── ask_tool ──────────────────────────────────────────────────────

@test "ask_tool returns 0 with NONINTERACTIVE=true" {
    NONINTERACTIVE=true
    run ask_tool "ripgrep"
    assert_success
}

@test "ask_tool returns 0 when stdin not TTY" {
    unset NONINTERACTIVE
    run ask_tool "ripgrep"
    assert_success
}

@test "ask_tool returns 0 with default tool name" {
    NONINTERACTIVE=true
    run ask_tool
    assert_success
}
