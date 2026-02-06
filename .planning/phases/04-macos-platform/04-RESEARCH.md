# Phase 4: macOS Platform - Research

**Researched:** 2026-02-06
**Domain:** Homebrew package management, macOS automation, profile-based installation
**Confidence:** HIGH

## Summary

Phase 4 brings macOS support to functional parity with Linux by implementing Homebrew-based package installation with profile selection (minimal, developer, full). Research focused on three critical areas: (1) Homebrew installation and idempotency patterns, (2) profile-based package management using data files, and (3) macOS-specific considerations including Bash version upgrades and PATH configuration.

The standard approach is to use **Homebrew Bundle with Brewfiles** for declarative, idempotent package management. However, the project's existing architecture uses simple text files (data/packages/*.txt) with custom shell logic, which is simpler and aligns with the "zero external dependencies" and KISS principles. The hybrid approach—using `brew install` with manual idempotency checks—matches the existing Linux implementation pattern and avoids introducing Brewfile as a new dependency format.

**Primary recommendation:** Mirror the existing Linux implementation pattern (apt.sh) with macOS equivalents: install Homebrew if missing, load packages from data files via existing load_profile() function, check installation status before installing each package, and handle both formulae (brew.txt) and casks (brew-cask.txt) separately.

## Standard Stack

### Core Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Homebrew | 4.x+ | Package manager for macOS | De facto standard, installed on 90%+ of developer Macs, official Apple developer documentation references it |
| bash | 5.x | Shell scripting (upgrade from macOS default 3.2) | Project requires Bash 4.0+, macOS ships 3.2 due to GPL3 licensing, Homebrew provides modern version |

### Package Types

| Type | Command | File | Purpose |
|------|---------|------|---------|
| Formulae | `brew install <pkg>` | data/packages/brew.txt | CLI tools, libraries, build tools (git, curl, node, python) |
| Casks | `brew install --cask <pkg>` | data/packages/brew-cask.txt | GUI applications (VSCode, Firefox, Docker Desktop) |

### Supporting Utilities (Already in Codebase)

| Function | Location | Purpose |
|----------|----------|---------|
| `load_profile()` | src/core/packages.sh | Load packages from profile (minimal/developer/full) |
| `is_brew_installed()` | src/core/idempotent.sh | Check if package already installed via `brew list` |
| `detect_platform()` | src/core/platform.sh | Detect macOS vs Linux, set DETECTED_OS="macos" |
| `verify_bash_version()` | src/core/platform.sh | Check Bash >= 4.0, provide upgrade instructions |

## Architecture Patterns

### Recommended Project Structure

```
src/platforms/macos/
├── main.sh              # Entry point (interactive profile menu)
├── install/
│   ├── brew.sh          # Install Homebrew formulae from data/packages/brew.txt
│   ├── brew-cask.sh     # Install Homebrew casks from data/packages/brew-cask.txt
│   └── homebrew.sh      # Install/verify Homebrew itself (NONINTERACTIVE mode)
```

### Pattern 1: Homebrew Installation Check (Idempotent)

**What:** Install Homebrew only if not already present, using official installer with NONINTERACTIVE=1 flag

**When to use:** At the start of macOS setup, before any package installation

**Example:**
```bash
# Source: Official Homebrew Installation docs
# https://docs.brew.sh/Installation

install_homebrew() {
    # Check if brew is already installed
    if command -v brew &>/dev/null; then
        log_ok "Homebrew already installed: $(brew --version | head -1)"
        return 0
    fi

    log_info "Installing Homebrew..."

    # Use NONINTERACTIVE=1 for automation (skips y/n prompts)
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_ok "Homebrew installed successfully"

        # Configure PATH for current session
        eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
        eval "$(/usr/local/bin/brew shellenv)"      # Intel (no-op if dir doesn't exist)

        return 0
    else
        log_error "Failed to install Homebrew"
        return 1
    fi
}
```

**Critical detail:** Official installer is idempotent—running twice is safe, but checking first avoids unnecessary network calls.

### Pattern 2: Package Installation with Idempotency Check

**What:** Check if package installed before attempting installation, use HOMEBREW_NO_INSTALL_UPGRADE to prevent unwanted upgrades

**When to use:** For each package in brew.txt or brew-cask.txt

