# Coding Conventions

**Analysis Date:** 2026-02-04

## Naming Patterns

**Files:**
- Shell scripts: `lowercase-with-hyphens.sh` (e.g., `test-platform.sh`, `lint-scripts.sh`)
- JavaScript/Node files: `camelCase.js` or `kebab-case.js` (mixed usage)
- Configuration files: `lowercase-with-hyphens.yaml` or `lowercase-with-hyphens.json`
- Main entry points: Descriptive names like `main.sh`, `cli.js`, `installer.js`

**Functions (JavaScript):**
- Use camelCase for function names: `formatYamlContent()`, `detectInstallationState()`, `processMarkdownFile()`
- Async functions explicitly declared: `async function functionName() {}`
- Arrow functions for callbacks and short operations

**Functions (Shell):**
- Use snake_case for function names: `show_banner()`, `detect_system()`, `show_menu()`
- Function definitions use `function_name() { ... }` syntax

**Variables:**
- JavaScript: camelCase for all variables (`installDir`, `platformName`, `yamlContent`, `originalCwd`)
- Shell: UPPERCASE for environment variables and constants (`RED='\033[0;31m'`, `REPO_URL`, `SKIP_REQUIREMENTS`)
- Shell: lowercase for local variables (`os`, `distro`, `version`, `arch`)

**Types/Classes:**
- JavaScript: PascalCase for class names (`Installer`, `DependencyResolver`, `WebBuilder`)
- Classes typically export as module exports with single export pattern

## Code Style

**Formatting:**
- No formal linting tool configured (no ESLint, Prettier, or Biome)
- Manual formatting conventions followed in codebase
- Shell scripts use 2-space indentation
- JavaScript files use 2-space indentation

**Linting:**
- ShellCheck for shell scripts (lint tool: `shellcheck`)
- Run via: `npm run dev:lint` or local invocation with `shellcheck script.sh`
- See `.github/TESTING_GUIDELINES.md` for test execution philosophy

**Line Width:**
- YAML formatting disables line wrapping: `lineWidth: -1`
- No hard line limit enforced across codebase

## Import Organization

**JavaScript:**
```javascript
// Order observed:
1. Node.js core modules first (require('fs'), require('path'), require('child_process'))
2. Third-party dependencies (require('js-yaml'), require('commander'), require('chalk'))
3. Local modules (require('./builders/web-builder'), require('./lib/yaml-utils'))
```

**Shell:**
```bash
# Typical structure:
#!/usr/bin/env bash
# Set strict mode
set -euo pipefail
# Load configuration/environment
# Define constants (colors, paths)
# Define functions
# Main execution
```

**Path Aliases:**
- Not used in this codebase
- Full relative paths with `require()` and file access

## Error Handling

**JavaScript Patterns:**
- Try-catch blocks for async operations
- Error propagation with `throw new Error(message)`
- Early exit with `process.exit(1)` for CLI tools
- Synchronous file operations wrapped in try-catch

Example from `bump-core-version.js`:
```javascript
try {
  // operation
  console.log('✓ Success message');
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
```

**Shell Patterns:**
- Strict mode: `set -euo pipefail` (error on failure, undefined vars, pipe failures)
- Exit on error with specific codes: `exit 1` for failures
- Conditional execution: `if [ condition ]; then ... else ... fi`
- Function return status checks: `if ! command-name; then ... fi`

Example from `lint-scripts.sh`:
```bash
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}❌ ShellCheck is not installed!${NC}"
    exit 1
fi
```

## Logging

**Framework:** Custom console output + color formatting (no logging library)

**JavaScript:**
- Direct `console.log()` for output
- Direct `console.error()` for errors
- Color codes via chalk library when imported
- Manual color ANSI codes: `'\x1b[0m'`, `'\x1b[31m'` (red), etc.

Example from `check-environment.js`:
```javascript
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  purple: '\x1b[35m'
};
console.log(`${colors.green}✓${colors.reset} ${tool} found`);
```

**Shell:**
- ANSI color variables defined at top
- Direct echo output with color variables
- Status emojis for visual feedback: ✓, ✗, ⚠, 🔍, 🚀

Example from `test-platform.sh`:
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}✓${NC} Task completed"
```

## Comments

**When to Comment:**
- Function headers with JSDoc/TSDoc style comments
- Licensing and authorship headers in scripts
- Complex logic explanations
- TODO/FIXME comments for incomplete work

**JSDoc/TSDoc Usage:**
- Standard JSDoc format used in utility functions
- Parameter and return type documentation included

Example from `yaml-utils.js`:
```javascript
/**
 * Extract YAML content from agent markdown files
 * @param {string} agentContent - The full content of the agent file
 * @param {boolean} cleanCommands - Whether to clean command descriptions (default: false)
 * @returns {string|null} - The extracted YAML content or null if not found
 */
function extractYamlFromAgent(agentContent, cleanCommands = false) {
```

**Header Comments:**
- Shebang: `#!/usr/bin/env node` or `#!/usr/bin/env bash`
- Description block with file purpose and author
- No license headers (handled in repository root)

## Function Design

**Size:** Functions are kept focused and reasonably sized (most under 50 lines)

**Parameters:**
- Pass objects for multiple parameters in JavaScript
- Single responsibility principle observed
- Optional parameters use defaults: `cleanCommands = false`

**Return Values:**
- Functions return `null` for not-found cases in JavaScript
- Async functions return Promises
- Shell functions return exit codes (0 for success, 1 for failure)
- Data returned via stdout in shell scripts or variable assignment

## Module Design

**Exports:**
- Single class per file typically: `module.exports = ClassName`
- Utility functions exported as object: `module.exports = { functionName1, functionName2 }`
- Mixed exports common: class + utility functions together

Example from `yaml-utils.js`:
```javascript
module.exports = {
  extractYamlFromAgent
};
```

**Barrel Files:**
- Not used in this codebase
- Direct require paths used for dependencies

## Shell Script Conventions

**Shebang:**
- Always use `#!/usr/bin/env bash` for shell scripts
- Allows system-wide bash location resolution

**Path Resolution:**
```bash
# Get script directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"
```

**String Handling:**
- Use double quotes for variable expansion: `"${variable}"`
- Single quotes for literal strings
- Always quote variables in conditionals

**Conditionals:**
- Prefer `[[ ]]` over `[ ]` for bash-specific features
- Long form syntax: `if [[ condition ]]; then ... fi`

## Async Patterns

**JavaScript:**
- Async/await for promise handling
- `.catch()` for error handling in some contexts
- Spinner/loader patterns with `ora` package when installed

Example from `installer.js`:
```javascript
async function initializeModules() {
  if (!chalk) {
    chalk = (await import("chalk")).default;
    ora = (await import("ora")).default;
  }
}
```

## Configuration Files

**YAML/JSON:**
- 2-space indentation for YAML
- Keys in lowercase with hyphens
- Comments prefixed with `#`

**Environment Variables:**
- Use `.env.local` for local development
- Reference via `process.env.VARIABLE_NAME`
- Cross-env for cross-platform environment setting: `cross-env VARIABLE=value script.sh`

---

*Convention analysis: 2026-02-04*
