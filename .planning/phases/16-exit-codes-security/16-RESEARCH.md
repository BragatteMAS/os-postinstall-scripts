# Phase 16: Exit Codes & Security - Research

**Researched:** 2026-02-21
**Domain:** Shell/PowerShell exit code semantics, curl|sh security mitigations, cross-process failure propagation
**Confidence:** HIGH

## Summary

This phase addresses two related concerns flagged by reviewers: (1) every script exits 0 regardless of outcome, making automation/chaining impossible, and (2) five `curl|sh` call sites are vulnerable to partial-download execution. Both problems have well-understood solutions that build on the project's existing infrastructure.

The exit code work is **minimal surgery** -- the failure tracking infrastructure (`FAILED_ITEMS[]`, `FAILURE_LOG`, `get_failure_count`, `Get-FailureCount`) already exists and works correctly. The only change is converting the final `exit 0` lines to use a computed exit code based on failure state. The `safe_curl_sh()` helper is approximately 15 lines of code that replaces the pipe pattern with a download-then-execute pattern.

The project has **existing prior research** in `.planning/phases/research-exit-codes.md` and `.planning/phases/research-curl-security.md` (both dated 2026-02-19) that provide verified, HIGH-confidence findings. This RESEARCH.md synthesizes and consolidates those findings with additional codebase verification for the planner's consumption.

**Primary recommendation:** Define three exit code constants (0/1/2) in errors.sh and errors.psm1. Add `compute_exit_code()` function. Change ~15 exit points across Bash/PowerShell. Add `safe_curl_sh()` to src/core/. Migrate 5 curl|sh sites. Write ADR-009. Amend ADR-001. Split into 2 plans: Plan 01 (exit codes) and Plan 02 (security + ADRs).

## Standard Stack

### Core (No new libraries -- pure shell)

| Component | Location | Purpose | Status |
|-----------|----------|---------|--------|
| `errors.sh` | `src/core/errors.sh` | Exit constants, `compute_exit_code()`, cleanup trap | Exists -- needs constants + function |
| `errors.psm1` | `src/platforms/windows/core/errors.psm1` | PS exit constants, `Get-ExitCode` | Exists -- needs constants + function |
| `safe_curl_sh()` | `src/core/errors.sh` (or new file) | Download-then-execute helper | New function |
| ADR-009 | `.planning/adrs/ADR-009-curl-trust-model.md` | curl|sh trust model documentation | New file |
| ADR-001 | `.planning/adrs/ADR-001-error-resilience.md` | Amendment for semantic exit codes | Exists -- needs amendment |

### Supporting

| Tool | Purpose | Already Available |
|------|---------|-------------------|
| bats-core | Test exit code behavior | Yes -- `tests/test-core-errors.bats` |
| curl | Used by `safe_curl_sh()` | Yes -- already a project dependency |
| mktemp | Temp file for download-then-execute | Yes -- already used in `errors.sh` |

### No New Dependencies

This phase introduces **zero new dependencies**. Everything is built with POSIX shell primitives, existing Bash functions, and existing PowerShell modules. No libraries, no packages, no external tools.

## Architecture Patterns

### Pattern 1: Three-Tier Exit Code Scheme

**What:** Semantic exit codes that map to the project's existing failure categories.
**When to use:** Every script that reaches its end-of-execution point.

```bash
# In errors.sh -- define as readonly constants
readonly EXIT_SUCCESS=0         # All operations completed successfully
readonly EXIT_PARTIAL_FAILURE=1 # Run completed, but some items failed
readonly EXIT_CRITICAL=2        # Pre-flight check failed, cannot proceed
```

```powershell
# In errors.psm1 -- module-scoped constants
$script:EXIT_SUCCESS = 0
$script:EXIT_PARTIAL_FAILURE = 1
$script:EXIT_CRITICAL = 2
```

**Why these codes:**
- 0 = POSIX success
- 1 = POSIX general error (natural for "something went wrong but we completed")
- 2 = POSIX shell builtin misuse / critical error (natural for "cannot proceed at all")
- No higher codes needed -- automation callers rarely parse beyond 0/non-zero

**Confidence:** HIGH -- POSIX spec, TLDP exit codes reference, BSD sysexits.h.

### Pattern 2: compute_exit_code() Function

