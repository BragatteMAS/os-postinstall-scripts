---
phase: 16-exit-codes-security
verified: 2026-02-21T20:18:04Z
status: passed
score: 7/7 must-haves verified
re_verification: false
gaps: []
human_verification: []
---

# Phase 16: Exit Codes and Security Verification Report

**Phase Goal:** Replace universal `exit 0` with semantic exit codes (0/1/2), propagate through parent-child chain, add download-then-execute helper for curl|sh, document trust model in ADR-009
**Verified:** 2026-02-21T20:18:04Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | EXIT_SUCCESS=0, EXIT_PARTIAL_FAILURE=1, EXIT_CRITICAL=2 constants defined in errors.sh and errors.psm1 | VERIFIED | Lines 18-20 in errors.sh; lines 20-22 in errors.psm1 |
| 2 | compute_exit_code() returns 0 with no failures, 1 with failures | VERIFIED | Function at line 132 in errors.sh; reads FAILURE_LOG then FAILED_ITEMS; returns EXIT_PARTIAL_FAILURE or EXIT_SUCCESS |
| 3 | All 9 child installer scripts exit with semantic code (not hardcoded 0) | VERIFIED | All 11 Bash children (9 original + fnm.sh + uv.sh) use EXIT_PARTIAL_FAILURE:-1 / EXIT_SUCCESS:-0 pattern at end |
| 4 | Parent orchestrators (setup.sh, main.sh, main.ps1) track worst exit code from children | VERIFIED | _worst_exit in setup.sh (line 51), linux/main.sh (line 57), macos/main.sh (line 57); $script:worstExit in setup.ps1 (line 61) and windows/main.ps1 (line 28) |
| 5 | safe_curl_sh() helper in src/core/ downloads to temp file before executing (5 call sites migrated) | VERIFIED | Function at line 216 in errors.sh; 5 call sites confirmed: cargo.sh (2), fnm.sh (1), uv.sh (1), ai-tools.sh (1); no curl-pipe patterns remain |
| 6 | ADR-009 documents curl|sh trust model (HTTPS-only, no checksum) | VERIFIED | .planning/adrs/ADR-009-curl-trust-model.md exists; documents HTTPS-only, download-then-execute, explicit no-checksum reasoning |
| 7 | ADR-001 amended to reflect semantic exit codes (preserving continue-on-failure intent) | VERIFIED | Status: "Amended", Amended: 2026-02-21, Amendment Phase: 16; section at line 47 |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `src/core/errors.sh` | EXIT_SUCCESS/PARTIAL_FAILURE/CRITICAL constants and compute_exit_code(), safe_curl_sh() | VERIFIED | All constants at lines 18-20; compute_exit_code() at line 132; safe_curl_sh() at line 216; all exported |
| `src/platforms/windows/core/errors.psm1` | PS exit constants and Get-ExitCode function | VERIFIED | $script:EXIT_SUCCESS/EXIT_PARTIAL_FAILURE/EXIT_CRITICAL at lines 20-22; Get-ExitCode() at line 86; exported via Export-ModuleMember |
| `.planning/adrs/ADR-009-curl-trust-model.md` | HTTPS-only curl trust model documentation | VERIFIED | File exists; documents download-then-execute, HTTPS-only, no-checksum with explicit reasoning; 5 call sites listed |
| `.planning/adrs/ADR-001-error-resilience.md` | Amended ADR with semantic exit codes section | VERIFIED | Status "Amended"; Amendment Phase 16; section documents 0/1/2 codes and preserved continue-on-failure |
| `tests/test-core-errors.bats` | Tests for exit constants, compute_exit_code, safe_curl_sh | VERIFIED | 16 total tests: EXIT_SUCCESS/PARTIAL_FAILURE/CRITICAL constant checks, compute_exit_code 0/1 cases, safe_curl_sh export check and no-URL failure |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| src/core/errors.sh | all 11 child Bash scripts | EXIT_PARTIAL_FAILURE constants sourced by children | WIRED | All 11 scripts use EXIT_PARTIAL_FAILURE:-1 / EXIT_SUCCESS:-0 fallback syntax |
| setup.sh | linux/main.sh or macos/main.sh | _worst_exit tracking after bash child invocation | WIRED | _worst_exit set at line 51; rc captured and compared after each platform dispatch |
| src/core/errors.sh cleanup() | compute_exit_code() | cleanup calls compute_exit_code BEFORE cleanup_temp_dir | WIRED | Lines 184-187: compute_exit_code, capture $?, cleanup_temp_dir, exit with code |
| src/platforms/linux/install/cargo.sh | safe_curl_sh() | replaces curl-pipe for rustup and cargo-binstall | WIRED | Line 56: safe_curl_sh "https://sh.rustup.rs" -- -y; line 127: safe_curl_sh for cargo-binstall |
| src/install/fnm.sh | safe_curl_sh() | replaces curl-bash for fnm installer | WIRED | Line 52: safe_curl_sh "https://fnm.vercel.app/install" -- --skip-shell |
| src/install/ai-tools.sh | safe_curl_sh() | replaces curl-sh for ollama installer | WIRED | Line 115: safe_curl_sh "https://ollama.com/install.sh" |
| src/install/uv.sh | safe_curl_sh() | replaces curl-sh for uv installer | WIRED | Line 52: safe_curl_sh "https://astral.sh/uv/install.sh" |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| Semantic exit codes 0/1/2 in core modules | SATISFIED | — |
| compute_exit_code() returns correct codes | SATISFIED | — |
| All child scripts use semantic exit | SATISFIED | — |
| Parent orchestrators propagate worst exit | SATISFIED | All 5 orchestrators (3 Bash + 2 PS) verified |
| safe_curl_sh() with 5 call sites migrated | SATISFIED | — |
| ADR-009 curl trust model documented | SATISFIED | — |
| ADR-001 amended with semantic exit codes | SATISFIED | — |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No stubs, placeholders, or empty implementations detected. All implementations are substantive.

