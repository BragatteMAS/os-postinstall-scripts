# ADR-007: Idempotency and Safety Patterns

**Status:** Accepted
**Date:** 2026-02-04
**Phases:** 01, 03, 05

## Context

Users run the script multiple times: first install, re-run after adding packages, re-run after pulling updates, re-run to fix a partial failure. Without idempotency, reinstalling already-installed packages wastes time, produces confusing output ("package already newest version" x100), and can cause issues (Snap re-installs reset config, APT lock contention on concurrent runs).

## Decision

Three-layer safety model applied to every mutation point:

1. **Idempotency check** -- verify before acting:
   - `is_apt_installed()` queries `dpkg -s`
   - `is_brew_installed()` queries `brew list`
   - `snap list <pkg>` / `flatpak list --app` for Snap/Flatpak
   - `command -v` for CLI tools (Cargo, npm globals)
   - `ensure_symlink()` checks if correct symlink already exists

2. **DRY_RUN guard** -- placed AFTER idempotency check, BEFORE mutation:
   ```bash
   if is_apt_installed "$pkg"; then return 0; fi
   if [[ "${DRY_RUN}" == "true" ]]; then log_info "[DRY_RUN] Would install $pkg"; return 0; fi
   # actual install here
   ```

3. **APT lock handling** -- `DPkg::Lock::Timeout=60` as apt option instead of manual lock file polling

Additionally:
- `backup_if_exists()` backs up files before overwriting (only non-symlinks)
- `add_to_path()` deduplicates PATH entries via `case ":$PATH:" in *":$path:"*)`
- `ensure_line_in_file()` checks before appending to prevent duplicate entries

## Alternatives Considered

### No idempotency (force reinstall)
- **Pros:** Simplest code, guaranteed latest version
- **Cons:** Wastes 15-30 minutes re-downloading/reinstalling everything. APT lock contention. Snap reinstalls reset app configuration. Confusing output noise. Poor UX

### Timestamp-based skip (skip if ran recently)
- **Pros:** Simple check, avoids re-running too soon
- **Cons:** Doesn't account for actual package state. A failed install followed by a re-run within the time window would skip the retry. Doesn't work across machines or fresh environments

### Lock file per-script (run-once pattern)
- **Pros:** Prevents accidental double execution
- **Cons:** Prevents intentional re-execution (adding packages to a list). Stale locks after crashes require manual cleanup. Doesn't solve the individual package idempotency problem

### Manual fuser polling for APT lock
- **Pros:** Explicit control over wait behavior
- **Cons:** Requires `fuser` (may not be installed). Complex polling loop. `DPkg::Lock::Timeout` is a built-in APT feature that does the same thing in one flag

## Recommendation

The three-layer model (idempotency check -> DRY_RUN guard -> mutation) is applied uniformly across all 12 installer scripts. The order matters: idempotency first means DRY_RUN output accurately reflects what WOULD change, not what is already done. `DPkg::Lock::Timeout=60` replaces 20 lines of fuser polling with one apt flag.

## Consequences

- **Positive:** Re-runs are fast (skip already-installed). DRY_RUN accurately previews pending changes. No lock contention with concurrent apt processes. PATH and config files don't accumulate duplicates. Backup protects user data before overwrites.
- **Negative:** Idempotency checks add latency per package (dpkg -s, brew list, snap list). Some checks are package-manager-specific (no universal `is_installed`). DRY_RUN guard placement is a convention that must be manually followed in every installer.