**What:** A function that derives the exit code from the existing failure tracking state.
**Where:** `src/core/errors.sh`

```bash
# compute_exit_code -- Return semantic exit code based on failure state
# Uses FAILURE_LOG (cross-process) or FAILED_ITEMS (in-process)
# Returns: 0 (success), 1 (partial failure), 2 (critical -- caller must set explicitly)
compute_exit_code() {
    local fail_count=0

    if [[ -n "${FAILURE_LOG:-}" && -f "$FAILURE_LOG" && -s "$FAILURE_LOG" ]]; then
        fail_count=$(wc -l < "$FAILURE_LOG" | tr -d ' ')
    elif [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        fail_count=${#FAILED_ITEMS[@]}
    fi

    if [[ "$fail_count" -gt 0 ]]; then
        return $EXIT_PARTIAL_FAILURE
    fi
    return $EXIT_SUCCESS
}
```

**Critical detail:** This function only distinguishes 0 vs 1. Exit code 2 (critical) is set explicitly by callers for pre-flight failures -- it is NOT computed from `FAILED_ITEMS`. Pre-flight failures (no internet, no sudo, bad platform) abort before any packages are attempted, so `FAILED_ITEMS` is empty.

**Confidence:** HIGH -- builds directly on existing infrastructure.

### Pattern 3: Parent Worst-Code Tracking

**What:** Parent orchestrators capture child exit codes and propagate the worst one.
**Where:** `setup.sh`, `linux/main.sh`, `macos/main.sh`, `setup.ps1`, `windows/main.ps1`

```bash
# Track worst exit code across children
_worst_exit=0

_track_child() {
    local rc=$?
    if [[ $rc -gt $_worst_exit ]]; then
        _worst_exit=$rc
    fi
}

# Usage in parent (after every bash child.sh invocation)
bash "${LINUX_DIR}/install/apt.sh"
_track_child

bash "${INSTALL_DIR}/dev-env.sh"
_track_child
```

**Critical constraint:** `$?` MUST be captured immediately after the child command. Any intervening command clobbers it. The `_track_child` pattern ensures this.

**PowerShell equivalent:**
```powershell
$script:worstExit = 0

function Update-WorstExit {
    if ($LASTEXITCODE -gt $script:worstExit) {
        $script:worstExit = $LASTEXITCODE
    }
}

# After each child invocation
& "$WindowsDir/install/winget.ps1"
Update-WorstExit
```

**PowerShell caveat:** `$LASTEXITCODE` is only set by external programs and explicit `exit N` statements. Every PS child script MUST end with explicit `exit $code`, or `$LASTEXITCODE` retains a stale value.

**Confidence:** HIGH -- standard POSIX behavior and PowerShell docs.

### Pattern 4: safe_curl_sh() Helper

**What:** Download installer to temp file before executing. Prevents partial-download execution.
**Where:** `src/core/errors.sh` (alongside existing utilities)

```bash
# safe_curl_sh -- Download installer to temp file before executing.
# Prevents partial download execution (the most practical curl|sh risk).
# Usage: safe_curl_sh [curl_flags...] URL [-- script_args...]
safe_curl_sh() {
    local -a curl_flags=()
    local url=""
    local -a script_args=()
    local past_separator=false

    # Parse: flags before URL, URL is first non-flag, everything after -- is script args
    for arg in "$@"; do
        if [[ "$past_separator" == "true" ]]; then
            script_args+=("$arg")
        elif [[ "$arg" == "--" ]]; then
            past_separator=true
        elif [[ -z "$url" && "$arg" != -* ]]; then
            url="$arg"
        else
            curl_flags+=("$arg")
        fi
    done

    if [[ -z "$url" ]]; then
        log_error "safe_curl_sh: no URL provided"
        return 1
    fi

    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/installer-XXXXXX.sh")

    if ! curl "${curl_flags[@]}" -fsSL "$url" -o "$tmp"; then
        rm -f "$tmp"
        log_error "Failed to download: $url"
        return 1
    fi

    local rc=0
    bash "$tmp" "${script_args[@]}" || rc=$?

    rm -f "$tmp"
    return "$rc"
}
```

