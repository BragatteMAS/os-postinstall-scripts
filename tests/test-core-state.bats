#!/usr/bin/env bats
# tests/test-core-state.bats -- Unit tests for src/core/state.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Use temp dirs to avoid polluting real state and data
    export _STATE_FILE="${BATS_TEST_TMPDIR}/state/package-state.txt"
    export DATA_DIR="${BATS_TEST_DIRNAME}/fixtures"
    mkdir -p "${BATS_TEST_TMPDIR}/state"
    # Unset source guards so modules re-source in each test subshell
    unset _LOGGING_SOURCED
    unset _STATE_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/state.sh"
}

# ── save_package_state ────────────────────────────────

@test "save_package_state fails with no arguments" {
    run save_package_state
    assert_failure
}

@test "save_package_state fails with missing package" {
    run save_package_state "brew"
    assert_failure
}

@test "save_package_state creates state file if missing" {
    rm -f "$_STATE_FILE"
    save_package_state "brew" "git" "developer"
    [ -f "$_STATE_FILE" ]
}

@test "save_package_state writes correct format" {
    save_package_state "brew" "git" "developer"
    run grep "^brew|git|" "$_STATE_FILE"
    assert_success
}

@test "save_package_state is idempotent (no duplicates)" {
    save_package_state "brew" "git" "developer"
    save_package_state "brew" "git" "developer"
    local count
    count=$(grep -c "^brew|git|" "$_STATE_FILE")
    [ "$count" -eq 1 ]
}

@test "save_package_state updates existing entry" {
    save_package_state "brew" "git" "minimal"
    save_package_state "brew" "git" "developer"
    run grep "^brew|git|" "$_STATE_FILE"
    assert_output --partial "|developer"
}

@test "save_package_state skips in DRY_RUN" {
    export DRY_RUN=true
    save_package_state "brew" "git" "developer"
    [ ! -f "$_STATE_FILE" ]
}

@test "save_package_state handles multiple managers" {
    save_package_state "brew" "git" "developer"
    save_package_state "apt" "curl" "developer"
    save_package_state "cargo" "bat" "developer"
    local count
    count=$(grep -cv '^#' "$_STATE_FILE" | tr -d ' ')
    [ "$count" -eq 3 ]
}

# ── load_package_state ────────────────────────────────

@test "load_package_state fails with no state file" {
    rm -f "$_STATE_FILE"
    run load_package_state "brew"
    assert_failure
}

@test "load_package_state filters by manager" {
    save_package_state "brew" "git" "dev"
    save_package_state "brew" "curl" "dev"
    save_package_state "apt" "vim" "dev"

    load_package_state "brew"
    [ "${#STATE_PACKAGES[@]}" -eq 2 ]
}

@test "load_package_state returns empty for unknown manager" {
    save_package_state "brew" "git" "dev"

    load_package_state "snap"
    [ "${#STATE_PACKAGES[@]}" -eq 0 ]
}

# ── detect_drift ──────────────────────────────────────

@test "detect_drift returns 0 when no state exists" {
    rm -f "$_STATE_FILE"
    run detect_drift "brew" "brew.txt"
    assert_success
}

@test "detect_drift detects removed packages" {
    # Create a data file with only 2 packages
    local data_file="${BATS_TEST_TMPDIR}/packages/brew.txt"
    mkdir -p "${BATS_TEST_TMPDIR}/packages"
    printf "git\ncurl\n" > "$data_file"

    # State has 3 packages (vim was removed from data file)
    save_package_state "brew" "git" "dev"
    save_package_state "brew" "curl" "dev"
    save_package_state "brew" "vim" "dev"

    run detect_drift "brew" "$data_file"
    assert_failure  # drift detected
    assert_output "vim"
}

@test "detect_drift returns 0 when no drift" {
    local data_file="${BATS_TEST_TMPDIR}/packages/brew.txt"
    mkdir -p "${BATS_TEST_TMPDIR}/packages"
    printf "git\ncurl\n" > "$data_file"

    save_package_state "brew" "git" "dev"
    save_package_state "brew" "curl" "dev"

    run detect_drift "brew" "$data_file"
    assert_success
}

# ── clear_package_state ───────────────────────────────

@test "clear_package_state removes entry" {
    save_package_state "brew" "git" "dev"
    save_package_state "brew" "curl" "dev"

    clear_package_state "brew" "git"

    run grep "^brew|git|" "$_STATE_FILE"
    assert_failure  # should not be found
}

@test "clear_package_state preserves other entries" {
    save_package_state "brew" "git" "dev"
    save_package_state "brew" "curl" "dev"

    clear_package_state "brew" "git"

    run grep "^brew|curl|" "$_STATE_FILE"
    assert_success
}

@test "clear_package_state handles missing state file" {
    rm -f "$_STATE_FILE"
    run clear_package_state "brew" "git"
    assert_success
}

# ── show_drift_report ────────────────────────────────

@test "show_drift_report returns 0 with no state file" {
    rm -f "$_STATE_FILE"
    run show_drift_report
    assert_success
}