**Example:**
```bash
# Source: Adapted from existing apt.sh pattern + Homebrew best practices
# https://github.com/Homebrew/brew/issues/2491

is_brew_installed() {
    local pkg="$1"
    brew list "$pkg" &>/dev/null
}

brew_install() {
    local pkg="$1"

    if is_brew_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"

    # Disable auto-upgrade to ensure true idempotency
    if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "$pkg" 2>/dev/null; then
        log_ok "Installed: $pkg"
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

brew_cask_install() {
    local cask="$1"

    if is_brew_installed "$cask"; then
        log_debug "Already installed: $cask"
        return 0
    fi

    log_info "Installing cask: $cask"

    # Casks require --cask flag for disambiguation
    if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install --cask "$cask" 2>/dev/null; then
        log_ok "Installed: $cask"
        return 0
    else
        log_error "Failed to install: $cask"
        return 1
    fi
}
```

**Why this pattern:** Mirrors existing apt.sh implementation, maintains consistency across platforms, avoids Brewfile dependency.

### Pattern 3: Profile-Based Installation (Reuse Existing)

**What:** Use existing load_profile() function to read profile definitions, install packages per profile

**When to use:** Main orchestrator (macos/main.sh) for user profile selection

**Example:**
```bash
# Source: Existing pattern from src/core/packages.sh
# Profiles defined in data/packages/profiles/{minimal,developer,full}.txt

install_profile() {
    local profile_name="$1"

    log_info "Installing profile: $profile_name"

    # Load profile (sets PACKAGES array with file references)
    if ! load_profile "$profile_name"; then
        log_error "Failed to load profile: $profile_name"
        return 1
    fi

    # Process each package file referenced in profile
    # Example: minimal.txt contains "brew.txt" only
    #          developer.txt contains "brew.txt\nbrew-cask.txt\ncargo.txt\nnpm.txt"

    for pkg_file in "${PACKAGES[@]}"; do
        case "$pkg_file" in
            brew.txt)
                bash "${SCRIPT_DIR}/install/brew.sh"
                ;;
            brew-cask.txt)
                bash "${SCRIPT_DIR}/install/brew-cask.sh"
                ;;
            cargo.txt)
                # Rust tools via cargo (Phase 5)
                log_info "Skipping cargo.txt (requires Rust, installed in Phase 5)"
                ;;
            npm.txt)
                # Node packages via npm (Phase 5)
                log_info "Skipping npm.txt (requires Node, installed in Phase 5)"
                ;;
            *)
                log_warn "Unknown package file: $pkg_file"
                ;;
        esac
    done
}
```

### Pattern 4: PATH Configuration (Shell-Specific)

**What:** Add Homebrew to PATH in user's shell RC file, idempotently

**When to use:** After Homebrew installation, once per user

**Example:**
```bash
# Source: Official Homebrew Installation docs
# https://docs.brew.sh/Installation

configure_shell_path() {
    local shell_name="${SHELL##*/}"
    local rc_file=""

    case "$shell_name" in
        zsh)
            rc_file="$HOME/.zprofile"
            ;;
        bash)
            rc_file="$HOME/.bash_profile"
            ;;
        *)
            log_warn "Unknown shell: $shell_name, skipping PATH configuration"
            return 1
            ;;
    esac

    local brew_shellenv='eval "$(/opt/homebrew/bin/brew shellenv)"'

    # Use existing ensure_line_in_file from idempotent.sh
    if ensure_line_in_file "$brew_shellenv" "$rc_file"; then
        log_ok "Homebrew added to $rc_file"
    else
        log_warn "Failed to update $rc_file"
    fi
}
```

**Critical:** macOS uses /opt/homebrew (Apple Silicon) or /usr/local (Intel), detect via `uname -m` if needed.

### Anti-Patterns to Avoid

- **Never use `sudo` with brew commands:** Homebrew manages its own permissions, sudo breaks ownership and causes future failures
- **Don't rely on `brew bundle` without Brewfile:** Project uses .txt files, not Brewfile format—introducing Brewfile violates "zero deps" and SSoT principles
- **Don't skip Bash version check:** macOS ships Bash 3.2, project requires 4.0+, user must upgrade manually (cannot be automated without Homebrew already installed—chicken-egg problem)
- **Don't install Homebrew silently without user awareness:** Even with NONINTERACTIVE=1, installation modifies /opt/homebrew and requires admin password—log clearly what's happening

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Homebrew installation | Custom download/extraction logic | Official installer script at raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | Handles permissions, architecture detection, PATH setup, Xcode CLI tools check |
| Package installation status check | Parse `brew info` output or maintain state file | `brew list <pkg>` with exit code check | Official command, returns 0 if installed, 1 if not—simple and reliable |
| Brewfile parsing | Custom Ruby/text parser | Either use `brew bundle` or stick with .txt files and shell loops | Brewfile is Ruby DSL—parsing requires Ruby or complex regex, project already uses .txt |
| Profile selection menu | Custom readline loop | Use `select` builtin (Bash 4.0+) | Native Bash construct, clean UX, automatically numbered |

