# Phase 1: Core Infrastructure - Research

**Researched:** 2026-02-05
**Domain:** Bash scripting infrastructure (platform detection, idempotency, error handling, logging)
**Confidence:** HIGH

## Summary

This phase establishes foundation utilities for cross-platform shell scripts. Research focused on four key areas constrained by user decisions in CONTEXT.md:

1. **Platform Detection:** Standard Unix approach using `uname` and `/etc/os-release` for Linux distro identification
2. **Idempotency Patterns:** Established patterns for checking state before acting (command -v, grep before append, mkdir -p)
3. **Error Handling:** Non-strict mode (no set -e) with trap cleanup and apt retry via native DPkg::Lock::Timeout
4. **Logging:** Colored output with automatic TTY detection, respecting NO_COLOR standard

The existing codebase already has partial implementations in `scripts/utils/logging.sh` and `scripts/utils/check-requirements.sh` that should be refactored to match the new patterns specified in CONTEXT.md.

**Primary recommendation:** Refactor existing utilities to use the documented patterns, removing set -e in favor of explicit error checking, and consolidating platform detection into a single reusable module.

## Standard Stack

This phase uses pure Bash with no external dependencies beyond standard Unix utilities.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Bash | 4.0+ | Shell scripting | Associative arrays, better string handling |
| uname | - | OS/kernel detection | POSIX standard, universally available |
| /etc/os-release | - | Linux distro detection | FreeDesktop.org standard since systemd adoption |
| curl | - | Internet connectivity check | More reliable than ping, HTTP-based |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| grep | - | Pattern matching | Checking file contents, idempotency |
| command | - | Command existence check | Primary idempotency check |
| tput | - | Terminal capability query | Color support detection |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| curl for net check | ping | ping often blocked by firewalls, curl more reliable |
| /etc/os-release | lsb_release | lsb_release not always installed, os-release is standard |
| tput colors | TERM check | tput more reliable across terminal emulators |

**No installation needed** - all tools are standard Unix utilities.

## Architecture Patterns

### Recommended Module Structure
```
scripts/
├── lib/                      # Core infrastructure (this phase)
│   ├── platform.sh           # Platform detection exports
│   ├── idempotent.sh         # Idempotency helper functions
│   ├── errors.sh             # Error handling, trap setup
│   └── logging.sh            # Logging with colors (refactor existing)
├── utils/                    # Existing utilities (migrate to lib/)
└── setup/                    # Entry points that source lib/
```

### Pattern 1: Platform Detection Module
**What:** Single file that detects and exports platform variables
**When to use:** Source at script start before any platform-specific code
**Example:**
```bash
# Source: Verified pattern from /etc/os-release standard
# scripts/lib/platform.sh

detect_platform() {
    # OS detection via uname
    case "$(uname -s)" in
        Darwin)  DETECTED_OS="macos" ;;
        Linux)   DETECTED_OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) DETECTED_OS="windows" ;;
        *)       DETECTED_OS="unknown" ;;
    esac

    # Architecture detection
    case "$(uname -m)" in
        x86_64|amd64)  DETECTED_ARCH="x86_64" ;;
        arm64|aarch64) DETECTED_ARCH="arm64" ;;
        *)             DETECTED_ARCH="$(uname -m)" ;;
    esac

    # Linux distro detection via /etc/os-release
    if [[ "$DETECTED_OS" == "linux" && -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DETECTED_DISTRO="$ID"
        DETECTED_VERSION="${VERSION_ID:-unknown}"
    fi

    # Package manager detection
    if command -v apt &>/dev/null; then
        DETECTED_PKG="apt"
    elif command -v brew &>/dev/null; then
        DETECTED_PKG="brew"
    elif command -v winget &>/dev/null; then
        DETECTED_PKG="winget"
    fi

    # Bash version
    DETECTED_BASH="${BASH_VERSION%%(*}"

    # Export all
    export DETECTED_OS DETECTED_DISTRO DETECTED_VERSION
    export DETECTED_PKG DETECTED_ARCH DETECTED_BASH
}
```

### Pattern 2: Idempotency Guards
**What:** Check state before acting
**When to use:** Before any installation or modification
**Example:**
```bash
# Source: arslan.io idempotent bash patterns
# Check command exists before installing
is_installed() {
    command -v "$1" &>/dev/null
}

# Check before appending to file (avoid duplicates)
ensure_line_in_file() {
    local line="$1"
    local file="$2"
    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
    fi
}

# Safe directory creation (idempotent by default)
ensure_dir() {
    mkdir -p "$1"
}

# Safe symlink (overwrite existing)
ensure_symlink() {
    ln -sfn "$1" "$2"
}
```

