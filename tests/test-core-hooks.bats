#!/usr/bin/env bats
# tests/test-core-hooks.bats -- Unit tests for src/core/hooks.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Use temp dir for hooks to avoid running real hooks
    export DATA_DIR="${BATS_TEST_TMPDIR}/data"
    mkdir -p "${DATA_DIR}/hooks"
    # Unset source guards so modules re-source in each test subshell
    unset _LOGGING_SOURCED
    unset _HOOKS_SOURCED
    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/hooks.sh"
}

# ── run_hooks basic behavior ──────────────────────────

@test "run_hooks succeeds with no hooks directory" {
    rm -rf "${DATA_DIR}/hooks"
    run run_hooks "macos"
    assert_success
}

@test "run_hooks succeeds with empty hooks directory" {
    run run_hooks "macos"
    assert_success
}

@test "run_hooks executes hooks in sorted order" {
    local log_file="${BATS_TEST_TMPDIR}/order.log"

    cat > "${DATA_DIR}/hooks/02-second.sh" << 'EOF'
#!/usr/bin/env bash
echo "second" >> "$ORDER_LOG"
EOF
    cat > "${DATA_DIR}/hooks/01-first.sh" << 'EOF'
#!/usr/bin/env bash
echo "first" >> "$ORDER_LOG"
EOF
    chmod +x "${DATA_DIR}/hooks/"*.sh

    export ORDER_LOG="$log_file"
    run_hooks "all"

    run cat "$log_file"
    assert_line --index 0 "first"
    assert_line --index 1 "second"
}

# ── DRY_RUN ──────────────────────────────────────────

@test "run_hooks respects DRY_RUN" {
    local marker="${BATS_TEST_TMPDIR}/marker"

    cat > "${DATA_DIR}/hooks/01-test.sh" << EOF
#!/usr/bin/env bash
touch "$marker"
EOF
    chmod +x "${DATA_DIR}/hooks/01-test.sh"

    export DRY_RUN=true
    run run_hooks "all"
    assert_success

    # Marker should NOT exist (hook should not have run)
    [ ! -f "$marker" ]
}

# ── Platform filtering ────────────────────────────────

@test "run_hooks skips macos hooks on linux" {
    local marker="${BATS_TEST_TMPDIR}/marker"

    cat > "${DATA_DIR}/hooks/01-macos-test.sh" << EOF
#!/usr/bin/env bash
touch "$marker"
EOF
    chmod +x "${DATA_DIR}/hooks/01-macos-test.sh"

    run_hooks "linux"

    [ ! -f "$marker" ]
}

@test "run_hooks skips linux hooks on macos" {
    local marker="${BATS_TEST_TMPDIR}/marker"

    cat > "${DATA_DIR}/hooks/01-linux-test.sh" << EOF
#!/usr/bin/env bash
touch "$marker"
EOF
    chmod +x "${DATA_DIR}/hooks/01-linux-test.sh"

    run_hooks "macos"

    [ ! -f "$marker" ]
}

@test "run_hooks runs macos hooks on macos" {
    local marker="${BATS_TEST_TMPDIR}/marker"

    cat > "${DATA_DIR}/hooks/01-macos-test.sh" << EOF
#!/usr/bin/env bash
touch "$marker"
EOF
    chmod +x "${DATA_DIR}/hooks/01-macos-test.sh"

    run_hooks "macos"

    [ -f "$marker" ]
}

@test "run_hooks runs platform-neutral hooks on any platform" {
    local marker="${BATS_TEST_TMPDIR}/marker"

    cat > "${DATA_DIR}/hooks/01-neutral.sh" << EOF
#!/usr/bin/env bash
touch "$marker"
EOF
    chmod +x "${DATA_DIR}/hooks/01-neutral.sh"

    run_hooks "linux"

    [ -f "$marker" ]
}

# ── Failure handling ──────────────────────────────────

@test "run_hooks returns 1 when a hook fails" {
    cat > "${DATA_DIR}/hooks/01-fail.sh" << 'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "${DATA_DIR}/hooks/01-fail.sh"

    run run_hooks "all"
    assert_failure
}

@test "run_hooks continues after hook failure" {
    local marker="${BATS_TEST_TMPDIR}/marker"

    cat > "${DATA_DIR}/hooks/01-fail.sh" << 'EOF'
#!/usr/bin/env bash
exit 1
EOF
    cat > "${DATA_DIR}/hooks/02-succeed.sh" << EOF
#!/usr/bin/env bash
touch "$marker"
EOF
    chmod +x "${DATA_DIR}/hooks/"*.sh

    run_hooks "all" || true

    [ -f "$marker" ]
}
