#!/usr/bin/env bats
# tests/test-regressions.bats -- Unit regressions for fixes 02a73b2..fa03a06.
# Each test names the commit it guards. They isolate one function per test
# (no real installs, no network) so failures point straight at the cause.

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
}

# ── parse_flags (commit c44301d) ──────────────────────────────────

# Helper: extracts parse_flags() from setup.sh and runs it with the given args.
# Echoes a single line: DRY_RUN=<v> VERBOSE=<v> UNATTENDED=<v> REMAINING=<...>
_run_parse_flags() {
    bash -c '
        eval "$(awk "/^parse_flags\\(\\) \\{/,/^\\}\$/" "$1")"
        unset DRY_RUN VERBOSE UNATTENDED NONINTERACTIVE
        REMAINING_ARGS=()
        shift
        parse_flags "$@"
        echo "DRY_RUN=${DRY_RUN:-unset} VERBOSE=${VERBOSE:-unset} UNATTENDED=${UNATTENDED:-unset} REMAINING=[${REMAINING_ARGS[*]}]"
    ' _ "${REPO_ROOT}/setup.sh" "$@"
}

@test "[c44301d] parse_flags: --dry-run before positional sets DRY_RUN" {
    run _run_parse_flags --dry-run developer
    assert_success
    assert_output --partial "DRY_RUN=true"
    assert_output --partial "REMAINING=[developer]"
}

@test "[c44301d] parse_flags: --dry-run AFTER positional still sets DRY_RUN" {
    # The original bug: parse_flags broke at the first non-flag, so this
    # combination silently ran a real install.
    run _run_parse_flags developer --dry-run
    assert_success
    assert_output --partial "DRY_RUN=true"
    assert_output --partial "REMAINING=[developer]"
}

@test "[c44301d] parse_flags: interleaved flags and positionals" {
    run _run_parse_flags developer --verbose dotfiles
    assert_success
    assert_output --partial "VERBOSE=true"
    assert_output --partial "REMAINING=[developer dotfiles]"
}

@test "[c44301d] parse_flags: -- terminates option processing" {
    run _run_parse_flags --verbose -- --weird-arg
    assert_success
    assert_output --partial "VERBOSE=true"
    assert_output --partial "REMAINING=[--weird-arg]"
}

# ── wizard stdout/stderr split (commit 02a73b2) ───────────────────

@test "[02a73b2] wizard menu goes to stderr; only profile name to stdout" {
    # The bug: select_profile_interactive printed the menu via echo (stdout),
    # but callers used profile=$(select_profile_interactive ...) — command
    # substitution swallowed the menu. User saw only the read prompt.
    run bash -c '
        unset _LOGGING_SOURCED _PROGRESS_SOURCED _WIZARD_SOURCED
        source "'"$REPO_ROOT"'/src/core/logging.sh"
        source "'"$REPO_ROOT"'/src/core/progress.sh" 2>/dev/null
        source "'"$REPO_ROOT"'/src/core/wizard.sh"
        # Pipe "1\ny" so it picks minimal and confirms.
        # stderr → file (the menu must be there); stdout → captured (only
        # the profile name must be there).
        captured=$(printf "1\ny\n" | select_profile_interactive macos 2>/tmp/_wiz_err)
        echo "STDOUT=[$captured]"
        echo "---STDERR---"
        cat /tmp/_wiz_err
        rm -f /tmp/_wiz_err
    '
    assert_success
    # stdout is exactly the chosen profile, no menu noise
    assert_output --partial "STDOUT=[minimal]"
    # stderr (after marker) carries the menu options
    assert_output --partial "Choose installation profile:"
    assert_output --partial "1) minimal"
    assert_output --partial "2) developer"
    assert_output --partial "3) full"
    assert_output --partial "c) cancel"
}

# ── brew-cask failure classification (commit 8466ff3) ─────────────

# Mocks `brew install --cask` to emit a fixture stderr, then asserts that
# _brew_cask_install translates it into a human-readable reason.
_run_cask_install_with_brew_stderr() {
    local cask="$1" stderr_fixture="$2" rc="${3:-1}"
    bash -c '
        unset _LOGGING_SOURCED _ERRORS_SOURCED _IDEMPOTENT_SOURCED _STATE_SOURCED _PACKAGES_SOURCED
        source "'"$REPO_ROOT"'/src/core/logging.sh"
        source "'"$REPO_ROOT"'/src/core/errors.sh"
        source "'"$REPO_ROOT"'/src/core/idempotent.sh" 2>/dev/null

        # Stub state.sh + packages.sh so brew-cask.sh sources cleanly.
        save_package_state() { :; }
        load_packages() { PACKAGES=(); }
        export -f save_package_state load_packages

        # Stub brew so it never hits the real binary.
        STDERR_FIXTURE="$2"
        BREW_RC="$3"
        brew() {
            if [[ "$1" == "list" ]]; then
                return 1   # "not installed" so install path runs
            fi
            # `brew install --cask <name>`
            echo "$STDERR_FIXTURE" >&2
            return "$BREW_RC"
        }
        export -f brew

        # Skip the "verify Homebrew is available" gate at top of brew-cask.sh
        # by sourcing its function block only.
        eval "$(awk "/^_is_cask_installed\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/macos/install/brew-cask.sh")"
        eval "$(awk "/^_brew_cask_install\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/macos/install/brew-cask.sh")"

        unset DRY_RUN
        BREW_LOG=/dev/null _brew_cask_install "$1" 2>&1
    ' _ "$cask" "$stderr_fixture" "$rc"
}

