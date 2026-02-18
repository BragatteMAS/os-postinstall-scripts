# Project Research Summary

**Project:** os-postinstall-scripts v3.0 "Quality & Parity"
**Domain:** Cross-platform post-install automation (Bash + PowerShell)
**Researched:** 2026-02-18
**Confidence:** HIGH

## Executive Summary

v3.0 is not a feature milestone — it is a quality milestone for a functionally complete system. The codebase installs across Linux, macOS, and Windows and earns a 7.5/10 from reviewers. The gap to 9+/10 is not about capabilities; it is about correctness (one active boolean bug that silently enables verbose mode for all users by default), consistency (NONINTERACTIVE and UNATTENDED are disconnected names for the same concept), Windows parity (step counters and completion summary exist only on Linux/macOS), and structural hygiene (duplicate PowerShell functions, a stale directory, a DATA_DIR readonly collision). All four categories are confirmed by direct code inspection with exact file and line number references.

The recommended approach is a strict dependency-ordered four-phase execution: fix the boolean/flag bugs first (they infect every module), then extract duplicated code and clean structure (creates a stable foundation for Windows parity work), then close the Windows UX parity gap (flags, step counters, completion summary), and finally add unit tests and documentation that validate the cleaned-up state. Reversing this order creates rework: writing tests before fixing the VERBOSE bug means tests validate broken behavior, and adding Windows features before extracting shared helpers means touching the same files twice.

The key risk is breakage in a working system. Each of the five architectural changes has a confirmed failure mode: 13+ hardcoded path references for the directory merge, PowerShell multi-process scope isolation for the module extraction, the NONINTERACTIVE/UNATTENDED Homebrew API exception trap, the VERBOSE boolean truthiness cascade. All risks have confirmed mitigations. The "always exit 0" policy from ADR-001 must be preserved — the reviewer suggestion to change exit codes contradicts a deliberate architectural decision that is correct for this use case.

---

## Key Findings

### Recommended Stack

The runtime stack (Bash 4+, PowerShell 5.1+, zero runtime deps) is unchanged. v3.0 adds dev-time quality tooling only. Three categories of tooling are needed: **bats-core 1.13.0** (with bats-support 0.3.0 and bats-assert 2.1.0) for Bash unit testing via git submodule; **ShellCheck 0.11.0 + shfmt 3.12.0** with a local `tools/lint.sh` runner for shell static analysis; and **PSScriptAnalyzer 1.24.0** with `[CmdletBinding()]` adoption for PowerShell quality. Pester is explicitly deferred — with only 8 PowerShell files, the cost of adoption exceeds the benefit. All tools are dev-machine only; no CI/CD pipeline is introduced (owner decision, permanent scope).

**Core technologies (new, dev-time only):**
- bats-core 1.13.0: Bash unit testing — industry standard, TAP-compliant, tests actual function behavior vs. current smoke-test-only approach
- bats-assert 2.1.0 + bats-support 0.3.0: Assertion helpers — eliminates manual `[ "$status" -eq 0 ]` boilerplate in test files
- ShellCheck 0.11.0: Shell static analysis — catches 400+ shell pitfalls, enforced via local `tools/lint.sh` (no CI required)
- shfmt 3.12.0: Shell formatter — parser-based (not regex), consistent formatting enforcement
- PSScriptAnalyzer 1.24.0: PowerShell linting — Microsoft-maintained, 80+ rules, enforced via local `tools/lint.ps1`
- CmdletBinding(): PowerShell language feature (zero install cost) — adds `-Verbose`, `-Debug`, `-ErrorAction` propagation to all PS exported functions

### Expected Features

**Must have (table stakes — confirmed bugs or parity gaps):**
- Fix VERBOSE boolean bug — `VERBOSE=false` currently enables verbose mode because `-n` tests string non-emptiness; 5 locations in logging.sh need `== "true"` comparison
- Unify NONINTERACTIVE/UNATTENDED — the `-y` flag sets UNATTENDED but apt.sh and interactive.sh check NONINTERACTIVE; they are disconnected, `-y` silently fails to suppress apt prompts
- Remove stale winget.txt entry — `kite.kite` (Kite AI shut down November 2022) causes install failures on Windows
- Windows -DryRun flag — Bash has `--dry-run`, Windows has only `$env:DRY_RUN`; highest-visibility parity gap identified by reviewers
- Windows step counters — Linux/macOS show `[Step X/Y]`, Windows shows nothing
- Windows completion summary — Linux/macOS show profile/platform/duration/failures, Windows shows bare "Setup Complete"
- Extract shared PowerShell helpers — `Test-WinGetInstalled` duplicated 3x, `Test-NpmInstalled` duplicated 2x; DRY violation confirmed by grep

