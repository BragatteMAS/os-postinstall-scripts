# Codebase Structure

**Analysis Date:** 2026-02-04

## Directory Layout

```
os-postinstall-scripts/
├── scripts/                    # Core executable scripts (cross-platform)
│   ├── setup/                  # Setup and entry points
│   │   ├── main.sh            # Main orchestrator (called by setup.sh)
│   │   ├── with-profile.sh    # Profile-based setup
│   │   ├── ai-project.sh      # AI project initialization
│   │   ├── unattended-install.sh  # Non-interactive setup
│   │   └── apply-template.sh  # Apply configuration templates
│   ├── install/                # Tool-specific installers (OS-agnostic)
│   │   ├── ai-tools.sh        # MCPs + BMAD Method installation
│   │   ├── bmad.sh            # BMAD Method installer
│   │   ├── rust-tools.sh      # Rust-based CLI tools (bat, eza, fd, ripgrep, zoxide)
│   │   └── git-focused.sh     # Git and GitHub configuration
│   ├── utils/                  # Shared utility functions
│   │   ├── logging.sh         # Colored output functions
│   │   ├── config-loader.sh   # YAML configuration parsing
│   │   ├── profile-loader.sh  # Profile loading and validation
│   │   ├── check-requirements.sh  # System requirement verification
│   │   └── package-safety.sh  # APT lock safety utilities
│   └── common/                 # Legacy/deprecated common functions
│
├── platforms/                  # Platform-specific implementations
│   ├── linux/                  # Linux implementations
│   │   ├── main.sh            # Linux menu orchestrator
│   │   ├── post_install.sh    # Post-installation setup
│   │   ├── auto/              # Automatic package detection
│   │   │   ├── auto_apt.sh
│   │   │   ├── auto_flat.sh
│   │   │   └── auto_snap.sh
│   │   ├── bash/              # Bash configuration
│   │   ├── config/            # Linux-specific configs
│   │   ├── distros/           # Distribution detection
│   │   ├── install/           # Linux-specific installers
│   │   │   ├── apt.sh        # APT package manager handler
│   │   │   ├── snap.sh       # Snap package handler
│   │   │   ├── flatpak.sh    # Flatpak package handler
│   │   │   └── desktop-environments.sh  # Desktop env setup
│   │   ├── utils/             # Linux-specific utilities
│   │   └── verify/            # Installation verification
│   │       └── check-installation.sh
│   ├── macos/                  # macOS implementations (minimal)
│   │   ├── main.sh
│   │   └── post_install.sh
│   └── windows/                # Windows implementations (PowerShell)
│       ├── win11.ps1
│       └── setup.ps1
│
├── configs/                    # Configuration files
│   ├── profiles/               # Installation profiles (YAML)
│   │   ├── developer-standard.yaml  # Default profile
│   │   ├── developer-minimal.yaml   # Minimal setup
│   │   ├── data-scientist.yaml      # Data science stack
│   │   ├── devops.yaml              # DevOps tools
│   │   ├── student.yaml             # Student environment
│   │   └── README.md                # Profile documentation
│   ├── settings/               # System settings (YAML)
│   │   ├── settings.yaml           # Current settings
│   │   └── settings.yaml.default   # Default template
│   ├── shell/                  # Shell configuration files
│   │   ├── zshrc               # Zsh configuration (symlinked to ~/.zshrc)
│   │   ├── bashrc              # Bash configuration
│   │   ├── aliases.sh          # Aliases definitions
│   │   └── functions.sh        # Shell functions
│   └── templates/              # Reusable configuration templates
│
├── docs/                       # Documentation
│   ├── guides/                 # User guides
│   │   ├── user-guide.md
│   │   ├── ai-tools-setup.md
│   │   └── troubleshooting.md
│   ├── contributing/           # Contribution guides
│   ├── architecture/           # Architecture decisions (ADRs)
│   └── core-architecture.md    # System architecture overview
│
├── tests/                      # Test suite
│   ├── unit/                   # Unit tests
│   │   └── test_*.sh          # Individual test scripts
│   ├── integration/            # Integration tests
│   ├── manual/                 # Manual testing guides
│   │   ├── smoke/              # Smoke tests
│   │   ├── integration/        # Integration test runners
│   │   └── run-story-tests.sh  # Story-based testing
│   ├── security/               # Security testing
│   ├── guides/                 # Testing guides
│   ├── results/                # Test results/reports
│   ├── test_harness.sh         # Main test runner
│   └── script_inventory.md     # Script catalog
│
├── tools/                      # Development tools
│   ├── check/                  # Verification tools
│   │   └── ai-tools.sh        # AI tools verification
│   ├── dev/                    # Development helpers
│   ├── update/                 # Update utilities
│   │   └── bmad.sh            # BMAD Method updater
│   └── local-dev/             # Local development testing
│
├── share/                      # Shared resources
│   ├── examples/               # Example configurations
│   └── exports/                # Export functions
│
├── .github/                    # GitHub configuration
│   └── PROJECT_DOCS/adrs/      # Architecture Decision Records
│
├── .agent-os/                  # Agent-OS backup (complete system backup)
│
├── agent-os -> .agent-os       # Symlink for convenience
│
├── .claude/                    # Claude AI context
│
├── .planning/                  # GSD planning documents
│   └── codebase/               # Codebase analysis docs
│
├── setup.sh                    # Main entry point (symlink to scripts/setup/main.sh)
├── quick-setup.sh              # One-command quick setup
├── package.json                # NPM project metadata
├── Makefile                    # Build and test targets
├── README.md                   # Project overview
├── CLAUDE.md                   # AI context and guidelines
├── PRD.md                      # Product Requirements Document
├── ROADMAP.md                  # Development roadmap
├── STATUS.md                   # Current project status
├── TESTING.md                  # Testing strategy
├── STORIES.md                  # User stories
├── CHANGELOG.md                # Version history
├── CONTRIBUTING.md             # Contribution guidelines
├── REQUIREMENTS.md             # System requirements
├── SECURITY.md                 # Security policy
├── LICENSE                     # MIT License
├── .gitignore                  # Git ignore patterns
├── .gitattributes              # Git attributes
└── .env.local.example          # Environment variables template
```