**Simpler alternative (recommended for KISS):**
```bash
# Minimal version -- caller passes curl flags inline
safe_curl_sh() {
    local url="$1"
    shift

    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/installer-XXXXXX.sh")

    if ! curl -fsSL "$url" -o "$tmp"; then
        rm -f "$tmp"
        log_error "Failed to download: $url"
        return 1
    fi

    local rc=0
    bash "$tmp" "$@" || rc=$?

    rm -f "$tmp"
    return "$rc"
}
```

**Trade-off:** The simpler version doesn't support passing custom curl flags (like `--proto '=https' --tlsv1.2` for rustup). The rustup call site would need special handling -- either a separate function or inline curl before calling `safe_curl_sh`. Given only 1 of 5 call sites needs custom curl flags, the simpler version is recommended with a special-case for rustup.

**Confidence:** HIGH -- verified pattern from research-curl-security.md and industry practice.

### Pattern 5: Cleanup Trap Separation (INT/TERM vs EXIT)

**What:** Separate signal traps from exit traps to preserve exit codes on Ctrl+C.
**Current problem:** The cleanup trap on `EXIT INT TERM` always runs, and in `setup.sh` it calls `exit 0`, overwriting the actual exit code.

```bash
# In errors.sh -- improved trap pattern
cleanup() {
    show_failure_summary
    cleanup_temp_dir

    # Compute and exit with semantic code
    compute_exit_code
    exit $?
}

# Signal handler for INT/TERM
signal_cleanup() {
    cleanup_temp_dir
    # 128 + signal number is the convention
    # INT=2, so exit 130
    exit 130
}

setup_error_handling() {
    create_temp_dir
    trap cleanup EXIT
    trap signal_cleanup INT TERM
}
```

**Key insight:** EXIT trap runs on ANY exit (normal, signal, explicit `exit N`). If INT/TERM also trigger `cleanup()` which calls `exit 0`, the EXIT trap fires again. Separating them avoids this.

**Confidence:** HIGH -- well-documented POSIX trap behavior.

### Anti-Patterns to Avoid

- **exit 0 in cleanup():** This is the root cause of the current problem. cleanup() must NEVER hardcode `exit 0`.
- **Reading FAILURE_LOG for exit code after cleanup_temp_dir:** The temp dir (and FAILURE_LOG inside it) gets deleted by cleanup. Read the failure state BEFORE cleaning up.
- **Forgetting explicit exit in PS scripts:** If a PowerShell script ends without `exit N`, `$LASTEXITCODE` retains a stale value from the last external command inside it.
- **Using `$?` after any intervening command:** `$?` gets overwritten by every command. Capture immediately: `bash script.sh; rc=$?`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Checksum verification for install scripts | SHA256 hash checking | Trust HTTPS transport | Upstreams don't publish stable checksums for scripts |
| GPG signature verification | Keyring management | Trust upstream reputation | Requires gpg binary, key rotation -- KISS violation |
| Script content caching/diffing | Content drift detection | Accept upstream changes | Maintenance burden, scripts change legitimately |
| Custom binary download pipeline | Per-tool download+verify | Let each tool's installer handle it | Different formats, platforms, architectures per tool |

**Key insight:** Every upstream installer (rustup, cargo-binstall, fnm, uv, ollama) relies solely on HTTPS transport security. None publishes stable checksums for their install scripts. Implementing verification the upstreams don't support is security theater.

## Common Pitfalls

### Pitfall 1: Trap Overwrites Exit Code
**What goes wrong:** `cleanup()` in `errors.sh` (line 168) and `setup.sh` (line 63) calls `exit 0` unconditionally, overwriting whatever exit code the script intended.
**Why it happens:** Original design (ADR-001) specified "always exit 0."
**How to avoid:** Replace `exit 0` with `compute_exit_code; exit $?` in cleanup functions. The setup.sh override must also be updated.
**Warning signs:** Script exits 0 even when FAILED_ITEMS has entries.

### Pitfall 2: $? Clobbered Between Command and Check
**What goes wrong:** Any command between `bash child.sh` and `$?` check resets the value.
**Why it happens:** `$?` reflects the most recent command, not the last "interesting" one.
**How to avoid:** Capture immediately: `bash child.sh; rc=$?` on the same logical line, or use the `_track_child` pattern that captures `$?` as its first action.
**Warning signs:** Parent always sees exit code 0 from children even when they fail.

