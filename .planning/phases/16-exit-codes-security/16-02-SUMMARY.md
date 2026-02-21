---
phase: 16-exit-codes-security
plan: 02
subsystem: security
tags: [curl, download-then-execute, safe-install, temp-file, bats]

# Dependency graph
requires:
  - phase: 16-01
    provides: "errors.sh with export -f, semantic exit codes, bats test infrastructure"
provides:
  - "safe_curl_sh() download-then-execute helper in errors.sh"
  - "ADR-009 documenting HTTPS-only curl|sh trust model"
  - "All 5 curl|sh call sites migrated to safe_curl_sh()"
affects: [future-installers, security-audit]

# Tech tracking
tech-stack:
  added: []
  patterns: [download-then-execute, temp-file-install]

key-files:
  created:
    - ".planning/adrs/ADR-009-curl-trust-model.md"
  modified:
    - "src/core/errors.sh"
    - "src/platforms/linux/install/cargo.sh"
    - "src/install/fnm.sh"
    - "src/install/uv.sh"
    - "src/install/ai-tools.sh"
    - "tests/test-core-errors.bats"

key-decisions:
  - "safe_curl_sh uses -fsSL flags (fail silently, show errors, follow redirects) -- HTTPS URL provides transport security"
  - "No checksum or GPG verification -- upstreams do not publish stable checksums for install scripts"
  - "KISS function: URL as first arg, remaining args passed to downloaded script via bash"
  - "DRY_RUN logic stays in callers, not in safe_curl_sh itself"

patterns-established:
  - "download-then-execute: All curl|sh patterns use safe_curl_sh() to prevent partial download execution"
  - "ADR documentation: Security-sensitive patterns get explicit ADR with risk acknowledgment"

# Metrics
duration: 2min
completed: 2026-02-21
---

# Phase 16 Plan 02: Safe curl|sh Summary

**safe_curl_sh() download-then-execute helper eliminates partial download risk across 5 installer call sites, with ADR-009 documenting HTTPS-only trust model**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-21T20:12:10Z
- **Completed:** 2026-02-21T20:14:41Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added safe_curl_sh() to errors.sh: downloads installer to temp file before executing, cleans up on both success and failure
- Migrated all 5 curl|sh pipe patterns (rustup, cargo-binstall, fnm, uv, ollama) to safe_curl_sh() calls
- Created ADR-009 documenting the HTTPS-only trust model with explicit risk acknowledgment and alternatives analysis
- Extended bats test suite to 16 tests (2 new: export check + no-URL failure handling)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add safe_curl_sh() and migrate call sites** - `170f236` (feat)
2. **Task 2: Create ADR-009 and add tests** - `1dee625` (docs)

## Files Created/Modified
- `src/core/errors.sh` - Added safe_curl_sh() function with temp-file download pattern
- `src/platforms/linux/install/cargo.sh` - Migrated rustup and cargo-binstall calls
- `src/install/fnm.sh` - Migrated fnm installer call
- `src/install/uv.sh` - Migrated uv installer call
- `src/install/ai-tools.sh` - Migrated ollama installer call
- `.planning/adrs/ADR-009-curl-trust-model.md` - Trust model documentation (new)
- `tests/test-core-errors.bats` - 2 new tests for safe_curl_sh

## Decisions Made
- safe_curl_sh uses `-fsSL` flags rather than per-site `--proto '=https' --tlsv1.2` -- the HTTPS URL provides transport security, and safe_curl_sh uses consistent curl flags for all call sites
- No checksum/GPG verification -- upstreams do not publish stable checksums for their install scripts (documented in ADR-009)
- DRY_RUN logic stays in each caller's guard block, not in safe_curl_sh itself (function is a pure download-then-execute helper)
- Function uses KISS design: URL as first arg, remaining args passed through to the downloaded script

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All curl|sh call sites use safe_curl_sh() -- no pipe patterns remain
- ADR-009 provides documented security posture for audit
- 16 bats tests passing across the errors module
- Ready for next plan in phase 16

## Self-Check: PASSED

All 8 expected files verified present. Both task commits (170f236, 1dee625) confirmed in git log. 16 bats tests pass.

---
*Phase: 16-exit-codes-security*
*Completed: 2026-02-21*
