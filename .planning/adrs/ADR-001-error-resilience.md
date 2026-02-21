# ADR-001: Error Resilience - Continue on Failure Strategy

**Status:** Amended
**Date:** 2026-02-04
**Amended:** 2026-02-21
**Amendment Phase:** 16
**Phases:** 01, 05, 07, 16

## Context

A post-install script installs 100+ packages across multiple managers (APT, Snap, Flatpak, Cargo, npm). Traditional shell scripting uses `set -e` to exit on first error. In this context, a single failed package (e.g., a removed PPA, a transient network error) would halt the entire run, leaving the system partially configured with no visibility into what succeeded.

## Decision

No `set -e` anywhere in the codebase. Failures are tracked, not fatal.

- Each installer appends failures to a `FAILED_ITEMS` array
- Child processes (spawned via `bash script.sh`) write to a shared log file (`$FAILURE_LOG`) since arrays cannot propagate across process boundaries
- The parent reads `$FAILURE_LOG` at exit to build a consolidated failure list
- `show_failure_summary()` runs at the end, listing everything that failed
- `retry_with_backoff()` provides automatic retries (5s, 15s, 30s) for transient network failures
- Scripts exit with semantic codes: 0 (all succeeded), 1 (some failed), 2 (critical pre-flight failure). The continue-on-failure intent is preserved -- scripts still complete their run and show the failure summary. The exit code now REFLECTS the outcome instead of masking it.

## Alternatives Considered

### `set -e` (Bash strict mode)
- **Pros:** Industry standard, catches unexpected errors early, simple to implement
- **Cons:** A single failed package kills the entire run. User gets partial install with no summary. Trap-based cleanup is fragile with nested function calls. `set -e` behavior is notoriously inconsistent across bash versions (subshells, pipes, conditionals)

### `set -e` with trap-based recovery
- **Pros:** Catches errors while allowing cleanup logic
- **Cons:** Trap handlers in bash are global, not stackable. Complex nested sourcing (8 core modules + platform installers) makes trap management brittle. Still exits on first unhandled failure

### Per-command `|| true` / manual error checking
- **Pros:** Granular control over which errors are fatal
- **Cons:** Verbose, error-prone (easy to forget), doesn't scale to 100+ install commands across 12 installer scripts

## Recommendation

Continue-on-failure with structured tracking is the only strategy that guarantees the user always sees a complete picture. The downside (a missed failure goes untracked) is mitigated by the shared log file pattern and consistent `record_failure()` usage across all installers.

## Consequences

- **Positive:** Script always completes. User sees everything that failed in one summary. Partial installs are usable (90 of 100 packages installed is still valuable). Retry logic recovers from transient failures automatically.
- **Negative:** Requires discipline -- every installer must call `record_failure()`. A forgotten tracking call means a silent failure. No early abort option for truly critical errors (e.g., no internet).

## Amendment: Semantic Exit Codes (Phase 16)

The original decision stated "All scripts exit 0 regardless of individual package failures." Phase 16 amends this to use semantic exit codes while preserving the continue-on-failure behavior:

- **EXIT_SUCCESS (0):** All operations completed without failures
- **EXIT_PARTIAL_FAILURE (1):** Some packages failed but the run completed and showed the failure summary
- **EXIT_CRITICAL (2):** Pre-flight failure (e.g., platform handler not found, verification failed)

This does NOT change the core strategy: scripts still complete their entire run, track failures, and show summaries. The only change is that the exit code now reflects whether failures occurred, enabling automation callers (CI, wrapper scripts, chaining) to distinguish success from failure. The `FAILED_ITEMS` array, `FAILURE_LOG`, `record_failure()`, and `show_failure_summary()` patterns remain unchanged.
