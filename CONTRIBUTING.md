# Contributing to OS Post-Install Scripts

Thank you for your interest in contributing. This document covers how to set up the project locally, follow our coding conventions, and submit changes.

## Table of Contents

- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Style Guide](#style-guide)
- [Commit Conventions](#commit-conventions)
- [Branch Strategy](#branch-strategy)
- [Pull Request Process](#pull-request-process)
- [ShellCheck](#shellcheck)
- [Adding Packages](#adding-packages)
- [Adding Platform Support](#adding-platform-support)
- [Development Methodology](#development-methodology)
- [Reporting Issues](#reporting-issues)

## Getting Started

### Requirements

- Bash 4.0+ (macOS ships 3.2; `brew install bash` for 5.x)
- [ShellCheck](https://www.shellcheck.net/) installed locally
- Git

### Development Setup

```bash
git clone https://github.com/BragatteMAS/os-postinstall-scripts.git
cd os-postinstall-scripts
```

### Running Tests

```bash
bash tests/test-dotfiles.sh
bash tests/test-linux.sh
```

### Dry-Run to Test Changes

Always verify your changes with dry-run before testing for real:

```bash
./setup.sh --dry-run
```

This simulates the full install process without making any changes to the system.

## Project Structure

```
os-postinstall-scripts/
├── setup.sh                    # Main entry point (Linux/macOS)
├── setup.ps1                   # Windows entry point
├── config.sh                   # Shared configuration
├── src/
│   ├── core/                   # Shared modules
│   │   ├── logging.sh          #   Log functions ([OK], [ERROR], [WARN], etc.)
│   │   ├── platform.sh         #   OS detection
│   │   ├── errors.sh           #   Error handling and failure tracking
│   │   ├── progress.sh         #   Step counters and completion summary
│   │   ├── idempotent.sh       #   Idempotency checks (is_*_installed)
│   │   ├── packages.sh         #   Package file loading
│   │   ├── dotfiles.sh         #   Dotfiles symlink management
│   │   └── interactive.sh      #   Interactive selection menus
│   ├── platforms/              # Platform-specific orchestrators
│   │   ├── linux/              #   Linux orchestrator and installers
│   │   ├── macos/              #   macOS orchestrator and installers
│   │   └── windows/            #   Windows modules (PowerShell)
│   ├── install/                # Cross-platform tool installers
│   │   ├── rust-cli.sh         #   Rust CLI tools (bat, eza, fd, ripgrep, etc.)
│   │   ├── fnm.sh              #   fnm + Node.js LTS + pnpm + bun
│   │   ├── uv.sh              #   uv + Python
│   │   ├── ai-tools.sh         #   AI/MCP tools (Claude, Codex, Ollama, etc.)
│   │   └── dev-env.sh          #   Dev environment orchestrator
│   └── installers/
│       └── dotfiles-install.sh #   Dotfiles deployment
├── data/
│   ├── packages/               # Package lists (one per line, # for comments)
│   │   ├── apt.txt, brew.txt, cargo.txt, npm.txt, winget.txt, ...
│   │   └── profiles/           #   minimal.txt, developer.txt, full.txt
│   └── dotfiles/               # Dotfile templates
│       ├── git/, zsh/, bash/, shared/, starship/
└── tests/                      # Test suites
    ├── test-dotfiles.sh
    └── test-linux.sh
```

## Style Guide

These conventions are extracted from the actual codebase. Follow them for consistency.

### Source Guard

Every module that should only be sourced once must start with:

```bash
[[ -n "${_MODULE_NAME_SOURCED:-}" ]] && return 0
readonly _MODULE_NAME_SOURCED=1
```

### Function Exports

Export functions that need to be available in subshells:

```bash
export -f function_name
```

### Variable Quoting

Always quote variable expansions:

```bash
# Good
echo "${variable}"
if [[ -n "${SOME_VAR:-}" ]]; then

# Bad
echo $variable
if [[ -n $SOME_VAR ]]; then
```

### Local Variables

Use `local` for all function-scoped variables:

```bash
my_function() {
    local file_path="$1"
    local result=""
    # ...
}
```

### Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Constants/globals | UPPER_CASE | `DRY_RUN`, `SCRIPT_DIR`, `DATA_DIR` |
| Functions | snake_case | `install_packages`, `load_packages` |
| Private helpers | _underscore_prefix | `_brew_formula_install`, `_parse_entry` |

### Logging

Use the log functions from `src/core/logging.sh`:

```bash
log_ok "Package installed"
log_error "Installation failed"
log_warn "Skipping optional step"
log_info "Starting installation"
log_debug "Variable value: ${var}"
```

These produce formatted output: `[OK]`, `[ERROR]`, `[WARN]`, `[INFO]`, `[DEBUG]`.

### Idempotency

Always check before installing. Use `is_*_installed()` functions before performing actions:

```bash
if is_apt_installed "${package}"; then
    log_ok "${package} already installed"
    return 0
fi
# ... install
```

### Failure Tracking

Track failures instead of aborting:

```bash
FAILED_ITEMS+=("${item}")
```

The project uses a continue-on-failure strategy. Never use `set -e`. Always exit 0 and show failures in the completion summary.

### DRY_RUN Guard

Place the dry-run check after the idempotency check but before any mutation:

```bash
if is_apt_installed "${package}"; then
    log_ok "${package} already installed"
    return 0
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "[DRY_RUN] Would install ${package}"
    return 0
fi

# Actual installation here
```

## Commit Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
type(scope): description

- detail 1
- detail 2
```

### Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature, endpoint, installer, module |
| `fix` | Bug fix, error correction |
| `docs` | Documentation changes |
| `test` | Test-only changes |
| `refactor` | Code restructuring, no behavior change |
| `chore` | Config, tooling, dependencies |

### Scopes

Use phase numbers (`01` through `08`) or module names as scope:

```
feat(05-03): cross-platform Rust CLI tools installer
fix(07-02): DRY_RUN guard placement in snap installer
docs(08-02): rewrite CONTRIBUTING.md
test(05-06): Linux platform test suite
refactor(02-05): remove deprecated scripts/common directory
```

### Guidelines

- Keep the first line under 72 characters
- Each commit should represent one logical change
- Do not mix unrelated changes in a single commit

## Branch Strategy

This project uses GitHub Flow.

- `main` is the default and only long-lived branch (protected)
- Create feature branches from `main`: `feat/description` or `fix/description`
- All changes go through pull requests -- direct pushes to `main` are not accepted
- There is no `develop`, `next`, or `staging` branch

## Pull Request Process

1. Fork the repository and create a feature branch from `main`
2. Make your changes, following the style guide above
3. Write or update tests as needed
4. Run ShellCheck with zero warnings (see below)
5. Test with `--dry-run` to verify behavior
6. Submit a pull request using the [pull request template](.github/pull_request_template.md)
7. Wait for review

### PR Guidelines

- One feature or fix per PR
- Keep PRs focused and reviewable
- Reference related issues with `Closes #N`

## ShellCheck

ShellCheck is **required** for all shell script changes. PRs with ShellCheck warnings will not be merged.

### Install

```bash
# Ubuntu/Debian
sudo apt install shellcheck

# macOS
brew install shellcheck
```

### Run

```bash
find src -name '*.sh' -exec shellcheck -x {} +
```

Note: `src/**/*.sh` glob requires `shopt -s globstar` which is not portable. Use `find` instead.

### Policy

- **Zero warnings required** -- all ShellCheck warnings must be resolved
- If you need to suppress a specific check, use `# shellcheck disable=SCXXXX` with a comment explaining why
- The `-x` flag tells ShellCheck to follow `source` directives

## Adding Packages

1. Edit the appropriate file in `data/packages/` (e.g., `apt.txt`, `brew.txt`, `cargo.txt`)
2. Add one package per line. Use `#` for comments
3. If the package belongs to a specific profile, ensure the package file is listed in the corresponding profile under `data/packages/profiles/`
4. Test with `./setup.sh --dry-run` to verify the package is picked up correctly

### Package File Format

```
# Category header
package-name
another-package

# Another category
third-package
```

Blank lines and lines starting with `#` are ignored by the package loader.

## Adding Platform Support

1. Create an installer script in `src/platforms/<platform>/install/`
2. Follow existing patterns from `apt.sh`, `brew.sh`, or `winget.ps1`
3. Use the idempotency check pattern (`is_*_installed`) before installing
4. Add a dispatch case in the platform's main orchestrator (`main.sh` or `main.ps1`)
5. Test with `--dry-run` on the target platform

## Development Methodology

This project uses structured development practices:

- **GSD (Get Shit Done) workflow** -- phased development with research, planning, and execution stages
- **Architecture Decision Records (ADRs)** -- 7 ADRs document key architectural choices (`.planning/adrs/`)
- **Conventional Commits** -- all 430+ commits follow the conventional format
- **Claude Code as development co-pilot** -- AI-assisted development across all 8 phases
- **Data-driven architecture** -- package lists in text files, not hardcoded arrays

## Reporting Issues

Use the GitHub issue templates:

- **[Bug Report](../../issues/new?template=bug_report.md)** -- for problems, errors, or unexpected behavior
- **[Feature Request](../../issues/new?template=feature_request.md)** -- for new functionality or improvements

When reporting bugs, include:
- Your OS and shell version
- The profile and flags you used
- Output from `./setup.sh --dry-run` if possible

## License

By contributing to this project, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
