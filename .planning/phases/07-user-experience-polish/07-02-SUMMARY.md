# Phase 7 Plan 02: DRY_RUN CLI Flags and Guards Summary

**One-liner:** CLI flag parsing (--dry-run, --verbose, --unattended) in setup.sh with DRY_RUN guards across all 9 previously unguarded installer scripts

## Metadata

| Field | Value |
|-------|-------|
| Phase | 07-user-experience-polish |
| Plan | 02 |
| Subsystem | cli-flags, dry-run |
| Tags | bash, cli, dry-run, ux |
| Duration | 4 min |
| Completed | 2026-02-07 |

## Dependency Graph

- **Requires:** Phase 1 (core infrastructure), Phase 4-6 (installer scripts exist)
- **Provides:** CLI flag parsing, comprehensive DRY_RUN coverage
- **Affects:** Phase 7 plan 03 (help/version output), Phase 8 (documentation)

## What Was Done

### Task 1: CLI Flag Parsing in setup.sh

Added `parse_flags()` function that processes flags before `main()` is called:

- `--dry-run` / `-n`: exports `DRY_RUN=true`
- `--verbose` / `-v`: exports `VERBOSE=true`
- `--unattended` / `-y`: exports `UNATTENDED=true`
- `--help` / `-h`: passes through to main() help handler
- Unknown flags (`-*`): error message to stderr + exit 1
- Non-flag args: preserved for main() via `REMAINING_ARGS` array

Updated help text with options section, examples, and flag documentation.

**Key design:** Flags use `export` so child processes (sub-scripts) inherit values. This complements the existing env var approach (`DRY_RUN=true ./setup.sh` still works via config.sh defaults).

### Task 2: DRY_RUN Guards in 9 Scripts

Added DRY_RUN guards at every system-mutating function, using the established `== "true"` pattern from brew.sh. Guards are placed after idempotency checks but before mutation commands.

| Script | Functions Guarded | Guard Count |
|--------|-------------------|-------------|
| apt.sh | safe_apt_update(), apt_hardened_install() | 2 |
| flatpak.sh | ensure_flathub_remote(), flatpak_install() | 2 |
| snap.sh | snap_install() | 1 |
| cargo.sh | ensure_rust_installed(), cargo_install(), ensure_binstall() | 3 |
| rust-cli.sh | install_rust_tools_linux(), install_rust_tools_macos(), create_rust_symlinks() | 3 |
| fnm.sh | install_fnm(), install_node_lts(), install_global_npm() | 3 |
| uv.sh | install_uv(), install_python() | 2 |
| ai-tools.sh | install_ai_tool() (npm branch + curl branch) | 2 |
| dev-env.sh | setup_ssh_key() | 1 |

**Total:** 19 DRY_RUN guard points across 9 scripts.

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| parse_flags before config.sh loads | Flags override env var defaults; export ensures propagation |
| REMAINING_ARGS array for passing args | Clean separation between flag parsing and main dispatch |
| Unknown flags cause exit 1 | Prevent silent misconfiguration (typos in flags) |
| DRY_RUN guard after idempotency check | Already-installed tools don't need dry-run log noise |
| [DRY_RUN] prefix in log messages | Consistent, grep-able indicator of simulated actions |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

| Check | Result |
|-------|--------|
| bash -n setup.sh | PASS |
| bash setup.sh --help shows flags | PASS |
| Unknown flag error message | PASS |
| DRY_RUN in Linux installers (4 files) | 16 occurrences |
| DRY_RUN in cross-platform installers (5 files) | 22 occurrences |
| All 10 files pass bash -n | PASS |
| All guards use == "true" | PASS (19/19) |
| No -n DRY_RUN pattern | PASS (0 found) |

## Files Changed

### Modified
- `setup.sh` - CLI flag parsing + updated help text
- `src/platforms/linux/install/apt.sh` - DRY_RUN guards
- `src/platforms/linux/install/flatpak.sh` - DRY_RUN guards
- `src/platforms/linux/install/snap.sh` - DRY_RUN guards
- `src/platforms/linux/install/cargo.sh` - DRY_RUN guards
- `src/install/rust-cli.sh` - DRY_RUN guards
- `src/install/fnm.sh` - DRY_RUN guards
- `src/install/uv.sh` - DRY_RUN guards
- `src/install/ai-tools.sh` - DRY_RUN guards
- `src/install/dev-env.sh` - DRY_RUN guards

## Commits

| Hash | Message |
|------|---------|
| cc94a2a | feat(07-02): add CLI flag parsing to setup.sh |
| a6c883c | feat(07-02): add DRY_RUN guards to all 9 scripts missing them |

## Tech Stack

- **Patterns established:** CLI flag parsing with while/case/shift, REMAINING_ARGS passthrough
- **Patterns reused:** DRY_RUN == "true" guard (from brew.sh), [DRY_RUN] log prefix

## Next Phase Readiness

- All installer scripts now respect DRY_RUN flag
- CLI flags are discoverable via --help
- Ready for 07-03 (help/version improvements) or Phase 8 (documentation)
