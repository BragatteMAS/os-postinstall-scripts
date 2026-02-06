# Phase 5: Linux Enhancements - Research

**Researched:** 2026-02-06
**Domain:** Bash scripting / Linux package management / Cross-platform CLI tool installation
**Confidence:** HIGH

## Summary

Phase 5 enhances the existing Linux platform support with six sub-phases: APT hardening, Flatpak/Snap rewrite, Rust CLI tools, dev environment (fnm + uv), AI tools, and the Linux main.sh orchestrator. The research focused on verifying package names, installer URLs, idempotency check patterns, shell integration syntax, and the correct non-interactive apt-get flags -- all within the constraints of pure bash, no external dependencies, and official Ubuntu repos only (no PPAs).

All six Rust CLI tools (bat, eza, fd-find, ripgrep, zoxide, git-delta) are confirmed available in Ubuntu 24.04 official universe repository via apt. Two have binary name divergences requiring symlinks: `batcat` (bat) and `fdfind` (fd-find). The remaining four (eza, ripgrep, zoxide, git-delta) install with their expected binary names. Cross-platform installers (fnm, uv, ai-tools) use well-documented curl-based installation scripts with verified URLs.

The codebase has a well-established pattern from Phases 1-4: data-driven installation via `load_packages()`, core utilities sourcing (logging, idempotent, errors, packages), `FAILED_ITEMS` tracking, `record_failure()`, and always-exit-0 strategy. All new scripts must follow this exact pattern. The macOS `main.sh` orchestrator provides the reference implementation for the Linux `main.sh` rewrite.

**Primary recommendation:** Follow the established data-driven installer pattern exactly (as in `brew.sh` / `apt.sh`), use `apt-get` with `-o DPkg::Lock::Timeout=60` for lock handling, and create cross-platform installers in `src/install/` (new directory) for fnm, uv, and ai-tools.

## Standard Stack

### Core Tools (All verified in official Ubuntu 24.04 repos)

| Tool | APT Package | Binary Name | Symlink Needed | Source |
|------|-------------|-------------|----------------|--------|
| bat | `bat` | `batcat` | `ln -s /usr/bin/batcat /usr/local/bin/bat` | Ubuntu universe |
| eza | `eza` | `eza` | No | Ubuntu universe |
| fd | `fd-find` | `fdfind` | `ln -s $(which fdfind) /usr/local/bin/fd` | Ubuntu universe |
| ripgrep | `ripgrep` | `rg` | No | Ubuntu universe |
| zoxide | `zoxide` | `zoxide` | No | Ubuntu universe (0.9.3-1) |
| delta | `git-delta` | `delta` | No | Ubuntu universe |

**Confidence:** HIGH -- verified via packages.ubuntu.com and multiple sources

### Cross-Platform Installers

| Tool | Install URL | Version Cmd | Purpose |
|------|-------------|-------------|---------|
| fnm | `curl -fsSL https://fnm.vercel.app/install \| bash -s -- --skip-shell` | `fnm --version` | Node.js version manager |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `uv --version` | Python version/package manager |
| ollama | `curl -fsSL https://ollama.com/install.sh \| sh` | `ollama --version` | Local LLM runtime |

**Confidence:** HIGH -- verified via official documentation

### AI CLI Tools (npm packages)

| Tool | NPM Package | Binary | Source |
|------|-------------|--------|--------|
| Claude Code | `@anthropic-ai/claude-code` | `claude` | npmjs.com |
| Codex | `@openai/codex` | `codex` | npmjs.com |
| Gemini CLI | `@google/gemini-cli` | `gemini` | npmjs.com |

**Confidence:** HIGH -- verified via npmjs.com search results

### Brew Equivalents (macOS)

| Tool | Brew Package | Binary |
|------|-------------|--------|
| bat | `bat` | `bat` |
| eza | `eza` | `eza` |
| fd | `fd` | `fd` |
| ripgrep | `ripgrep` | `rg` |
| zoxide | `zoxide` | `zoxide` |
| delta | `git-delta` | `delta` |

Note: brew.txt already contains bat, eza, fd, ripgrep, zoxide, git-delta. No additions needed for macOS.

## Architecture Patterns

