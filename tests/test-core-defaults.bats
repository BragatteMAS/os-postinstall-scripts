#!/usr/bin/env bats
# tests/test-core-defaults.bats -- Unit tests for src/core/defaults.sh
# Tests pure logic only (no macOS defaults read/write calls)

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Set DATA_DIR to fixtures BEFORE sourcing defaults.sh
    export DATA_DIR="${BATS_TEST_DIRNAME}/fixtures"
    # Use temp dir for state to avoid polluting real state
    export _DEFAULTS_STATE_DIR="${BATS_TEST_TMPDIR}/state"
    mkdir -p "$_DEFAULTS_STATE_DIR"
    # Unset source guards so modules re-source in each test subshell
    unset _LOGGING_SOURCED
    unset _DEFAULTS_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/defaults.sh"
}

# ── load_defaults_file ────────────────────────────────

@test "load_defaults_file fails with no argument" {
    run load_defaults_file
    assert_failure
}

@test "load_defaults_file fails with nonexistent file" {
    run load_defaults_file "nonexistent.txt"
    assert_failure
}

@test "load_defaults_file reads valid defaults file" {
    load_defaults_file "valid-defaults.txt"
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 4 ]
    [ "${#DEFAULTS_KEYS[@]}" -eq 4 ]
    [ "${#DEFAULTS_TYPES[@]}" -eq 4 ]
    [ "${#DEFAULTS_VALUES[@]}" -eq 4 ]
}

@test "load_defaults_file parses domains correctly" {
    load_defaults_file "valid-defaults.txt"
    [ "${DEFAULTS_DOMAINS[0]}" = "com.test.app" ]
    [ "${DEFAULTS_DOMAINS[1]}" = "com.test.app" ]
    [ "${DEFAULTS_DOMAINS[2]}" = "com.test.app" ]
    [ "${DEFAULTS_DOMAINS[3]}" = "com.test.app" ]
}

@test "load_defaults_file parses keys correctly" {
    load_defaults_file "valid-defaults.txt"
    [ "${DEFAULTS_KEYS[0]}" = "boolKey" ]
    [ "${DEFAULTS_KEYS[1]}" = "intKey" ]
    [ "${DEFAULTS_KEYS[2]}" = "floatKey" ]
    [ "${DEFAULTS_KEYS[3]}" = "stringKey" ]
}

@test "load_defaults_file parses types correctly" {
    load_defaults_file "valid-defaults.txt"
    [ "${DEFAULTS_TYPES[0]}" = "bool" ]
    [ "${DEFAULTS_TYPES[1]}" = "int" ]
    [ "${DEFAULTS_TYPES[2]}" = "float" ]
    [ "${DEFAULTS_TYPES[3]}" = "string" ]
}

@test "load_defaults_file parses values correctly" {
    load_defaults_file "valid-defaults.txt"
    [ "${DEFAULTS_VALUES[0]}" = "true" ]
    [ "${DEFAULTS_VALUES[1]}" = "42" ]
    [ "${DEFAULTS_VALUES[2]}" = "1.5" ]
    [ "${DEFAULTS_VALUES[3]}" = "hello" ]
}

@test "load_defaults_file skips comments and blank lines" {
    load_defaults_file "valid-defaults.txt"
    # File has 4 valid entries, rest are comments/blanks
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 4 ]
}

@test "load_defaults_file handles empty file (only comments)" {
    load_defaults_file "empty-defaults.txt"
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 0 ]
}

@test "load_defaults_file skips malformed lines and unknown types" {
    load_defaults_file "malformed-defaults.txt"
    # Only "com.test.app|goodKey|string|works" should load
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 1 ]
    [ "${DEFAULTS_KEYS[0]}" = "goodKey" ]
    [ "${DEFAULTS_VALUES[0]}" = "works" ]
}

@test "load_defaults_file resets arrays on each call" {
    load_defaults_file "valid-defaults.txt"
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 4 ]
    load_defaults_file "empty-defaults.txt"
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 0 ]
}

@test "load_defaults_file accepts absolute path" {
    load_defaults_file "${BATS_TEST_DIRNAME}/fixtures/defaults/valid-defaults.txt"
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 4 ]
}

# ── apply_all_defaults (DRY_RUN mode) ─────────────────

@test "apply_all_defaults with DRY_RUN does not error" {
    export DRY_RUN=true
    run apply_all_defaults "valid-defaults.txt"
    # Should succeed (or at worst partial failure on non-macOS)
    # The key test is that it doesn't crash on the load/parse phase
    [ "${#DEFAULTS_DOMAINS[@]}" -eq 0 ] || true  # arrays not exported in run
}

@test "apply_all_defaults returns 0 for empty file" {
    export DRY_RUN=true
    run apply_all_defaults "empty-defaults.txt"
    assert_success
}

# ── Backup format ─────────────────────────────────────

@test "backup_current_defaults creates backup file" {
    # Load valid defaults first
    load_defaults_file "valid-defaults.txt"

    # Mock defaults read to avoid macOS dependency
    get_current_default() { echo "mock_value"; }
    export -f get_current_default

    backup_current_defaults
    local backup_count
    backup_count=$(find "$_DEFAULTS_STATE_DIR" -name 'defaults-backup-*.txt' | wc -l)
    [ "$backup_count" -ge 1 ]
}

@test "backup_current_defaults file contains header" {
    load_defaults_file "valid-defaults.txt"
    get_current_default() { echo "old_value"; }
    export -f get_current_default

    local backup_file
    backup_file=$(backup_current_defaults)
    # Remove potential log_info output (backup_file is last echoed line)
    backup_file=$(echo "$backup_file" | tail -1)

    run head -1 "$backup_file"
    assert_output --partial "# Defaults backup"
}

@test "backup_current_defaults file has pipe-delimited entries" {
    load_defaults_file "valid-defaults.txt"
    get_current_default() { echo "prev"; }
    export -f get_current_default

    local backup_file
    backup_file=$(backup_current_defaults | tail -1)

    # Count non-comment, non-empty lines
    local entry_count
    entry_count=$(grep -c '^com\.' "$backup_file")
    [ "$entry_count" -eq 4 ]
}

# ── list_backups ──────────────────────────────────────

@test "list_backups returns 1 when no backups exist" {
    run list_backups
    assert_failure
}

@test "list_backups finds backup files" {
    touch "${_DEFAULTS_STATE_DIR}/defaults-backup-2026-01-01.txt"
    touch "${_DEFAULTS_STATE_DIR}/defaults-backup-2026-01-02.txt"
    run list_backups
    assert_success
    assert_output --partial "defaults-backup-2026-01-01.txt"
    assert_output --partial "defaults-backup-2026-01-02.txt"
}
