# Phase 2: Consolidation & Data Migration - Research

**Researched:** 2026-02-05
**Domain:** Bash script restructuring, code consolidation, package list extraction
**Confidence:** HIGH

## Summary

This phase focuses on restructuring the project from the current `scripts/` + `platforms/` layout to the new `src/` + `data/` + `docs/` layout defined in CONTEXT.md. Research investigated three key domains:

1. **Directory Restructuring:** Best practices for moving bash scripts while maintaining portable paths using `SCRIPT_DIR` pattern. The codebase already uses `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` consistently, which is the recommended portable approach.

2. **Package List Extraction:** Moving hardcoded package arrays from scripts to external `.txt` files under `data/packages/`. The `mapfile -t` command is the recommended modern approach for reading lines into arrays (Bash 4.0+).

3. **Code Consolidation:** The codebase has Phase 1 utilities already implemented in `scripts/utils/` (logging.sh, platform.sh, idempotent.sh, errors.sh). These need to move to `src/core/` with symlinks already in place in `platforms/linux/utils/`.

**Primary recommendation:** Execute migration in order: create structure -> migrate core -> extract data -> migrate platforms -> update entry point -> cleanup. Use `git mv` for history preservation and update all `source` statements immediately in each commit.

## Standard Stack

This phase uses pure Bash with standard Unix utilities. No external dependencies needed.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Bash | 4.0+ | Shell scripting | Required for `mapfile`, associative arrays |
| git | 2.0+ | Version control | `git mv` for history preservation |
| rg (ripgrep) | Any | Reference checking | Verify no dangling references before deletion |
| sed | - | Path updates | Update source statements in scripts |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| mapfile | Bash 4.0+ | Read file lines to array | Loading package lists from .txt files |
| grep -F | - | Fixed string matching | Check if line already exists in file |
| ln -sfn | - | Symbolic links | Temporary compatibility during migration |

### Not Needed
| Tool | Why Not Used |
|------|--------------|
| symlinks for compat | CONTEXT decided: update imports immediately, no temporary symlinks |
| jq | Package lists are plain .txt, not JSON |
| YAML parser | Profiles are simple lists of filenames |

## Architecture Patterns

### Recommended Project Structure (from CONTEXT.md)
```
./
  setup.sh                    # Entry point (new)
  config.sh                   # User configuration (new)
  Makefile                    # Build/test shortcuts
  .github/                    # CI/CD
  .planning/                  # GSD planning
  src/
    core/                     # Shared utilities (from scripts/utils/)
      logging.sh
      platform.sh
      idempotent.sh
      errors.sh
      packages.sh             # NEW: load_packages() function
    platforms/                # Platform-specific scripts
      linux/                  # From platforms/linux/
      macos/                  # Future
      windows/                # Future
  data/
    packages/                 # Package lists by manager
      apt.txt
      brew.txt
      brew-cask.txt
      cargo.txt
      npm.txt
      winget.txt
      ai-tools.txt
      profiles/
        minimal.txt
        developer.txt
        full.txt
    dotfiles/                 # Configuration templates
      git/
      zsh/
      bash/
  docs/                       # Documentation
  tests/                      # Test suites
```

### Pattern 1: SCRIPT_DIR for Portable Paths
**What:** Use `BASH_SOURCE[0]` to get script location regardless of working directory
**When to use:** Every script that sources other files or accesses relative paths
**Example:**
```bash
# Source: BashFAQ/028 - https://mywiki.wooledge.org/BashFAQ/028
#!/usr/bin/env bash

# Get directory where THIS script lives (works when sourced or executed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
readonly SCRIPT_DIR

# Now use SCRIPT_DIR for all relative paths
source "${SCRIPT_DIR}/../core/logging.sh"
```

### Pattern 2: Load Packages from Text File
**What:** Read package names from .txt file into array for installation
**When to use:** Instead of hardcoded package arrays in scripts
**Example:**
```bash
# Source: Baeldung - https://www.baeldung.com/linux/file-lines-into-array
# load_packages() - Load packages from a text file
# Args: $1 = path to package file
# Returns: Packages in PACKAGES array
load_packages() {
    local file="$1"
    PACKAGES=()

    # Validate file exists
    if [[ ! -f "$file" ]]; then
        log_error "Package file not found: $file"
        return 1
    fi

    # Read non-empty, non-comment lines into array
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Trim whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] && PACKAGES+=("$line")
    done < "$file"

    return 0
}

# Alternative using mapfile (simpler, Bash 4.0+)
load_packages_mapfile() {
    local file="$1"
    # Read all lines, then filter
    mapfile -t raw_lines < "$file"
    PACKAGES=()
    for line in "${raw_lines[@]}"; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        PACKAGES+=("$line")
    done
}
```