**Key insight:** Homebrew's CLI is designed for scripting—exit codes are meaningful, output is parseable, idempotency is built-in when used correctly. Avoid reinventing what `brew` already provides.

## Common Pitfalls

### Pitfall 1: `brew: command not found` After Installation

**What goes wrong:** Homebrew installs successfully, but `brew` command not recognized in same script session

**Why it happens:** Installation adds Homebrew to PATH via shell profile (~/.zprofile), which only loads on new shell sessions. Current script session doesn't see the updated PATH.

**How to avoid:** Immediately after installation, manually source the shellenv in the script:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"      # Intel
```

**Warning signs:** Script reports "Homebrew installed successfully" but next line fails with "brew: command not found"

### Pitfall 2: Mixed Ownership (sudo brew)

**What goes wrong:** User runs `sudo brew install` or script uses `sudo` with brew commands, causing /opt/homebrew files to be owned by root instead of user

**Why it happens:** Misconception that brew needs root permissions (it doesn't—Homebrew explicitly designs around user-owned directories)

**How to avoid:**
- Never use `sudo` with `brew` commands
- Document clearly in logs: "Installing without sudo (Homebrew manages its own permissions)"
- If user sees permission errors, direct them to `brew doctor` not `sudo`

**Warning signs:** Errors like "Permission denied" on /opt/homebrew/Cellar, or subsequent brew commands failing with ownership errors

### Pitfall 3: Double Homebrew Installation (Migration)

**What goes wrong:** Mac migrated from Intel to Apple Silicon via Migration Assistant copies /usr/local/Homebrew, new setup script installs to /opt/homebrew—now two Homebrews exist, PATH confusion ensues

**Why it happens:** Homebrew location changed from /usr/local (Intel) to /opt/homebrew (Apple Silicon), Migration Assistant blindly copies /usr/local

**How to avoid:**
- Check both locations before installing: `if [[ -d /opt/homebrew ]] || [[ -d /usr/local/Homebrew ]]; then`
- Use `command -v brew` which respects PATH priority
- Log which Homebrew is being used: `brew --prefix` shows active installation

**Warning signs:** `brew --prefix` returns /usr/local on Apple Silicon Mac (should be /opt/homebrew)

### Pitfall 4: Missing Xcode Command Line Tools

**What goes wrong:** Formulae that compile from source (e.g., some Python packages) fail with "xcrun: error: invalid active developer path"

**Why it happens:** Fresh macOS install doesn't include Xcode CLI tools, Homebrew installer usually prompts for them, but NONINTERACTIVE=1 skips the prompt

**How to avoid:**
```bash
# Check before installing Homebrew
if ! xcode-select -p &>/dev/null; then
    log_info "Installing Xcode Command Line Tools (required for Homebrew)..."
    xcode-select --install
    # Wait for user to complete GUI installation
    log_info "Please complete Xcode CLI Tools installation, then press Enter"
    read -r
fi
```

**Warning signs:** Homebrew installs successfully, but first compile-from-source formula fails

### Pitfall 5: Bash 3.2 Limitation on Fresh macOS

**What goes wrong:** Script requires Bash 4.0+ (for associative arrays, ${BASH_VERSINFO[@]}, etc.), but macOS ships Bash 3.2, causing syntax errors or unexpected behavior

**Why it happens:** Apple stopped updating Bash at 3.2 due to GPL3 license change, modern Bash requires Homebrew installation—chicken-egg problem

**How to avoid:**
- Verify Bash version BEFORE doing anything else (existing verify_bash_version() in platform.sh does this)
- If Bash < 4.0, print clear instructions to upgrade:
  ```
  brew install bash
  sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
  chsh -s /opt/homebrew/bin/bash
  ```
- Require user to re-run setup after upgrading Bash (can't be automated—requires logout/login)

**Warning signs:** Errors like "declare: -A: invalid option" or "bad array subscript" on fresh macOS

### Pitfall 6: Profile Files Already Have Homebrew in Different Format

**What goes wrong:** User's ~/.zprofile already has `export PATH="/opt/homebrew/bin:$PATH"` (manual setup), script adds `eval "$(...brew shellenv)"` line—PATH has duplicates, or worse, old path takes precedence

**Why it happens:** Users often manually configure Homebrew before running setup scripts, or re-run setup multiple times

**How to avoid:** Use existing `ensure_line_in_file()` which checks if line already exists before adding (exact match). Consider checking for *any* Homebrew PATH modification:
```bash
if grep -q "brew" "$rc_file"; then
    log_info "Homebrew already configured in $rc_file, skipping"
    return 0