### Human Verification Required

None. All success criteria are verifiable programmatically.

### Gaps Summary

No gaps. All 7 success criteria are fully implemented and wired in the actual codebase.

---

## Verification Detail

### SC1: Exit Code Constants

`src/core/errors.sh` lines 18-20:
```bash
readonly EXIT_SUCCESS=0
readonly EXIT_PARTIAL_FAILURE=1
readonly EXIT_CRITICAL=2
```

`src/platforms/windows/core/errors.psm1` lines 20-22:
```powershell
$script:EXIT_SUCCESS = 0
$script:EXIT_PARTIAL_FAILURE = 1
$script:EXIT_CRITICAL = 2
```

Both exported: `export EXIT_SUCCESS EXIT_PARTIAL_FAILURE EXIT_CRITICAL` and `Export-ModuleMember ... -Variable EXIT_SUCCESS, EXIT_PARTIAL_FAILURE, EXIT_CRITICAL`.

### SC2: compute_exit_code()

Function reads FAILURE_LOG (cross-process) first, falls back to FAILED_ITEMS array. Called in cleanup() BEFORE cleanup_temp_dir() so the log file is still available. Returns EXIT_PARTIAL_FAILURE (1) if fail_count > 0, EXIT_SUCCESS (0) otherwise.

### SC3: Child Scripts (11 verified, roadmap says 9)

All 11 Bash child scripts use:
```bash
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    exit "${EXIT_PARTIAL_FAILURE:-1}"
else
    exit "${EXIT_SUCCESS:-0}"
fi
```

The plan notes the roadmap SC says "9" but the actual count is 11 (fnm.sh and uv.sh use it in their main guard, not at the bottom-of-file like the others). All verified.

PowerShell children (4 files) use:
```powershell
$exitCode = Get-ExitCode
exit $exitCode
```

### SC4: Parent Orchestrators

- `setup.sh`: `_worst_exit=0` at line 51; tracks per-platform dispatch; cleanup exits with `${_worst_exit:-0}`
- `src/platforms/linux/main.sh`: `_worst_exit=0` at line 57; `rc=$?; [[ $rc -gt $_worst_exit ]] && _worst_exit=$rc` after each child bash call; returns `$_worst_exit`
- `src/platforms/macos/main.sh`: Same pattern; 7 tracking points visible
- `setup.ps1`: `$script:worstExit = 0` at line 61; `if ($LASTEXITCODE -gt $script:worstExit) { $script:worstExit = $LASTEXITCODE }` at line 75; `exit $script:worstExit` at line 89
- `src/platforms/windows/main.ps1`: `$script:worstExit = 0` at line 28; 4 tracking points; `exit $script:worstExit` at line 129

### SC5: safe_curl_sh() — Download-Then-Execute

Function in `src/core/errors.sh` at line 216. Uses mktemp for temp file. Removes temp file on download failure (line 230). Runs `bash "$tmp" "$@"` capturing rc. Removes temp file after execution (line 237). Returns rc of downloaded script. Exported via `export -f safe_curl_sh`.

5 call sites confirmed with no curl-pipe patterns remaining. Comments in errors.sh mentioning "curl|sh" are documentation, not code.

### SC6: ADR-009

File `.planning/adrs/ADR-009-curl-trust-model.md` exists. Documents:
- Download-then-execute via safe_curl_sh()
- HTTPS-only (no HTTP fallback)
- No checksum verification with explicit reasoning (upstreams do not publish stable checksums)
- No GPG verification with explicit reasoning
- All 5 call sites listed in a table
- Alternatives considered and consequences documented

### SC7: ADR-001 Amendment

Status changed to "Amended". Amended date 2026-02-21. Section "Amendment: Semantic Exit Codes (Phase 16)" at line 47 documents the 3-code scheme and explicitly states the continue-on-failure behavior is preserved.

### Commits Verified

All 4 task commits present in git history:
- `0171841` feat(16-01): add exit code constants, compute_exit_code(), and refactor cleanup/trap
- `0b91dfa` feat(16-01): semantic exit codes in all child scripts and parent orchestrators
- `170f236` feat(16-02): add safe_curl_sh() and migrate all curl|sh call sites
- `1dee625` docs(16-02): add ADR-009 curl trust model and safe_curl_sh tests

### Syntax Checks

All modified Bash files pass `bash -n`:
- errors.sh: OK
- setup.sh: OK
- linux/main.sh: OK
- macos/main.sh: OK

### Test Count

`tests/test-core-errors.bats`: 16 tests total
- Original 9 tests preserved
- 5 new tests from Plan 01 (EXIT_SUCCESS, EXIT_PARTIAL_FAILURE, EXIT_CRITICAL constants; compute_exit_code 0 and 1)
- 2 new tests from Plan 02 (safe_curl_sh exported; safe_curl_sh fails with no URL)

---

_Verified: 2026-02-21T20:18:04Z_
_Verifier: Claude (gsd-verifier)_