### Pattern 3: Profile Loading (Include Files)
**What:** Profile is a list of other package files to include
**When to use:** Composing installation sets from multiple package lists
**Example:**
```bash
# Profile file format (data/packages/profiles/developer.txt):
# apt.txt
# cargo.txt
# npm.txt

# load_profile() - Load packages from all files listed in a profile
# Args: $1 = profile name (e.g., "developer")
load_profile() {
    local profile_name="$1"
    local profile_file="${DATA_DIR}/packages/profiles/${profile_name}.txt"
    local all_packages=()

    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile not found: $profile_name"
        return 1
    fi

    # Read each file listed in profile
    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        [[ -z "$pkg_file" || "$pkg_file" =~ ^[[:space:]]*# ]] && continue

        local full_path="${DATA_DIR}/packages/${pkg_file}"
        if [[ -f "$full_path" ]]; then
            load_packages "$full_path"
            all_packages+=("${PACKAGES[@]}")
        else
            log_warn "Package file not found: $pkg_file"
        fi
    done < "$profile_file"

    PACKAGES=("${all_packages[@]}")
}
```

### Pattern 4: Migration Commit Pattern
**What:** Each commit is self-contained: move + update imports + test
**When to use:** Every file move during migration
**Example:**
```bash
# Step 1: Move file with git mv
git mv scripts/utils/logging.sh src/core/logging.sh

# Step 2: Update all references (using rg to find them first)
rg -l 'scripts/utils/logging\.sh' --type sh | while read -r file; do
    sed -i '' 's|scripts/utils/logging\.sh|src/core/logging.sh|g' "$file"
done

# Step 3: Test the change works
bash -n src/core/logging.sh
source src/core/logging.sh && log_ok "Test"

# Step 4: Commit as atomic unit
git add -A
git commit -m "refactor: move logging.sh to src/core/

- scripts/utils/logging.sh -> src/core/logging.sh
- Updated 15 source statements in scripts/
- Updated 3 source statements in platforms/"
```

### Anti-Patterns to Avoid
- **Temporary symlinks:** CONTEXT decided against them. Update imports immediately.
- **set -e during migration:** Conflicts with Phase 1's continue-on-failure strategy.
- **Relative paths without SCRIPT_DIR:** Scripts fail when run from different directories.
- **Moving without updating imports:** Creates broken references that fail silently.
- **Accumulating dead code:** Remove original immediately after verifying migration.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package file parsing | Custom parser with awk/sed | `mapfile -t` + simple loop | Standard, handles edge cases |
| Finding references | Manual grep | `rg -l 'pattern'` | Faster, respects .gitignore |
| Path canonicalization | String manipulation | `cd "$(dirname ...)" && pwd -P` | Handles symlinks, spaces |
| History preservation | Manual add/rm | `git mv` | Git tracks rename correctly |
| Comment detection | Complex regex | `[[ "$line" =~ ^# ]]` | Simple, readable |

**Key insight:** The decisions in CONTEXT.md explicitly favor simplicity. Plain .txt files, no special syntax, let the package manager validate packages. The code should be equally simple.

## Common Pitfalls

### Pitfall 1: Breaking Source Paths During Migration
**What goes wrong:** Scripts can't find dependencies after move
**Why it happens:** Source statements use hardcoded relative paths that change when structure changes
**How to avoid:** Update ALL source statements in same commit as file move. Use `rg` to find all references.
**Warning signs:** `source: file not found` errors, scripts dying on startup
```bash
# Before moving, find all references
rg -l 'utils/logging\.sh' --type sh

# After moving, verify no orphaned references
rg 'utils/logging\.sh' --type sh  # Should return nothing
```

### Pitfall 2: mapfile Not Available (Bash 3.x)
**What goes wrong:** `mapfile: command not found` on macOS with default bash
**Why it happens:** macOS ships Bash 3.2, mapfile requires 4.0+
**How to avoid:** Phase 1 already handles this with `verify_bash_version()`. Use while-read loop as fallback.
**Warning signs:** Script works on Linux but fails on macOS
```bash
# Portable fallback (works on Bash 3.2+)
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    array+=("$line")
done < file.txt
```

