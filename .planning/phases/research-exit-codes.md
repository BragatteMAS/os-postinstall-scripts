# Research: Semantic Exit Codes

**Researched:** 2026-02-19
**Domain:** Shell/PowerShell exit code conventions, cross-process failure propagation
**Confidence:** HIGH

## Summary

The project currently follows ADR-001 "continue on failure" where **every script exits 0 regardless of outcome**. This was a sound decision for interactive use (user sees summary, script never aborts mid-run), but 5 specialist reviewers flagged it HIGH severity because automation callers (wrapper scripts, `&&` chains, monitoring) cannot distinguish "100/100 installed" from "0/100 installed" -- both return exit 0.

The fix is minimal. The failure tracking infrastructure (`FAILED_ITEMS[]`, `FAILURE_LOG`, `get_failure_count`, `Get-FailureCount`) already exists in both Bash and PowerShell. The only change is converting the final `exit 0` statements to `exit $code` where `$code` is derived from the failure state. No behavioral change for the continue-on-failure strategy itself -- scripts still run to completion, still show summaries, still track failures. The only difference: the exit code now tells callers what happened.

**Primary recommendation:** Three exit codes: `0` = all success, `1` = partial failure (some items failed but run completed), `2` = critical pre-flight failure (cannot proceed at all). Define these as constants in errors.sh / errors.psm1 and change ~12 exit points across the codebase.

---

## 1. Standard Exit Code Conventions

### POSIX/Unix Standards

| Code | POSIX Meaning | Project Mapping |
|------|---------------|-----------------|
| 0 | Success | All packages/operations succeeded |
| 1 | General error | Partial failure -- some packages failed |
| 2 | Shell builtin misuse | Critical pre-flight failure (no internet, no sudo, bad platform) |
| 126 | Command not executable | (reserved -- do not use) |
| 127 | Command not found | (reserved -- do not use) |
| 128+N | Killed by signal N | (reserved -- do not use) |
| 130 | Ctrl+C (SIGINT) | (reserved -- handled by trap) |

**Safe custom range:** BSD `sysexits.h` defines codes 64-78 for specific conditions (EX_USAGE=64, EX_UNAVAILABLE=69, EX_NOPERM=77, EX_CONFIG=78). However, for a **post-install script** (not a library), keeping to 0/1/2 is the pragmatic choice. Automation callers universally understand `0 = ok, non-zero = problem`. Few parse specific codes beyond that.

**Precedent from well-known tools:**
- **rsync**: 0=success, 23=partial transfer (some files failed), 24=partial transfer (vanished source files)
- **ansible**: 0=success, 2=run failed on some hosts, 4=unreachable hosts
- **grep**: 0=found, 1=not found, 2=error
- **curl**: 0=success, various non-zero for specific failures

**Confidence:** HIGH -- based on POSIX spec, TLDP exit codes reference, and BSD sysexits.h man pages.

