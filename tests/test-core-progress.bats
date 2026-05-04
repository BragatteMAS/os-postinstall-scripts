#!/usr/bin/env bats
# tests/test-core-progress.bats -- Unit tests for src/core/progress.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    unset _LOGGING_SOURCED _ERRORS_SOURCED _PROGRESS_SOURCED

    # Source full dependency chain: logging -> errors -> progress
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/errors.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/progress.sh"

    clear_failures
    SECONDS=90
    FAILURE_LOG="$(mktemp)"
    export FAILURE_LOG
}

teardown() {
    rm -f "$FAILURE_LOG"
}

# ── show_dry_run_banner ───────────────────────────────────────────

@test "show_dry_run_banner outputs banner when DRY_RUN=true" {
    DRY_RUN=true
    run show_dry_run_banner
    assert_success
    assert_output --partial "DRY RUN MODE"
}

@test "show_dry_run_banner outputs nothing when DRY_RUN unset" {
    unset DRY_RUN
    run show_dry_run_banner
    assert_success
    assert_output ""
}

@test "show_dry_run_banner outputs nothing when DRY_RUN=false" {
    DRY_RUN=false
    run show_dry_run_banner
    assert_success
    assert_output ""
}

# ── count_platform_steps ─────────────────────────────────────────

@test "count_platform_steps counts linux-relevant files" {
    local profile="${BATS_TEST_TMPDIR}/test-profile.txt"
    cat > "$profile" <<'EOF'
# Test profile
apt.txt
brew.txt
csv:rust-cli
winget.txt
flatpak-developer.txt
EOF
    run count_platform_steps "$profile" "linux"
    assert_output "3"
}

@test "count_platform_steps counts macos-relevant files" {
    local profile="${BATS_TEST_TMPDIR}/test-profile.txt"
    cat > "$profile" <<'EOF'
apt.txt
brew.txt
csv:rust-cli
winget.txt
flatpak-developer.txt
EOF
    run count_platform_steps "$profile" "macos"
    assert_output "2"
}

@test "count_platform_steps returns 0 for missing file" {
    run count_platform_steps "/nonexistent/path/profile.txt" "linux"
    assert_output "0"
}

@test "count_platform_steps returns 0 for empty profile" {
    local profile="${BATS_TEST_TMPDIR}/empty-profile.txt"
    touch "$profile"
    run count_platform_steps "$profile" "linux"
    assert_output "0"
}

@test "count_platform_steps skips comments" {
    local profile="${BATS_TEST_TMPDIR}/comments-profile.txt"
    cat > "$profile" <<'EOF'
# This is a comment
# Another comment
EOF
    run count_platform_steps "$profile" "linux"
    assert_output "0"
}

# ── show_completion_summary ──────────────────────────────────────

@test "show_completion_summary shows success with no failures" {
    clear_failures
    : > "$FAILURE_LOG"
    run show_completion_summary "developer" "macos"
    assert_output --partial "All sections completed successfully"
}

@test "show_completion_summary shows failure count" {
    echo "failed-pkg" > "$FAILURE_LOG"
    run show_completion_summary "developer" "linux"
    assert_output --partial "1 failure"
}

@test "show_completion_summary shows dry-run label" {
    DRY_RUN=true
    run show_completion_summary "developer" "linux"
    assert_output --partial "Dry Run Complete"
}

@test "show_completion_summary shows profile and platform" {
    run show_completion_summary "minimal" "macos"
    assert_output --partial "minimal"
    assert_output --partial "macos"
}

# ── count_packages_in_profile ────────────────────────────────────

# Helper: build a minimal DATA_DIR layout with 1 profile, 2 package files,
# and a packages.csv for csv:rust-cli resolution.
_setup_pkg_data() {
    DATA_DIR="${BATS_TEST_TMPDIR}/data"
    mkdir -p "$DATA_DIR/packages/profiles"
    cat > "$DATA_DIR/packages/profiles/test-profile.txt" <<'EOF'
apt.txt
brew.txt
csv:rust-cli
EOF
    cat > "$DATA_DIR/packages/apt.txt" <<'EOF'
# Linux essentials
git
curl
build-essential
EOF
    cat > "$DATA_DIR/packages/brew.txt" <<'EOF'
# macOS base
bat
eza
fd
zoxide
ripgrep
EOF
    cat > "$DATA_DIR/packages.csv" <<'EOF'
# Cross-source rust tools
category,name,brew,cargo
rust-cli,bat,bat,bat
rust-cli,eza,eza,eza
rust-cli,fd,fd,fd
rust-dev,cargo-watch,cargo-watch,cargo-watch
EOF
    export DATA_DIR
}

@test "count_packages_in_profile counts macos packages (skips apt) plus csv:rust-cli" {
    _setup_pkg_data
    run count_packages_in_profile "test-profile" "macos"
    # 5 brew packages + 3 rust-cli rows = 8 (apt skipped on macos)
    assert_output "8"
}

@test "count_packages_in_profile counts linux packages (skips brew) plus csv:rust-cli" {
    _setup_pkg_data
    run count_packages_in_profile "test-profile" "linux"
    # 3 apt packages + 3 rust-cli rows = 6 (brew skipped on linux)
    assert_output "6"
}

@test "count_packages_in_profile returns 0 for missing profile" {
    DATA_DIR="${BATS_TEST_TMPDIR}/data"
    mkdir -p "$DATA_DIR/packages/profiles"
    export DATA_DIR
    run count_packages_in_profile "nonexistent" "macos"
    assert_output "0"
}