### Established Project Structure (from Phases 1-4)

```
src/
  core/               # Shared utilities (logging, idempotent, errors, packages, platform)
  install/            # NEW: Cross-platform installers (fnm, uv, ai-tools)
  installers/         # Existing: dotfiles-install.sh
  platforms/
    linux/
      install/        # Platform-specific: apt.sh, cargo.sh, flatpak.sh, snap.sh
      main.sh         # Linux orchestrator (rewrite target)
    macos/
      install/        # Platform-specific: homebrew.sh, brew.sh, brew-cask.sh
      main.sh         # macOS orchestrator (reference implementation)
data/
  packages/           # Package lists (txt files)
    profiles/         # Profile definitions (minimal.txt, developer.txt, full.txt)
  dotfiles/           # Shell configs, git config, aliases
```

### Pattern 1: Data-Driven Installer Script

**What:** Every installer follows the exact same structure
**When to use:** All package installation scripts
**Example:**

```bash
#!/usr/bin/env bash
# NOTE: No set -e (per Phase 1 decision)

SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Source core utilities
source "${SCRIPT_DIR}/../../../core/logging.sh" || { echo "[ERROR] Failed to load logging.sh" >&2; exit 1; }
source "${SCRIPT_DIR}/../../../core/idempotent.sh" || { log_error "Failed to load idempotent.sh"; exit 1; }
source "${SCRIPT_DIR}/../../../core/errors.sh" || { log_error "Failed to load errors.sh"; exit 1; }
source "${SCRIPT_DIR}/../../../core/packages.sh" || { log_error "Failed to load packages.sh"; exit 1; }

# Helper functions specific to this installer
# ...

# Cleanup trap
cleanup() {
    local exit_code=$?
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_warn "Failed packages: ${FAILED_ITEMS[*]}"
    fi
    log_debug "Cleaning up ${SCRIPT_NAME}..."
    exit $exit_code
}
trap cleanup EXIT INT TERM

declare -a FAILED_ITEMS=()

# Main
log_banner "Installer Name"
# load_packages -> install loop -> summary
# Always exit 0
exit 0
```

### Pattern 2: Profile-Based Dispatch (macOS reference)

**What:** The orchestrator reads profile files and dispatches to correct installers
**When to use:** Linux main.sh orchestrator
**Critical detail:** Use `LINUX_DIR` (not `SCRIPT_DIR`) because packages.sh overwrites SCRIPT_DIR

```bash
# macOS uses MACOS_DIR for this reason -- Linux must use LINUX_DIR
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly LINUX_DIR

# Profile dispatch pattern from macOS main.sh
install_profile() {
    local profile_name="$1"
    local profile_file="${DATA_DIR}/packages/profiles/${profile_name}.txt"

    while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
        pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"
        [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

        case "$pkg_file" in
            apt.txt)        bash "${LINUX_DIR}/install/apt.sh" ;;
            apt-post.txt)   bash "${LINUX_DIR}/install/apt.sh" --post ;;
            flatpak.txt)    bash "${LINUX_DIR}/install/flatpak.sh" ;;
            # ... platform filtering: skip brew.txt, brew-cask.txt
            brew.txt|brew-cask.txt) log_debug "Skipping $pkg_file (macOS only)" ;;
            ai-tools.txt)   bash "${INSTALL_DIR}/ai-tools.sh" ;;
            *) log_warn "Unknown package file: $pkg_file" ;;
        esac
    done < "$profile_file"
}
```

### Pattern 3: Interactive Selection (grupo+custom)

**What:** User chooses all/choose/skip for each category
**When to use:** Rust CLI tools, dev env, AI tools in interactive mode
**Example:**

```bash
show_category_menu() {
    local category="$1"
    shift
    local tools=("$@")

    echo ""
    echo "Install ${category}? (${tools[*]})"
    echo "  1) All"
    echo "  2) Choose"
    echo "  3) Skip"
    echo ""
    read -rp "Select [1-3]: " choice

    case "$choice" in
        1) return 0 ;;  # install all
        2) return 1 ;;  # choose individually
        3) return 2 ;;  # skip
        *) return 2 ;;  # default: skip
    esac
}
```