**Should have (differentiators that raise quality score):**
- Unit tests for core Bash modules — logging.sh, errors.sh, progress.sh, packages.sh, idempotent.sh tested at function level, not just file existence
- Windows -Verbose flag — map PS -Verbose switch to `$env:VERBOSE=true` for parity with Bash `--verbose`
- Profile validation tests — verify profile .txt files reference existing package files; typos currently skipped silently
- DATA_DIR readonly collision fix — packages.sh and config.sh both set `readonly DATA_DIR`; one-line guard in packages.sh resolves latent bug

**Defer to v3.1+:**
- CmdletBinding on PS installer scripts (additive, low impact, no functionality change)
- src/installers/ directory consolidation (cosmetic, low user impact)
- PSScriptAnalyzer integration (quality enhancement, project works without it)
- ARCHITECTURE.md drift fix (contributor-only impact)
- Full Windows troubleshooting documentation
- Pester test framework (8 PS files is below the justification threshold)
- PS ShouldProcess/WhatIf migration (breaks cross-platform `DRY_RUN` consistency — explicit anti-feature for v3.0)

### Architecture Approach

Five architectural changes define v3.0. Four are mutually independent and can be sequenced freely: (1) merge `src/installers/` into `src/install/` (one file move, 3 path references in setup.sh, 1 in test_harness.sh); (2) extract shared PS helpers into a new `windows/core/idempotent.psm1` module (4 scripts updated, 1 new file); (3) remove duplicate color definitions from platform.sh so logging.sh becomes the single SSoT for output formatting; (4) fix DATA_DIR dual-readonly collision in packages.sh with a one-line guard. The fifth — unit tests for core modules — depends on the DATA_DIR fix being in place before packages.sh unit tests can run without hitting a readonly error. Post-v3.0, `src/install/` holds all cross-platform installers (merged), `windows/core/` holds 4 PS modules (up from 3), and `tests/` gains 5 new `test-core-*.sh` unit test files alongside the existing smoke/validation tests which are not replaced.

**Major components (post-v3.0):**
1. `src/core/*.sh` (8 Bash modules) — foundation layer; VERBOSE bug fix and DATA_DIR guard live here; logging.sh becomes color SSoT
2. `src/install/*.sh` (6 cross-platform installers, post-merge) — unified; dotfiles-install.sh moves here from src/installers/
3. `src/platforms/windows/core/*.psm1` (4 modules, up from 3) — idempotent.psm1 is new; shared check helpers extracted here
4. `src/platforms/windows/install/*.ps1` (4 installer scripts, thinner) — import idempotent.psm1, local duplicates removed
5. `tests/` — two layers preserved: existing smoke/validation tests (keep, do not replace) and new unit test files for core modules

### Critical Pitfalls

1. **VERBOSE boolean truthiness trap** — changing `-n`/`-z` tests to `== "true"` in logging.sh must cover all 5 locations (lines 99, 113, 127, 141, 153) atomically; add a normalization bridge for non-standard user values (`VERBOSE=1`, `VERBOSE=yes`); test both `VERBOSE=false` (no timestamps) and `VERBOSE=true` (timestamps visible) after the fix
2. **NONINTERACTIVE/UNATTENDED Homebrew exception** — `homebrew.sh` line 95 uses `NONINTERACTIVE=1` as a Homebrew installer API variable, NOT the project flag; do NOT rename it; the correct fix is a bridge in config.sh (`export NONINTERACTIVE="${UNATTENDED}"`) rather than a rename sweep across all files
3. **Directory merge path cascade** — 13+ hardcoded references to `src/installers/` exist across setup.sh, test_harness.sh, and test-linux.sh; use `git mv` (not delete+create), update test_harness.sh to expect new path before moving the file, verify with `bash tests/test_harness.sh` + `bash tests/test-linux.sh` after
4. **PowerShell multi-process scope isolation** — shared helper module functions are NOT inherited by child processes spawned with `&`; each `.ps1` installer must explicitly `Import-Module "$PSScriptRoot/../core/idempotent.psm1" -Force`; `$script:` scoped state does NOT propagate cross-process; only `$env:` vars do
5. **Exit code trap cascade** — do NOT change the "always exit 0" policy (ADR-001); four different `cleanup()` functions co-exist with different behaviors; changing exit codes breaks the trap cascade and contradicts the deliberate "partial failure is acceptable" design; only exit non-zero for hard prerequisites before any work begins

