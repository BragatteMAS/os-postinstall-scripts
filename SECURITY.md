# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability within OS Post-Install Scripts, please:

1. **DO NOT** open a public issue
2. Email us at: marcelobragatte@gmail.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We'll respond within 48 hours and work with you to resolve the issue responsibly.

## Security Measures

This project implements:
- ✅ Safe APT lock handling (no force removal)
- ✅ Input validation on all user inputs
- ✅ Audit logging of package operations
- ✅ Secure credential handling
- ✅ No hardcoded secrets

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.3.x   | :white_check_mark: |
| 2.2.x   | :white_check_mark: |
| < 2.2   | :x:                |