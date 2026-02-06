# Codebase Concerns

**Analysis Date:** 2026-02-04

## Tech Debt

**Architecture: Core/Adapters Not Implemented:**
- Issue: ADR-003 and ADR-007 promised a core/adapters architecture to support cross-platform development (Linux, macOS, Windows), but the structure does not exist in codebase
- Files: `platforms/linux/`, `platforms/` root, all scripts directly call platform-specific commands
- Impact: Code duplication across platforms, impossible to test with mocks, adding new platforms requires complete reimplementation
- Fix approach: Implement complete core/adapters pattern as detailed in `/.github/PROJECT_DOCS/adrs/ADR-007-implement-core-adapters-architecture.md` - Create `core/interfaces/`, `core/common/`, and `adapters/` directories with unified interfaces for package managers, shell compatibility, and system info

**macOS Support: Incomplete and Minimal:**
- Issue: macOS platform support is approximately 20% complete according to STATUS.md
- Files: `platforms/macos/` exists but contains minimal implementation
- Impact: Users cannot use this tool effectively on macOS; claimed cross-platform support is misleading
- Fix approach: Expand macOS to 80% parity with Linux using adapter pattern; prioritize Homebrew package manager support

**Test Coverage: Critically Low with False Claims:**
- Issue: Codebase claims "100% coverage with 50 tests" but actual coverage is ~5% with only basic checks (no framework, no assertions)
- Files: `/tests/` contains only `script_inventory.md` and `test_harness.sh` - no real test framework installed
- Impact: False sense of security; actual quality gaps go undetected; users may encounter untested code paths
- Fix approach: Per ADR-006, implement bats-core framework with 30% coverage target; use kcov for bash coverage measurement; add unit, integration, and security test categories

## Known Bugs

**APT Lock Handling: Critical Security Vulnerability:**
- Symptoms: Scripts force remove `/var/lib/dpkg/lock-frontend` and `/var/cache/apt/archives/lock`, risking database corruption and system instability
- Files: Multiple scripts in `platforms/linux/install/apt.sh` and related installers; partially mitigated in v2.3.1
- Trigger: Running install scripts when APT is locked by another package manager or background process
- Workaround: Documented in ADR-005; use `wait_for_apt()` and `apt_install_with_retry()` functions; safe module should be at `scripts/utils/package-manager-safety.sh`
- Status: ADR-005 accepted and implemented per STATUS.md, but verify all scripts are updated

**Post-Install Scripts: Incomplete and Inconsistent:**
- Symptoms: `/platforms/linux/post_install.sh` (12KB) exists but `/platforms/linux/post_install_new.sh` (249B) is empty stub
- Files: `platforms/linux/post_install.sh`, `platforms/linux/post_install_new.sh`
- Trigger: Running post-install phase
- Status: Unclear which is current; migration apparently incomplete

## Security Considerations

**Input Validation: Package Names Not Validated:**
- Risk: Command injection if package names aren't validated; scripts accept user input without sanitization in some paths
- Files: `platforms/linux/install/apt.sh`, all package installer scripts
- Current mitigation: ADR-005 specifies validation regex `^[a-zA-Z0-9._+-]+$` in `validate_package_name()`, but verify all call sites use it
- Recommendations: Make input validation mandatory before any apt-get call; add integration tests for injection attempts

**Audit Logging Not Implemented:**
- Risk: Package operations not logged; cannot trace what was installed, when, and by whom
- Files: All installation scripts lack centralized logging
- Current mitigation: ADR-005 specifies log format to `/var/log/os-postinstall/package-operations.log`
- Recommendations: Implement centralized audit logging as per ADR-005; include timestamp, user, operation type, package name, status

**Hardcoded Credentials or Paths:**
- Risk: Review for environment variable exposure or hardcoded sensitive paths
- Files: Check `scripts/`, `platforms/`, and `configs/` directories
- Current mitigation: `.env.local.example` exists at root, but verify all secrets use env vars
- Recommendations: Add pre-commit hook to detect hardcoded credentials; document all required env vars in REQUIREMENTS.md

## Performance Bottlenecks

**APT Operations: Timeout Risk:**
- Problem: Scripts wait up to 5 minutes for APT locks per ADR-005, blocking execution
- Files: `scripts/utils/package-manager-safety.sh` (when implemented), all apt install scripts
- Cause: System-wide APT lock from background updates or other package managers
- Improvement path: Implement exponential backoff; add user-friendly progress messages; allow configurable timeout via `APT_LOCK_TIMEOUT` env var (documented in ADR-005)

**Script Startup Time:**
- Problem: Multiple scripts sourced sequentially; unclear if there are circular dependencies or redundant loads
- Files: Multiple entry points in `scripts/setup/main.sh`, `platforms/linux/main.sh`
- Cause: Modular design without clear dependency graph
- Improvement path: Profile startup time; identify circular imports; document load order; consider lazy loading for optional features

## Fragile Areas

**Platform Detection and Routing:**
- Files: `platforms/linux/auto/logging.sh`, distro detection logic spread across multiple files
- Why fragile: Distro detection using regex against `/etc/os-release` is brittle; new distros or naming variations break routing
- Safe modification: Add comprehensive distro detection tests; use existing tools like `lsb_release`; centralize detection in `core/interfaces/system-info.sh` when implementing ADR-007
- Test coverage: Minimal - need unit tests for each distro variant

**Configuration Loading and Merging:**
- Files: `scripts/utils/config-loader.sh`, `scripts/utils/profile-loader.sh`
- Why fragile: Unclear precedence when multiple config sources exist (YAML, JSON, env vars, CLI flags)
- Safe modification: Document config precedence explicitly; add validation that all required keys exist; fail fast on malformed configs
- Test coverage: None documented - add integration tests for each config format