### Pitfall 3: FAILURE_LOG Deleted Before Exit Code Computed
**What goes wrong:** `cleanup_temp_dir()` deletes `$TEMP_DIR` which contains `$FAILURE_LOG`. If `compute_exit_code()` runs after cleanup, it finds no log file and returns 0.
**Why it happens:** Ordering dependency in cleanup function.
**How to avoid:** In cleanup(), compute exit code BEFORE calling `cleanup_temp_dir()`. The sequence must be: (1) compute code, (2) show summary, (3) cleanup temp, (4) exit.
**Warning signs:** Exit code is always 0 despite failures logged during the run.

### Pitfall 4: PowerShell $LASTEXITCODE Stale Value
**What goes wrong:** If a PS child script finishes without explicit `exit N`, `$LASTEXITCODE` retains whatever value the last external command inside that script set.
**Why it happens:** PowerShell only updates `$LASTEXITCODE` from explicit `exit` or external programs.
**How to avoid:** Every PS child script MUST end with explicit `exit $exitCode`.
**Warning signs:** Parent sees random exit codes that don't correlate with actual failures.

### Pitfall 5: Signal Traps Masking Exit Code
**What goes wrong:** Ctrl+C triggers INT trap, which runs cleanup(), which calls `exit 0`. Convention is to exit 130 (128 + SIGINT=2) on Ctrl+C.
**Why it happens:** Single trap handles both EXIT and INT/TERM.
**How to avoid:** Separate EXIT trap from INT/TERM trap. INT/TERM should exit 130/143 respectively.
**Warning signs:** Ctrl+C appears as successful exit to parent process.

### Pitfall 6: DRY_RUN Contract for safe_curl_sh
**What goes wrong:** `safe_curl_sh()` could download and execute in dry-run mode.
**Why it happens:** The DRY_RUN guard is in each caller's `install_*()` function, not in the helper itself.
**How to avoid:** Keep DRY_RUN guard in the caller (existing pattern). The helper is a low-level utility that doesn't know about DRY_RUN. Callers already guard: `if [[ "${DRY_RUN:-}" == "true" ]]; then return 0; fi`.
**Warning signs:** curl downloads happen during --dry-run.

### Pitfall 7: Existing early exits (exit 1) in source-loading sections
**What goes wrong:** Many scripts have `exit 1` in their source-loading blocks (e.g., `source ... || exit 1`). These are pre-flight failures that should map to EXIT_CRITICAL=2.
**Why it happens:** The source-loading `exit 1` predates the semantic exit code system.
**How to avoid:** Decision: leave these as `exit 1` for now. They fire only when core modules are missing (broken installation). Changing them to `exit 2` is correct but cosmetic -- the planner can decide whether to include this or defer.
**Warning signs:** None -- these exits are extremely rare in practice.

## Code Examples

### Example 1: Child Script Exit Pattern (Bash)

```bash
# At the bottom of any child installer (apt.sh, snap.sh, etc.)
# BEFORE: exit 0
# AFTER:
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    exit "${EXIT_PARTIAL_FAILURE:-1}"
else
    exit "${EXIT_SUCCESS:-0}"
fi
```

Note: Uses `${EXIT_PARTIAL_FAILURE:-1}` as a safety fallback in case the constant isn't available (though it should always be, since errors.sh is sourced).

### Example 2: Parent Orchestrator Pattern (setup.sh)

```bash
# In setup.sh -- replace the cleanup function
_worst_exit=0

cleanup() {
    if [[ -z "${_SUMMARY_SHOWN:-}" ]]; then
        if [[ -n "${FAILURE_LOG:-}" && -f "$FAILURE_LOG" && -s "$FAILURE_LOG" ]]; then
            log_warn "Failures detected:"
            while IFS= read -r item; do
                echo "  - $item"
            done < "$FAILURE_LOG"
        else
            show_failure_summary
        fi
    fi
    cleanup_temp_dir
    exit "${_worst_exit:-0}"
}

# After dispatching to platform handler
bash "$linux_main" "$profile"
rc=$?
[[ $rc -gt $_worst_exit ]] && _worst_exit=$rc
```

### Example 3: Pre-flight Critical Exit (setup.sh)

