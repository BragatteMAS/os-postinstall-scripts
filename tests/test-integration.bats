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

# ── Trophy: integration tests for the bug regressions ──────────────────────
# These assert against a single cached run of `setup.sh --dry-run -y full`.
# Real script, real dispatch, real output — but executed once across the file
# so the suite stays fast (one dry-run instead of N).

setup_file() {
    export NO_COLOR=1
    BATS_FILE_TMPDIR="${BATS_FILE_TMPDIR:-$(mktemp -d)}"
    export FIXTURE_FULL="${BATS_FILE_TMPDIR}/dryrun-full.log"
    bash "${BATS_TEST_DIRNAME}/../setup.sh" --dry-run -y full \
        >"$FIXTURE_FULL" 2>&1 || true
}

teardown_file() {
    [[ -n "${BATS_FILE_TMPDIR:-}" && -d "$BATS_FILE_TMPDIR" ]] \
        && rm -rf "$BATS_FILE_TMPDIR"
}

@test "[regression fa03a06] full profile loads each brew formula file" {
    # brew.sh used to ignore --developer/--full and load brew.txt three times,
    # silently dropping ~56 dev/full formulae.
    grep -q "Loaded 5 formulae from brew.txt"   "$FIXTURE_FULL"
    grep -q "formulae from brew-developer.txt"  "$FIXTURE_FULL"
    grep -q "formulae from brew-full.txt"       "$FIXTURE_FULL"
}

@test "[regression] full profile loads both cask files" {
    grep -q "casks from brew-cask-developer.txt" "$FIXTURE_FULL"
    grep -q "casks from brew-cask-full.txt"      "$FIXTURE_FULL"
}

@test "[regression] full profile dispatches all five rust CSV categories" {
    for cat in rust-cli rust-dev rust-data rust-tui rust-shell; do
        grep -q "CSV category: $cat" "$FIXTURE_FULL"
    done
}

@test "[regression c44301d] --dry-run after positional still triggers DRY RUN" {
    # parse_flags used to break at the first non-flag, so `setup.sh developer
    # --dry-run` silently ran a real install. Independent of the cached run.
    run bash "${BATS_TEST_DIRNAME}/../setup.sh" -y developer --dry-run
    assert_success
    assert_output --partial "DRY RUN"
}

@test "[regression 515368f+9a54ab6] dev-env failure not duplicated" {
    # retry_with_backoff used to re-run dev-env.sh 3 times and each retry
    # called record_failure "fnm" (3× duplicates). dedup + dropping the retry
    # collapses it to a single entry per failure.
    local count
    count=$(grep -c "Failed: dev-env" "$FIXTURE_FULL" || true)
    [[ "$count" -le 1 ]]
}
