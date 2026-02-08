# ADR-001: Error Resilience - Continue on Failure Strategy

**Status:** Accepted
**Date:** 2026-02-04
**Phases:** 01, 05, 07

## Context

A post-install script installs 100+ packages across multiple managers (APT, Snap, Flatpak, Cargo, npm). Traditional shell scripting uses `set -e` to exit on first error. In this context, a single failed package (e.g., a removed PPA, a transient network error) would halt the entire run, leaving the system partially configured with no visibility into what succeeded.

## Decision

No `set -e` anywhere in the codebase. Failures are tracked, not fatal.

- Each installer appends failures to a `FAILED_ITEMS` array
- Child processes (spawned via `bash script.sh`) write to a shared log file (`$FAILURE_LOG`) since arrays cannot propagate across process boundaries
- The parent reads `$FAILURE_LOG` at exit to build a consolidated failure list
- `show_failure_summary()` runs at the end, listing everything that failed
- `retry_with_backoff()` provides automatic retries (5s, 15s, 30s) for transient network failures
- All scripts exit 0 regardless of individual package failures

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
