#!/usr/bin/env bats
# tests/test-core-dotfiles.bats -- Unit tests for src/core/dotfiles.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    # Unset source guards so modules re-source in each test subshell
    unset _DOTFILES_SOURCED _LOGGING_SOURCED

    TEST_DIR="$(mktemp -d)"
    export HOME="${TEST_DIR}/home"
    mkdir -p "$HOME"

    # These MUST be set BEFORE sourcing dotfiles.sh (Pitfall 4: source-time expansion)
    export BACKUP_DIR="${HOME}/.dotfiles-backup"
    export MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"
    SESSION_BACKUPS=()

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/dotfiles.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# =========================================================
# path_to_backup_name (4 tests)
# =========================================================

@test "path_to_backup_name converts simple dotfile" {
    run path_to_backup_name "$HOME/.zshrc"
    assert_success
    [[ "$output" =~ ^zshrc\.bak\.[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "path_to_backup_name converts nested path" {
    run path_to_backup_name "$HOME/.config/git/ignore"
    assert_success
    [[ "$output" =~ ^config-git-ignore\.bak\.[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "path_to_backup_name returns error for empty arg" {
    run path_to_backup_name ""
    assert_failure
}

@test "path_to_backup_name includes date suffix" {
    run path_to_backup_name "$HOME/.bashrc"
    assert_success
    assert_output --partial ".bak.$(date +%Y-%m-%d)"
}

# =========================================================
# backup_with_manifest (6 tests)
# =========================================================

@test "backup_with_manifest creates backup directory" {
    echo "original" > "$HOME/.testrc"
    run backup_with_manifest "$HOME/.testrc"
    assert_success
    [ -d "$BACKUP_DIR" ]
}

@test "backup_with_manifest copies file to backup dir" {
    echo "original content" > "$HOME/.testrc"
    run backup_with_manifest "$HOME/.testrc"
    assert_success
    # A .bak file should exist in BACKUP_DIR
    local bak_count
    bak_count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" 2>/dev/null | wc -l | tr -d ' ')
    [ "$bak_count" -ge 1 ]
}

@test "backup_with_manifest writes to manifest file" {
    echo "test content" > "$HOME/.testrc"
    run backup_with_manifest "$HOME/.testrc"
    assert_success
    [ -f "$MANIFEST_FILE" ]
    grep -q ".testrc" "$MANIFEST_FILE"
}

@test "backup_with_manifest handles name collision" {
    echo "first" > "$HOME/.testrc"
    # First backup (direct call, not via run, to populate state)
    backup_with_manifest "$HOME/.testrc"
    # Second backup same file same day -- should get timestamp suffix
    backup_with_manifest "$HOME/.testrc"
    # Count backup files -- should be 2
    local bak_count
    bak_count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" 2>/dev/null | wc -l | tr -d ' ')
    [ "$bak_count" -eq 2 ]
}

@test "backup_with_manifest skips in DRY_RUN mode" {
    export DRY_RUN=true
    echo "dry content" > "$HOME/.testrc"
    run backup_with_manifest "$HOME/.testrc"
    assert_success
    # No file should have been created in BACKUP_DIR
    if [ -d "$BACKUP_DIR" ]; then
        local bak_count
        bak_count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" 2>/dev/null | wc -l | tr -d ' ')
        [ "$bak_count" -eq 0 ]
    fi
}

@test "backup_with_manifest fails on empty arg" {
    run backup_with_manifest ""
    assert_failure
}

# =========================================================
# create_dotfile_symlink (6 tests)
# =========================================================

@test "create_dotfile_symlink creates symlink" {
    mkdir -p "$TEST_DIR/source"
    echo "source content" > "$TEST_DIR/source/myconfig"
    run create_dotfile_symlink "$TEST_DIR/source/myconfig" "$HOME/.myconfig"
    assert_success
    [ -L "$HOME/.myconfig" ]
    local link_target
    link_target="$(readlink "$HOME/.myconfig")"
    [ "$link_target" = "$TEST_DIR/source/myconfig" ]
}

@test "create_dotfile_symlink backs up existing non-symlink file" {
    # Create existing file at target
    echo "old content" > "$HOME/.myconfig"
    # Create source file
    mkdir -p "$TEST_DIR/source"
    echo "new content" > "$TEST_DIR/source/myconfig"
    run create_dotfile_symlink "$TEST_DIR/source/myconfig" "$HOME/.myconfig"
    assert_success
    [ -L "$HOME/.myconfig" ]
    # A backup should exist in BACKUP_DIR
    [ -d "$BACKUP_DIR" ]
    local bak_count
    bak_count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" 2>/dev/null | wc -l | tr -d ' ')
    [ "$bak_count" -ge 1 ]
}

@test "create_dotfile_symlink replaces existing symlink without backup" {
    # Create a symlink at target pointing to /dev/null
    ln -sfn /dev/null "$HOME/.myconfig"
    # Create source file
    mkdir -p "$TEST_DIR/source"
    echo "real content" > "$TEST_DIR/source/myconfig"
    run create_dotfile_symlink "$TEST_DIR/source/myconfig" "$HOME/.myconfig"
    assert_success
    [ -L "$HOME/.myconfig" ]
    local link_target
    link_target="$(readlink "$HOME/.myconfig")"
    [ "$link_target" = "$TEST_DIR/source/myconfig" ]
    # No backup should have been created (symlinks replaced silently)
    if [ -d "$BACKUP_DIR" ]; then
        local bak_count
        bak_count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.bak.*" 2>/dev/null | wc -l | tr -d ' ')
        [ "$bak_count" -eq 0 ]
    fi
}

@test "create_dotfile_symlink creates parent directory" {
    mkdir -p "$TEST_DIR/source"
    echo "deep content" > "$TEST_DIR/source/deepfile"
    run create_dotfile_symlink "$TEST_DIR/source/deepfile" "$HOME/.config/deep/nested/file"
    assert_success
    [ -d "$HOME/.config/deep/nested" ]
    [ -L "$HOME/.config/deep/nested/file" ]
}

@test "create_dotfile_symlink fails for missing source" {
    run create_dotfile_symlink "/nonexistent/path/file" "$HOME/.foo"
    assert_failure
}

@test "create_dotfile_symlink dry-run does not create symlink" {
    export DRY_RUN=true
    mkdir -p "$TEST_DIR/source"
    echo "dry content" > "$TEST_DIR/source/myconfig"
    run create_dotfile_symlink "$TEST_DIR/source/myconfig" "$HOME/.myconfig"
    assert_success
    [ ! -L "$HOME/.myconfig" ]
}

# =========================================================
# unlink_dotfiles (4 tests)
# =========================================================

@test "unlink_dotfiles removes symlink" {
    mkdir -p "$TEST_DIR/source"
    echo "link target" > "$TEST_DIR/source/myconfig"
    ln -sfn "$TEST_DIR/source/myconfig" "$HOME/.myconfig"
    run unlink_dotfiles "$HOME/.myconfig"
    assert_success
    [ ! -L "$HOME/.myconfig" ]
}

@test "unlink_dotfiles restores backup from manifest" {
    local target="$HOME/.testrc"
    # Create original file with known content
    echo "original content" > "$target"
    # Backup it directly (not via run) so SESSION_BACKUPS and MANIFEST_FILE are populated
    backup_with_manifest "$target"
    # Now create symlink at the target location (replacing the file)
    mkdir -p "$TEST_DIR/source"
    echo "symlink target" > "$TEST_DIR/source/testrc"
    ln -sfn "$TEST_DIR/source/testrc" "$target"
    [ -L "$target" ]
    # Unlink should remove symlink and restore from manifest
    run unlink_dotfiles "$target"
    assert_success
    # Target should exist and NOT be a symlink (restored from backup)
    [ -e "$target" ]
    [ ! -L "$target" ]
    # Content should match original
    local restored_content
    restored_content="$(cat "$target")"
    [ "$restored_content" = "original content" ]
}

@test "unlink_dotfiles skips non-symlink files" {
    echo "regular file" > "$HOME/.myconfig"
    run unlink_dotfiles "$HOME/.myconfig"
    assert_success
    # File should still exist unchanged
    [ -f "$HOME/.myconfig" ]
    local content
    content="$(cat "$HOME/.myconfig")"
    [ "$content" = "regular file" ]
}

@test "unlink_dotfiles handles nonexistent target" {
    run unlink_dotfiles "$HOME/.nonexistent"
    assert_success
}

# =========================================================
# show_backup_summary and list_backups (2 tests)
# =========================================================

@test "show_backup_summary shows empty message when no backups" {
    SESSION_BACKUPS=()
    run show_backup_summary
    assert_success
    assert_output --partial "No backups created"
}

@test "list_backups shows message when no backup files exist" {
    run list_backups
    assert_success
    assert_output --partial "No backup"
}
