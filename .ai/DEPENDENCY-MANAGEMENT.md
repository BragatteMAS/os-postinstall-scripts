# Dependency and License Management System

> 🎯 **Purpose**: Maintain up-to-date requirements and license documentation for intellectual property protection

## Overview

This system provides automated tools for:
- 📦 Requirements file generation
- ⚖️ License analysis and compliance
- 🔍 Dependency monitoring
- 📋 IP documentation preparation

## Quick Start

```bash
# Generate all documentation
make all-docs

# Or run individual commands:
make requirements  # Generate requirements files
make licenses     # Analyze licenses
make monitor-deps # Check for changes
make ip-docs      # Create IP package
```

## Tools

### 1. Requirements Generator
**Script**: `.ai/scripts/generate-requirements.sh`

Automatically detects and generates requirements for:
- Python (requirements.txt, Pipfile, pyproject.toml)
- Node.js (package.json, package-lock.json)
- Rust (Cargo.toml, Cargo.lock)
- Go (go.mod, go.sum)
- Ruby (Gemfile)
- PHP (composer.json)

**Output**: `requirements/` directory with:
- Language-specific requirement files
- SBOM.json (Software Bill of Materials)
- Dependency trees and metadata

### 2. License Analyzer
**Script**: `.ai/scripts/analyze-licenses.sh`

Features:
- Identifies all dependency licenses
- Checks license compatibility
- Downloads full license texts
- Creates attribution files
- Generates IP-ready reports

**Output**: `licenses/` directory with:
- LICENSE-SUMMARY.md - Quick overview
- DETAILED-LICENSE-REPORT.md - For IP filing
- License texts archive
- Per-language license reports

### 3. Dependency Monitor
**Script**: `.ai/scripts/monitor-dependencies.sh`

Capabilities:
- Detects dependency changes
- Identifies major version updates
- Security vulnerability scanning
- Git hook integration
- CI/CD ready

**Output**: `.dependency-monitor/` directory

### 4. IP Documentation Generator

Creates a complete package for intellectual property filing:
```bash
make ip-docs
# Creates: .ai/ip-documentation-YYYYMMDD.tar.gz
```

Contains:
- All requirements files
- Complete license analysis
- IP documentation template
- Supporting evidence

## CI/CD Integration

### GitHub Actions
The included workflow (`.github/workflows/dependency-check.yml`) automatically:
- Runs on dependency file changes
- Performs weekly scans
- Comments on PRs with analysis
- Fails on critical issues

### Git Hooks
Install pre-commit hooks:
```bash
bash .ai/scripts/monitor-dependencies.sh --setup-hooks
```

## Best Practices

### For Development
1. Run `make requirements` after adding dependencies
2. Check `make licenses` before releases
3. Monitor changes with `make monitor-deps`
4. Keep baseline updated in `.dependency-monitor/`

### For IP Protection
1. Generate documentation before filing:
   ```bash
   make ip-docs
   ```
2. Review all "Unknown" or "GPL" licenses
3. Ensure proper attribution
4. Document your original contributions

### License Compatibility Quick Reference

| Your License | Safe to Use | Risky | Avoid |
|--------------|-------------|-------|-------|
| Proprietary | MIT, Apache-2.0, BSD | LGPL | GPL, AGPL |
| MIT | All | None | None |
| Apache-2.0 | MIT, Apache-2.0, BSD | GPL-2.0 | None |
| GPL-3.0 | GPL-compatible only | LGPL | Proprietary |

## Troubleshooting

### Missing Tools
The scripts will attempt to install required tools automatically. Manual installation:

```bash
# Python
pip install pip-licenses safety pipreqs

# Node.js
npm install -g license-checker npm-check

# Rust
cargo install cargo-license

# Go
go install github.com/google/go-licenses@latest
```

### Common Issues

**"No requirements found"**
- Ensure you're in the project root
- Check for supported dependency files

**"License Unknown"**
- Manually check the package repository
- Add to `licenses/manual-review.txt`

**"Vulnerability detected"**
- Run `npm audit fix` or `pip install --upgrade [package]`
- Document if false positive

## Maintenance

### Weekly Tasks
- Review dependency updates
- Check security advisories
- Update baselines if needed

### Before Release
- Run `make all-docs`
- Review license changes
- Update CHANGELOG.md

### For IP Filing
1. Run `make ip-docs`
2. Fill out `.ai/templates/IP-DOCUMENTATION.md`
3. Review all "TODO" items
4. Archive the generated package

## Support

For issues or improvements:
1. Check existing scripts in `.ai/scripts/`
2. Review logs in `.dependency-monitor/`
3. Submit issues to the repository

---

Remember: **Good dependency hygiene protects your intellectual property!** 🛡️