Sources:
- [TLDP Exit Codes with Special Meanings](https://tldp.org/LDP/abs/html/exitcodes.html)
- [Baeldung Standard Exit Status Codes](https://www.baeldung.com/linux/status-codes)
- [BSD sysexits man page](https://man.freebsd.org/cgi/man.cgi?query=sysexits)

### PowerShell Conventions

| Mechanism | Behavior |
|-----------|----------|
| `exit 0` | Sets process exit code to 0 |
| `exit N` | Sets process exit code to N |
| `$LASTEXITCODE` | Holds exit code of last external program |
| `$?` | Boolean: did last command succeed? |
| `$ErrorActionPreference = 'Continue'` | Equivalent to project's "continue on failure" |

PowerShell uses the same 0=success, non-zero=failure convention. `exit N` from a `.ps1` script propagates to the calling process via `$LASTEXITCODE`. The project already uses `$ErrorActionPreference = 'Continue'` which mirrors ADR-001.

**Confidence:** HIGH -- based on official PowerShell docs and GitHub issues.

Sources:
- [Understanding $LASTEXITCODE in PowerShell](https://christosmonogios.com/2025/04/22/understanding-the-lastexitcode-and-exit-codes-in-powershell/)
- [ManageEngine PowerShell Exit Codes](https://www.manageengine.com/products/desktop-central/returning-error-code-on-scripts-how-to.html)

---

## 2. How Similar Projects Handle This

### thoughtbot/laptop
- Uses `set -e` (fail-fast on first error)
- Trap handler: `trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT`
- **No partial failure handling** -- either completes fully or exits with error
- Not applicable to this project's "continue on failure" strategy

### Dotfiles managers (chezmoi, yadm, rcm)
- Typically fail-fast since they manage config files, not package installs
- Less relevant -- package installation is inherently more failure-tolerant

### Key insight
No popular post-install script project uses a 3-tier exit code system. Most use `set -e` (binary pass/fail). This project's "continue on failure + structured tracking" is actually more sophisticated. Adding semantic exit codes is the missing final piece that makes the tracking useful to automation.

**Confidence:** MEDIUM -- based on thoughtbot/laptop source inspection and general ecosystem knowledge.

Sources:
- [thoughtbot/laptop](https://github.com/thoughtbot/laptop)
- [thoughtbot Shell Script Suggestions](https://thoughtbot.com/blog/shell-script-suggestions-for-speedy-setups)

---

## 3. Recommended Exit Code Scheme

### Three Codes (Minimal, Complete)

```bash
# In errors.sh -- define as constants
readonly EXIT_SUCCESS=0         # All operations completed successfully
readonly EXIT_PARTIAL_FAILURE=1 # Run completed, but some items failed
readonly EXIT_CRITICAL=2        # Pre-flight check failed, cannot proceed
```

```powershell
# In errors.psm1 -- define as constants
$script:EXIT_SUCCESS = 0         # All operations completed successfully
$script:EXIT_PARTIAL_FAILURE = 1 # Run completed, but some items failed
$script:EXIT_CRITICAL = 2        # Pre-flight check failed, cannot proceed
```

### Why These Three

| Code | When | Example Scenarios |
|------|------|-------------------|
| 0 | Every tracked operation succeeded | All APT packages installed, all brew formulas installed |
| 1 | Run completed but FAILURE_LOG has entries | 3 of 50 APT packages failed, 1 snap not available |
| 2 | Pre-flight abort before any installation | No internet, no sudo, unsupported platform, missing package manager |

**Why not more codes?** Automation callers almost never switch on specific codes beyond `== 0` / `!= 0`. Two non-zero codes (recoverable vs. critical) is the sweet spot. More granularity belongs in the failure log and stderr output, not exit codes.

**Why 1 for partial (not a higher number)?** Code 1 is the universal "something went wrong" in Unix. Using it for partial failure is natural -- callers that just check `!= 0` get the right behavior. Code 2 for "misuse/critical" follows the POSIX convention for shell builtin errors and clearly separates "script ran but had problems" from "script could not run at all."

**Confidence:** HIGH -- this maps directly to POSIX conventions and the project's existing infrastructure.

---

## 4. Exit Code Propagation: Current State and Required Changes

### Bash: `bash script.sh` Subshell Pattern

The project invokes child scripts as separate processes:
```bash
# In linux/main.sh and macos/main.sh
bash "${LINUX_DIR}/install/apt.sh"
bash "${INSTALL_DIR}/dev-env.sh"
```

**Current behavior:** Child exits 0 (hardcoded). Parent ignores return code (no `$?` check after most calls).

**Required change:** Each child script must:
1. Exit with semantic code based on its own `FAILED_ITEMS` count
2. Write failures to `$FAILURE_LOG` (already done)

Parent script must:
1. Capture child exit code via `$?`
2. Track the worst exit code seen across all children
3. Exit with that worst code

**Pattern:**
```bash
# Define in errors.sh
compute_exit_code() {
    local fail_count
    if [[ -n "${FAILURE_LOG:-}" && -f "$FAILURE_LOG" ]]; then
        fail_count=$(wc -l < "$FAILURE_LOG" | tr -d ' ')
    else
        fail_count=${#FAILED_ITEMS[@]}
    fi

    if [[ "$fail_count" -gt 0 ]]; then
        return $EXIT_PARTIAL_FAILURE
    fi
    return $EXIT_SUCCESS
}
```

```bash
# In cleanup() or at script end
cleanup() {
    show_failure_summary
    cleanup_temp_dir

    local code=$EXIT_SUCCESS
    compute_exit_code
    code=$?

    exit $code
}
```

**For parent orchestrators (setup.sh, main.sh):**
```bash
# Track worst exit code across children
_worst_exit=0

run_child() {
    bash "$1" "${@:2}"
    local rc=$?
    if [[ $rc -gt $_worst_exit ]]; then
        _worst_exit=$rc
    fi
}

# Usage
run_child "${LINUX_DIR}/install/apt.sh"
run_child "${INSTALL_DIR}/dev-env.sh"

# At end
exit $_worst_exit
```

**Key constraint:** `$?` must be captured immediately after the child command. Any command between the child and `$?` overwrites it.

**Confidence:** HIGH -- standard POSIX behavior, verified with multiple sources.

Sources:
- [CravenCode: Exit from Subshell](https://cravencode.com/post/essentials/exit-shell-script-from-subshell/)
- [Baeldung: Exit Shell Script from Subshell](https://www.baeldung.com/linux/exit-shell-script-subshell)

### PowerShell: `& script.ps1` Invocation Pattern

The project invokes child scripts as:
```powershell
# In windows/main.ps1
& "$WindowsDir/install/winget.ps1"
```

**Current behavior:** Child scripts exit 0 (hardcoded). Parent does not check `$LASTEXITCODE`.

**Required change:**
```powershell
# In child scripts (winget.ps1, cargo.ps1, etc.)
$failCount = Get-FailureCount
if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
```

```powershell
# In parent (main.ps1)
$worstExit = 0

function Invoke-ChildScript {
    param([string]$Path)
    & $Path
    if ($LASTEXITCODE -gt $worstExit) {
        $script:worstExit = $LASTEXITCODE
    }
}

# At end
exit $worstExit
```

**Important caveat:** `$LASTEXITCODE` is only set by external programs and `exit` statements. If a child script finishes without an explicit `exit`, `$LASTEXITCODE` may retain a stale value. Always use explicit `exit N` in child scripts.

**Confidence:** HIGH -- verified behavior per PowerShell documentation.

---

## 5. Files Requiring Changes

### Definitive List (12 exit points)

**Bash -- define constants + compute function:**
| File | Current Exit | Change To |
|------|-------------|-----------|
| `src/core/errors.sh` | `exit 0` (in cleanup trap) | `exit $(compute_exit_code)` + add constants + `compute_exit_code()` |

**Bash -- child installer scripts (exit semantic code):**
| File | Current Exit | Change To |
|------|-------------|-----------|
| `src/platforms/linux/install/apt.sh` | `exit 0` (line 163) | `exit based on FAILED_ITEMS count` |
| `src/platforms/linux/install/flatpak.sh` | `exit 0` | same pattern |
| `src/platforms/linux/install/snap.sh` | `exit 0` | same pattern |
| `src/platforms/linux/install/cargo.sh` | `exit 0` | same pattern |
| `src/platforms/macos/install/brew.sh` | `exit 0` | same pattern |
| `src/platforms/macos/install/brew-cask.sh` | `exit 0` | same pattern |
| `src/install/ai-tools.sh` | `exit 0` | same pattern |
| `src/install/dev-env.sh` | `exit 0` | same pattern |
| `src/install/rust-cli.sh` | `exit 0` | same pattern |

**Bash -- parent orchestrators (capture + propagate worst code):**
| File | Current Behavior | Change To |
|------|-----------------|-----------|
| `setup.sh` | `exit 0` in cleanup trap | Capture child exit codes, exit with worst |
| `src/platforms/linux/main.sh` | `exit $?` from install_profile | Capture child exit codes, exit with worst |
| `src/platforms/macos/main.sh` | `exit $?` from install_profile | Capture child exit codes, exit with worst |

**Bash -- pre-flight failures (already return 1, but parent must react):**
| File | Current Behavior | Change Needed |
|------|-----------------|---------------|
| `src/core/platform.sh` | `verify_all()` returns 1 | Parent (`setup.sh`) must exit 2 when verify_all fails |

**PowerShell -- define constants:**
| File | Change |
|------|--------|
| `src/platforms/windows/core/errors.psm1` | Add `$EXIT_SUCCESS`, `$EXIT_PARTIAL_FAILURE`, `$EXIT_CRITICAL` constants |

**PowerShell -- child scripts:**
| File | Current Exit | Change To |
|------|-------------|-----------|
| `src/platforms/windows/install/winget.ps1` | `exit 0` | `exit based on Get-FailureCount` |
| `src/platforms/windows/install/cargo.ps1` | `exit 0` | same pattern |
| `src/platforms/windows/install/npm.ps1` | `exit 0` | same pattern |
| `src/platforms/windows/install/ai-tools.ps1` | `exit 0` | same pattern |

**PowerShell -- parent orchestrators:**
| File | Current Behavior | Change To |
|------|-----------------|-----------|
| `setup.ps1` | `exit 0` | Capture child exit codes, exit with worst |
| `src/platforms/windows/main.ps1` | `exit 0` | Capture child exit codes, exit with worst |

### What Does NOT Change

- **`set -e` is still NOT used** -- ADR-001 is preserved
- **`record_failure()` / `Add-FailedItem` calls** -- unchanged, already correct
- **`FAILURE_LOG` cross-process mechanism** -- unchanged, already correct
- **`show_failure_summary()` / `Show-FailureSummary`** -- unchanged, still runs
- **Interactive behavior** -- user still sees the same output
- **Script continues on failure** -- no early abort on package failures

---

## 6. ADR-001 Amendment

ADR-001 line "All scripts exit 0 regardless of individual package failures" must be amended. Suggested replacement:

> All scripts run to completion regardless of individual package failures. Exit codes reflect outcome: 0 = all succeeded, 1 = partial failure (some items failed), 2 = critical pre-flight failure. The "continue on failure" strategy is preserved -- scripts never abort mid-run due to a single package failure.

This preserves the **intent** of ADR-001 (never abort mid-run) while fixing the **exit code masking** problem.

---

## 7. Common Pitfalls

### Pitfall 1: Trap Overwrites Exit Code
**What goes wrong:** The `cleanup()` trap function runs on EXIT. If it calls `exit 0` unconditionally, it overwrites whatever code the script tried to exit with.
**Current state:** This is exactly what happens in `errors.sh` line 168 (`exit 0` in cleanup).
**Fix:** Replace `exit 0` with `exit $(compute_exit_code)` or capture the intended code before entering cleanup.

### Pitfall 2: `$?` Clobbered Between Command and Check
**What goes wrong:** Any command between the child process and `$?` check resets `$?`.
**Fix:** Always capture immediately: `bash script.sh; rc=$?`

### Pitfall 3: FAILURE_LOG Read Before Children Write
**What goes wrong:** Parent reads `FAILURE_LOG` to compute exit code before all children have flushed writes.
**Current state:** Not an issue -- children run sequentially (not backgrounded), so log is complete when parent reads.

### Pitfall 4: PowerShell `$LASTEXITCODE` Stale Value
**What goes wrong:** If a PS child script finishes without explicit `exit`, `$LASTEXITCODE` retains the value from the last external command inside that script.
**Fix:** Every PS child script must end with explicit `exit $code`.

### Pitfall 5: Signal Traps Masking Exit Code
**What goes wrong:** When user presses Ctrl+C, the trap runs cleanup which force-exits 0.
**Fix:** Ctrl+C should exit 130 (128 + SIGINT=2). Separate the INT/TERM trap from the EXIT trap, or check the signal in cleanup.

---

## 8. Testing Strategy

### Verification Points

1. **Clean run**: `./setup.sh --dry-run developer` -- should exit 0 (dry run installs nothing, records no failures)
2. **Partial failure simulation**: Manually add a nonexistent package to `apt.txt`, run `./setup.sh developer` -- should exit 1
3. **Pre-flight failure**: Disconnect internet, run `./setup.sh` in unattended mode -- should exit 2
4. **Exit code in chain**: `./setup.sh && echo "all good" || echo "something failed"` -- verify correct branch taken
5. **PowerShell**: `.\setup.ps1 -DryRun; $LASTEXITCODE` -- should print 0

### Existing Tests to Update

The bats tests in `tests/` test `errors.sh` functions. Add tests for:
- `compute_exit_code` returns 0 when `FAILED_ITEMS` is empty
- `compute_exit_code` returns 1 when `FAILED_ITEMS` has entries
- Exit code constants are exported and have correct values

---

## 9. Open Questions

1. **Should `--dry-run` always exit 0?** Likely yes -- dry run never actually fails. But if package data files are missing (pre-flight error), it should still exit 2.

2. **Should individual installer scripts (apt.sh, brew.sh) exit 2 for their own critical failures?** Example: apt.sh cannot load package file. Currently exits 1 (`exit 1` on line 135). This could become exit 2 since it is a "cannot proceed" condition for that installer. However, the parent orchestrator treats per-installer failures as partial (code 1), not critical (code 2). Recommend: keep child scripts using only 0/1, reserve code 2 for top-level pre-flight checks only.

3. **What about `homebrew.sh`?** macOS main.sh already does `bash "${MACOS_DIR}/install/homebrew.sh" || return 1` -- Homebrew failure is treated as a blocker. This should map to exit 2 at the setup.sh level since without Homebrew, nothing else works on macOS.

---

## Sources

### Primary (HIGH confidence)
- [TLDP Exit Codes with Special Meanings](https://tldp.org/LDP/abs/html/exitcodes.html)
- [Baeldung Standard Exit Status Codes in Linux](https://www.baeldung.com/linux/status-codes)
- [BSD sysexits(3) man page](https://man.freebsd.org/cgi/man.cgi?query=sysexits)
- [Understanding $LASTEXITCODE in PowerShell](https://christosmonogios.com/2025/04/22/understanding-the-lastexitcode-and-exit-codes-in-powershell/)

### Secondary (MEDIUM confidence)
- [thoughtbot/laptop source](https://github.com/thoughtbot/laptop)
- [CravenCode: Exit Shell Script from Subshell](https://cravencode.com/post/essentials/exit-shell-script-from-subshell/)
- [Baeldung: Exit Shell Script from Subshell](https://www.baeldung.com/linux/exit-shell-script-subshell/)

### Codebase (HIGH confidence -- direct inspection)
- `src/core/errors.sh` -- current cleanup trap, FAILED_ITEMS tracking
- `src/core/platform.sh` -- verify_all() returns 1 on pre-flight failure
- `src/platforms/windows/core/errors.psm1` -- Get-FailureCount, Add-FailedItem
- `setup.sh` -- cleanup trap overrides errors.sh, always exits 0
- `setup.ps1` -- always exits 0
- All 9 child installer scripts -- all hardcoded to exit 0
