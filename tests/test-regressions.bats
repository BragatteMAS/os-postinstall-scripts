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
    # v5.6.0: call migrated to prompt_default "Select" <default> "1-3" 30 —
    # the default is now the 2nd positional arg (rendered into the hint).
    grep -qE 'prompt_default "Select" "1" "1-3"' "$REPO_ROOT/src/core/interactive.sh"
    ! grep -qE 'prompt_default "Select" "3" "1-3"' "$REPO_ROOT/src/core/interactive.sh"
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

@test "[v5.4.3] select_preset falls back to project config when preset missing" {
    # Reported by Deney: a missing preset file silently skipped the whole
    # starship install ("pasta nao existente skippa o install"). Now we
    # warn + fall back to project_config instead of return 1.
    local tmp; tmp=$(mktemp -d)
    local fake_repo="$tmp/repo"
    mkdir -p "$fake_repo/terminal/presets" "$fake_repo/data/dotfiles/starship"
    # project_config exists; minimal.toml does NOT (the preset user picks)
    echo "format = '[project]'" > "$fake_repo/data/dotfiles/starship/starship.toml"

    run bash -c '
        SCRIPT_DIR="'"$fake_repo/terminal"'"
        HOME="'"$tmp"'"
        DRY_RUN=true
        INTERACTIVE=true
        log_info()  { echo "[INFO] $*"; }
        log_warn()  { echo "[WARN] $*"; }
        log_ok()    { echo "[OK] $*"; }
        log_error() { echo "[ERROR] $*"; }
        log_dry()   { echo "[DRY] $*"; }
        eval "$(awk "/^select_preset\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/terminal/setup.sh")"
        # User picks preset 2 (minimal) — file does not exist in fake_repo
        echo "2" | select_preset
    '

    assert_success
    assert_output --partial "Preset file not found"
    assert_output --partial "Falling back to project starship config"
    rm -rf "$tmp"
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
    # v5.6.0: call migrated to prompt_default "Install ${tool}?" <default> "Y/n" 30 —
    # the default is now the 2nd positional arg (rendered into the hint).
    grep -qE 'prompt_default "Install \$\{tool\}\?" "y" "Y/n"' "$REPO_ROOT/src/core/interactive.sh"
    ! grep -qE 'prompt_default "Install \$\{tool\}\?" "n" "Y/n"' "$REPO_ROOT/src/core/interactive.sh"
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

# ── snap classifier (v5.4.5) ─────────────────────────────────────────
#
# Mirrors v5.4.2 cask classifier pattern. snap_install() now does single
# attempt + classifier instead of retry_with_backoff. Helper stubs `sudo`
# (which is what snap_install invokes) to emit a fixture stderr.

_run_snap_install_with_stderr() {
    local pkg="$1" stderr_fixture="$2" rc="${3:-1}"
    bash -c '
        unset _LOGGING_SOURCED _ERRORS_SOURCED _IDEMPOTENT_SOURCED _STATE_SOURCED _PACKAGES_SOURCED
        source "'"$REPO_ROOT"'/src/core/logging.sh"
        source "'"$REPO_ROOT"'/src/core/errors.sh"
        source "'"$REPO_ROOT"'/src/core/idempotent.sh" 2>/dev/null
        save_package_state() { :; }
        load_packages() { PACKAGES=(); }
        export -f save_package_state load_packages

        STDERR_FIXTURE="$2"
        SNAP_RC="$3"
        snap() { return 1; }
        sudo() {
            >&2 echo "$STDERR_FIXTURE"
            return "$SNAP_RC"
        }
        export -f snap sudo

        eval "$(awk "/^is_snap_installed\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/linux/install/snap.sh")"
        eval "$(awk "/^snap_install\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/linux/install/snap.sh")"

        unset DRY_RUN
        snap_install "$1"
    ' _ "$pkg" "$stderr_fixture" "$rc"
}

@test "[v5.4.5] snap classify: 'no snap found' → not-found reason + hint" {
    run _run_snap_install_with_stderr "missing-pkg" \
        'error: no snap found for "missing-pkg"'
    assert_failure
    assert_output --partial "snap not found in store"
    assert_output --partial "Fix: snap find missing-pkg"
}

@test "[v5.4.5] snap classify: 'requires --classic' → classic flag hint" {
    run _run_snap_install_with_stderr "code" \
        'error: This revision of snap "code" was published using classic confinement and thus requires --classic'
    assert_failure
    assert_output --partial "package requires --classic confinement"
    assert_output --partial "prefix entry with 'classic:'"
}

# ── flatpak classifier (v5.4.5) ──────────────────────────────────────

_run_flatpak_install_with_stderr() {
    local app_id="$1" stderr_fixture="$2" rc="${3:-1}"
    bash -c '
        unset _LOGGING_SOURCED _ERRORS_SOURCED _IDEMPOTENT_SOURCED _STATE_SOURCED _PACKAGES_SOURCED
        source "'"$REPO_ROOT"'/src/core/logging.sh"
        source "'"$REPO_ROOT"'/src/core/errors.sh"
        source "'"$REPO_ROOT"'/src/core/idempotent.sh" 2>/dev/null
        save_package_state() { :; }
        load_packages() { PACKAGES=(); }
        export -f save_package_state load_packages

        STDERR_FIXTURE="$2"
        FLATPAK_RC="$3"
        flatpak() {
            if [[ "$1" == "list" ]]; then return 1; fi
            >&2 echo "$STDERR_FIXTURE"
            return "$FLATPAK_RC"
        }
        export -f flatpak

        eval "$(awk "/^is_flatpak_installed\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/linux/install/flatpak.sh")"
        eval "$(awk "/^flatpak_install\\(\\) \\{/,/^\\}\$/" "'"$REPO_ROOT"'/src/platforms/linux/install/flatpak.sh")"

        unset DRY_RUN
        flatpak_install "$1"
    ' _ "$app_id" "$stderr_fixture" "$rc"
}

@test "[v5.4.5] flatpak classify: 'Nothing matches' → not-found reason + hint" {
    run _run_flatpak_install_with_stderr "org.fake.app" \
        'error: Nothing matches org.fake.app in remote flathub'
    assert_failure
    assert_output --partial "app_id not found in flathub"
    assert_output --partial "Fix: flatpak search org.fake.app"
}

# ── linux main.sh: snap/flatpak waves no longer wrapped (v5.4.5) ─────

@test "[v5.4.5] linux main.sh: snap/flatpak dispatchers are not wrapped in retry_with_backoff" {
    # Mirror of macos/main.sh:215 NOTE — snap and flatpak dispatchers must
    # not be wrapped in retry_with_backoff. Wrapping deterministic errors
    # (package missing, classic flag missing) in retry wasted ~50s per
    # failure before per-package classifier was added in v5.4.5.
    run grep -nE 'retry_with_backoff bash .*(snap|flatpak)\.sh' \
        "$REPO_ROOT/src/platforms/linux/main.sh"
    assert_failure
}

# ── default surfacing convention (v5.4.6) ────────────────────────────
#
# v5.4.0 fixed show_category_menu, v5.4.4 fixed detect_previous_install.
# Same class: prompt offered numeric choices but did not surface the
# default, so Enter = surprise side effect. v5.4.6 closes the remaining
# two prompts that had the same shape (ai-tools ollama, group-selector
# bash fallback). Tests are grep-based — fingerprint that the convention
# is in the source. Behavior tests would require interactive stdin
# replay, which is overkill for a one-line prompt change.

@test "[v5.4.6] ai-tools: ollama prompt surfaces default=2 (Skip)" {
    # v5.6.0: migrated to prompt_default "Select" "2" "1-2" — the surfaced
    # default is now the 2nd positional arg (rendered into the hint).
    grep -qE 'prompt_default "Select" "2" "1-2"' \
        "$REPO_ROOT/src/install/ai-tools.sh"
}

@test "[v5.4.6] ai-tools: ollama skip path emits log_info, not log_debug" {
    # Convention from v5.4.0: skip should be visible. log_debug hid the
    # non-action behind a debug flag.
    grep -qE 'log_info "Skipped model download' \
        "$REPO_ROOT/src/install/ai-tools.sh"
    ! grep -qE 'log_debug "Skipping model download' \
        "$REPO_ROOT/src/install/ai-tools.sh"
}

@test "[v5.4.6] group-selector: bash-fallback prompt surfaces default=none" {
    grep -qE "default=none" \
        "$REPO_ROOT/src/core/group-selector.sh"
}

# ── linux main.sh: last orchestrator without wave-level retry (v5.4.7) ──

@test "[v5.4.7] linux main.sh: ai-tools dispatcher is not wrapped in retry_with_backoff" {
    # ai-tools.sh is an orchestrator (multiple sub-installers); wave-level
    # retry multiplied failures (each retry re-recorded the same failed
    # sub-installer). Same rationale as dev-env.sh:138 which never had
    # retry, and v5.4.5 dropped it for snap/flatpak. v5.4.7 closes the
    # last orchestrator still under wave-level retry.
    run grep -nE 'retry_with_backoff bash .*ai-tools\.sh' \
        "$REPO_ROOT/src/platforms/linux/main.sh"
    assert_failure
}

# ── macos dispatcher: winget-*.txt symmetry (v5.4.8) ─────────────────

@test "[v5.4.8] macos main.sh: all winget-*.txt files silenced as Windows-only" {
    # Discovered by v5.4.7 dry-run audit on full profile: macos/main.sh
    # only listed winget.txt as Windows-only; winget-developer.txt and
    # winget-full.txt fell through to the *) catch-all and printed
    # "WARN Unknown package file". Asymmetric with Linux which handles
    # all brew-cask-* variants. Now all three winget files are matched.
    grep -qE 'winget\.txt\|winget-developer\.txt\|winget-full\.txt' \
        "$REPO_ROOT/src/platforms/macos/main.sh"
}

# ── skip granular: section state helpers (v5.5.0) ────────────────────
#
# Deney's wishlist: "se ja fez partes anteriores tem que ter algo para
# pular mais facil." Section state lets dotfiles + terminal-blueprint
# get marked done after success, then skipped on subsequent runs.

_run_section_helpers_in_tmp_home() {
    local cmd="$1"
    local tmp; tmp=$(mktemp -d)
    bash -c '
        unset _LOGGING_SOURCED _PROGRESS_SOURCED
        export HOME="'"$tmp"'"
        export DRY_RUN=""
        source "'"$REPO_ROOT"'/src/core/logging.sh"
        source "'"$REPO_ROOT"'/src/core/progress.sh"
        '"$cmd"'
    '
    rm -rf "$tmp"
}

@test "[v5.5.0] mark_section_done writes section to state file" {
    run _run_section_helpers_in_tmp_home '
        mark_section_done "dotfiles"
        cat "$HOME/.config/os-postinstall/state"
    '
    assert_success
    assert_output --partial "sections_done=dotfiles"
}

@test "[v5.5.0] mark_section_done is idempotent (no duplicate entries)" {
    run _run_section_helpers_in_tmp_home '
        mark_section_done "dotfiles"
        mark_section_done "dotfiles"
        mark_section_done "dotfiles"
        grep "^sections_done=" "$HOME/.config/os-postinstall/state"
    '
    assert_success
    [[ "$output" == "sections_done=dotfiles" ]]
}

@test "[v5.5.0] mark_section_done appends multiple distinct sections" {
    run _run_section_helpers_in_tmp_home '
        mark_section_done "dotfiles"
        mark_section_done "terminal_blueprint"
        grep "^sections_done=" "$HOME/.config/os-postinstall/state"
    '
    assert_success
    assert_output --partial "dotfiles"
    assert_output --partial "terminal_blueprint"
}

@test "[v5.5.0] is_section_done returns 0 for marked, 1 for unmarked" {
    run _run_section_helpers_in_tmp_home '
        mark_section_done "dotfiles"
        if is_section_done "dotfiles"; then echo "DOTFILES_DONE"; fi
        if is_section_done "missing_section"; then echo "WRONG"; else echo "MISSING_NOT_DONE"; fi
    '
    assert_success
    assert_output --partial "DOTFILES_DONE"
    assert_output --partial "MISSING_NOT_DONE"
    refute_output --partial "WRONG"
}

@test "[v5.5.0] clear_sections_done removes line but preserves metadata" {
    run _run_section_helpers_in_tmp_home '
        DETECTED_OS=macos save_install_state "developer"
        mark_section_done "dotfiles"
        clear_sections_done
        cat "$HOME/.config/os-postinstall/state"
    '
    assert_success
    assert_output --partial "profile=developer"
    assert_output --partial "platform=macos"
    refute_output --partial "sections_done="
}

@test "[v5.5.0] save_install_state preserves existing sections_done" {
    # Regression: original save_install_state clobbered the whole file,
    # so a second save (e.g., final state save at end of setup.sh) would
    # nuke any sections_done lines mark_section_done had written.
    run _run_section_helpers_in_tmp_home '
        DETECTED_OS=macos save_install_state "developer"
        mark_section_done "dotfiles"
        DETECTED_OS=macos save_install_state "developer"
        cat "$HOME/.config/os-postinstall/state"
    '
    assert_success
    assert_output --partial "sections_done=dotfiles"
}

@test "[v5.5.0] detect_previous_install offers 4 options (Continue is new)" {
    grep -qE '1\) Continue \(skip sections marked done' \
        "$REPO_ROOT/src/core/progress.sh"
    grep -qE '2\) Reinstall everything' \
        "$REPO_ROOT/src/core/progress.sh"
    # v5.6.0: migrated to prompt_default "Select" "1" "1-4" — the surfaced
    # default is now the 2nd positional arg (rendered into the hint).
    grep -qE 'prompt_default "Select" "1" "1-4"' \
        "$REPO_ROOT/src/core/progress.sh"
}

@test "[v5.5.0] setup.sh gates dotfiles + terminal_blueprint on is_section_done" {
    grep -qE 'is_section_done "dotfiles"' "$REPO_ROOT/setup.sh"
    grep -qE 'is_section_done "terminal_blueprint"' "$REPO_ROOT/setup.sh"
    grep -qE 'mark_section_done "dotfiles"' "$REPO_ROOT/setup.sh"
    grep -qE 'mark_section_done "terminal_blueprint"' "$REPO_ROOT/setup.sh"
}

# ── v5.6.1: silent-layer regressions (M5 cutover findings, 2026-07-13) ──

@test "[v5.6.1] dispatch loops feed the profile on FD3 (stdin-drain guard)" {
    # Children (brew/apt/installers) inherit stdin; feeding the profile on
    # stdin let a real `brew install` drain it — the M5 full install silently
    # stopped after brew-developer.txt (casks/npm/ai-tools/csv never ran).
    grep -qE 'read -r pkg_file <&3' "$REPO_ROOT/src/platforms/macos/main.sh"
    grep -qE 'done 3< "\$profile_file"' "$REPO_ROOT/src/platforms/macos/main.sh"
    grep -qE 'read -r pkg_file <&3' "$REPO_ROOT/src/platforms/linux/main.sh"
    grep -qE 'done 3< "\$profile_file"' "$REPO_ROOT/src/platforms/linux/main.sh"
}

@test "[v5.6.1] install_csv_category fails loudly on 0 entries" {
    run bash -c '
        source "$1/src/core/logging.sh"
        FAILED_ITEMS=()
        source "$1/src/core/errors.sh"
        DATA_DIR="$1/data"
        source "$1/src/core/csv.sh"
        install_csv_category "no-such-category"
    ' _ "$REPO_ROOT"
    assert_failure
    assert_output --partial "0 entries"
}

@test "[v5.6.1] install_csv_category still succeeds on a real category (dry-run)" {
    run bash -c '
        source "$1/src/core/logging.sh"
        FAILED_ITEMS=()
        source "$1/src/core/errors.sh"
        DATA_DIR="$1/data"
        DRY_RUN=true
        source "$1/src/core/csv.sh"
        install_csv_category "rust-cli"
    ' _ "$REPO_ROOT"
    assert_success
    assert_output --partial "Summary (csv:rust-cli)"
    assert_output --partial "(total 19)"
}

@test "[v5.6.1] dry-run summary declares NOTHING was installed and hides post-install tips" {
    run bash -c '
        source "$1/src/core/logging.sh"
        FAILED_ITEMS=()
        source "$1/src/core/errors.sh"
        source "$1/src/core/progress.sh"
        DRY_RUN=true show_completion_summary "full" "macos"
    ' _ "$REPO_ROOT"
    assert_success
    assert_output --partial "DRY-RUN complete — NOTHING was installed."
    assert_output --partial "To install for real"
    refute_output --partial "What's next"
}

@test "[v5.6.1] real-run summary keeps the post-install tips" {
    run bash -c '
        source "$1/src/core/logging.sh"
        FAILED_ITEMS=()
        source "$1/src/core/errors.sh"
        source "$1/src/core/progress.sh"
        show_completion_summary "full" "macos"
    ' _ "$REPO_ROOT"
    assert_success
    assert_output --partial "What's next"
    refute_output --partial "NOTHING was installed"
}

@test "[v5.6.1] setup.sh optional layers are gated off in dry-run" {
    grep -qE '\[\[ "\$\{DRY_RUN:-\}" != "true" && "\$\{UNATTENDED:-\}" != "true" \]\]' \
        "$REPO_ROOT/setup.sh"
    grep -qE 'DRY_RUN.*Skipping optional config layers' "$REPO_ROOT/setup.sh"
}

@test "[v5.6.1] dev-env runs non-interactive for the full profile (no mid-install prompts)" {
    grep -qE 'NONINTERACTIVE=true bash "\$\{INSTALL_DIR\}/dev-env.sh"' \
        "$REPO_ROOT/src/platforms/macos/main.sh"
    grep -qE 'NONINTERACTIVE=true bash "\$\{INSTALL_DIR\}/dev-env.sh"' \
        "$REPO_ROOT/src/platforms/linux/main.sh"
}

@test "[v5.6.1] SCRIPT_VERSION, README badge and CHANGELOG head agree" {
    script_v=$(grep -Eo 'SCRIPT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"' "$REPO_ROOT/setup.sh" \
        | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
    badge_v=$(grep -Eo 'Version-[0-9]+\.[0-9]+\.[0-9]+-' "$REPO_ROOT/README.md" \
        | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
    changelog_v=$(grep -Eom1 '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$REPO_ROOT/CHANGELOG.md" \
        | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
    [ -n "$script_v" ]
    assert_equal "$script_v" "$badge_v"
    assert_equal "$script_v" "$changelog_v"
}