@test "[8466ff3] cask classify: 'app already exists' → manual-install reason" {
    run _run_cask_install_with_brew_stderr "rectangle" \
        "Error: It seems there is already an App at '/Applications/Rectangle.app'."
    assert_failure
    assert_output --partial "Failed to install: rectangle (app exists at /Applications"
}

@test "[8466ff3] cask classify: unavailable cask → 'cask name not found'" {
    run _run_cask_install_with_brew_stderr "made-up-cask" \
        "Error: Cask 'made-up-cask' is unavailable: No Cask with this name exists."
    assert_failure
    assert_output --partial "cask name not found"
}

@test "[8466ff3] cask classify: connection error → 'network error'" {
    run _run_cask_install_with_brew_stderr "firefox" \
        "curl: (6) Could not resolve host: github.com"
    assert_failure
    assert_output --partial "network error"
}

# ── interactive defaults (Deney's "menu logic inverted" report) ─────

@test "[v5.4.0] show_category_menu default on timeout is 1 (All), not 3 (Skip)" {
    # Previously defaulted to 3 (Skip) — silently un-installed dev-env
    # categories for users who didn't react to the prompt within 30s.
    # New default 1 (All) matches the profile the user picked.
    grep -qE '"Select \[1-3\]"[[:space:]]+"1"' "$REPO_ROOT/src/core/interactive.sh"
    ! grep -qE '"Select \[1-3\]"[[:space:]]+"3"' "$REPO_ROOT/src/core/interactive.sh"
}

@test "[v5.4.2] cask classify: 'conflicts with cask X' → conflict reason + fix hint" {
    run _run_cask_install_with_brew_stderr "github" \
        "Error: Cask github conflicts with cask github@beta. Remove the conflicting cask first."
    assert_failure
    assert_output --partial "conflicts with another cask (github@beta)"
    assert_output --partial "Fix: brew uninstall --cask github@beta && brew install --cask github"
}

@test "[v5.4.2] cask classify: 'app exists' includes --force hint" {
    run _run_cask_install_with_brew_stderr "claude" \
        "Error: It seems there is already an App at '/Applications/Claude.app'."
    assert_failure
    assert_output --partial "Fix: brew install --cask --force claude"
}

@test "[v5.4.1] terminal-setup diverts to .zshrc.local when target is symlink" {
    # Reported by Deney's M5: dotfiles-install.sh symlinks ~/.zshrc to
    # <repo>/data/dotfiles/zsh/zshrc. terminal-setup then `cat >> ~/.zshrc`
    # was writing INTO the repo file, polluting `git status`.
    # Fix: detect symlink, divert to ~/.zshrc.local (already sourced by repo rc).
    local tmp; tmp=$(mktemp -d)
    ln -s "/fake/repo/zshrc" "$tmp/.zshrc"

    run bash -c '
        SHELL_RC="'"$tmp/.zshrc"'"
        SHELL_NAME=zsh
        HOME="'"$tmp"'"
        DRY_RUN=true
        log_info() { :; }; log_warn() { :; }; log_ok() { :; }; run() { :; }
        update_shell_files() { :; }
        eval "$(awk "/^setup_shell\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/terminal/setup.sh")"
        setup_shell >/dev/null 2>&1
        echo "$SHELL_RC"
    '
    [[ "$output" == "$tmp/.zshrc.local" ]]
    rm -rf "$tmp"
}

@test "[v5.4.0] ask_tool default 'y' matches [Y/n] prompt convention" {
    # Previously prompt said [Y/n] (capital Y = default) but the actual
    # timeout default was "n". UX bug — Enter or timeout now installs.
    grep -qE '"Install \$\{tool\}\? \[Y/n\]"[[:space:]]+"y"' "$REPO_ROOT/src/core/interactive.sh"
    ! grep -qE '"Install \$\{tool\}\? \[Y/n\]"[[:space:]]+"n"' "$REPO_ROOT/src/core/interactive.sh"
}

@test "[8466ff3] cask install writes header + stderr to BREW_LOG" {
    # Validates the diagnostic path E2E: BREW_LOG must be appended with a
    # "=== brew install --cask <name> (rc=N) ===" header followed by the
    # actual brew stderr. Without this, observability silently does nothing.
    local brew_log
    brew_log="$(mktemp)"
    bash -c '
        unset _LOGGING_SOURCED _ERRORS_SOURCED _IDEMPOTENT_SOURCED
        source "'"$REPO_ROOT"'/src/core/logging.sh"
        source "'"$REPO_ROOT"'/src/core/errors.sh"
        source "'"$REPO_ROOT"'/src/core/idempotent.sh" 2>/dev/null
        save_package_state() { :; }
        load_packages() { PACKAGES=(); }
        export -f save_package_state load_packages

        brew() {
            if [[ "$1" == "list" ]]; then return 1; fi
            echo "Error: It seems there is already an App at /Applications/X.app." >&2
            return 1
        }
        export -f brew

        eval "$(awk "/^_is_cask_installed\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/macos/install/brew-cask.sh")"
        eval "$(awk "/^_brew_cask_install\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/macos/install/brew-cask.sh")"

        unset DRY_RUN
        # _brew_cask_install returns 1 by design (install failed). Swallow
        # the exit so bash -c does not fail the bats test — we only care
        # whether the diagnostic write happened.
        BREW_LOG="'"$brew_log"'" _brew_cask_install rectangle >/dev/null 2>&1 || true
        exit 0
    '

    # Header line with command + return code
    grep -qE "^=== brew install --cask rectangle \(rc=1\) ===$" "$brew_log"
    # Original stderr captured verbatim
    grep -q "It seems there is already an App at /Applications/X.app" "$brew_log"

    rm -f "$brew_log"
}