---

## Implications for Roadmap

Based on the dependency chain confirmed across all four research files, four phases are recommended:

### Phase 1: Flag & Boolean Correctness

**Rationale:** The VERBOSE bug and NONINTERACTIVE/UNATTENDED disconnect affect every module that does logging or interactivity checks. Testing anything that touches logging while the boolean bug exists means tests validate broken behavior. These fixes have zero dependencies on other changes, the smallest blast radius (5 lines in logging.sh, one bridge line in config.sh, one line deletion in winget.txt), and the highest confidence (exact locations confirmed by code inspection).

**Delivers:** A codebase where flag semantics are correct — `VERBOSE=false` does not show timestamps, `-y` propagates to apt.sh, `kite.kite` no longer causes Windows install failures.

**Addresses:** VERBOSE boolean bug (logging.sh lines 99/113/127/141/153), NONINTERACTIVE/UNATTENDED split (config.sh bridge + no rename of homebrew.sh), stale winget.txt entry.

**Avoids:** Pitfall 1 (truthiness normalization bridge), Pitfall 2 (Homebrew NONINTERACTIVE exception), Pitfall 3 (exit code policy — do not change).

**Research flag:** No additional research needed. Exact file locations, line numbers, and fix patterns are fully specified in FEATURES.md and PITFALLS.md.

---

### Phase 2: Structure & DRY Cleanup

**Rationale:** Clean module boundaries before adding features to them. The PowerShell DRY extraction creates `idempotent.psm1`, which Windows parity features (step counters, completion summary) will also use. Merging install directories resolves the naming ambiguity. The DATA_DIR fix prevents the readonly collision from surfacing in Phase 4 unit tests. All four changes in this phase are mutually independent and can be done in any order.

**Delivers:** Unified `src/install/` directory, shared `windows/core/idempotent.psm1`, logging.sh as the sole color SSoT (platform.sh no longer defines its own), DATA_DIR guard in packages.sh.

**Addresses:** Directory merge (src/installers/ into src/install/), PS DRY violation (Test-WinGetInstalled 3x, Test-NpmInstalled 2x consolidated into idempotent.psm1), duplicate color variables in platform.sh, DATA_DIR readonly collision.

**Avoids:** Pitfall 4 (PS scope isolation — Import-Module in every consumer, not dot-source), Pitfall 5 (directory path cascade — git mv + update all 13+ references before moving), Pitfall 8 (source guard collision — keep old guard variable names as aliases when touching platform.sh).

**Research flag:** No additional research needed. All implementation details, file locations, and exact code patterns are specified in ARCHITECTURE.md.

---

### Phase 3: Windows Parity

**Rationale:** Windows parity features depend on `idempotent.psm1` from Phase 2. Adding step counters and completion summary before extracting shared helpers means touching main.ps1 in two phases. The `-DryRun` and `-Verbose` switches map directly to `$env:DRY_RUN` and `$env:VERBOSE` — preserving cross-platform UX symmetry without introducing ShouldProcess asymmetry. The Bash `show_completion_summary` and `count_platform_steps` functions are the direct reference implementations for the PS ports.

**Delivers:** Windows users see `[Step X/Y]` progress during installation, a DryRun banner when running in dry-run mode, a completion summary showing profile/platform/duration/failures, and `-DryRun`/`-Verbose` CLI flags matching Bash `--dry-run`/`--verbose` equivalents.