**Shell Compatibility (bash vs zsh):**
- Files: Scripts throughout codebase; `.zshrc` symlink in root
- Why fragile: Bash-specific features (arrays, test operators) may fail in zsh or other shells; not centralized
- Safe modification: When implementing ADR-007, create `adapters/shell-compat/` with shell detection and compatibility layer
- Test coverage: Currently missing

## Scaling Limits

**Cross-Platform Support Architecture:**
- Current capacity: Linux 100% complete, Windows 80%, macOS 20%
- Limit: Cannot scale beyond 3 platforms without core/adapters refactoring (ADR-007)
- Scaling path: Implement ADR-007 core/adapters pattern; new platform addition should take < 1 day vs current multi-week effort

**Test Infrastructure:**
- Current capacity: ~30 basic checks, no automation framework
- Limit: Impossible to run tests in CI/CD reliably; coverage cannot exceed 5-10% without framework
- Scaling path: Implement ADR-006 bats-core framework; target 30% coverage by EOY; automate in CI pipeline

**Package Manager Support:**
- Current capacity: apt (Linux), basic Homebrew (macOS), minimal Winget (Windows)
- Limit: Each new package manager requires dedicated script rewrite
- Scaling path: Use ADR-007 adapters to add snap, flatpak, pacman, yum/dnf automatically when new distros needed

## Dependencies at Risk

**BMAD Method Version Pinning:**
- Risk: Tight coupling to BMAD v4.34.0; updates might break `.claude/commands/`
- Impact: Cannot easily adopt new BMAD features; breaking changes force manual integration
- Migration plan: Document BMAD update process; add version check script; maintain compatibility matrix in `docs/bmad-compatibility.md`
- Files: `.github/BMAD/` directory, `.claude/commands/`

**Bash 4+ Dependency:**
- Risk: Some scripts require Bash 4+ features (associative arrays); macOS ships with Bash 3.2
- Impact: Installation fails on older macOS; users must manually upgrade Bash first
- Migration plan: Document Bash version requirements; detect and upgrade automatically in setup phase
- Files: `scripts/setup/upgrade-bash.sh` exists - verify it's always called

**APT/Apt-get Specific Logic:**
- Risk: Heavy reliance on apt-specific commands; porting to other package managers requires manual effort
- Impact: Cannot easily add dnf/yum/pacman support
- Migration plan: Implement ADR-007 adapters for each package manager; design interfaces to support multiple backends

## Missing Critical Features

**Windows Platform Support:**
- Problem: Windows support is labeled 80% in STATUS.md but actual implementation is unclear
- Blocks: Cross-platform users cannot use tool on Windows; no clear failure modes documented
- Files: `platforms/windows/` likely minimal or missing
- Impact: Breaks claim of cross-platform support; unclear what works and what doesn't

**Error Recovery and Rollback:**
- Problem: No mechanism to rollback failed installations; partial installs leave system inconsistent
- Blocks: Users cannot safely test different configurations
- Impact: Each failed run requires manual cleanup
- Priority: High - document rollback strategy in ADR or ARCHITECTURE.md

**Configuration Management Beyond Profiles:**
- Problem: Profile system (v2.4.0) is being deprecated (see STATUS.md v3.2.0) with no replacement documented
- Blocks: Users cannot customize installations after deprecation
- Impact: Loss of key feature; migration path needed
- Priority: High - implement technology detection system (Story 1.6 in STATUS.md) before deprecating profiles

## Test Coverage Gaps

**APT Lock Handling:**
- What's not tested: Race conditions, timeout scenarios, concurrent package manager operations
- Files: `platforms/linux/install/apt.sh`, `scripts/utils/package-manager-safety.sh`
- Risk: Lock handling may fail silently under load; production failures not caught
- Priority: High - per ADR-005, add security tests in `tests/security/apt-lock-handling.bats`

**Cross-Platform Execution:**
- What's not tested: Same script behavior on Ubuntu, Debian, other Linux variants, macOS, Windows
- Files: All scripts in `scripts/`, `platforms/`
- Risk: Platform-specific failures only discovered by users
- Priority: High - need CI pipeline running on multiple OS images

**Configuration Edge Cases:**
- What's not tested: Missing config files, malformed YAML/JSON, conflicting config sources, empty profiles
- Files: `scripts/utils/config-loader.sh`, `scripts/utils/profile-loader.sh`
- Risk: Scripts crash or behave unpredictably with non-standard input
- Priority: Medium - add 10-15 integration tests for config paths

**Package Installation Idempotency:**
- What's not tested: Running same installation script twice; already-installed packages; partial installations
- Files: `platforms/linux/install/apt.sh` and all package installers
- Risk: Second run may fail or reinstall packages unnecessarily
- Priority: Medium - add idempotency tests per ADR-006 example

**Error Path Validation:**
- What's not tested: Invalid package names, network failures, insufficient permissions, disk full
- Files: All installation and setup scripts
- Risk: Error handling untested; users see confusing output in failure scenarios
- Priority: Medium - add error scenario tests

---

*Concerns audit: 2026-02-04*

**Related Documents:**
- `/.github/PROJECT_DOCS/adrs/ADR-005-security-apt-lock-handling.md` - Critical security issue resolution
- `/.github/PROJECT_DOCS/adrs/ADR-006-test-coverage-reality-check.md` - Test framework implementation roadmap
- `/.github/PROJECT_DOCS/adrs/ADR-007-implement-core-adapters-architecture.md` - Architecture refactoring plan
- `/.github/PROJECT_DOCS/adrs/ADR-008-postpone-v3-release.md` - Decision to address issues before v3.0.0 release
- `/STATUS.md` - Current project health and sprint status
