# GitHub Configuration

This directory contains GitHub-specific configuration files for the os-postinstall-scripts project.

## Workflows

### ShellCheck (`shellcheck.yml`)
- Runs on every push and PR that modifies shell scripts
- Validates all `.sh` files and scripts with bash shebang
- Ensures code quality and catches common shell scripting issues

### Test Scripts (`test-scripts.yml`)
- Tests installation scripts on Ubuntu 20.04, 22.04, and 24.04
- Runs syntax checks on all shell scripts
- Checks for common issues like Windows line endings
- Runs weekly to ensure compatibility

### Documentation Check (`documentation.yml`)
- Validates all Markdown files with markdownlint
- Checks for broken links in documentation
- Ensures all required documentation files are present
- Runs on changes to `.md` files or `.ai/` directory

### Dependency Check (`dependency-check.yml`)
- Monitors for security vulnerabilities in dependencies
- Runs daily and on dependency changes
- Currently checks shell script dependencies

## Branch Protection

The `main` branch is protected with the following rules:
- Requires pull request reviews before merging
- Dismisses stale PR reviews when new commits are pushed
- Requires 1 approving review
- Prevents force pushes and deletions
- Recommended: Run status checks before merging

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on contributing to this project.