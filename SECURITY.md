# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 4.x     | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in this
project, please report it responsibly.

### How to Report

1. **Do NOT open a public issue** for security vulnerabilities
2. Use GitHub's [private vulnerability reporting](https://github.com/BragatteMAS/os-postinstall-scripts/security/advisories/new)

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment:** Within 3 business days
- **Assessment:** Within 7 business days
- **Resolution:** Dependent on severity; critical issues prioritized

## Scope

This policy covers the `os-postinstall-scripts` repository including:

- Shell scripts (Bash, PowerShell)
- Package installation logic
- Dotfiles management
- Configuration files

## Out of Scope

- Third-party packages installed by the scripts (report to package maintainers)
- Issues in upstream tools (apt, brew, winget, etc.)

## Disclosure Policy

- We follow coordinated disclosure
- We will credit reporters in the release notes (unless anonymity is requested)
- Public disclosure after a fix is available and users have had time to update