### Pattern 4: Retry with Exponential Backoff

**What:** Network operations retry 3 times with increasing delay
**When to use:** apt-get update, apt-get install, curl downloads

```bash
retry_with_backoff() {
    local max_attempts=3
    local delays=(5 15 30)
    local cmd=("$@")
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if "${cmd[@]}"; then
            return 0
        fi
        if [[ $attempt -lt $max_attempts ]]; then
            local delay=${delays[$((attempt - 1))]}
            log_warn "Retry ${attempt}/${max_attempts} in ${delay}s..."
            sleep "$delay"
        fi
        attempt=$((attempt + 1))
    done
    return 1
}
```

### Anti-Patterns to Avoid

- **`set -e` / `set -euo pipefail`:** Legacy scripts use this -- must be removed. Conflicts with continue-on-failure strategy (decision [01-01]).
- **Hardcoded arrays in scripts:** Legacy flatpak.sh/snap.sh embed package lists directly. Must use `load_packages()` from data files.
- **`dpkg -l | grep` for snap/flatpak checks:** Legacy snap.sh uses `dpkg -l` to check snap packages (wrong tool). Use `snap list | grep` for snap and `flatpak list --app | grep` for flatpak.
- **`apt` instead of `apt-get`:** The `apt` command warns about unstable CLI interface in scripts. Always use `apt-get`.
- **`SCRIPT_DIR` in orchestrator after sourcing packages.sh:** packages.sh overwrites SCRIPT_DIR. Use a unique name like `LINUX_DIR`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| APT lock handling | Custom fuser loops with sleeps | `apt-get -o DPkg::Lock::Timeout=60` | Built-in apt feature, race-condition free |
| Package loading | Reading files manually | `load_packages("file.txt")` | Already exists in core/packages.sh, handles comments/whitespace |
| Failure tracking | Custom arrays | `record_failure()` + `show_failure_summary()` | Already exists in core/errors.sh |
| Idempotency checks | Custom dpkg/command checks | `is_apt_installed()`, `is_installed()` | Already exists in core/idempotent.sh |
| Color output | Manual ANSI codes | `log_info()`, `log_ok()`, `log_warn()`, `log_error()` | Already exists in core/logging.sh |
| Profile loading | Custom file reading | `load_profile()` | Already exists in core/packages.sh |
| Symlink creation | Custom ln commands | `ensure_symlink()` | Already exists in core/idempotent.sh |
| Path management | Manual PATH manipulation | `add_to_path()` | Already exists in core/idempotent.sh AND dotfiles/shared/path.sh |

**Key insight:** The core/ module library built in Phases 1-2 provides nearly every utility needed. New scripts should source and use these, not reinvent them.

## Common Pitfalls

### Pitfall 1: SCRIPT_DIR Overwrite by packages.sh

**What goes wrong:** packages.sh defines its own `SCRIPT_DIR` at line 20-21 and marks it `readonly`. If the calling script also uses `SCRIPT_DIR`, the packages.sh value wins, breaking relative path resolution.
**Why it happens:** packages.sh needs SCRIPT_DIR to resolve DATA_DIR relative to itself.
**How to avoid:** Use a unique variable name in orchestrator scripts (e.g., `LINUX_DIR` like macOS uses `MACOS_DIR`).
**Warning signs:** "No such file or directory" errors when running sub-scripts.

### Pitfall 2: Legacy `set -euo pipefail` in Flatpak/Snap Scripts

**What goes wrong:** Legacy scripts at `platforms/linux/install/` use `set -euo pipefail` (line 2 of both flatpak.sh and snap.sh). If any single package fails, the entire script aborts.
**Why it happens:** Old scripting convention before Phase 1 decisions.
**How to avoid:** New scripts at `src/platforms/linux/install/` must NOT include `set -e`. Add comment: `# NOTE: No set -e (per Phase 1 decision)`.
**Warning signs:** Script exits after first package failure.

### Pitfall 3: Wrong Idempotency Check for Snap/Flatpak

