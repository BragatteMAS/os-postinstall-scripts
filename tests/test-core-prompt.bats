#!/usr/bin/env bats
# tests/test-core-prompt.bats -- Contract tests for src/core/prompt.sh
#
# prompt_default() is the single source of truth for default-bearing prompts.
# These tests pin the contract that kept regressing across v5.4.0/v5.4.4/v5.4.6:
#   - the resolved default is correct (empty / explicit / unattended / timeout)
#   - ONLY the resolved value reaches stdout (logging.sh writes to stdout, so a
#     naive notice would pollute value=$(prompt_default ...))
#
# Note: read -p renders its prompt only on a real TTY (bash design), so the
# hint string itself is not unit-testable via a pipe — we assert behaviour.

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    export REPO_ROOT
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    export LOGGING_SH="${REPO_ROOT}/src/core/logging.sh"
    export PROMPT_SH="${REPO_ROOT}/src/core/prompt.sh"
}

@test "prompt_default: empty input resolves to the default" {
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        printf "" | prompt_default "Select" "1" "1-4" 2>/dev/null
    '
    assert_success
    assert_output "1"
}

@test "prompt_default: explicit input is echoed verbatim" {
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        printf "3\n" | prompt_default "Select" "1" "1-4" 2>/dev/null
    '
    assert_success
    assert_output "3"
}

@test "prompt_default: works with no keys label (binary-style default)" {
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        printf "\n" | prompt_default "Proceed?" "Y" 2>/dev/null
    '
    assert_success
    assert_output "Y"
}

@test "prompt_default: NONINTERACTIVE returns the default and ignores stdin" {
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        export NONINTERACTIVE=true
        printf "3\n" | prompt_default "Select" "1" "1-4" 2>/dev/null
    '
    assert_success
    assert_output "1"
}

@test "prompt_default: unattended stdout is EXACTLY the default (no log leak)" {
    # The crux: logging.sh writes to stdout. If the auto-select notice leaked,
    # out would be "[INFO] Auto-selected: 1\n1" instead of "1".
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        export NONINTERACTIVE=true
        out=$(prompt_default "Select" "1" "1-4" 2>/dev/null)
        [ "$out" = "1" ] || { echo "LEAK:[$out]"; exit 1; }
    '
    assert_success
}

@test "prompt_default: unattended auto-select notice goes to stderr" {
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        export NONINTERACTIVE=true
        prompt_default "Select" "2" "1-4" 2>&1 >/dev/null
    '
    assert_output --partial "Auto-selected: 2"
}

@test "prompt_default: timeout resolves to the default" {
    # sleep holds the pipe open with no data, so read -t 1 hits the timeout
    # branch (not EOF) and falls back to the default.
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        sleep 2 | prompt_default "Pick" "D" "1-9" 1 2>/dev/null
    '
    assert_success
    assert_output "D"
}

@test "prompt_default: always returns 0 so callers branch on the value" {
    run bash -c '
        source "$LOGGING_SH"; source "$PROMPT_SH"
        printf "nonsense\n" | prompt_default "Select" "1" "1-4" 2>/dev/null
    '
    assert_success
}