### Pitfall 3: Orphaned Files After Partial Migration
**What goes wrong:** Old files remain in `scripts/` after being moved to `src/`
**Why it happens:** Forgot to delete original, or commit split incorrectly
**How to avoid:** CONTEXT says "remove conforme migrar". Each commit: move + update + delete.
**Warning signs:** Same file exists in both locations, unclear which is authoritative
```bash
# Verify no duplicates after migration
diff <(ls src/core/) <(ls scripts/utils/)  # Should show differences
```

### Pitfall 4: Hardcoded Package Lists Remain
**What goes wrong:** New .txt files created but scripts still use hardcoded arrays
**Why it happens:** Incomplete extraction - created data files but didn't update scripts
**How to avoid:** Search for `APT_INSTALL=`, `RUST_TOOLS=` patterns after extraction
**Warning signs:** Changes to .txt files have no effect on installations
```bash
# Find remaining hardcoded arrays
rg 'APT_INSTALL=|RUST_TOOLS=|PACKAGES=' --type sh
```

### Pitfall 5: Circular Source Dependencies
**What goes wrong:** Script A sources B, B sources A -> infinite loop
**Why it happens:** Complex dependency chains not tracked during consolidation
**How to avoid:** Use source guards (`[[ -n "${_SOURCED:-}" ]] && return 0`) in all modules
**Warning signs:** Scripts hang on startup, stack overflow errors

### Pitfall 6: Broken Profile Composition
**What goes wrong:** Installing "developer" profile misses packages
**Why it happens:** Profile file references wrong filenames or paths
**How to avoid:** Validate profile files list actual existing .txt files
**Warning signs:** Profile installs fewer packages than expected
```bash
# Validate profile contents
for f in $(cat data/packages/profiles/developer.txt); do
    [[ -f "data/packages/$f" ]] || echo "Missing: $f"
done
```

## Code Examples

### Complete packages.sh Module
```bash
#!/usr/bin/env bash
# src/core/packages.sh
# Package loading utilities for data-driven installation

# Prevent multiple sourcing
[[ -n "${_PACKAGES_SOURCED:-}" ]] && return 0
readonly _PACKAGES_SOURCED=1

# Get data directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
DATA_DIR="$(cd "${SCRIPT_DIR}/../../data" &>/dev/null && pwd -P)"

# Global array for loaded packages
declare -a PACKAGES=()

# load_packages() - Load packages from a text file
# Args: $1 = filename (relative to data/packages/) or absolute path
# Sets: PACKAGES array
# Returns: 0 on success, 1 on error
load_packages() {
    local file="$1"
    PACKAGES=()

    # Resolve relative paths
    if [[ "$file" != /* ]]; then
        file="${DATA_DIR}/packages/${file}"
    fi

    if [[ ! -f "$file" ]]; then
        [[ -n "${log_error:-}" ]] && log_error "Package file not found: $file"
        return 1
    fi

    # Read lines, skip comments and empty
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Remove leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        PACKAGES+=("$line")
    done < "$file"

    [[ -n "${log_debug:-}" ]] && log_debug "Loaded ${#PACKAGES[@]} packages from $(basename "$file")"
    return 0
}

# load_profile() - Load all packages from a profile
# Args: $1 = profile name (e.g., "developer")
# Sets: PACKAGES array (combined from all files)
# Returns: 0 on success, 1 if profile not found
load_profile() {
    local profile_name="$1"
    local profile_file="${DATA_DIR}/packages/profiles/${profile_name}.txt"
    local all_packages=()

    if [[ ! -f "$profile_file" ]]; then
        [[ -n "${log_error:-}" ]] && log_error "Profile not found: $profile_name"
        return 1
    fi

    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"
        pkg_file="${pkg_file%"${pkg_file##*[![:space:]]}"}"
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        if load_packages "$pkg_file"; then
            all_packages+=("${PACKAGES[@]}")
        fi
    done < "$profile_file"

    PACKAGES=("${all_packages[@]}")
    [[ -n "${log_info:-}" ]] && log_info "Profile '$profile_name': ${#PACKAGES[@]} total packages"
    return 0
}

# get_packages_for_manager() - Filter packages for a specific manager
# Args: $1 = manager name (apt, brew, cargo, npm, winget)
# Sets: PACKAGES array
get_packages_for_manager() {
    local manager="$1"
    local file="${DATA_DIR}/packages/${manager}.txt"

    if [[ -f "$file" ]]; then
        load_packages "$file"
    else
        PACKAGES=()
        [[ -n "${log_warn:-}" ]] && log_warn "No package list for manager: $manager"
    fi
}

# Export functions
export -f load_packages load_profile get_packages_for_manager
```

