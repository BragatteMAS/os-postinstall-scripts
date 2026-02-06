# Architecture

**Analysis Date:** 2026-02-04

## Pattern Overview

**Overall:** Layered Bash-based orchestration system with platform-specific implementations and modular configuration-driven execution.

**Key Characteristics:**
- Universal entry point (`scripts/setup/main.sh`) detects OS and delegates to platform implementations
- Configuration-driven through YAML profiles (`configs/profiles/*.yaml`)
- Utility-first design with shared helpers (`scripts/utils/`) sourced by all executors
- Platform isolation with common layer contracts
- Package management abstraction supporting APT, Snap, Flatpak

## Layers

**Presentation/Entry:**
- Purpose: User interface and orchestration decision making
- Location: `scripts/setup/main.sh`, `quick-setup.sh`
- Contains: Menu systems, argument parsing, user interaction flows
- Depends on: Utils (config-loader, profile-loader, logging)
- Used by: End users and CI systems

**Platform Abstraction:**
- Purpose: Handle OS-specific installation mechanics while maintaining common contract
- Location: `platforms/linux/`, `platforms/macos/`, `platforms/windows/`
- Contains: OS-specific installers (apt.sh, snap.sh, flatpak.sh for Linux; main.sh for orchestration)
- Depends on: Utilities, configuration system
- Used by: Main setup script to delegate platform work

**Installation Engine:**
- Purpose: Execute specific tool/package installation with idempotency
- Location: `scripts/install/` (universal) + `platforms/<os>/install/` (platform-specific)
- Contains: Tool-specific installers (ai-tools.sh, rust-tools.sh, bmad.sh, git-focused.sh)
- Depends on: Utils, platform handlers, configuration
- Used by: Platform layer to install specific packages

**Utility/Shared Services:**
- Purpose: Provide cross-cutting functionality (logging, configuration, profiles)
- Location: `scripts/utils/`
- Contains: logging.sh, config-loader.sh, profile-loader.sh, package-safety.sh, check-requirements.sh
- Depends on: Nothing (foundational layer)
- Used by: All other layers

**Configuration/Data:**
- Purpose: Define installation profiles and system settings
- Location: `configs/profiles/` (installation profiles), `configs/settings/`, `configs/templates/`
- Contains: YAML files defining package lists, post-install actions, platform requirements
- Depends on: Nothing (data layer)
- Used by: Config loader and profile loader utilities

## Data Flow

**Interactive Installation Flow:**

1. User runs `./setup.sh` or `./quick-setup.sh`
2. `scripts/setup/main.sh` detects OS (via `detect_system()`)
3. If requirements missing, either skips or executes `scripts/utils/check-requirements.sh`
4. User selects installation profile (minimal, standard, data-scientist, etc.)
5. Profile loader resolves YAML from `configs/profiles/<profile>.yaml`
6. Config loader parses YAML into environment variables via `parse_yaml()` function
7. Platform handler at `platforms/<os>/main.sh` receives loaded configuration
8. Platform handler delegates to specific installers: `apt.sh`, `snap.sh`, `flatpak.sh` (Linux example)
9. Each installer sources utility functions and executes package installations
10. Post-install hooks execute shell configuration, git setup, etc.
11. System verification happens optionally via `platforms/<os>/verify/` scripts

**Configuration Propagation:**

1. YAML profile → Bash associative arrays via `parse_yaml()` function
2. Dot notation keys converted to underscore notation: `packages.languages` → `CONFIG_packages_languages`
3. `get_config()` utility retrieves values with fallback defaults
4. Feature flags via `is_feature_enabled()` function

**State Management:**

- **In-Process**: Environment variables and shell variables during execution
- **Persistent Configuration**: YAML files in `configs/` directory
- **Execution State**: Logged to stderr/stdout with color-coded messages (log_info, log_warning, log_error, log_success)
- **Post-Install State**: Modified system files (.zshrc, git config, etc.)

## Key Abstractions

