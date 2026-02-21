#!/usr/bin/env bats
# tests/test-data-validation.bats -- Data integrity tests for profile and package files

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    PROFILES_DIR="${BATS_TEST_DIRNAME}/../data/packages/profiles"
    PACKAGES_DIR="${BATS_TEST_DIRNAME}/../data/packages"
}

# =========================================================
# Profile existence
# =========================================================

@test "expected profiles exist (minimal, developer, full)" {
    [ -f "$PROFILES_DIR/minimal.txt" ]
    [ -f "$PROFILES_DIR/developer.txt" ]
    [ -f "$PROFILES_DIR/full.txt" ]
}

# =========================================================
# Reference integrity
# =========================================================

@test "all profile files reference existing package files" {
    for profile in "$PROFILES_DIR"/*.txt; do
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "$line" || "$line" == \#* ]] && continue
            [ -f "${PACKAGES_DIR}/${line}" ] || \
                fail "Profile $(basename "$profile") references '${line}' but ${PACKAGES_DIR}/${line} does not exist"
        done < "$profile"
    done
}

@test "no empty profiles - each has at least one package file reference" {
    for profile in "$PROFILES_DIR"/*.txt; do
        local count=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "$line" || "$line" == \#* ]] && continue
            count=$((count + 1))
        done < "$profile"
        [ "$count" -gt 0 ] || \
            fail "Profile $(basename "$profile") has no package file references"
    done
}

# =========================================================
# Orphan detection
# =========================================================

@test "no orphaned package files" {
    for pkg_file in "$PACKAGES_DIR"/*.txt; do
        local basename_pkg
        basename_pkg="$(basename "$pkg_file")"
        # Check that at least one profile references this package file
        local found=0
        for profile in "$PROFILES_DIR"/*.txt; do
            if grep -q "^${basename_pkg}$" "$profile" 2>/dev/null || \
               grep -q "^${basename_pkg}[[:space:]]" "$profile" 2>/dev/null; then
                found=1
                break
            fi
        done
        [ "$found" -eq 1 ] || \
            fail "Package file ${basename_pkg} is not referenced by any profile"
    done
}

# =========================================================
# Content validation
# =========================================================

@test "package files contain at least one package" {
    for pkg_file in "$PACKAGES_DIR"/*.txt; do
        local count=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "$line" || "$line" == \#* ]] && continue
            count=$((count + 1))
        done < "$pkg_file"
        [ "$count" -gt 0 ] || \
            fail "Package file $(basename "$pkg_file") contains no packages"
    done
}

@test "profile files are valid text with no binary content" {
    for profile in "$PROFILES_DIR"/*.txt; do
        local mime_type
        mime_type="$(file --mime-type -b "$profile")"
        [[ "$mime_type" == text/* ]] || \
            fail "Profile $(basename "$profile") is not a text file (mime: ${mime_type})"
    done
}
