# Installation Profiles

Profiles allow you to customize what gets installed based on your needs. Each profile is a curated collection of tools and configurations for specific use cases.

## Available Profiles

### 🚀 developer-standard
**For:** Full-stack developers, general software development  
**Install time:** ~15 minutes  
**Includes:** All essential development tools, modern CLI replacements, multiple languages

### ⚡ developer-minimal
**For:** Quick setup, containers, cloud development  
**Install time:** ~5 minutes  
**Includes:** Git, Docker, VS Code, Python, Node.js - just the essentials

### 🔧 devops
**For:** Infrastructure engineers, SREs, Cloud architects  
**Install time:** ~20 minutes  
**Includes:** Terraform, Ansible, K8s tools, cloud CLIs, monitoring tools

### 📊 data-scientist
**For:** ML engineers, Data analysts, Researchers  
**Install time:** ~25 minutes  
**Includes:** Python scientific stack, R, Jupyter, data visualization tools

### 📚 student
**For:** CS students, learners, educational environments  
**Install time:** ~15 minutes  
**Includes:** Multiple languages, educational IDEs, documentation tools

## Using Profiles

### Quick Start
```bash
# Interactive selection
./setup.sh

# Use specific profile
./setup.sh --profile minimal

# See what would be installed
./setup.sh --profile devops --dry-run
```

### Commands
```bash
# List all profiles
./setup.sh --list

# Show profile details
./setup.sh --details student

# Help
./setup.sh --help
```

## Creating Custom Profiles

1. Copy an existing profile as a template:
```bash
cp profiles/developer-minimal.yaml profiles/my-profile.yaml
```

2. Edit the YAML file to include your desired packages:
```yaml
name: my-profile
description: My custom development setup
author: Your Name
version: 1.0.0

packages:
  version_control:
    - git
  
  editors:
    - vscode
    - neovim
  
  languages:
    - rust
    - go
```

3. Use your profile:
```bash
./setup.sh --profile my-profile
```

## Profile Structure

Each profile is a YAML file with:

- **Metadata**: name, description, author, version
- **Packages**: Organized by category
- **Configuration**: Tool-specific settings
- **Post-install**: Actions after installation
- **Requirements**: System requirements

## Integration with Main Setup

The traditional `setup.sh` still works and installs the `developer-standard` profile by default:

```bash
# These are equivalent:
./setup.sh
./setup.sh --profile developer-standard
```

## Tips

1. **Start minimal**: Use `developer-minimal` and add tools as needed
2. **Check requirements**: Some profiles need more RAM/disk space
3. **Dry run first**: Use `--dry-run` to see what will be installed
4. **Mix and match**: Install a minimal profile, then add specific tools

## Contributing

To contribute a new profile:

1. Create a meaningful profile for a specific use case
2. Test it on a fresh system
3. Document system requirements
4. Submit a pull request

Profile naming convention: `{role}-{variant}.yaml`  
Examples: `developer-minimal.yaml`, `devops-kubernetes.yaml`