```bash
# In setup.sh main() -- after verify_all
verify_all
if [[ $? -ne 0 ]]; then
    exit "${EXIT_CRITICAL:-2}"
fi
```

Note: `verify_all` already returns 1 on failure. The parent translates this to exit code 2.

### Example 4: safe_curl_sh Migration

```bash
# BEFORE (cargo.sh:56):
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# AFTER:
safe_curl_sh "https://sh.rustup.rs" -- -y
# Note: --proto and --tlsv1.2 are not needed -- safe_curl_sh uses -fsSL
# and rustup-init.sh itself enforces TLS when downloading the binary.
# However, if we want to preserve them, the flexible version supports it.

# BEFORE (fnm.sh:52):
curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

# AFTER:
safe_curl_sh "https://fnm.vercel.app/install" -- --skip-shell

# BEFORE (uv.sh:52):
curl -LsSf https://astral.sh/uv/install.sh | sh

# AFTER:
safe_curl_sh "https://astral.sh/uv/install.sh"

# BEFORE (ai-tools.sh:115):
curl -fsSL https://ollama.com/install.sh | sh

# AFTER:
safe_curl_sh "https://ollama.com/install.sh"

# BEFORE (cargo.sh:127-128):
curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

# AFTER:
safe_curl_sh "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh"
```

### Example 5: PowerShell Child Exit Pattern

```powershell
# At the bottom of any PS child installer (winget.ps1, cargo.ps1, etc.)
# BEFORE: exit 0
# AFTER:
Show-FailureSummary
$failCount = Get-FailureCount
if ($failCount -gt 0) {
    exit $script:EXIT_PARTIAL_FAILURE
} else {
    exit $script:EXIT_SUCCESS
}
```

### Example 6: PowerShell Parent Tracking

```powershell
# In main.ps1 and setup.ps1
$script:worstExit = 0

# After each child dispatch
& "$WindowsDir/install/winget.ps1"
if ($LASTEXITCODE -gt $script:worstExit) {
    $script:worstExit = $LASTEXITCODE
}

# At the end
exit $script:worstExit
```

## Definitive File Change List

### Bash -- Core Module Changes

| File | What Changes | Lines Affected |
|------|-------------|----------------|
| `src/core/errors.sh` | Add constants (EXIT_SUCCESS/PARTIAL_FAILURE/CRITICAL), add `compute_exit_code()`, add `safe_curl_sh()`, update `cleanup()` to use computed exit code, separate EXIT from INT/TERM trap, export new functions | ~40 lines added, ~10 lines changed |

### Bash -- Child Installer Scripts (exit 0 -> semantic exit)

| File | Current Exit | Change To | Line |
|------|-------------|-----------|------|
| `src/platforms/linux/install/apt.sh` | `exit 0` | Semantic exit based on FAILED_ITEMS | 164 |
| `src/platforms/linux/install/flatpak.sh` | `exit 0` | Same pattern | 162 |
| `src/platforms/linux/install/snap.sh` | `exit 0` | Same pattern | 152 |
| `src/platforms/linux/install/cargo.sh` | `exit 0` | Same pattern | 194 |
| `src/platforms/macos/install/brew.sh` | `exit 0` | Same pattern | 123 |
| `src/platforms/macos/install/brew-cask.sh` | `exit 0` | Same pattern | 132 |
| `src/install/ai-tools.sh` | `exit 0` | Same pattern | 284 |
| `src/install/dev-env.sh` | `exit 0` | Same pattern | 168 |
| `src/install/rust-cli.sh` | `exit 0` | Same pattern | 256 |
| `src/install/fnm.sh` | `exit 0` | Same pattern | 172 |
| `src/install/uv.sh` | `exit 0` | Same pattern | 117 |

### Bash -- Parent Orchestrators (capture + propagate worst code)

| File | Current Behavior | Change To |
|------|-----------------|-----------|
| `setup.sh` | cleanup() overrides exit 0 (line 63) | Track worst child exit code, exit with worst |
| `src/platforms/linux/main.sh` | `exit $?` from install_profile (line 216) | Track worst child code inside install_profile, propagate |
| `src/platforms/macos/main.sh` | `exit $?` from install_profile (line 230) | Same pattern |

### Bash -- Pre-flight Critical Exit

