#!/usr/bin/env bats
# tests/test-core-wizard.bats -- Unit tests for src/core/wizard.sh
# select_profile_interactive() is the single, OS-independent profile menu used
# by setup.sh AND (since the menu unification) by the platform main.sh scripts.

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

bats_require_minimum_version 1.5.0

setup() {
    export NO_COLOR=1
    unset _WIZARD_SOURCED _PROMPT_SOURCED _LOGGING_SOURCED _PROGRESS_SOURCED

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/progress.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/prompt.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/wizard.sh"
}

# Menu text goes to stderr; only the chosen profile name goes to stdout.

@test "select_profile_interactive maps choice 1 to minimal" {
    run --separate-stderr select_profile_interactive "linux" <<< $'1\nY'
    assert_success
    assert_equal "$output" "minimal"
}

@test "select_profile_interactive maps choice 2 to developer" {
    run --separate-stderr select_profile_interactive "linux" <<< $'2\nY'
    assert_success
    assert_equal "$output" "developer"
}

@test "select_profile_interactive maps choice 3 to full" {
    run --separate-stderr select_profile_interactive "macos" <<< $'3\nY'
    assert_success
    assert_equal "$output" "full"
}

@test "select_profile_interactive defaults empty choice to developer" {
    run --separate-stderr select_profile_interactive "linux" <<< $'\nY'
    assert_success
    assert_equal "$output" "developer"
}

@test "select_profile_interactive returns non-zero on cancel" {
    run select_profile_interactive "linux" <<< "c"
    assert_failure
}

@test "select_profile_interactive renders the three profiles in the menu" {
    run select_profile_interactive "linux" <<< $'2\nY'
    assert_output --partial "minimal"
    assert_output --partial "developer"
    assert_output --partial "full"
}

# ── PP8: help callout in the menu ─────────────────────────────────

@test "menu shows the help/dry-run tip and the preview option" {
    run select_profile_interactive "linux" <<< $'2\nY'
    assert_output --partial "preview"
    assert_output --partial "--dry-run"
    assert_output --partial "help"
}

@test "invalid choice message cites help and the preview key" {
    # 'z' is invalid -> warns and re-prompts; then '2' + confirm selects.
    run select_profile_interactive "linux" <<< $'z\n2\nY'
    assert_output --partial "Invalid choice"
    assert_output --partial "--help"
}

# ── PP9: preview a profile's package list (no changes) ────────────

@test "preview (p) lists a profile then loops back to selection" {
    # p -> preview which? 1 (minimal) -> back to menu -> 2 (developer) -> confirm
    run --separate-stderr select_profile_interactive "linux" <<< $'p\n1\n2\nY'
    assert_success
    assert_equal "$output" "developer"          # stdout = final pick, not the preview
}

@test "preview output announces it makes no changes" {
    run select_profile_interactive "linux" <<< $'p\n3\n2\nY'
    assert_output --partial "Preview: full"
    assert_output --partial "nothing was installed"
}

@test "preview_profile_packages is read-only and self-contained" {
    run preview_profile_packages "minimal" "linux"
    assert_success
    assert_output --partial "Preview: minimal"
    assert_output --partial "nothing was installed"
}

# ── v5.6.1: preview platform filter + explicit success footer ──────
# Finding #1 (2026-07-13, first run on a real fresh machine): a macos
# preview listed apt/winget/snap/flatpak groups. Finding #2: the owner
# could not tell whether the preview had worked.

@test "[v5.6.1] preview on macos hides other-OS package groups" {
    export DATA_DIR="${BATS_TEST_DIRNAME}/../data"
    run preview_profile_packages "full" "macos"
    assert_success
    assert_output --partial "brew-developer.txt"
    assert_output --partial "CSV category: rust-cli"
    refute_output --partial "apt.txt"
    refute_output --partial "winget"
    refute_output --partial "snap-developer"
    refute_output --partial "flatpak-developer"
    assert_output --partial "entries for other platforms not shown"
}

@test "[v5.6.1] preview on linux hides brew/winget groups" {
    export DATA_DIR="${BATS_TEST_DIRNAME}/../data"
    run preview_profile_packages "full" "linux"
    assert_success
    assert_output --partial "apt.txt"
    refute_output --partial "brew.txt"
    refute_output --partial "winget"
    refute_output --partial "macos-defaults"
}

@test "[v5.6.1] preview ends with an explicit success footer" {
    export DATA_DIR="${BATS_TEST_DIRNAME}/../data"
    run preview_profile_packages "developer" "macos"
    assert_success
    assert_output --partial "✓ Preview of 'developer' done — nothing was installed."
}