**What goes wrong:** Legacy snap.sh uses `dpkg -l | grep` to check snap packages (line 40). dpkg only knows about deb packages, not snaps.
**Why it happens:** Copy-paste from apt install pattern.
**How to avoid:**
- Snap: `snap list 2>/dev/null | grep -q "^$pkg_name "`
- Flatpak: `flatpak list --app --columns=application 2>/dev/null | grep -q "$app_id"`
**Warning signs:** "Already installed" never triggers for snap/flatpak packages.

### Pitfall 4: Ubuntu Binary Name Divergences

**What goes wrong:** Scripts try to run `bat` or `fd` after apt install, but the binaries are named `batcat` and `fdfind`.
**Why it happens:** Ubuntu renames packages to avoid conflicts with existing packages (bat conflicts with bacula, fd conflicts with fdclone).
**How to avoid:** After apt install, create symlinks:
- `sudo ln -sf /usr/bin/batcat /usr/local/bin/bat`
- `sudo ln -sf $(which fdfind) /usr/local/bin/fd`
**Warning signs:** `command -v bat` returns false even after successful `apt install bat`.

### Pitfall 5: DEBIAN_FRONTEND Conditional Application

**What goes wrong:** Setting `DEBIAN_FRONTEND=noninteractive` globally prevents users from answering debconf questions when running interactively.
**Why it happens:** Over-eager non-interactive hardening.
**How to avoid:** Only set when `NONINTERACTIVE=true`:
```bash
if [[ "${NONINTERACTIVE:-false}" == "true" ]]; then
    export DEBIAN_FRONTEND=noninteractive
    APT_OPTS="-o Dpkg::Options::=--force-confold"
fi
```
**Warning signs:** Users can't answer configuration prompts (e.g., postfix setup during openssh-server install).

### Pitfall 6: Missing Node.js Before npm-Based AI Tools

**What goes wrong:** AI tools installer runs `npm install -g` but Node.js isn't installed yet.
**Why it happens:** Execution order not enforced; ai-tools.sh runs before dev-env.sh.
**How to avoid:** Two strategies (use both):
1. Orchestrator ensures dev-env runs before ai-tools (structural guarantee via profile dispatch order)
2. ai-tools.sh checks `command -v node` before npm operations, warns and skips if missing
**Warning signs:** "npm: command not found" errors.

### Pitfall 7: Snap Classic Confinement

**What goes wrong:** Some snap packages require `--classic` flag (e.g., `snap install docker --classic`). Without it, install fails silently or with confusing error.
**Why it happens:** Snap's strict confinement model doesn't work for all apps.
**How to avoid:** The data file format could use a prefix like `classic:docker` and the installer parses it, or the installer catches the specific error and retries with `--classic`.
**Warning signs:** Snap install returns error about "classic confinement".

### Pitfall 8: Flatpak Remote Not Added

**What goes wrong:** `flatpak install flathub <app>` fails because Flathub remote isn't configured.
**Why it happens:** Fresh Ubuntu installations may not have Flathub remote added.
**How to avoid:** Run `flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo` before any flatpak installs. The `--if-not-exists` flag makes it idempotent.
**Warning signs:** "No remote refs found" error.

## Code Examples

### APT Hardened Install (with lock timeout + retry + confold)

```bash
# Source: Verified via apt-get man page + community best practices
apt_hardened_install() {
    local pkg="$1"

    if is_apt_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"

    local apt_cmd=(sudo apt-get install -y -o DPkg::Lock::Timeout=60)

    # Add non-interactive options only when NONINTERACTIVE=true
    if [[ "${NONINTERACTIVE:-false}" == "true" ]]; then
        apt_cmd+=(-o Dpkg::Options::="--force-confold")
    fi

    apt_cmd+=("$pkg")

    if retry_with_backoff "${apt_cmd[@]}"; then
        log_ok "Installed: $pkg"
        return 0
    else
        log_warn "Package not found or install failed: $pkg"
        return 1
    fi
}
```

### Flatpak Idempotent Install

```bash
# Source: flatpak list man page + Flatpak documentation
is_flatpak_installed() {
    local app_id="$1"
    flatpak list --app --columns=application 2>/dev/null | grep -q "^${app_id}$"
}

flatpak_install() {
    local app_id="$1"

    if is_flatpak_installed "$app_id"; then
        log_debug "Already installed: $app_id"
        return 0
    fi

    log_info "Installing: $app_id"
    if retry_with_backoff flatpak install flathub "$app_id" -y --noninteractive; then
        log_ok "Installed: $app_id"
        return 0
    else
        log_error "Failed to install: $app_id"
        return 1
    fi
}
```