## Directory Purposes

**scripts/:**
- Purpose: Cross-platform executable scripts serving as the main codebase
- Contains: Setup orchestration, tool installers, utility functions
- Key files: `setup/main.sh`, `install/ai-tools.sh`, `utils/config-loader.sh`

**platforms/:**
- Purpose: Isolate OS-specific implementation details
- Contains: OS-specific installers, configuration, verification
- Pattern: Each OS folder mirrors the other for consistency; Linux most complete, macOS basic, Windows minimal

**configs/:**
- Purpose: Store user-modifiable configuration files and templates
- Contains: Installation profiles (YAML), shell configs, settings templates
- Key files: `profiles/*.yaml` define what gets installed

**docs/:**
- Purpose: User and developer documentation
- Contains: Setup guides, architecture decisions, contribution guidelines
- Committed: Yes, part of source control

**tests/:**
- Purpose: Testing framework for validation and verification
- Contains: Unit tests, integration tests, manual testing procedures
- Pattern: Test files match the code they test (test_module.sh for module.sh)

**tools/:**
- Purpose: Development and maintenance utilities
- Contains: BMAD updater, AI tools verification, local dev testing
- Pattern: Executable scripts that support development workflow

**share/:**
- Purpose: Shared resources and examples
- Contains: Example configurations, export functions
- Generated: No, maintained manually

## Key File Locations

**Entry Points:**
- `setup.sh`: Root entry point (symlink to scripts/setup/main.sh)
- `quick-setup.sh`: One-command setup with auto-requirement installation
- `scripts/setup/main.sh`: Main orchestrator with OS detection
- `platforms/<os>/main.sh`: Platform-specific orchestrators

**Configuration:**
- `configs/profiles/developer-standard.yaml`: Default installation profile
- `configs/settings/settings.yaml`: User settings (created on first run)
- `configs/settings/settings.yaml.default`: Default settings template
- `configs/shell/zshrc`: Zsh configuration with 1700+ lines of optimizations

**Core Logic:**
- `scripts/utils/config-loader.sh`: YAML parsing and configuration retrieval
- `scripts/utils/profile-loader.sh`: Profile loading and validation
- `scripts/utils/logging.sh`: Logging functions with color output
- `scripts/install/ai-tools.sh`: MCPs and BMAD Method installation
- `platforms/linux/install/apt.sh`: APT package manager handler

