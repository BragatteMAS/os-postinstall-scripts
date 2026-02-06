# Phase 1: Core Infrastructure - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Foundation utilities that all other phases will use: platform detection, idempotency patterns, error handling, and logging system. This phase establishes safe patterns for cross-platform execution.

</domain>

<decisions>
## Implementation Decisions

### Platform Detection

- **Detection method:** uname + /etc/os-release (standard Unix approach)
- **Supported distros:** Debian-based (Pop!_OS, Linux Mint, Elementary OS, Zorin OS, Ubuntu, Debian)
- **Unsupported distro:** Warn and ask "Continue anyway? [y/N]"
- **Unsupported package manager:** Exit with clear error ("pacman is not supported. Supported: apt, brew, winget")
- **Bash version:** Require 4.0+, if older show instructions to upgrade (don't auto-install)
- **Output:** One line: "Detected: Pop!_OS 22.04 (apt)"
- **Exported variables:** DETECTED_OS, DETECTED_DISTRO, DETECTED_PKG, DETECTED_BASH, DETECTED_ARCH
- **Detection failure:** Exit with error
- **Sudo handling:** Require at start (ask once), skip in --dry-run mode
- **Detection cache:** No cache, detect every run (KISS)
- **Internet check:** Verify at start, ask "No internet. Continue? [y/N]"
- **CPU architecture:** Detect arm64/x86_64 (DETECTED_ARCH)
- **Verification order:** OS -> Bash -> Net -> Sudo

### Idempotency Patterns

- **Check if installed:** command -v first, package manager query as fallback
- **Already installed:** Skip with log ("bat already installed")
- **Version management:** No version checking (KISS, let apt upgrade handle it)
- **Existing dotfiles:** Backup + overwrite (.zshrc.bak.2026-02-04)
- **PATH duplicates:** Check before adding (avoid duplicates)
- **Shell reload:** Instruct "exec $SHELL" at end
- **State tracking:** No (KISS, leave for v2)
- **Verification step:** Check exit code + optionally verify binary exists

### Error Handling

- **Package failure:** Continue + summary at end (don't stop for one package)
- **Retry logic:** 1 retry for apt (lock contention), no retry for brew
- **Exit code:** Exit 0 always + warning summary (pragmatic, if 95% works it's success)
- **Trap/cleanup:** Yes, clean temp files on SIGINT/SIGTERM
- **Log file:** Optional via LOG_FILE=path env var
- **Verbose mode:** Yes, -v flag or VERBOSE=1 for debug output
- **set -e:** No (conflicts with "continue on failure" strategy)

### Logging Style

- **Format:** Text with colors, no emojis ([OK] [ERROR] [WARN] [INFO])
- **Colors:** Standard palette (blue=info, green=success, yellow=warn, red=error, gray=debug)
- **Timestamp:** Only in verbose mode
- **Progress indicator:** Dots progressivos for long operations
- **Color detection:** Auto-detect tty (colors in terminal, plain in pipe)
- **Indentation:** 2 levels (steps + items)
- **Banner:** Simple one line with name + version

### Claude's Discretion

- Exact implementation of dots progress animation
- Specific retry delay for apt (suggested 5s)
- Order of detection checks (as long as follows OS -> Bash -> Net -> Sudo)
- Exact wording of error messages (as long as clear and actionable)

</decisions>

<specifics>
## Specific Ideas

- Distro preference: Pop!_OS, Linux Mint, Elementary OS, Zorin OS (all Debian-based, use apt)
- Banner example: "OS Post-Install Scripts v4.0.0"
- Detection output example: "Detected: Pop!_OS 22.04 (apt)"
- Log hierarchy: Steps at top level, individual items indented
- Pragmatic philosophy: "If 95% installed and system started, it's a victory"

</specifics>

<deferred>
## Deferred Ideas

- Timeout for operations - leave for v2
- State tracking (what was installed) - leave for v2
- Dry-run mode implementation - Phase 7 (UX Polish)
- set -e / strict mode - decided against, conflicts with continue strategy
- i18n for messages - out of scope

</deferred>

---

*Phase: 01-core-infrastructure*
*Context gathered: 2026-02-04*