### Snap Idempotent Install

```bash
# Source: snap list man page
is_snap_installed() {
    local pkg="$1"
    snap list 2>/dev/null | grep -q "^${pkg} "
}

snap_install() {
    local pkg="$1"

    if is_snap_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    log_info "Installing: $pkg"
    if sudo snap install "$pkg" 2>/dev/null; then
        log_ok "Installed: $pkg"
        return 0
    else
        # Retry with --classic if strict confinement fails
        if sudo snap install "$pkg" --classic 2>/dev/null; then
            log_ok "Installed (classic): $pkg"
            return 0
        fi
        log_error "Failed to install: $pkg"
        return 1
    fi
}
```

### Rust CLI Symlink Creation (Ubuntu name divergences)

```bash
# Source: bat/fd-find GitHub READMEs + Ubuntu package info
create_rust_symlinks() {
    # bat -> batcat (Ubuntu naming conflict with bacula)
    if [[ -f /usr/bin/batcat ]] && ! [[ -f /usr/local/bin/bat ]]; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log_ok "Created symlink: bat -> batcat"
    fi

    # fd -> fdfind (Ubuntu naming conflict with fdclone)
    local fdfind_path
    fdfind_path=$(which fdfind 2>/dev/null)
    if [[ -n "$fdfind_path" ]] && ! command -v fd &>/dev/null; then
        sudo ln -sf "$fdfind_path" /usr/local/bin/fd
        log_ok "Created symlink: fd -> fdfind"
    fi
}
```

### fnm Installation and Shell Integration

```bash
# Source: https://github.com/Schniz/fnm README
install_fnm() {
    if command -v fnm &>/dev/null; then
        log_debug "fnm already installed: $(fnm --version)"
        return 0
    fi

    log_info "Installing fnm (Fast Node Manager)..."
    if curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell; then
        # Source for current session
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env)"
        log_ok "fnm installed"
        return 0
    fi
    log_error "Failed to install fnm"
    return 1
}

# Shell integration line for dotfiles:
# command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"
```

### uv Installation

```bash
# Source: https://docs.astral.sh/uv/getting-started/installation/
install_uv() {
    if command -v uv &>/dev/null; then
        log_debug "uv already installed: $(uv --version)"
        return 0
    fi

    log_info "Installing uv (Python package manager)..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        # Source for current session
        export PATH="$HOME/.local/bin:$PATH"
        log_ok "uv installed"
        return 0
    fi
    log_error "Failed to install uv"
    return 1
}
```

### Git Delta Configuration (for gitconfig)

```gitconfig
# Source: https://github.com/dandavison/delta README
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    dark = true

[merge]
    conflictStyle = zdiff3
```

### AI Tools Prefix-Based Dispatcher

```bash
# ai-tools.txt format:
# npm:@anthropic-ai/claude-code
# npm:@openai/codex
# npm:@google/gemini-cli
# curl:ollama

install_ai_tool() {
    local entry="$1"
    local prefix="${entry%%:*}"
    local tool="${entry#*:}"

    case "$prefix" in
        npm)
            if ! command -v node &>/dev/null; then
                log_warn "Node.js not found, skipping npm tool: $tool"
                return 1
            fi
            npm install -g "$tool"
            ;;
        curl)
            case "$tool" in
                ollama)
                    curl -fsSL https://ollama.com/install.sh | sh
                    ;;
            esac
            ;;
        npx|uv)
            # MCP servers -- no install action needed, they run via npx/uvx
            log_debug "Skipping $prefix tool (runs on demand): $tool"
            return 0
            ;;
    esac
}
```

## State of the Art

