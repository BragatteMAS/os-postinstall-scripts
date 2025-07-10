# Technical Project Context

## Repository Structure

```
os-postinstall-scripts/
├── .ai/                      # AI context and documentation (BMad Method)
│   ├── README.md            # Project overview for AI assistants
│   ├── conventions/         # Coding standards and conventions
│   ├── patterns/           # Common implementation patterns
│   └── context/            # This file - detailed technical context
├── ai-context-template/     # AI documentation templates
├── bmad-core/              # BMad Method core files
├── common/                 # Shared utilities and tasks
├── dist/                   # Distribution files
├── docs/                   # BMad Method documentation
├── expansion-packs/        # BMad Method expansion packs
├── linux/                  # Linux-specific scripts
│   ├── auto/              # Automated installation modules
│   │   ├── auto_apt.sh    # APT package installations
│   │   ├── auto_flat.sh   # Flatpak installations
│   │   ├── auto_snap.sh   # Snap package installations
│   │   └── flavors.sh     # Distribution flavors detection
│   ├── bash/              # Bash configuration files
│   │   ├── bashrc.sh      # Bash configuration
│   │   └── vscode_list_extensions.txt
│   ├── distros/           # Distribution-specific scripts
│   │   ├── Mint/          # Linux Mint specific
│   │   ├── POP-OS/        # Pop!_OS specific
│   │   └── Ubuntu/        # Ubuntu specific
│   └── post_install.sh    # Main installation script
├── mac/                    # macOS scripts (future implementation)
├── tools/                  # Build and utility tools
├── windows/                # Windows scripts
│   └── win11.ps1          # Windows 11 post-install script
├── install_rust_tools.sh   # Rust development tools installer
├── setup.sh               # Project setup script
├── zshrc                  # Zsh configuration file
├── zshrc-prd.md          # Zsh configuration documentation
├── zshrc_rust_integration.zsh # Rust-specific Zsh configuration
├── Makefile              # Build automation
├── package.json          # Node.js project configuration
└── README.md             # Main project documentation
```

## Key Components

### Main Installation Script (`linux/post_install.sh`)
- Entry point for Linux post-installation automation
- Orchestrates all installation and configuration tasks
- Handles user interaction and confirmation prompts
- Sources modular components from `auto/` directory
- Implements error handling and logging

### Modular Installation Components (`linux/auto/`)
- **auto_apt.sh**: Handles APT package manager installations
- **auto_flat.sh**: Manages Flatpak application installations
- **auto_snap.sh**: Controls Snap package installations
- **flavors.sh**: Detects and handles distribution-specific variations

### Distribution-Specific Scripts (`linux/distros/`)
- Customized scripts for different Linux distributions
- Handles version-specific package names and repositories
- Manages distribution-specific configurations
- Currently supports: Ubuntu, Pop!_OS, Linux Mint

### Shell Configuration Files
- **bashrc.sh**: Bash shell customizations and aliases
- **zshrc**: Zsh shell configuration with enhanced features
- **zshrc_rust_integration.zsh**: Rust development environment for Zsh

### Cross-Platform Support
- **windows/win11.ps1**: PowerShell script for Windows 11 setup
- **mac/**: Placeholder for future macOS support
- Demonstrates multi-OS architecture potential

## Data Flow

```
User Execution
     ↓
post_install.sh (Main Script)
     ↓
Distribution Detection (flavors.sh)
     ↓
Package Manager Selection
     ├── auto_apt.sh (Debian-based)
     ├── auto_flat.sh (Flatpak)
     └── auto_snap.sh (Snap)
     ↓
Installation & Configuration
     ↓
Shell Configuration (bashrc/zshrc)
     ↓
Completion & Cleanup
```

## External Integrations

### Package Repositories
- Official distribution repositories (APT)
- Flatpak repositories (Flathub)
- Snap Store
- Third-party PPAs and repositories
- Direct downloads from vendors

### Development Tools
- VS Code and extensions
- Git and Git LFS
- Docker and container tools
- Programming language environments (Rust, Node.js, Python)
- Database tools (MongoDB Compass, pgAdmin, DBeaver)

### System Tools
- System monitoring (Stacer, htop, btop)
- Backup solutions (Timeshift)
- Virtualization (VirtualBox)
- Remote access (OpenSSH, TigerVNC)

## Technical Decisions

### Script Architecture
- **Modular Design**: Separated concerns into focused scripts
- **Distribution Agnostic Core**: Main logic works across distributions
- **Extensibility**: Easy to add new distributions or package managers
- **User Safety**: Confirmation prompts and non-destructive defaults

### Technology Choices
- **Bash**: Universal shell scripting for maximum compatibility
- **Native Package Managers**: Leverages distribution-provided tools
- **Multiple Installation Methods**: APT, Snap, Flatpak for flexibility
- **Version Control**: Git-based for easy updates and contributions

### Error Handling Strategy
- Graceful failure with informative messages
- Continue on non-critical errors
- Log all operations for debugging
- Cleanup on script exit

## Development Environment

### Prerequisites
- Bash 4.0 or higher
- Git for version control
- sudo/root access for system modifications
- Internet connection for package downloads

### Testing Requirements
- Virtual machines for each supported distribution
- Fresh OS installations for clean testing
- Network connectivity for package downloads
- Sufficient disk space for all packages

### Development Tools
- ShellCheck for script validation
- Git for version control
- Text editor with Bash syntax highlighting
- Virtual machine software (VirtualBox, VMware, etc.)

## Configuration Management

### User Preferences
- Package selection stored in script arrays
- Easy customization by editing package lists
- Shell preference (bash vs zsh) configurable
- Development tools optional installation

### System Settings
- Firewall configuration (gufw)
- System monitoring setup
- Development environment paths
- Shell aliases and functions

## Security Considerations

### Script Security
- No hardcoded passwords or secrets
- Validates package sources
- Uses official repositories where possible
- Implements safe download practices

### System Security
- Firewall setup included (gufw)
- SSH server configuration
- VPN client support (OpenConnect)
- Regular system update enforcement

## Performance Optimization

### Installation Efficiency
- Batch operations where possible
- Minimal redundant package manager updates
- Parallel downloads when supported
- Progress indication for long operations

### Resource Management
- Cleanup temporary files
- Efficient package caching
- Minimal memory footprint
- Network bandwidth consideration

## Future Enhancements

### Planned Features
- macOS support completion
- GUI installation wizard
- Custom package list profiles
- Automated testing framework
- Configuration backup/restore

### Architecture Improvements
- Plugin system for extensions
- Cloud-based configuration sync
- Multi-user support
- Rollback capabilities
- Installation verification

## BMad Method Integration

The project now incorporates the BMad Method for:
- Structured AI assistance documentation
- Consistent development patterns
- Enhanced contribution guidelines
- Automated documentation generation
- Improved project maintainability

## Maintenance Guidelines

### Regular Updates
- Package list maintenance
- Distribution version support
- Security patch integration
- Documentation updates
- Community contribution review

### Version Support Policy
- Current stable release + 1 previous
- LTS versions get extended support
- Clear EOL communication
- Migration guides for major changes