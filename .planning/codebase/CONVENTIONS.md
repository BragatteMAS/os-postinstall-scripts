# Coding Conventions

**Analysis Date:** 2026-02-08

## Naming Patterns

**Files:**
- Shell scripts: `lowercase-with-hyphens.sh` (e.g., `rust-cli.sh`, `brew-cask.sh`)
- Core modules: `lowercase.sh` (e.g., `logging.sh`, `errors.sh`, `platform.sh`)
- Package lists: `lowercase.txt` or `lowercase-with-hyphens.txt` (e.g., `apt.txt`, `ai-tools.txt`)
- PowerShell: `lowercase.ps1` / `lowercase.psm1` (e.g., `winget.ps1`, `logging.psm1`)

**Functions (Shell):**
- snake_case: `detect_os()`, `log_info()`, `is_installed()`, `load_packages()`
- Function definitions: `function_name() { ... }` syntax

**Variables:**
- UPPERCASE for constants and env vars: `PROJECT_ROOT`, `DRY_RUN`, `VERBOSE`
- lowercase for local variables: `os`, `distro`, `pkg_file`

## Code Style

**Formatting:**
- 2-space indentation for shell scripts
- ShellCheck for static analysis

**Shebang:**
- Always `#!/usr/bin/env bash`

**Strict Mode:**
- Every script starts with `set -o pipefail` (no set -e, per ADR-001)

## Import Organization

**Shell:**
```bash
#!/usr/bin/env bash
set -o pipefail

# Resolve project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source core modules
source "$PROJECT_ROOT/src/core/logging.sh"
source "$PROJECT_ROOT/src/core/platform.sh"

# Constants
readonly PACKAGE_DIR="$PROJECT_ROOT/data/packages"

# Functions
install_packages() { ... }

# Main execution
main() { ... }
main "$@"
```

## Error Handling

**Shell Patterns:**
- `set -o pipefail` at top of every script (no set -e, per ADR-001)
- `src/core/errors.sh`: trap-based cleanup, failure tracking, summary at end
- Conditional checks: `if ! command -v tool &>/dev/null; then ...`
- Guard functions: `is_installed()`, `needs_update()` from `src/core/idempotent.sh`

## Logging

**Framework:** Custom color-coded output in `src/core/logging.sh`

**Functions:**
- `log_info "message"` - blue, informational
- `log_warn "message"` - yellow, warnings
- `log_error "message"` - red, errors
- `log_success "message"` - green, success

**Auto-detection:** Colors disabled when stdout is not a terminal.

## Comments

**When to Comment:**
- Script header: description, author
- Complex logic that isn't self-evident
- TODO/FIXME for incomplete work

**Header Pattern:**
```bash
#!/usr/bin/env bash
#######################################
# Script: script-name.sh
# Description: What this script does
# Author: Bragatte
#######################################
```

## Function Design

**Size:** Functions under 50 lines, single responsibility
**Parameters:** Positional args with clear variable names at top
**Return:** Exit codes (0 success, 1 failure); data via stdout

## String Handling

- Double quotes for variable expansion: `"${variable}"`
- Single quotes for literal strings
- Always quote variables in conditionals
- Prefer `[[ ]]` over `[ ]`

## Data Files

**Package lists (`data/packages/*.txt`):**
- One package per line
- `#` for comments
- Empty lines ignored

**Profile composition (`data/packages/profiles/*.txt`):**
- One package list name per line (without .txt extension)
- Maps to `data/packages/<name>.txt`

---

*Convention analysis: 2026-02-08*
