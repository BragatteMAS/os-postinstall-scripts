#!/usr/bin/env bats
# tests/test-core-platform.bats -- Unit tests for src/core/platform.sh

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    export NO_COLOR=1
    unset _PLATFORM_SOURCED _LOGGING_SOURCED

    # Mock uname: dispatches on $1 (-s vs -m)
    uname() {
        case "$1" in
            -s) echo "Linux" ;;
            -m) echo "x86_64" ;;
            *)  echo "Linux" ;;
        esac
    }
    export -f uname

    # Mock command: intercept -v only, passthrough everything else
    _MOCK_COMMANDS=("apt-get")
    command() {
        if [[ "$1" == "-v" ]]; then
            local cmd="$2"
            for c in "${_MOCK_COMMANDS[@]}"; do
                [[ "$cmd" == "$c" ]] && return 0
            done
            return 1
        fi
        builtin command "$@"
    }
    export -f command

    source "${BATS_TEST_DIRNAME}/../src/core/logging.sh"
    source "${BATS_TEST_DIRNAME}/../src/core/platform.sh"
}

# ── detect_platform OS detection ──────────────────────────────────

@test "detect_platform sets DETECTED_OS=linux for uname=Linux" {
    detect_platform
    [ "$DETECTED_OS" == "linux" ]
}

@test "detect_platform sets DETECTED_OS=macos for uname=Darwin" {
    uname() {
        case "$1" in
            -s) echo "Darwin" ;;
            -m) echo "x86_64" ;;
            *)  echo "Darwin" ;;
        esac
    }
    export -f uname
    detect_platform
    [ "$DETECTED_OS" == "macos" ]
}

@test "detect_platform sets DETECTED_OS=windows for uname=MINGW" {
    uname() {
        case "$1" in
            -s) echo "MINGW64_NT-10.0" ;;
            -m) echo "x86_64" ;;
            *)  echo "MINGW64_NT-10.0" ;;
        esac
    }
    export -f uname
    detect_platform
    [ "$DETECTED_OS" == "windows" ]
}

@test "detect_platform sets DETECTED_OS=unknown for unsupported uname" {
    uname() {
        case "$1" in
            -s) echo "FreeBSD" ;;
            -m) echo "x86_64" ;;
            *)  echo "FreeBSD" ;;
        esac
    }
    export -f uname
    detect_platform
    [ "$DETECTED_OS" == "unknown" ]
}

# ── detect_platform architecture ──────────────────────────────────

@test "detect_platform sets DETECTED_ARCH=x86_64" {
    detect_platform
    [ "$DETECTED_ARCH" == "x86_64" ]
}

@test "detect_platform sets DETECTED_ARCH=arm64 for arm64" {
    uname() {
        case "$1" in
            -s) echo "Linux" ;;
            -m) echo "arm64" ;;
            *)  echo "Linux" ;;
        esac
    }
    export -f uname
    detect_platform
    [ "$DETECTED_ARCH" == "arm64" ]
}

@test "detect_platform normalizes aarch64 to arm64" {
    uname() {
        case "$1" in
            -s) echo "Linux" ;;
            -m) echo "aarch64" ;;
            *)  echo "Linux" ;;
        esac
    }
    export -f uname
    detect_platform
    [ "$DETECTED_ARCH" == "arm64" ]
}

# ── detect_platform package manager ───────────────────────────────

@test "detect_platform sets DETECTED_PKG=apt when apt-get available" {
    detect_platform
    [ "$DETECTED_PKG" == "apt" ]
}

@test "detect_platform sets DETECTED_PKG=brew when brew available" {
    _MOCK_COMMANDS=("brew")
    detect_platform
    [ "$DETECTED_PKG" == "brew" ]
}

@test "detect_platform sets DETECTED_PKG empty when no package manager" {
    _MOCK_COMMANDS=()
    detect_platform
    [ -z "$DETECTED_PKG" ]
}

# ── detect_platform bash version ──────────────────────────────────

@test "detect_platform sets DETECTED_BASH from BASH_VERSINFO" {
    detect_platform
    [ -n "$DETECTED_BASH" ]
    [[ "$DETECTED_BASH" == *"."* ]]
}

# ── verify_bash_version ──────────────────────────────────────────

@test "verify_bash_version passes with current Bash" {
    run verify_bash_version
    assert_success
}

# ── verify_supported_distro ──────────────────────────────────────

@test "verify_supported_distro passes for macOS" {
    DETECTED_OS=macos
    run verify_supported_distro
    assert_success
}

@test "verify_supported_distro passes for ubuntu" {
    DETECTED_OS=linux
    DETECTED_DISTRO=ubuntu
    run verify_supported_distro
    assert_success
}

@test "verify_supported_distro continues for unsupported distro in non-TTY" {
    DETECTED_OS=linux
    DETECTED_DISTRO=arch
    run verify_supported_distro
    assert_success
    assert_output --partial "not officially supported"
}

# ── verify_package_manager ────────────────────────────────────────

@test "verify_package_manager fails when DETECTED_PKG empty" {
    DETECTED_PKG=""
    run verify_package_manager
    assert_failure
}

@test "verify_package_manager passes when DETECTED_PKG=apt" {
    DETECTED_PKG=apt
    run verify_package_manager
    assert_success
}

# ── request_sudo ──────────────────────────────────────────────────

@test "request_sudo skips in DRY_RUN mode" {
    DRY_RUN=true
    run request_sudo
    assert_success
    assert_output --partial "skipping sudo"
}