| File | Current Behavior | Change To |
|------|-----------------|-----------|
| `setup.sh` | `verify_all` return is not checked for exit code | If verify_all fails, exit EXIT_CRITICAL (2) |

### Bash -- curl|sh Migration Sites

| File | Line | Current | After |
|------|------|---------|-------|
| `src/platforms/linux/install/cargo.sh` | 56 | `curl ... \| sh -s -- -y` (rustup) | `safe_curl_sh "https://sh.rustup.rs" -- -y` |
| `src/platforms/linux/install/cargo.sh` | 127-128 | `curl ... \| bash` (cargo-binstall) | `safe_curl_sh "URL"` |
| `src/install/fnm.sh` | 52 | `curl ... \| bash -s -- --skip-shell` | `safe_curl_sh "URL" -- --skip-shell` |
| `src/install/uv.sh` | 52 | `curl ... \| sh` | `safe_curl_sh "URL"` |
| `src/install/ai-tools.sh` | 115 | `curl ... \| sh` (ollama) | `safe_curl_sh "URL"` |

### PowerShell -- Core Module Changes

| File | What Changes |
|------|-------------|
| `src/platforms/windows/core/errors.psm1` | Add `$EXIT_SUCCESS`, `$EXIT_PARTIAL_FAILURE`, `$EXIT_CRITICAL` constants. Add `Get-ExitCode` function. Export constants and function. |

### PowerShell -- Child Scripts

| File | Current | Change To | Line |
|------|---------|-----------|------|
| `src/platforms/windows/install/winget.ps1` | `exit 0` | Semantic exit via Get-FailureCount | 101 |
| `src/platforms/windows/install/cargo.ps1` | `exit 0` | Same pattern | 183 |
| `src/platforms/windows/install/npm.ps1` | `exit 0` | Same pattern | 106 |
| `src/platforms/windows/install/ai-tools.ps1` | `exit 0` | Same pattern | 181 |

### PowerShell -- Parent Orchestrators

| File | Current | Change To |
|------|---------|-----------|
| `setup.ps1` | `exit 0` (line 85) | Track worst child exit, exit with worst |
| `src/platforms/windows/main.ps1` | `exit 0` (line 122) | Same pattern |

### Documentation

| File | What Changes |
|------|-------------|
| `.planning/adrs/ADR-001-error-resilience.md` | Amend "All scripts exit 0" to describe semantic exit codes while preserving continue-on-failure intent |
| `.planning/adrs/ADR-009-curl-trust-model.md` | New ADR documenting curl|sh trust model: HTTPS-only, download-then-execute, no checksum |

### Tests

| File | What Changes |
|------|-------------|
| `tests/test-core-errors.bats` | Add tests for: exit code constants exist and have correct values, `compute_exit_code` returns 0 when FAILED_ITEMS empty, `compute_exit_code` returns 1 when FAILED_ITEMS has entries, `safe_curl_sh` function exists and is exported |

## What Does NOT Change

These are important "do not touch" boundaries:

- **`set -e` is still NOT used** -- ADR-001 is preserved
- **`record_failure()` / `Add-FailedItem` calls** -- unchanged, already correct
- **`FAILURE_LOG` cross-process mechanism** -- unchanged, already correct
- **`show_failure_summary()` / `Show-FailureSummary`** -- unchanged, still runs
- **Interactive behavior** -- user still sees the same output
- **Script continues on failure** -- no early abort on package failures
- **DRY_RUN logic** -- unchanged, each caller handles it
- **Profile system** -- unchanged
- **Package data files** -- unchanged

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `exit 0` always | Semantic exit codes (0/1/2) | This phase | Automation callers can distinguish success from failure |
| `curl URL \| sh` | Download-then-execute (`safe_curl_sh`) | This phase | Prevents partial download execution |
| Undocumented trust model | ADR-009 documents HTTPS-only decision | This phase | Explicit risk acknowledgment, audit trail |

## Recommended Plan Split

### Plan 01: Exit Codes (EXIT-01, EXIT-02)

