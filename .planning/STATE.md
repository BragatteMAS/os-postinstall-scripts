# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** Facil de manter. Simplicidade e manutenibilidade superam features e cobertura.
**Current focus:** v4.1 Production Ready — robustez, segurança, testes para uso real por outros.

## Current Position

Milestone: v4.1 Production Ready -- IN PROGRESS
Status: Phase 17 in progress, Plan 01 complete
Last activity: 2026-02-21 -- Phase 17-01 executed (platform, progress, interactive tests)

Progress: 53/~57 plans complete (v1.0-v3.0: 48, v4.1: 5/~9)

## Previous Milestone Performance

v1.0 + v2.1: 41 plans complete, 98 min total, 2.4 min avg

## Performance Metrics

**Velocity:**
- Total plans completed: 53
- Average duration: 2.4 min
- Total execution time: 128 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-core-infrastructure | 3/3 | 6 min | 2 min |
| 02-consolidation-data-migration | 7/7 | 20 min | 2.9 min |
| 03-dotfiles-management | 4/4 | 10 min | 2.5 min |
| 04-macos-platform | 3/3 | 6 min | 2 min |
| 05-linux-enhancements | 6/6 | 13 min | 2.2 min |
| 06-windows-foundation | 2/2 | 5 min | 2.5 min |
| 07-user-experience-polish | 3/3 | 10 min | 3.3 min |
| 08-documentation | 3/3 | 15 min | 5 min |
| 08.1-terminal-setup-windows | 1/1 | 3 min | 3 min |
| 08.2-audit-remediation | 4/4 | 6 min | 1.5 min |
| 09-terminal-blueprint | 2/2 | 6 min | 3 min |
| 10-windows-cross-platform-installers | 2/2 | 5 min | 2.5 min |
| 10.1-process-debt-cleanup | 1/1 | 1 min | 1 min |
| 11-flag-boolean-fixes | 1/1 | 2 min | 2 min |
| 12-structure-dry-cleanup | 2/2 | 5 min | 2.5 min |
| 13-windows-parity | 2/2 | 6 min | 3 min |
| 14-testing-documentation | 2/2 | 4 min | 2 min |
| 15-data-compatibility-fixes | 2/? | 3 min | 1.5 min |
| 16-exit-codes-security | 2/? | 8 min | 4 min |
| 17-test-expansion-bash | 1/? | 2 min | 2 min |

**Recent Trend:**
- Last 5 plans: 15-01 (1 min), 15-02 (2 min), 16-01 (6 min), 16-02 (2 min), 17-01 (2 min)
- Trend: Stable at ~1-6 min

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v3.0]: Phase ordering: flags -> DRY -> Windows parity -> tests (dependency-driven)
- [v3.0]: No CI/CD automation -- explicit owner decision (permanent)
- [v3.0]: No Pester migration -- PS surface area < 15 files
- [v3.0]: No ShouldProcess/WhatIf -- breaks cross-platform DRY_RUN consistency
- ~~[v3.0]: No exit code changes -- ADR-001 "always exit 0" preserved~~ Superseded by 16-01: semantic exit codes (0/1/2)
- [16-01]: Semantic exit codes (0=success, 1=partial, 2=critical) replace hardcoded exit 0; ADR-001 amended
- [16-01]: INT/TERM traps separated from EXIT; Ctrl+C exits 130
- [16-01]: Early-return exit 0 preserved for skip/not-applicable scenarios
- [11-01]: VERBOSE checks use == "true" string comparison (not -n/-z)
- [11-01]: NONINTERACTIVE two-site bridge: config.sh for env-var path, setup.sh for -y flag path
- [12-01]: Test-CargoInstalled extracted into shared module despite no duplication (future-proofing for Phase 13)
- [12-02]: logging.sh is SSoT for colors and log functions; platform.sh delegates to log_info/log_ok/log_warn/log_error
- [12-02]: DATA_DIR readonly guarded with -z check to prevent collision on re-source
- [13-01]: No CmdletBinding on setup.ps1 or main.ps1 (scripts) -- only on module exported functions
- [13-01]: Show-CompletionSummary reads FAILURE_LOG internally, replacing inline failure aggregation
- [13-02]: Bare [CmdletBinding()] only on module functions -- no ShouldProcess (WPAR-04)
- [13-02]: Parameterless functions get [CmdletBinding()] + empty param() for PS compliance
- [14-01]: bats-core via git submodules (not Homebrew) for portability across CI-less environments
- [14-01]: sleep override via export -f in errors.bats to avoid 20s retry delays
- [14-01]: .shellcheckrc suppresses SC2034/SC1091 project-wide (export -f and dynamic source false positives)
- [14-02]: EXTRA_PACKAGES/SKIP_PACKAGES documented with honest note that no installer consumes them yet
- [14-02]: Troubleshooting uses existing collapsible <details> pattern with Problem/Solution structure
- [15-01]: Skype removed from flatpak.txt (archived on Flathub July 2025)
- [15-01]: TogglDesktop + Workflow removed from flatpak-post.txt (discontinued/archived, 404 on Flathub)
- [15-01]: MasterPDFEditor correct ID uses underscore: net.code_industry.MasterPDFEditor
- [15-02]: verify_bash_version() warns and returns 0 on macOS Bash < 4 (no Bash 4+ features used)
- [15-02]: node removed from brew.txt -- conflicts with fnm (src/install/fnm.sh)
- [15-02]: main.ps1 ValidateSet includes empty string '' for interactive menu mode
- [16-02]: safe_curl_sh() uses -fsSL flags with HTTPS URLs (no per-site --proto/--tlsv1.2 needed)
- [16-02]: No checksum/GPG for curl|sh installers -- upstreams don't publish stable checksums (ADR-009)
- [16-02]: DRY_RUN logic stays in callers, safe_curl_sh is a pure download-then-execute helper
- [17-01]: uname mock dispatches on $1 (-s vs -m); command mock intercepts -v only with builtin passthrough
- [17-01]: BASH_VERSINFO is readonly -- Bash <4 path untestable on Bash 5.x, only passing path tested
- [17-01]: interactive.sh non-interactive paths return 0 before echoing -- test return codes only

### Pending Todos

- [ ] Terminal screenshot (static PNG) for README hero image
- [ ] Terminal demo video (asciinema + agg -> GIF) for README (OSS-03 in Phase 18)
- [ ] Social preview image via socialify.git.ci

### Blockers/Concerns

- ~~CmdletBinding rollout scope: research defers to v3.1, but WPAR-04 requires it for exported functions.~~ Resolved in 13-02: added to all 9 core module functions.
- ~~packages.sh readonly DATA_DIR in test context~~ -- resolved in 12-02 (DRY-04: -z guard added).
- NO CI/CD automation -- explicit owner decision (2026-02-08). Tests are manual only.

## Session Continuity

Last session: 2026-02-21
Stopped at: Completed 17-01-PLAN.md (platform, progress, interactive bats tests)
Resume file: None
Next step: Execute Phase 17 Plan 02 (dotfiles, data validation, integration tests)

---
*Milestone v4.1 Production Ready -- started 2026-02-19*