**Addresses:** Windows -DryRun flag (setup.ps1 param block), Windows DryRun banner (main.ps1), Windows step counters (Get-PlatformStepCount function in main.ps1), Windows completion summary (Show-CompletionSummary function), Windows -Verbose flag (maps to `$env:VERBOSE='true'`).

**Avoids:** Pitfall 12 (env var case sensitivity — always use `$env:DRY_RUN` uppercase, never `$env:DryRun`). Anti-feature explicitly rejected: do NOT adopt ShouldProcess/WhatIf as replacement for DRY_RUN — breaks cross-platform UX symmetry where Bash uses `DRY_RUN=true ./setup.sh` and Windows should mirror `.\setup.ps1 -DryRun`.

**Research flag:** No additional research needed. Bash reference implementations are identified. PS port strategy is defined. Anti-patterns are explicitly documented.

---

### Phase 4: Testing & Documentation

**Rationale:** Tests should validate the final cleaned-up state, not intermediate states. Writing tests before Phase 1-3 changes would require test rewrites after each phase. The unit test pattern is already established in `test-dotfiles.sh` — new tests follow that exact pattern (temp dir isolation, assert_eq, trap cleanup). bats-core reduces boilerplate but is optional; the existing harness pattern also works and introduces less infrastructure overhead.

**Delivers:** Unit tests for logging.sh, errors.sh, packages.sh, idempotent.sh, platform.sh (5 new test-core-*.sh files); profile validation tests (each profile .txt verified against existing package files); ShellCheck + shfmt local lint runner (`tools/lint.sh`); PSScriptAnalyzer local lint runner (`tools/lint.ps1`); ARCHITECTURE.md updated to reflect actual codebase patterns; EXTRA_PACKAGES documented in README.

**Addresses:** Unit tests for core Bash modules, profile validation, ShellCheck/shfmt enforcement, PSScriptAnalyzer enforcement, ARCHITECTURE.md drift (references detect_os() not detect_platform(), lists needs_update() that does not exist, says set -euo pipefail when project uses only set -o pipefail).

**Uses:** bats-core 1.13.0 (git submodule, no external dep), bats-assert 2.1.0, bats-support 0.3.0, ShellCheck 0.11.0, shfmt 3.12.0, PSScriptAnalyzer 1.24.0.

**Avoids:** Pitfall 9 (system-dependent tests — test functions not scripts, mock externals like dpkg with shell functions, never run `apt install` in tests), Pitfall 3 (exit code test — verify `./setup.sh --dry-run minimal; echo $?` returns 0 as ADR-001 requires).

**Research flag:** Needs attention for packages.sh tests specifically — the `readonly DATA_DIR` behavior when unit-testing requires special setup: either pre-set DATA_DIR before sourcing packages.sh, or source packages.sh in a subshell. All other module tests follow the test-dotfiles.sh pattern directly.

---

### Phase Ordering Rationale

- **Phase 1 before everything** because VERBOSE and NONINTERACTIVE/UNATTENDED are evaluated by virtually every module. Any test or feature built on broken flag semantics produces false confidence or requires rework.
- **Phase 2 before Phase 3** because `idempotent.psm1` is created in Phase 2 and consumed by Windows parity features in Phase 3. Also, the directory structure stabilizes in Phase 2 — test file paths written in Phase 4 do not need updates after Phase 2 is done.
- **Phase 3 before Phase 4** because tests should validate finished behavior. Writing step counter tests before step counters exist requires the test to be written twice.
- **Phase 4 last** as the validation and documentation layer. The research explicitly recommends this order: correctness fixes → structure cleanup → feature additions → tests and docs.

### Research Flags

No phase requires `/gsd:research-phase` — all implementation details are fully specified by the existing research:

- **Phase 1:** File locations, line numbers, and exact fix patterns confirmed by code inspection. Zero unknowns.
- **Phase 2:** All 13+ path references for directory merge enumerated in PITFALLS.md. Module extraction pattern with exact code specified in ARCHITECTURE.md. DATA_DIR guard one-liner specified.
- **Phase 3:** Bash reference implementations (`show_completion_summary`, `count_platform_steps`) identified and documented. PS port strategy defined. The Bash implementations are the spec.
- **Phase 4 (most modules):** test-dotfiles.sh is the established template. bats-core patterns documented in STACK.md with concrete working examples.