1. Add constants and `compute_exit_code()` to `errors.sh`
2. Add constants and `Get-ExitCode` to `errors.psm1`
3. Update `cleanup()` in `errors.sh` (separate EXIT from INT/TERM)
4. Update `setup.sh` cleanup override and add worst-code tracking
5. Update all 11 Bash child scripts (exit 0 -> semantic)
6. Update `linux/main.sh` and `macos/main.sh` with worst-code tracking
7. Update all 4 PowerShell child scripts
8. Update `setup.ps1` and `windows/main.ps1` with worst-code tracking
9. Amend ADR-001
10. Update `tests/test-core-errors.bats`

### Plan 02: Security (SEC-01, SEC-02)

1. Add `safe_curl_sh()` function to `errors.sh`
2. Migrate 5 curl|sh call sites
3. Write ADR-009
4. Test safe_curl_sh (bats test)

## Open Questions

1. **Where should `safe_curl_sh()` live?**
   - Option A: `src/core/errors.sh` (alongside existing utilities) -- simplest, no new file
   - Option B: New `src/core/network.sh` -- cleaner separation of concerns
   - **Recommendation:** Option A (KISS -- errors.sh is already the "utility" module, and adding a new module means updating all source chains)

2. **Should source-loading `exit 1` become `exit 2`?**
   - These are pre-flight failures (missing core modules = broken installation)
   - Semantically, they ARE critical failures (code 2)
   - But they are extremely rare and changing them is cosmetic
   - **Recommendation:** Defer -- address only if time permits. The main exit code value is at the end-of-script points.

3. **Should `--dry-run` always exit 0?**
   - Dry run never actually installs anything, so there are no real failures
   - But if data files are missing (pre-flight error), it should still signal failure
   - **Recommendation:** Yes, dry-run exits 0 unless pre-flight checks fail (then exit 2)

4. **How should the `rustup` call handle `--proto '=https' --tlsv1.2`?**
   - rustup-init.sh itself enforces TLS when downloading the binary
   - The `--proto` flags on the outer curl are belt-and-suspenders
   - **Recommendation:** Keep them by passing them to `safe_curl_sh` or by using the flexible version. Alternatively, since `safe_curl_sh` uses `-fsSL` and HTTPS URL, the TLS enforcement is implicit. Document the decision.

## Sources

### Primary (HIGH confidence -- direct codebase inspection)
- `src/core/errors.sh` -- current cleanup trap, FAILED_ITEMS tracking, line 168 exit 0
- `src/core/platform.sh` -- verify_all() returns 1 on pre-flight failure
- `src/platforms/windows/core/errors.psm1` -- Get-FailureCount, Add-FailedItem
- `setup.sh` -- cleanup trap override on line 51-64, always exits 0
- `setup.ps1` -- always exits 0 on line 85
- All 11 Bash child installer scripts -- all hardcoded to exit 0
- All 4 PowerShell child installer scripts -- all hardcoded to exit 0
- `.planning/adrs/ADR-001-error-resilience.md` -- "All scripts exit 0" on line 20
- `tests/test-core-errors.bats` -- existing 10 tests for errors.sh

### Primary (HIGH confidence -- prior research)
- `.planning/phases/research-exit-codes.md` -- dated 2026-02-19, verified against POSIX spec and codebase
- `.planning/phases/research-curl-security.md` -- dated 2026-02-19, verified against upstream repos

### Primary (HIGH confidence -- specifications)
- [TLDP Exit Codes with Special Meanings](https://tldp.org/LDP/abs/html/exitcodes.html)
- [BSD sysexits(3) man page](https://man.freebsd.org/cgi/man.cgi?query=sysexits)
- [POSIX Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)

### Secondary (MEDIUM confidence)
- [PowerShell $LASTEXITCODE behavior](https://christosmonogios.com/2025/04/22/understanding-the-lastexitcode-and-exit-codes-in-powershell/)
- [thoughtbot/laptop](https://github.com/thoughtbot/laptop) -- curl|sh with no verification (industry norm)

## Metadata

**Confidence breakdown:**
- Exit code scheme: HIGH -- POSIX spec, codebase verified, prior research confirmed
- File change list: HIGH -- every file inspected, every exit point catalogued
- curl|sh mitigation: HIGH -- upstream repos checked, industry patterns verified
- Architecture patterns: HIGH -- builds on existing infrastructure, no new dependencies
- Pitfalls: HIGH -- derived from direct codebase analysis of current behavior

**Research date:** 2026-02-21
**Valid until:** 2026-05-21 (stable domain -- POSIX exit codes don't change)