### Pattern 3: Error Handler with Continue Strategy
**What:** Trap for cleanup without stopping on errors
**When to use:** Main script entry point
**Example:**
```bash
# Source: linuxcommand.org trap documentation
# Track failures for summary
declare -a FAILED_ITEMS=()

# Cleanup function
cleanup() {
    local exit_code=$?
    # Clean temp files
    rm -rf "${TEMP_DIR:-/tmp/os-postinstall-$$}" 2>/dev/null

    # Show summary if failures occurred
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warning "The following items failed:"
        for item in "${FAILED_ITEMS[@]}"; do
            echo "  - $item"
        done
    fi

    exit 0  # Always exit 0 per CONTEXT decision
}

# Set trap on EXIT, INT, TERM
trap cleanup EXIT INT TERM

# Record failure without stopping
record_failure() {
    FAILED_ITEMS+=("$1")
}
```

### Pattern 4: Logging with Color Detection
**What:** Automatic TTY and NO_COLOR detection
**When to use:** All user-facing output
**Example:**
```bash
# Source: no-color.org standard + tput detection
# Color setup with auto-detection
setup_colors() {
    # Respect NO_COLOR standard
    if [[ -n "${NO_COLOR:-}" ]]; then
        USE_COLORS=false
    # Check if stdout is a terminal
    elif [[ -t 1 ]] && [[ "$(tput colors 2>/dev/null)" -ge 8 ]]; then
        USE_COLORS=true
    else
        USE_COLORS=false
    fi

    if [[ "$USE_COLORS" == true ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        GRAY='\033[0;90m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' GRAY='' NC=''
    fi
}

# Logging functions per CONTEXT decisions
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_debug() { [[ -n "${VERBOSE:-}" ]] && echo -e "${GRAY}[DEBUG]${NC} $*"; }
```

### Anti-Patterns to Avoid
- **set -e with continue strategy:** These conflict. CONTEXT decided no set -e.
- **Nested color codes:** Don't include colors inside logged messages, only in prefix.
- **Piping sensitive commands:** `curl | bash` loses exit codes. Use temp file + source.
- **Hardcoded paths:** Use `$HOME` not `~`, expand variables properly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| apt lock retry | Custom fuser loop | `apt-get -o DPkg::Lock::Timeout=60` | Native apt feature, handles all edge cases |
| Color detection | Check $TERM manually | `tput colors` + NO_COLOR check | tput queries terminfo, more reliable |
| OS detection | Multiple if/elseif chains | Source /etc/os-release | Standard provides ID, VERSION_ID, etc. |
| Progress animation | Complex async | Simple dots loop | CONTEXT says dots, keep simple |
| Version comparison | String parsing | Bash arithmetic on major version | Only need major version per CONTEXT |

**Key insight:** The user explicitly decided against complexity (no state tracking, no version checking, no timeouts). Keep implementations minimal.

## Common Pitfalls

### Pitfall 1: macOS Default Bash 3.2
**What goes wrong:** Scripts using Bash 4+ features fail silently or with cryptic errors
**Why it happens:** macOS ships ancient Bash 3.2 due to GPLv3 licensing
**How to avoid:** Check version early, show upgrade instructions, don't auto-install
**Warning signs:** `declare -A` fails, `${var,,}` lowercase fails
```bash
# Detection pattern
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "[ERROR] Bash 4.0+ required. You have: $BASH_VERSION"
    echo "On macOS: brew install bash"
    exit 1
fi
```

### Pitfall 2: set -e With Error Recovery
**What goes wrong:** Script exits on first error, can't implement "continue on failure"
**Why it happens:** set -e traps all non-zero exits
**How to avoid:** Don't use set -e, check exit codes explicitly where needed
**Warning signs:** Script dies unexpectedly on grep finding no matches

### Pitfall 3: Color Codes in Log Files
**What goes wrong:** Log files contain garbage escape sequences
**Why it happens:** Colors written to non-TTY output
**How to avoid:** Check TTY before using colors, or strip in log_to_file function
**Warning signs:** `cat logfile` shows `^[[0;31m` text
```bash
# Strip colors when writing to file
_write_log() {
    if [[ -n "$LOG_FILE" ]]; then
        echo "$*" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    fi
}
```

### Pitfall 4: PATH Pollution
**What goes wrong:** PATH grows with duplicate entries on re-runs
**Why it happens:** Blindly appending to PATH without checking
**How to avoid:** Check if path component exists before adding
**Warning signs:** `echo $PATH` shows repeated directories
```bash
# Safe PATH append
add_to_path() {
    case ":$PATH:" in
        *":$1:"*) return 0 ;;  # Already in PATH
    esac
    export PATH="$1:$PATH"
}
```

### Pitfall 5: Sourcing With set -e
**What goes wrong:** Sourced file errors kill the parent script
**Why it happens:** set -e propagates to sourced files
**How to avoid:** Since we're not using set -e, this is mitigated. If needed:
```bash
# Safe source (not needed per CONTEXT decision)
source file.sh || true
```