**Testing:**
- `tests/test_harness.sh`: Main test runner
- `tests/unit/`: Unit test scripts
- `tests/manual/run-story-tests.sh`: Story-based integration testing

## Naming Conventions

**Files:**
- Executables: Lowercase with hyphens (e.g., `config-loader.sh`, `rust-tools.sh`)
- YAML profiles: Hyphenated adjective pairs (e.g., `developer-standard`, `data-scientist`)
- Test files: Prefix with `test_` then module name (e.g., `test_config_loader.sh`)
- Shell functions: Lowercase with underscores (e.g., `log_error()`, `get_config()`)

**Directories:**
- Core functionality: Descriptive nouns (scripts, platforms, configs, docs, tests, tools)
- Feature directories: Hyphenated lowercase (e.g., `local-dev`, `desktop-environments`)
- Platform names: Lowercase OS names (linux, macos, windows)

**Shell Functions:**
- Logging: `log`, `log_info`, `log_warning`, `log_error`, `log_success`
- Configuration: `get_config`, `is_feature_enabled`, `get_config_list`, `load_config`
- Profiles: `load_profile`, `list_profiles`, `parse_profile_section`
- Validation: `check_requirements`, `validate_config`

## Where to Add New Code

**New Feature (e.g., new package manager support):**
- Primary code: `platforms/linux/install/newmanager.sh` (or appropriate platform)
- Integration: Call from `platforms/linux/main.sh` menu system
- Tests: `tests/unit/test_newmanager.sh` and `tests/integration/test_newmanager_integration.sh`
- Configuration: Add package lists to relevant profiles in `configs/profiles/*.yaml`

**New Component/Module (e.g., new installer script):**
- Implementation: `scripts/install/myfeature.sh` (if cross-platform) or `platforms/<os>/install/myfeature.sh`
- Utilities: Add helper functions to appropriate file in `scripts/utils/`
- Configuration: Reference in `configs/settings/settings.yaml.default` if configurable
- Documentation: Add to `docs/guides/` with examples

**Utilities (shared helpers):**
- Shared helpers: `scripts/utils/mynew-util.sh` (must be sourced by callers)
- Platform-specific: `platforms/<os>/utils/myutil.sh`
- Pattern: Export functions with `export -f function_name` so child scripts can use them

**Documentation:**
- User guides: `docs/guides/` with markdown files
- Architecture decisions: `.github/PROJECT_DOCS/adrs/` with ADR-XXX-title.md format
- API/function docs: JSDoc-style comments in shell scripts (# param, # return, # example)

**Configuration/Data:**
- Installation profiles: `configs/profiles/newprofile.yaml` following developer-standard.yaml structure
- Settings: Add keys to `configs/settings/settings.yaml.default`
- Shell config: Add to `configs/shell/` files

## Special Directories

**platforms/:**
- Purpose: Platform-specific code isolation
- Generated: No
- Committed: Yes
- Structure: Each OS (linux/macos/windows) has identical directory layout (install/, verify/, config/, utils/)
- Maintenance: Changes here affect only specific OS behavior

**.agent-os/:**
- Purpose: Complete Agent-OS backup for system migration
- Generated: Yes (created by backup script)
- Committed: Yes (committed for reference)
- Contents: Full system snapshot including all dotfiles and configurations

**.planning/codebase/:**
- Purpose: GSD (Get Shit Done) codebase analysis and planning documents
- Generated: Yes (created by `/gsd:map-codebase` command)
- Committed: Yes
- Contents: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md, STACK.md, INTEGRATIONS.md

**sprint-archives/:**
- Purpose: Historical sprint documentation and implementation tasks
- Generated: Yes
- Committed: Yes (for historical reference)
- Pattern: Directory per version (v3.2.0, etc.) containing sprint artifacts

## Code Layout Principles

1. **Platform Independence First**: Put code in `scripts/` unless it must be platform-specific
2. **Centralized Utilities**: All shared functions in `scripts/utils/` with clear exports
3. **Configuration Driven**: Use YAML profiles and config-loader for all customization
4. **Clear Separation**: Platform code only in `platforms/<os>/` directories
5. **Test Co-location**: Test files parallel source structure
6. **Documentation Proximity**: Guides live in `docs/guides/` with links from code

---

*Structure analysis: 2026-02-04*
