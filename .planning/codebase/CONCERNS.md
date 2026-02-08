# Codebase Concerns

**Analysis Date:** 2026-02-08

## Tech Debt

**macOS Support: Incomplete:**
- Issue: macOS platform has basic Homebrew support but limited coverage
- Files: `src/platforms/macos/` contains main.sh and install/ with brew scripts
- Impact: Users cannot use this tool effectively on macOS for full setup
- Fix approach: Expand macOS installers to match Linux parity; add brew-cask coverage

**Test Coverage: Minimal:**
- Issue: Only 3 test scripts exist (test_harness.sh, test-dotfiles.sh, test-linux.sh) with basic checks
- Files: `tests/` directory
- Impact: Quality gaps go undetected; no automated CI pipeline
- Fix approach: Implement bats-core framework; target 30% coverage; add ShellCheck linting

## Known Bugs

**Post-Install Scripts: Legacy Code:**
- Symptoms: `src/platforms/linux/post_install.sh` contains hardcoded package arrays that should use data-driven loading
- Files: `src/platforms/linux/post_install.sh`
- Status: Partially migrated to data-driven pattern; needs completion

## Security Considerations

**Input Validation: Package Names:**
- Risk: Package names from txt files should be validated before passing to apt/brew/etc
- Files: `src/core/packages.sh`, all platform install scripts
- Current mitigation: Package lists are version-controlled; no user input at runtime
- Recommendations: Add validation regex before any package manager call

**APT Lock Handling:**
- Risk: Scripts should wait for APT locks, never force-remove them
- Files: `src/platforms/linux/install/apt.sh`
- Current mitigation: Safe wait pattern documented in ADR-001
- Status: Implemented in current apt.sh

## Performance Bottlenecks

**Script Startup Time:**
- Problem: Multiple core modules sourced sequentially
- Files: `src/core/*.sh` sourced by platform orchestrators
- Improvement: Profile startup time; consider lazy loading for optional modules

## Fragile Areas

**Platform Detection:**
- Files: `src/core/platform.sh`
- Why fragile: Distro detection using `/etc/os-release` is brittle for new distros
- Safe modification: Add comprehensive detection tests; use fallback chains

**Shell Compatibility (bash vs zsh):**
- Files: Scripts use bash features (arrays); dotfiles target zsh
- Why fragile: Bash 4+ required but macOS ships with Bash 3.2
- Safe modification: Document Bash version requirement; detect and warn

## Scaling Limits

**Cross-Platform Support:**
- Current capacity: Linux ~95%, macOS ~40%, Windows ~30%
- Limit: Adding new platforms requires new orchestrator + install scripts
- Scaling path: Current src/platforms/ pattern scales well per platform

**Package Manager Support:**
- Current capacity: apt, brew, cargo, snap, flatpak, winget, npm
- Limit: Each new manager needs handler script + data file
- Scaling path: Pattern is clear - add `src/platforms/<os>/install/newmgr.sh` + `data/packages/newmgr.txt`

## Missing Critical Features

**Error Recovery and Rollback:**
- Problem: No mechanism to rollback failed installations
- Impact: Partial installs leave system inconsistent
- Priority: Medium - document rollback strategy

**Configuration Management:**
- Problem: Profile system uses plain text composition; no override mechanism
- Impact: Users cannot customize beyond existing profiles without editing files
- Priority: Low - current profiles cover main use cases

## Test Coverage Gaps

**Cross-Platform Execution:**
- What's not tested: Same script behavior on different Linux distros, macOS, Windows
- Risk: Platform-specific failures only discovered by users
- Priority: High - need CI pipeline on multiple OS images

**Package Installation Idempotency:**
- What's not tested: Running same script twice; already-installed packages
- Risk: Second run may produce warnings or reinstall unnecessarily
- Priority: Medium - add idempotency tests

---

*Concerns audit: 2026-02-08*

**Related Documents:**
- `.planning/adrs/ADR-001-error-resilience.md` - Error handling strategy
- `.planning/adrs/ADR-003-data-driven-packages.md` - Package management approach
- `.planning/adrs/ADR-007-idempotency-safety.md` - Idempotency patterns