**Profile System:**
- Purpose: Define reusable installation templates (developer-standard, data-scientist, devops, etc.)
- Examples: `configs/profiles/developer-standard.yaml`, `configs/profiles/data-scientist.yaml`
- Pattern: YAML with sections for packages, configuration, post-install actions, platform-specific overrides

**Configuration Loader:**
- Purpose: Abstract YAML parsing and provide type-safe configuration access
- Examples: `get_config()`, `is_feature_enabled()`, `get_config_list()` in `scripts/utils/config-loader.sh`
- Pattern: Simple YAML parser that converts to environment variables; functions provide type-safe access

**Platform Handler:**
- Purpose: Encapsulate platform-specific logic while maintaining common interface
- Examples: `platforms/linux/main.sh`, `platforms/macos/main.sh`, `platforms/windows/`
- Pattern: Each platform has same directory structure (install/, verify/, config/, utils/) but different implementations

**Package Manager Abstraction:**
- Purpose: Provide unified interface to different package managers (APT, Snap, Flatpak, Brew, etc.)
- Examples: `platforms/linux/install/apt.sh`, `platforms/linux/install/snap.sh`, `platforms/linux/install/flatpak.sh`
- Pattern: Each manager script handles detection, installation, configuration independently

**Installation Scripts:**
- Purpose: Encapsulate complete setup for specific tools
- Examples: `scripts/install/ai-tools.sh` (MCPs + BMAD), `scripts/install/rust-tools.sh`, `scripts/install/git-focused.sh`
- Pattern: Self-contained scripts that source utilities, load config, execute idempotent installation steps

## Entry Points

**Primary Entry:**
- Location: `setup.sh` (symlink to `scripts/setup/main.sh`)
- Triggers: User invokes from repo root
- Responsibilities: Detect OS, handle --profile and --skip-requirements arguments, display menu, delegate to platform handler

**Quick Entry:**
- Location: `quick-setup.sh`
- Triggers: One-command setup from fresh clone
- Responsibilities: Install requirements automatically, then call setup.sh

**Unattended Entry:**
- Location: `scripts/setup/unattended-install.sh`
- Triggers: CI/CD or automation scripts
- Responsibilities: Non-interactive profile-based installation with pre-set options

**AI Tools Installation:**
- Location: `scripts/install/ai-tools.sh`
- Triggers: Called from main.sh menu or standalone
- Responsibilities: Install MCPs (context7, fetch, sequential-thinking, serena) and BMAD Method

**Direct Platform Entry:**
- Location: `platforms/<os>/main.sh`
- Triggers: Advanced users running platform-specific scripts
- Responsibilities: Platform menu system, delegate to specific installers

## Error Handling

**Strategy:** Fail-fast with clear error messages; safe defaults for non-critical operations.

**Patterns:**
- `set -euo pipefail` at top of every script (exit on error, undefined vars, pipe failures)
- `log_error()` function outputs to stderr with [ERROR] prefix
- Requirement checks via `check-requirements.sh` before main execution (can be skipped with `--skip-requirements`)
- APT lock safety via `package-safety.sh` prevents apt conflicts
- Graceful fallback to default config if user config missing
- Installation flags allow skip/retry of failed packages

## Cross-Cutting Concerns

**Logging:**
- Framework: Custom bash functions (log, log_info, log_warning, log_error, log_success)
- Implementation: `scripts/utils/logging.sh` defines colored output functions
- Convention: All scripts source logging.sh; use log_info for info, log_error for failures

**Validation:**
- Configuration validation in `config-loader.sh` via `validate_config()` function
- Requirements checking in `check-requirements.sh` (Bash 4+, Git 2.25+, jq 1.6+)
- Script executability validated in tests via `test_script_executable()`
- YAML profile validation on load (presence checks)

**Authentication:**
- No centralized auth; platform-specific git config setup in `scripts/install/git-focused.sh`
- SSH/GPG setup guided interactively for security
- Sudo required for system package installation; no privilege escalation attempted

---

*Architecture analysis: 2026-02-04*