| Old Approach (Legacy) | Current Approach (Phase 5) | When Changed | Impact |
|----------------------|---------------------------|--------------|--------|
| `set -euo pipefail` | No `set -e`, continue-on-failure | Phase 1 | Scripts don't abort on first failure |
| Hardcoded arrays in scripts | `load_packages("file.txt")` | Phase 2 | Data-driven, maintainable |
| `dpkg -l \| grep` for snap | `snap list \| grep` | Phase 5 | Correct idempotency check |
| `sudo fuser` lock wait loop | `apt-get -o DPkg::Lock::Timeout=60` | Phase 5 | Race-condition free, built-in |
| Manual menu loop | Profile-based dispatch | Phase 4 (macOS) | Consistent UX across platforms |
| nvm for Node.js | fnm (Rust-based, reads .nvmrc) | Phase 5 | Faster, compatible, consistent with Rust philosophy |
| pip/venv for Python | uv (all-in-one) | Phase 5 | Faster, manages versions+deps |
| `apt` command | `apt-get` command | Phase 5 | Stable CLI interface for scripting |

**Deprecated/outdated (to be removed):**
- `platforms/linux/install/flatpak.sh` (legacy, hardcoded, uses `set -e`) -- replaced by `src/platforms/linux/install/flatpak.sh`
- `platforms/linux/install/snap.sh` (legacy, hardcoded, uses `set -e`) -- replaced by `src/platforms/linux/install/snap.sh`
- `platforms/linux/install/desktop-environments.sh` (deferred, out of scope)
- `apt-get autoclean` and `apt-get autoremove` in apt.sh lines 137-139 (CONTEXT decision: remove intentionally)

## Existing Code Inventory

Critical existing code that Phase 5 modifies or interacts with:

### Files to MODIFY
| File | What Changes |
|------|-------------|
| `src/platforms/linux/install/apt.sh` | Add lock timeout, retry, confold, two-pass (apt.txt + apt-post.txt), remove autoclean/autoremove |
| `src/platforms/linux/main.sh` | Complete rewrite: profile menu, dispatch, dual-mode, macOS parity |
| `data/dotfiles/shared/aliases.sh` | Add `--group-directories-first` to eza `ll` alias |
| `data/dotfiles/git/gitconfig` | Add delta pager config sections |
| `data/packages/profiles/developer.txt` | Add ai-tools.txt reference |
| `data/packages/ai-tools.txt` | Add npm: entries for Claude/Codex/Gemini + curl:ollama |

### Files to CREATE
| File | Purpose |
|------|---------|
| `src/install/` (new directory) | Cross-platform installers |
| `src/install/fnm.sh` | fnm installer (cross-platform) |
| `src/install/uv.sh` | uv installer (cross-platform) |
| `src/install/ai-tools.sh` | AI tools installer (cross-platform) |
| `src/install/rust-cli.sh` | Rust CLI tools installer (handles apt vs brew + symlinks) |
| `src/install/dev-env.sh` | Dev environment orchestrator (fnm + uv + Node LTS + pnpm + bun) |
| `src/platforms/linux/install/flatpak.sh` | Data-driven flatpak installer |
| `src/platforms/linux/install/snap.sh` | Data-driven snap installer |

### Files to REFERENCE (read-only patterns)
| File | What to Copy |
|------|-------------|
| `src/platforms/macos/main.sh` | Profile dispatch pattern, dual-mode, MACOS_DIR trick |
| `src/platforms/macos/install/brew.sh` | Data-driven installer pattern |
| `src/platforms/linux/install/cargo.sh` | Existing Linux installer pattern |

### Profile File Updates Needed
| Profile | Current Contents | Add |
|---------|-----------------|-----|
| `minimal.txt` | apt.txt, brew.txt | No changes (minimal = apt only + dotfiles) |
| `developer.txt` | apt.txt, brew.txt, brew-cask.txt, cargo.txt, npm.txt | ai-tools.txt, flatpak.txt, snap.txt |
| `full.txt` | apt.txt, brew.txt, brew-cask.txt, cargo.txt, npm.txt, ai-tools.txt | flatpak.txt, flatpak-post.txt, snap.txt, snap-post.txt |

### Dotfiles Shell Integration Lines Needed

These lines should be added to `data/dotfiles/bash/bashrc` and/or `data/dotfiles/shared/path.sh`:

```bash
# fnm (Fast Node Manager)
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"

# zoxide (smarter cd)
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"
```

### Alias Update Needed

