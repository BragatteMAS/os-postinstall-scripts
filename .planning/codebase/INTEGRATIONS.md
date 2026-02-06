# External Integrations

**Analysis Date:** 2026-02-04

## APIs & External Services

**Package Installation:**
- Rustup - Rust installer via `https://sh.rustup.rs`
  - SDK: curl-based installation script
  - Files: `scripts/install/rust-tools.sh`
  - Purpose: Automated Rust language and cargo installation

- UV (Python package manager) - Astral installer via `https://astral.sh/uv/install.sh`
  - SDK: curl-based installation script
  - Files: `scripts/install/ai-tools.sh`, `scripts/install/rust-tools.sh`
  - Purpose: Python package management and tool installation

- Cargo-binstall - Binary installer via `https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh`
  - SDK: curl-based bash script
  - Files: `scripts/install/rust-tools.sh`
  - Purpose: Fast binary installation for Rust tools

- Homebrew - macOS package manager via `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`
  - SDK: curl-based installation script
  - Files: `scripts/install/rust-tools.sh`
  - Purpose: Package installation on macOS

**Repository Access:**
- GitHub API (implicit via Git and GitHub CLI)
  - SDK: GitHub CLI (`gh` command)
  - Purpose: Repository management, cloning, and authentication
  - Files: `scripts/install/git-focused.sh`

**AI/Development Tools:**
- BMAD Method v4.32.0 - AI-enhanced agile framework
  - Integration point: `.github/BMAD/tools/installer/`
  - Provides: CLI tool `bmad` via bin entry point
  - Config: `package.json` (v4.32.0, Node.js 20.0.0+)
  - Purpose: AI agent orchestration and development workflow automation

- MCPs (Model Context Protocol) - Four essential MCPs pre-configured:
  - context7 - Documentation and context library tool
  - fetch - HTTP request utility
  - sequential-thinking - Complex reasoning tool
  - serena - Code analysis and refactoring tool
  - Installation: via npm/node in BMAD environment
  - Files: Installed by BMAD installer at `.github/BMAD/tools/installer/`

## Data Storage

**Databases:**
- Not detected - No persistent database integration. Installation state tracked via shell variables and system state only.

**File Storage:**
- Local filesystem only
  - User configuration: `$HOME/.config/linux-postinstall`
  - Shell profiles: `$HOME/.zshrc`, `$HOME/.bashrc`
  - Installation logs: Generated in `.logs/` (if created during setup)

**Caching:**
- None detected - No caching layer. Direct package manager access on each install.

## Authentication & Identity

**Auth Provider:**
- Custom Git-based authentication (no centralized provider)
  - GitHub SSH keys via `.ssh/config` configuration
  - Implementation: Git authentication for repository access
  - Files: `scripts/install/git-focused.sh` handles GitHub CLI setup

**Multi-User Support:**
- System-level user context detection
  - Current user via `$USER` environment variable
  - Home directory via `$HOME` environment variable
  - Implementation: Runtime detection in `scripts/setup/main.sh`

## Monitoring & Observability

**Error Tracking:**
- Not detected - No external error tracking service. Errors output to stdout/stderr only.

**Logs:**
- Shell script output (stdout/stderr)
  - Approach: Console output with color-coded messages via bash color variables
  - Controlled by: `VERBOSE_OUTPUT`, `ENABLE_DEBUG` environment variables
  - Files: All scripts in `scripts/` use RED, GREEN, YELLOW, BLUE, PURPLE color codes
  - Manual test suite: Output captured in `tests/manual/` directory structure

**Metrics:**
- Not detected - No metrics collection or analytics.

## CI/CD & Deployment

**Hosting:**
- GitHub repository (self-hosted on GitHub platform)
  - URL: `https://github.com/BragatteMAS/os-postinstall-scripts`
  - Configuration: `package.json` repository field

**CI Pipeline:**
- Workflows removed as of latest commits
  - Previous location: `.github/workflows/`
  - Current state: Manual testing only (see recent commit: "chore: remove CI/CD workflows")
  - Testing approach: All tests on-demand via `make test-*` targets
  - No automated test execution in CI

**Git Hooks:**
- Git hooks directory exists at `.githooks/`
  - Implementation: Not currently enforced (would need to be configured with `git config core.hooksPath`)
  - Purpose: Pre-commit, post-commit hook definitions for future enforcement

## Environment Configuration

**Required env vars (critical for local development):**
- `NODE_ENV` - Sets development vs production mode
- `TEST_MODE` - Enables local test mode
- `OS_TARGET` - Specifies platform (linux, windows, darwin)
- `ENABLE_DEBUG` - Enables debug output
- `VERBOSE_OUTPUT` - Enables verbose logging
- `PREFERRED_SHELL` - Shell selection (bash or zsh)
- `DEFAULT_PROFILE` - Installation profile selection

**Optional env vars:**
- `SKIP_DEPENDENCY_CHECK` - Skip checks for required tools
- `SKIP_PERMISSION_CHECK` - Skip file permission checks
- `DRY_RUN` - Simulate operations without execution
- `SIMULATE_ERRORS` - Inject test failures for validation

**Secrets location:**
- Secrets not stored in repository
  - Git credentials: Standard `~/.ssh/` or `~/.git-credentials`
  - GitHub CLI token: Stored in `~/.config/gh/config.yml` (GitHub CLI standard)
  - API keys: Not used (no external API integrations)

## Webhooks & Callbacks

**Incoming:**
- None detected - No webhook endpoints exposed.

**Outgoing:**
- Git push events (implicit via Git)
  - Trigger: Manual git commit and push operations
  - Target: GitHub repository

---

*Integration audit: 2026-02-04*