### Package File Format Example
```
# data/packages/apt.txt
# System utilities for Debian/Ubuntu
# Format: one package per line, comments start with #

# Core utilities
git
git-lfs
curl
wget

# Terminal enhancements
zsh
terminator
tilix

# System monitoring
htop
stacer

# Development
build-essential
cmake
pkg-config

# Media
ffmpeg
flameshot
```

### Profile File Format Example
```
# data/packages/profiles/developer.txt
# Developer profile - includes base system + dev tools
# List other package files to include (relative to data/packages/)

apt.txt
cargo.txt
npm.txt
```

### Updated Script Using Data Files
```bash
#!/usr/bin/env bash
# src/platforms/linux/install/apt.sh
# Install APT packages from data file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
source "${SCRIPT_DIR}/../../../core/logging.sh"
source "${SCRIPT_DIR}/../../../core/errors.sh"
source "${SCRIPT_DIR}/../../../core/packages.sh"

setup_colors
setup_error_handling

# Load packages from data file
if ! load_packages "apt.txt"; then
    log_error "Failed to load apt packages"
    exit 1
fi

log_info "Installing ${#PACKAGES[@]} APT packages..."

for pkg in "${PACKAGES[@]}"; do
    log_info "Installing: $pkg"
    if ! apt_install "$pkg"; then
        record_failure "$pkg"
    fi
done

show_failure_summary
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded arrays in scripts | External .txt files | This phase | Easier maintenance, user customization |
| Mixed scripts/platforms dirs | Unified src/ structure | This phase | Clearer organization, reduced duplication |
| Multiple logging implementations | Single SSoT module | Phase 1 | Consistent output format |
| set -e everywhere | Explicit error handling | Phase 1 | Better continue-on-failure support |

**Deprecated/outdated:**
- `scripts/common/`: To be removed after migration
- `platforms/` at root level: Moving to `src/platforms/`
- Hardcoded package arrays: Moving to `data/packages/`

## Open Questions

1. **Exact ordering within each package file**
   - What we know: CONTEXT says "ordem natural dos arquivos" (natural file order)
   - What's unclear: Should we sort alphabetically for readability?
   - Recommendation: Keep original order from hardcoded arrays initially, sort later if desired

2. **Handling platform-specific packages**
   - What we know: apt.txt for Linux, brew.txt for macOS, etc.
   - What's unclear: What about packages that exist in multiple managers (e.g., git)?
   - Recommendation: Include in each manager's file, let user choose which to run

3. **Dotfiles migration scope**
   - What we know: `data/dotfiles/` structure defined in CONTEXT
   - What's unclear: Which dotfiles to extract from `configs/shell/`?
   - Recommendation: Defer detailed dotfiles migration to later phase, focus on packages first

## Sources

### Primary (HIGH confidence)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Bash scripting standards
- [BashFAQ/028](https://mywiki.wooledge.org/BashFAQ/028) - Getting script directory portably
- [Baeldung - Read File Lines to Array](https://www.baeldung.com/linux/file-lines-into-array) - mapfile and while-read patterns
- [Git Documentation - git mv](https://git-scm.com/docs/git-mv) - Official git mv documentation

### Secondary (MEDIUM confidence)
- [Git preserve history when moving files](https://linuxctl.com/p/git-preserve-history-when-moving-files/) - git mv best practices
- [Modularizing Bash Script Code](https://medium.com/mkdir-awesome/the-ultimate-guide-to-modularizing-bash-script-code-f4a4d53000c2) - Script organization patterns
- [Using relative paths in Linux scripts](https://tjelvarolsson.com/blog/using-relative-paths-in-linux-scripts/) - Portable path handling

### Tertiary (LOW confidence)
- Current codebase analysis - identified 50+ files using SCRIPT_DIR pattern
- Current codebase analysis - identified hardcoded arrays in rust-tools.sh, apt.sh

## Metadata

**Confidence breakdown:**
- Directory restructuring: HIGH - Well-established bash patterns, codebase already uses recommended approach
- Package extraction: HIGH - Simple format, mapfile is standard Bash 4.0+ feature
- Migration process: HIGH - git mv is standard, CONTEXT decisions are clear

**Research date:** 2026-02-05
**Valid until:** 2026-03-05 (30 days - stable domain, restructuring patterns don't change frequently)