### Pitfall 6: Internet Check With Ping
**What goes wrong:** Script thinks there's no internet when ping is blocked
**Why it happens:** Many networks/firewalls block ICMP
**How to avoid:** Use curl with timeout to well-known HTTPS endpoint
```bash
# Reliable internet check
check_internet() {
    curl -sfm 5 https://www.google.com > /dev/null 2>&1
}
```

## Code Examples

### Complete Platform Detection Module
```bash
#!/usr/bin/env bash
# scripts/lib/platform.sh
# Source: Verified against /etc/os-release FreeDesktop standard

# Prevent multiple sourcing
[[ -n "${_PLATFORM_SOURCED:-}" ]] && return 0
readonly _PLATFORM_SOURCED=1

# Supported Debian-based distros (per CONTEXT)
readonly SUPPORTED_DISTROS="ubuntu debian pop linuxmint elementary zorin"

detect_platform() {
    # OS detection
    case "$(uname -s)" in
        Darwin)  DETECTED_OS="macos" ;;
        Linux)   DETECTED_OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) DETECTED_OS="windows" ;;
        *)       DETECTED_OS="unknown" ;;
    esac

    # Architecture
    case "$(uname -m)" in
        x86_64|amd64)  DETECTED_ARCH="x86_64" ;;
        arm64|aarch64) DETECTED_ARCH="arm64" ;;
        *)             DETECTED_ARCH="$(uname -m)" ;;
    esac

    # Linux distro
    DETECTED_DISTRO=""
    DETECTED_VERSION=""
    if [[ "$DETECTED_OS" == "linux" && -f /etc/os-release ]]; then
        . /etc/os-release
        DETECTED_DISTRO="$ID"
        DETECTED_VERSION="${VERSION_ID:-}"
    fi

    # Package manager
    DETECTED_PKG=""
    if command -v apt &>/dev/null; then
        DETECTED_PKG="apt"
    elif command -v brew &>/dev/null; then
        DETECTED_PKG="brew"
    elif command -v winget &>/dev/null; then
        DETECTED_PKG="winget"
    fi

    # Bash version (major.minor)
    DETECTED_BASH="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"

    export DETECTED_OS DETECTED_DISTRO DETECTED_VERSION
    export DETECTED_PKG DETECTED_ARCH DETECTED_BASH
}

# Verify Bash 4.0+ requirement
verify_bash_version() {
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        echo "[ERROR] Bash 4.0+ required. Current: $BASH_VERSION"
        echo ""
        echo "Upgrade instructions:"
        case "$(uname -s)" in
            Darwin)
                echo "  brew install bash"
                echo "  echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells"
                echo "  chsh -s /opt/homebrew/bin/bash"
                ;;
            *)
                echo "  Use your package manager to update bash"
                ;;
        esac
        return 1
    fi
    return 0
}

# Verify supported distro
verify_supported_distro() {
    if [[ "$DETECTED_OS" == "linux" ]]; then
        if [[ ! " $SUPPORTED_DISTROS " =~ " $DETECTED_DISTRO " ]]; then
            echo "[WARN] $DETECTED_DISTRO is not officially supported."
            echo "Supported: $SUPPORTED_DISTROS"
            read -rp "Continue anyway? [y/N] " response
            [[ "$response" =~ ^[Yy]$ ]] || return 1
        fi
    fi
    return 0
}

# Verify supported package manager
verify_package_manager() {
    if [[ -z "$DETECTED_PKG" ]]; then
        echo "[ERROR] No supported package manager found."
        echo "Supported: apt, brew, winget"
        return 1
    fi

    local supported="apt brew winget"
    if [[ ! " $supported " =~ " $DETECTED_PKG " ]]; then
        echo "[ERROR] $DETECTED_PKG is not supported."
        echo "Supported: apt, brew, winget"
        return 1
    fi
    return 0
}

# Check internet connectivity
check_internet() {
    if ! curl -sfm 5 https://www.google.com > /dev/null 2>&1; then
        echo "[WARN] No internet connection detected."
        read -rp "Continue anyway? [y/N] " response
        [[ "$response" =~ ^[Yy]$ ]] || return 1
    fi
    return 0
}

# Request sudo upfront
request_sudo() {
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        return 0
    fi

    echo "[INFO] This script requires sudo privileges."
    if ! sudo -v; then
        echo "[ERROR] Failed to obtain sudo privileges."
        return 1
    fi

    # Keep sudo alive in background
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &

    return 0
}

# Main verification sequence (per CONTEXT: OS -> Bash -> Net -> Sudo)
verify_all() {
    detect_platform

    echo "Detected: $DETECTED_DISTRO ${DETECTED_VERSION:-$DETECTED_OS} ($DETECTED_PKG)"

    verify_bash_version || return 1
    verify_supported_distro || return 1
    verify_package_manager || return 1
    check_internet || return 1
    request_sudo || return 1

    return 0
}
```

