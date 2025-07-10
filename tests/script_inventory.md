# Script Inventory - Pre-Reorganization

## Public Entry Points (DO NOT CHANGE)
These are the main entry points users interact with:

1. `setup.sh` - Universal installer entry point
2. `linux/post_install.sh` - Linux full installation
3. `install_rust_tools.sh` - Rust tools installer
4. `zshrc` - Zsh configuration file
5. `windows/win11.ps1` - Windows installer

## Internal Scripts

### Linux Auto Scripts (`linux/auto/`)
- `auto_apt.sh` - APT package installations
- `auto_flat.sh` - Flatpak installations  
- `auto_snap.sh` - Snap package installations
- `anaconda3.sh` - Anaconda installation
- `flavors.sh` - (Currently non-functional, just comments)

### Distribution-Specific Scripts (`linux/distros/`)
Current structure:
```
linux/distros/
├── Mint/
├── POP-OS/
└── Ubuntu/
```

## Naming Issues to Fix

### Inconsistent Naming
- `post_install.sh` vs `install_rust_tools.sh` (underscore vs hyphen)
- `auto_apt.sh` vs other scripts
- `posintall_old_POP-OS20.sh` (typo in "posintall")

### Recommended Naming Convention
Use hyphens for all scripts: `script-name.sh`

## Functionality Mapping

| Current Function | Located In | Proposed Location |
|-----------------|------------|-------------------|
| APT packages | `post_install.sh` + `auto_apt.sh` | `linux/install/apt.sh` |
| Snap packages | `post_install.sh` + `auto_snap.sh` | `linux/install/snap.sh` |
| Flatpak | `post_install.sh` + `auto_flat.sh` | `linux/install/flatpak.sh` |
| Rust tools | `install_rust_tools.sh` | `install-rust-tools.sh` |
| Verification | zshrc `checktools()` | `tests/verify-installation.sh` |

## Scripts with Issues

### Missing Shebang
(To be populated by test harness)

### Non-Executable Scripts
(To be populated by test harness)

### Scripts with Placeholder URLs
- `setup.sh` - Contains `SEU_USUARIO`
- `install_rust_tools.sh` - Contains `SEU_USUARIO`

## User Workflows to Preserve

1. **Quick Rust Install**
   ```bash
   ./install_rust_tools.sh
   ```

2. **Full Linux Install**
   ```bash
   cd linux && sudo ./post_install.sh
   ```

3. **Zsh Only**
   ```bash
   cp zshrc ~/.zshrc && source ~/.zshrc
   ```

These workflows must continue to work exactly the same after reorganization.