fi
```

**Warning signs:** User reports `brew` command works but script still tries to modify shell profile

## Code Examples

### Complete Homebrew Installer (homebrew.sh)

```bash
#!/usr/bin/env bash
# install/homebrew.sh - Install Homebrew package manager

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../../core/logging.sh"
source "${SCRIPT_DIR}/../../core/idempotent.sh"

install_homebrew() {
    log_banner "Homebrew Installation"

    # Check if already installed
    if command -v brew &>/dev/null; then
        log_ok "Homebrew already installed: $(brew --version | head -1)"
        log_info "Location: $(brew --prefix)"
        return 0
    fi

    # Check for Xcode CLI Tools first
    if ! xcode-select -p &>/dev/null; then
        log_warn "Xcode Command Line Tools not found"
        log_info "Installing Xcode CLI Tools (required for Homebrew)..."

        xcode-select --install

        log_info "Please complete the GUI installation, then press Enter to continue"
        read -r

        # Verify installation completed
        if ! xcode-select -p &>/dev/null; then
            log_error "Xcode CLI Tools installation incomplete. Please install manually and re-run."
            return 1
        fi
    fi

    log_info "Installing Homebrew..."
    log_info "This will install to /opt/homebrew (Apple Silicon) or /usr/local (Intel)"

    # Use official installer with NONINTERACTIVE flag
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_ok "Homebrew installed successfully"
    else
        log_error "Homebrew installation failed"
        return 1
    fi

    # Configure PATH for current session
    local brew_path=""
    if [[ -d /opt/homebrew ]]; then
        brew_path="/opt/homebrew"
    elif [[ -d /usr/local/Homebrew ]]; then
        brew_path="/usr/local"
    else
        log_error "Homebrew installation directory not found"
        return 1
    fi

    eval "$($brew_path/bin/brew shellenv)"

    # Verify installation
    if command -v brew &>/dev/null; then
        log_ok "Homebrew available: $(brew --version | head -1)"
    else
        log_error "Homebrew installed but not in PATH"
        return 1
    fi

    # Configure shell profile
    configure_shell_path

    return 0
}

configure_shell_path() {
    local shell_name="${SHELL##*/}"
    local rc_file=""

    case "$shell_name" in
        zsh)
            rc_file="$HOME/.zprofile"
            ;;
        bash)
            rc_file="$HOME/.bash_profile"
            ;;
        *)
            log_warn "Unknown shell: $shell_name, skipping PATH configuration"
            return 1
            ;;
    esac

    # Check if already configured
    if grep -q "brew shellenv" "$rc_file" 2>/dev/null; then
        log_info "Homebrew already configured in $rc_file"
        return 0
    fi

    # Detect architecture
    local brew_path="/opt/homebrew"
    if [[ "$(uname -m)" == "x86_64" ]]; then
        brew_path="/usr/local"
    fi

    local brew_shellenv="eval \"\$($brew_path/bin/brew shellenv)\""

    log_info "Adding Homebrew to $rc_file"
    if ensure_line_in_file "$brew_shellenv" "$rc_file"; then
        log_ok "Shell configured. Restart terminal or run: source $rc_file"
    else
        log_warn "Failed to update $rc_file. You may need to add manually."
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_homebrew
fi
```

### Formula Installer (brew.sh)

```bash
#!/usr/bin/env bash
# install/brew.sh - Install Homebrew formulae from data/packages/brew.txt

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../../core/logging.sh"
source "${SCRIPT_DIR}/../../core/packages.sh"
source "${SCRIPT_DIR}/../../core/errors.sh"

# Verify Homebrew is installed
if ! command -v brew &>/dev/null; then
    log_error "Homebrew not found. Run install/homebrew.sh first."
    exit 1
fi

log_banner "Homebrew Formulae Installer"

# Load packages from data file
if ! load_packages "brew.txt"; then
    log_error "Failed to load brew packages from data/packages/brew.txt"
    exit 1
fi

log_info "Loaded ${#PACKAGES[@]} formulae from brew.txt"

# Install each package
for pkg in "${PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        log_debug "Already installed: $pkg"
        continue
    fi

    log_info "Installing: $pkg"
    if HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "$pkg" 2>/dev/null; then
        log_ok "Installed: $pkg"
    else
        record_failure "$pkg"
    fi
done