### apt Retry Pattern
```bash
# Source: apt DPkg::Lock::Timeout documentation
# Retry apt commands with lock timeout

apt_install() {
    local packages=("$@")
    local timeout=60  # 60 second timeout for lock

    # First attempt
    if sudo apt-get -o DPkg::Lock::Timeout=$timeout install -y "${packages[@]}"; then
        return 0
    fi

    # One retry (per CONTEXT decision)
    log_warn "apt failed, retrying in 5 seconds..."
    sleep 5

    if sudo apt-get -o DPkg::Lock::Timeout=$timeout install -y "${packages[@]}"; then
        return 0
    fi

    return 1
}
```

### Progress Dots Animation
```bash
# Source: shellscript.sh spinner example (simplified to dots per CONTEXT)
# Simple dots progress indicator

show_dots() {
    local pid=$1
    local delay=0.5
    local dots=""

    while kill -0 "$pid" 2>/dev/null; do
        dots+="."
        printf "\r%s%s" "$2" "$dots"

        # Reset after 5 dots
        if [[ ${#dots} -ge 5 ]]; then
            printf "\r%s     \r%s" "$2" "$2"
            dots=""
        fi

        sleep $delay
    done

    # Clear and show done
    printf "\r%s done\n" "$2"
}

# Usage:
# long_running_command &
# show_dots $! "Installing packages"
```

### Backup Pattern for Dotfiles
```bash
# Source: Idempotent bash patterns
# Backup with date stamp before overwrite

backup_and_copy() {
    local src="$1"
    local dest="$2"
    local backup_suffix=".bak.$(date +%Y-%m-%d)"

    if [[ -f "$dest" ]]; then
        cp "$dest" "${dest}${backup_suffix}"
        log_info "Backed up: ${dest}${backup_suffix}"
    fi

    cp "$src" "$dest"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| lsb_release | /etc/os-release | ~2015 | More universal, no extra package |
| ping for net check | curl with timeout | Always better | Works through firewalls |
| fuser for apt lock | apt -o DPkg::Lock::Timeout | apt 1.9.11 (2020) | Native, reliable |
| Manual color codes | tput + NO_COLOR | NO_COLOR: 2017 | Respects user preference |

**Deprecated/outdated:**
- `lsb_release -a`: Not installed by default on minimal systems
- `set -e` with error recovery: Mutually exclusive designs
- `/etc/lsb-release`: Older format, prefer `/etc/os-release`

## Open Questions

1. **Exact retry delay for apt**
   - What we know: 5 seconds suggested in CONTEXT, DPkg::Lock::Timeout handles lock wait
   - What's unclear: Is 5s optimal or should it match timeout?
   - Recommendation: Use 5s as suggested, the lock timeout handles actual contention

2. **WSL detection specifics**
   - What we know: Can check `/proc/version` for "microsoft" string
   - What's unclear: Should WSL be treated as Linux or special case?
   - Recommendation: Detect as Linux with WSL flag, use apt normally

3. **Verbose mode timestamp format**
   - What we know: CONTEXT says timestamps only in verbose mode
   - What's unclear: Exact format preference
   - Recommendation: ISO format `[2026-02-05 10:30:00]` for consistency

## Sources

### Primary (HIGH confidence)
- [NO_COLOR Standard](https://no-color.org/) - Color output convention
- [FreeDesktop os-release](https://www.freedesktop.org/software/systemd/man/os-release.html) - Linux distro detection standard
- [apt DPkg::Lock::Timeout](https://blog.sinjakli.co.uk/2021/10/25/waiting-for-apt-locks-without-the-hacky-bash-scripts/) - Native apt lock handling

### Secondary (MEDIUM confidence)
- [arslan.io Idempotent Bash](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) - Idempotency patterns
- [metaist/idempotent-bash](https://github.com/metaist/idempotent-bash) - Idempotency library reference
- [shellscript.sh Spinner](https://www.shellscript.sh/examples/spinner/) - Progress animation
- [GoLinuxCloud Internet Check](https://www.golinuxcloud.com/commands-check-if-connected-to-internet-shell/) - curl/tcp connectivity

### Tertiary (LOW confidence)
- Various bash scripting guides for trap patterns
- Stack Overflow for edge case handling

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Pure bash, no external deps, well-documented standards
- Architecture: HIGH - Patterns verified against established sources
- Pitfalls: HIGH - Common issues, verified in existing codebase

**Research date:** 2026-02-05
**Valid until:** 2026-03-05 (30 days - stable domain, bash patterns rarely change)