One implementation detail needs resolution during Phase 4 execution (not blocking): packages.sh unit test setup sequence for the `readonly DATA_DIR` scenario. Options are documented; the correct one depends on how the test runner sources the module.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All tool versions verified via official GitHub releases. bats-core 1.13.0, ShellCheck 0.11.0, shfmt 3.12.0, PSScriptAnalyzer 1.24.0 confirmed. Pester deferral justified by file count (8 PS files). |
| Features | HIGH | All bugs confirmed by direct code inspection with file and line number references. NONINTERACTIVE/UNATTENDED disconnect verified by grep across 7 files. Kite AI shutdown date confirmed. |
| Architecture | HIGH | All changes derived from reading every file in src/, tests/, setup.sh, setup.ps1, config.sh. 13+ path references enumerated. No external library dependencies introduced. |
| Pitfalls | HIGH | Critical pitfalls confirmed by code structure analysis and shell/PS runtime semantics. ADR-001 and ADR-007 consulted and preserved. |

**Overall confidence:** HIGH

### Gaps to Address

- **packages.sh readonly DATA_DIR in test context:** The exact setup sequence for unit-testing packages.sh without triggering the readonly collision is not fully resolved. Options are: pre-set DATA_DIR before sourcing, or run tests in a subshell. Resolve during Phase 4 implementation when the actual test is being written.
- **bats-core on Windows (Git Bash):** STACK.md notes bats-core works on Windows via Git Bash but does not address test isolation differences or shebang handling. New unit tests target Linux/macOS only; Windows unit test coverage remains at the existing test-windows.ps1 level.
- **CmdletBinding rollout scope:** STACK.md recommends CmdletBinding on all PS functions; FEATURES.md defers it to v3.1. This gap should be resolved before Phase 2 begins — the decision between "add to installer scripts in Phase 2" vs "defer entirely" affects which files Phase 2 touches.

---

## Sources

### Primary (HIGH confidence — official releases and direct code analysis)
- [bats-core v1.13.0 Release](https://github.com/bats-core/bats-core/releases) — version confirmed Nov 2024
- [ShellCheck v0.11.0 Release](https://github.com/koalaman/shellcheck/releases) — version confirmed Aug 2025
- [shfmt v3.12.0 Release](https://github.com/mvdan/sh/releases) — version confirmed Jul 2024
- [PSScriptAnalyzer v1.24.0 Release](https://github.com/PowerShell/PSScriptAnalyzer/releases) — version confirmed Mar 2025
- [CmdletBinding Attribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute) — Microsoft Learn
- [PowerShell about_Scopes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes) — scope isolation confirmation for multi-process architecture
- Direct code inspection: src/core/logging.sh (VERBOSE bug, lines 99-153), config.sh (VERBOSE default line 25), interactive.sh + apt.sh (NONINTERACTIVE), setup.sh (UNATTENDED), windows/install/*.ps1 (Test-WinGetInstalled 3x duplication)
- Project ADR-001 (error resilience, "always exit 0") and ADR-007 (idempotency safety, guard ordering)

### Secondary (MEDIUM confidence — community consensus)
- [Baeldung: Boolean in Shell Scripts](https://www.baeldung.com/linux/shell-script-boolean-type-variable) — `-n` vs `== "true"` pitfall confirmation
- [Testing Bash Scripts with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide) — unit test patterns
- [bats-core documentation](https://bats-core.readthedocs.io/) — setup/teardown, run helper, load directive
- [PowerShell Scripting Best Practices 2025](https://dstreefkerk.github.io/2025-06-powershell-scripting-best-practices/) — CmdletBinding patterns
- [Cross-Platform BATS Issues](https://blog.shukebeta.com/2025/09/02/git-bash-test-compatibility-a-deep-dive-into-cross-platform-bats-issues/) — Windows/macOS differences in bats-core

---

*Research completed: 2026-02-18*
*Supersedes: SUMMARY.md from 2026-02-04 (v1.0 research, pre-v3.0 scope)*
*Ready for roadmap: yes*