In `data/dotfiles/shared/aliases.sh`, line 16:
```bash
# Current:
alias ll="eza -la --git"
# Should become:
alias ll="eza -la --git --group-directories-first"
```

## Open Questions

1. **apt-post.txt dispatch in orchestrator**
   - What we know: CONTEXT says "two-pass install: apt.txt first, then apt-post.txt". Profile files currently only reference apt.txt.
   - What's unclear: Should apt-post.txt be added to profile files, or should the orchestrator always run both?
   - Recommendation: Add apt-post.txt to developer.txt and full.txt profiles. Minimal profile gets apt.txt only. The orchestrator dispatches both sequentially when it encounters them.

2. **Cross-platform installer source path depth**
   - What we know: Cross-platform installers go in `src/install/`. Core utilities are in `src/core/`.
   - What's unclear: The source path from `src/install/foo.sh` to `src/core/` is `${SCRIPT_DIR}/../core/` (one level up), which differs from platform scripts (`${SCRIPT_DIR}/../../../core/`).
   - Recommendation: Use `${SCRIPT_DIR}/../core/` in cross-platform installers. This is simpler and correct.

3. **Snap classic confinement handling**
   - What we know: Some snaps need `--classic` flag. The current data format is one package per line.
   - What's unclear: How to indicate classic confinement in the data file.
   - Recommendation: Use `classic:` prefix in snap.txt/snap-post.txt (e.g., `classic:docker`). The snap installer parses the prefix. This is consistent with ai-tools.txt prefix pattern.

4. **Profile files cross-platform additions**
   - What we know: developer.txt and full.txt need flatpak, snap, and new installer references.
   - What's unclear: The orchestrator case-match needs to handle these new file names.
   - Recommendation: Add all relevant package file names to profiles. The orchestrator's case statement silently skips files it doesn't recognize for its platform.

## Sources

### Primary (HIGH confidence)
- Ubuntu packages.ubuntu.com -- verified bat, eza, fd-find, ripgrep, zoxide, git-delta availability in noble/universe
- [fnm GitHub README](https://github.com/Schniz/fnm) -- install URL, shell integration syntax
- [uv official docs](https://docs.astral.sh/uv/getting-started/installation/) -- install URL, `uv python install` usage
- [ollama install docs](https://docs.ollama.com/linux) -- curl install script URL
- [npmjs.com @anthropic-ai/claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code) -- package name verified
- [npmjs.com @openai/codex](https://www.npmjs.com/package/@openai/codex) -- package name verified
- [npmjs.com @google/gemini-cli](https://www.npmjs.com/package/@google/gemini-cli) -- package name verified
- [delta GitHub README](https://github.com/dandavison/delta) -- gitconfig integration syntax
- Existing codebase: src/core/*.sh, src/platforms/macos/main.sh, src/platforms/linux/install/apt.sh

### Secondary (MEDIUM confidence)
- [apt-get DPkg::Lock::Timeout best practices](https://blog.sinjakli.co.uk/2021/10/25/waiting-for-apt-locks-without-the-hacky-bash-scripts/) -- verified via multiple sources
- [DEBIAN_FRONTEND noninteractive](https://www.cyberciti.biz/faq/explain-debian_frontend-apt-get-variable-for-ubuntu-debian/) -- well-documented standard
- [bat Ubuntu naming](https://github.com/sharkdp/bat/issues/1420) -- confirmed via bat GitHub issues
- [fd-find Ubuntu naming](https://github.com/sharkdp/fd) -- confirmed via fd README
- [Flatpak idempotent check](https://docs.flatpak.org/en/latest/flatpak-command-reference.html) -- official flatpak docs

### Tertiary (LOW confidence)
- None -- all findings verified with at least one official/authoritative source

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all package names and URLs verified via official sources
- Architecture: HIGH -- follows patterns established in Phases 1-4 codebase (direct code inspection)
- Pitfalls: HIGH -- identified from codebase analysis (legacy scripts examined) and verified documentation
- Code examples: HIGH -- based on verified APIs and existing codebase patterns

**Research date:** 2026-02-06
**Valid until:** 2026-03-06 (30 days -- stable domain, apt/npm/curl patterns rarely change)