# Summary
show_failure_summary
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual package lists in shell scripts | Data-driven .txt files in data/packages/ | Phase 2 (2026-02-05) | Packages now editable without touching code, easier to maintain |
| `brew cask install` | `brew install --cask` | Homebrew 2.6.0 (2020) | Unified interface, --cask flag for disambiguation only |
| Separate Homebrew/Cask taps | Unified homebrew-cask integrated | Homebrew 1.6.0 (2018) | No need to `brew tap caskroom/cask` anymore |
| Manual PATH export | `brew shellenv` command | Homebrew 2.1.0 (2019) | Handles both bin and sbin, detects architecture automatically |

**Deprecated/outdated:**
- `brew cask install`: Still works but deprecated in favor of `brew install --cask`
- `brew tap homebrew/cask`: No longer needed, casks are part of main tap
- Manual PATH setting `export PATH=/usr/local/bin:$PATH`: Use `eval "$(brew shellenv)"` for arch-aware setup

## Open Questions

1. **Should Bash 4.0 upgrade be automated in Phase 4?**
   - What we know: Project requires Bash 4.0+, macOS ships 3.2, existing verify_bash_version() shows instructions but doesn't install
   - What's unclear: Can we install bash via Homebrew in the same script run, or does it require logout/login to take effect?
   - Recommendation: Keep manual upgrade requirement, document clearly in error message. Installing Bash 4+ via script but continuing to run in Bash 3.2 session would be confusing. Better UX: verify at start, exit with clear instructions if < 4.0, user upgrades and re-runs.

2. **Should profiles install GUI casks by default?**
   - What we know: Casks require GUI interaction (dock icons, app permissions), data/packages/brew-cask.txt has ~10 apps
   - What's unclear: Is it better to prompt per-cask, or install silently and let user remove unwanted apps?
   - Recommendation: Install silently (matches apt behavior), user can run `brew uninstall --cask <app>` if unwanted. Document in profile README which casks are included.

3. **Should we support Homebrew on Linux in Phase 4 or defer to Phase 5?**
   - What we know: Homebrew officially supports Linux, could replace some apt packages
   - What's unclear: Does introducing Homebrew on Linux violate "keep it simple"? Would it confuse the Linux platform implementation?
   - Recommendation: Defer to Phase 5. Phase 4 is "macOS platform", Linux already works with apt. If Homebrew-on-Linux is needed, it's a separate decision for Phase 5.

## Sources

### Primary (HIGH confidence)

- [Homebrew Installation Documentation](https://docs.brew.sh/Installation) - Official installation instructions, NONINTERACTIVE mode, system requirements
- [Homebrew Bundle Documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile) - brew bundle commands, Brewfile format, idempotency behavior
- [Homebrew Manpage](https://docs.brew.sh/Manpage) - Complete command reference, exit codes, environment variables
- [Homebrew Common Issues](https://docs.brew.sh/Common-Issues) - Official troubleshooting guide, permission issues, sudo pitfalls

### Secondary (MEDIUM confidence)

- [Homebrew GitHub Issue #11393](https://github.com/Homebrew/brew/issues/11393) - Idempotency discussion, HOMEBREW_NO_INSTALL_UPGRADE flag
- [Homebrew GitHub Issue #2491](https://github.com/Homebrew/brew/issues/2491) - Install-only-if-not-installed behavior
- [Install Homebrew on Mac Guide (2026)](https://mac.install.guide/homebrew/3) - PATH configuration for zsh/bash, Apple Silicon vs Intel
- [Sling Academy: Check if Package Installed](https://www.slingacademy.com/article/homebrew-how-to-check-if-a-package-is-installed/) - `brew list` patterns for scripting
- [DEV Community: What I Wish I Knew About Homebrew](https://dev.to/leonwong282/what-i-wish-i-knew-about-homebrew-before-wasting-2-hours-troubleshooting-3don) - Real-world pitfalls (sudo, PATH issues)
- [Mac Setup Guide (2026)](https://mac.install.guide/) - Developer setup best practices, Homebrew as first install
- [macOS Setup Blog (2026)](https://blog.ayjc.net/posts/macos-setup-2026/) - Current developer setup patterns

### Tertiary (LOW confidence)

- Various Stack Overflow and GitHub Gist snippets for `brew list | grep` patterns (not used in final recommendations—official docs preferred)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Homebrew is undisputed standard, official docs comprehensive
- Architecture: HIGH - Patterns mirror existing Linux implementation, proven approach
- Pitfalls: HIGH - Sourced from official Common Issues doc + verified community reports

**Research date:** 2026-02-06
**Valid until:** 2026-04-06 (60 days - Homebrew is stable, major version updates rare)
