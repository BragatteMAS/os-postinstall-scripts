# Code Conventions & Standards

## Shell Script Conventions

### File Naming
- **Scripts**: Use snake_case with `.sh` extension (e.g., `post_install.sh`)
- **Directories**: Use lowercase with underscores (e.g., `auto_install/`)
- **Config files**: Use lowercase with hyphens (e.g., `config-file.conf`)
- **Documentation**: Use UPPERCASE for main docs (e.g., `README.md`)

### Shebang and Headers
All scripts must start with:
```bash
#!/usr/bin/env bash
```

Include a header with:
- Description of the script's purpose
- Author information
- License declaration
- Usage instructions

### Code Style

#### Indentation
- Use 4 spaces for indentation (no tabs)
- Align continuation lines with the opening delimiter

#### Variables
- **Constants**: UPPERCASE with underscores (e.g., `APT_INSTALL`)
- **Local variables**: lowercase with underscores (e.g., `local_path`)
- **Global variables**: Prefix with `g_` (e.g., `g_system_type`)
- Always quote variables: `"$variable"` not `$variable`
- Use `${variable}` when concatenating

#### Functions
```bash
# Function naming: verb_noun format
function install_packages() {
    local package_list="$1"
    # Function body
}

# Alternative syntax for simple functions
update_system() {
    sudo apt update && sudo apt upgrade -y
}
```

#### Arrays
```bash
# Declare arrays explicitly
declare -a packages=(
    "package1"
    "package2"
    "package3"
)

# Iterate over arrays
for package in "${packages[@]}"; do
    echo "Installing $package"
done
```

### Error Handling
- Always check command execution status
- Use `set -euo pipefail` for strict error handling
- Provide meaningful error messages
- Clean up on exit with trap

```bash
# Error handling template
set -euo pipefail
trap cleanup EXIT

cleanup() {
    # Cleanup code here
    echo "Cleaning up..."
}

# Check command success
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed" >&2
    exit 1
fi
```

### Comments
- Use `#` for single-line comments
- Place comments above the code they describe
- Use meaningful comments that explain "why" not "what"
- Section headers use multiple `#` characters

```bash
# ============================================================================ #
# SECTION: Package Installation
# ============================================================================ #

# Install development tools - required for building from source
install_dev_tools() {
    # Implementation
}
```

### Output and Logging
- Use `echo` for normal output
- Use `>&2` for error messages
- Implement color coding for better visibility
- Add verbosity levels when appropriate

```bash
# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
```

## Git Conventions

### Branch Naming
- `main` or `master`: Stable release branch
- `develop`: Development branch
- `feature/description`: New features
- `bugfix/description`: Bug fixes
- `hotfix/description`: Urgent fixes
- `refactor/description`: Code refactoring

### Commit Messages
Follow conventional commits format:
```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(installer): add support for Ubuntu 24.04

- Added Ubuntu 24.04 to supported distributions
- Updated package names for new versions
- Tested on fresh Ubuntu 24.04 installation

Closes #123
```

## Testing Standards

### Script Testing
- Test on all supported distributions
- Use shellcheck for static analysis
- Create test scenarios for:
  - Fresh installations
  - Upgrade scenarios
  - Error conditions
  - User interruptions

### Test Structure
```bash
tests/
├── unit/           # Unit tests for functions
├── integration/    # Full script tests
├── fixtures/       # Test data
└── run_tests.sh    # Test runner
```

## Documentation Standards

### README Files
- Clear installation instructions
- Prerequisites listed upfront
- Usage examples with actual commands
- Troubleshooting section
- Contributing guidelines

### Inline Documentation
- Document complex logic
- Explain non-obvious decisions
- Include examples for functions
- Reference external resources

### Change Documentation
- Update CHANGELOG.md for all releases
- Document breaking changes clearly
- Include migration guides when needed

## Security Best Practices

### Script Security
- Never hardcode passwords or secrets
- Validate all user inputs
- Use absolute paths for critical operations
- Check file permissions before modifications
- Avoid using `eval` or executing arbitrary code

### System Security
- Minimize use of `sudo` where possible
- Log all system modifications
- Verify package sources
- Check GPG signatures when available
- Implement confirmation prompts for destructive actions

## Performance Guidelines

### Efficiency
- Minimize external command calls in loops
- Use built-in bash features when possible
- Cache repeated command results
- Implement progress indicators for long operations

### Resource Usage
- Clean up temporary files
- Don't load entire files into memory
- Use streaming for large data processing
- Implement timeouts for network operations

## Compatibility Standards

### Cross-Distribution Support
- Test on multiple distributions
- Use distribution-agnostic commands when possible
- Implement detection for distribution-specific features
- Provide fallbacks for missing commands

### Version Support
- Support current stable and LTS releases
- Document minimum version requirements
- Implement version checking
- Provide upgrade paths

## Review Checklist

Before submitting code:
- [ ] Shellcheck passes without warnings
- [ ] Scripts are tested on target distributions
- [ ] Documentation is updated
- [ ] Comments explain complex logic
- [ ] Error handling is comprehensive
- [ ] No hardcoded values that should be configurable
- [ ] Follows naming conventions
- [ ] Includes appropriate logging
- [ ] Handles user interruption gracefully
- [ ] Cleans up on exit