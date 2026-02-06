# Phase 7: User Experience Polish - Research

**Researched:** 2026-02-06
**Domain:** Bash UX patterns, CLI progress feedback, dry-run mode, completion summaries
**Confidence:** HIGH

## Summary

Phase 7 enhances four UX areas across an existing shell script codebase: progress feedback (UX-01), dry-run mode (UX-02), completion summary (UX-03), and one-command setup (UX-04). The codebase already has substantial infrastructure: `logging.sh` provides colored output with OK/ERROR/WARN/INFO/DEBUG/BANNER levels, `errors.sh` tracks failures via `FAILED_ITEMS[]` and `show_failure_summary()`, `config.sh` exports `DRY_RUN` (defaulting to `false`), and `setup.sh` is already the single entry point. The remaining work is filling gaps: adding `--dry-run` flag parsing, propagating DRY_RUN into 6 installers that lack it, adding step counters/progress indicators to orchestrators, building a rich completion summary, and ensuring setup.sh handles CLI args properly.

The codebase is pure Bash (zero external dependencies by design decision), so all solutions must use shell builtins and standard POSIX tools. No external libraries or frameworks. The patterns needed are well-understood shell scripting patterns with no novel technology.

**Primary recommendation:** Extend the existing infrastructure (logging.sh, errors.sh, config.sh, setup.sh) rather than building new modules. The work is surgical: add flag parsing to setup.sh, add DRY_RUN guards to 6 scripts missing them, add step counters to 3 orchestrators, and build a summary tracker in a new `src/core/progress.sh` module.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Bash builtins | 3.2+ (macOS compat) | All UX features | Zero deps requirement, macOS ships 3.2 |
| printf/echo -e | POSIX | Formatted output | Available everywhere |
| tput | ncurses | Terminal width, cursor control | Standard on all Unix, already used in logging.sh |
| date | coreutils | Timestamps, duration calculation | Available everywhere |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `SECONDS` Bash builtin | Elapsed time tracking | Duration in completion summary |
| `COLUMNS` env var / `tput cols` | Terminal width detection | Progress bar width (if used) |
| `\r` (carriage return) | In-place line updates | Live progress counter on same line |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom progress bar | `pv`, `dialog`, `whiptail` | External dependency violates zero-deps rule |
| Spinner library | `gum`, `charmbracelet` | Go binary, violates zero-deps rule |
| Rich terminal UI | `tui` frameworks | Massive overkill for this use case |
| JSON summary output | `jq` formatting | External dependency, shell-native is sufficient |

**Installation:** None. All tools are Bash builtins or standard POSIX utilities.

## Architecture Patterns

### Recommended Project Structure

```
src/core/
  progress.sh       # NEW - Step counter, elapsed time, summary tracker
  logging.sh        # EXISTING - Add log_step() for progress messages
  errors.sh         # EXISTING - Already has failure tracking

setup.sh            # MODIFY - Add --dry-run flag parsing, step counter integration
src/platforms/linux/main.sh   # MODIFY - Add step counting in install_profile()
src/platforms/macos/main.sh   # MODIFY - Add step counting in install_profile()
```

### Pattern 1: Step Counter in Orchestrators

**What:** Track current step number and total steps, display "[Step X/Y]" prefix
**When to use:** In main.sh orchestrators during install_profile() dispatch loop
**How it works:**

```bash
# Count total steps BEFORE executing
local total_steps=0
while IFS= read -r pkg_file; do
    pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"
    [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue
    ((total_steps++))
done < "$profile_file"

# Execute with step counter
local current_step=0
while IFS= read -r pkg_file; do
    pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"
    [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue
    ((current_step++))

    log_info "[Step ${current_step}/${total_steps}] Installing from ${pkg_file}..."
    # ... dispatch to installer
done < "$profile_file"
```

**Why this pattern:** Simple, no external deps, gives user clear position awareness. Follows KISS principle. Each sub-installer already logs individual package progress.

### Pattern 2: DRY_RUN Guard at Point of Mutation

**What:** Check `DRY_RUN == "true"` immediately before any system-modifying command
**When to use:** In every installer function that executes `sudo`, `install`, `curl | sh`, etc.
**Established pattern (from brew.sh, homebrew.sh, dotfiles.sh):**

```bash
# CORRECT: Check at the specific install function
my_install() {
    local pkg="$1"

    if is_already_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        return 0
    fi

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_info "[DRY_RUN] Would install: $pkg"
        return 0
    fi

    # Actual mutation
    sudo apt-get install -y "$pkg"
}
```

**Critical:** Use `== "true"` not `-n` (because config.sh sets DRY_RUN=false, not empty string). This is a locked decision from [03-04].

### Pattern 3: Flag Parsing in setup.sh

**What:** Parse `--dry-run`, `--verbose`, `--unattended` as CLI flags
**When to use:** setup.sh entry point
**Pattern from legacy scripts/setup/with-profile.sh:**

```bash
# Parse arguments before main()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            export DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            export VERBOSE=true
            shift
            ;;
        --unattended|-y)
            export UNATTENDED=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            # Remaining arg is profile or action
            break
            ;;
    esac
done
```

**Why:** setup.sh currently only supports env vars (DRY_RUN=true ./setup.sh). Adding flags makes it more discoverable. The `export` ensures child processes inherit the values. This complements (not replaces) the env var approach.

### Pattern 4: Completion Summary with Counters

**What:** Track installed/skipped/failed counts across the session, display rich summary at end
**When to use:** In setup.sh after platform handler returns
**Implementation approach:**

```bash
# In progress.sh (new core module)
declare -g PROGRESS_INSTALLED=0
declare -g PROGRESS_SKIPPED=0
declare -g PROGRESS_FAILED=0
declare -ga PROGRESS_INSTALLED_ITEMS=()
declare -ga PROGRESS_SKIPPED_ITEMS=()

track_installed() { ((PROGRESS_INSTALLED++)); PROGRESS_INSTALLED_ITEMS+=("$1"); }
track_skipped()   { ((PROGRESS_SKIPPED++)); PROGRESS_SKIPPED_ITEMS+=("$1"); }
# track_failed uses existing FAILED_ITEMS from errors.sh

show_completion_summary() {
    local elapsed=${SECONDS:-0}
    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))

    echo ""
    log_banner "Setup Summary"
    log_info "Profile: ${1:-unknown}"
    log_info "Platform: ${DETECTED_OS:-unknown}"
    log_info "Duration: ${mins}m ${secs}s"
    echo ""
    log_ok  "Installed: $PROGRESS_INSTALLED packages"
    log_info "Skipped:   $PROGRESS_SKIPPED (already installed)"

    local fail_count=${#FAILED_ITEMS[@]}
    if [[ $fail_count -gt 0 ]]; then
        log_warn "Failed:    $fail_count packages"
        show_failure_summary
    else
        log_ok "Failed:    0"
    fi
    echo ""
}
```

### Pattern 5: DRY_RUN Banner

**What:** Show prominent banner when running in dry-run mode
**When to use:** At start of setup.sh main(), if DRY_RUN=true
**Example:**

```bash
if [[ "${DRY_RUN:-}" == "true" ]]; then
    echo ""
    log_warn "=== DRY RUN MODE ==="
    log_warn "No changes will be made to the system"
    echo ""
fi
```

### Anti-Patterns to Avoid

- **Spinner/animation loops:** Complex terminal manipulation that breaks in non-TTY contexts (CI, piped output, NO_COLOR). The codebase already handles NO_COLOR and non-TTY gracefully -- don't add features that violate that.
- **DRY_RUN at orchestrator level:** The established pattern checks DRY_RUN at the point of mutation, not at the orchestrator. Orchestrators still run (loading packages, checking idempotency) even in dry-run mode.
- **Separate dry-run code path:** Don't create a parallel "dry-run version" of each installer. The `if DRY_RUN; log; return 0` pattern inline is simpler and stays DRY.
- **Percent-based progress bar:** Would require knowing total package count across all sub-installers before starting. Too complex for the benefit. Step counters per orchestrator section are sufficient.
- **Fancy Unicode characters for progress:** Violates NO_COLOR/non-TTY compatibility. Stick with ASCII and the existing `[OK]`/`[INFO]` tag format.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Failure tracking | New failure array | Existing `FAILED_ITEMS[]` + `record_failure()` + `show_failure_summary()` from errors.sh | Already battle-tested, used by all installers |
| Colored output | Custom color codes | Existing `log_ok`/`log_info`/`log_warn`/`log_error` from logging.sh | Already handles NO_COLOR, non-TTY, color detection |
| Elapsed time | `date` math | Bash `$SECONDS` builtin | Auto-increments, no subprocess, works everywhere |
| Flag parsing | `getopts` | Manual `while/case/shift` loop | `getopts` doesn't support long flags (--dry-run); manual loop is the established pattern in this codebase (see with-profile.sh) |
| Config propagation | Pass flags to sub-scripts | `export` env vars from config.sh | Already the established pattern -- DRY_RUN, VERBOSE, UNATTENDED are exported |

**Key insight:** 80% of the UX infrastructure already exists. The work is connecting existing pieces, not building new ones. The codebase has logging, error tracking, config exports, and color support. What's missing is: flag parsing, step counting, completion summary, and DRY_RUN in 6 scripts.

## Common Pitfalls

### Pitfall 1: DRY_RUN Check Using Wrong Comparison

**What goes wrong:** `if [[ -n "$DRY_RUN" ]]` evaluates true even when DRY_RUN=false (non-empty string)
**Why it happens:** config.sh sets `DRY_RUN="${DRY_RUN:-false}"` -- it's never empty, always "true" or "false"
**How to avoid:** Always use `[[ "${DRY_RUN:-}" == "true" ]]`
**Warning signs:** DRY_RUN mode activating when user didn't request it
**Locked decision:** [03-04] explicitly requires `== "true"` comparison

### Pitfall 2: Sub-process Scope for Tracking Variables

**What goes wrong:** Platform orchestrators run installers via `bash "script.sh"` which creates a new process. Global variables (FAILED_ITEMS, PROGRESS counters) don't propagate back to parent.
**Why it happens:** `bash script.sh` forks a new process with its own variable scope
**How to avoid:** Two approaches:
  1. Track progress at the orchestrator level (what install_profile dispatched and what returned non-zero)
  2. Use `source` instead of `bash` (but this changes established patterns)

**Recommendation:** Track at orchestrator level. Each sub-installer already logs its own success/failure. The orchestrator tracks "sections completed" not "individual packages." This is already the pattern: show_failure_summary in errors.sh cleanup trap shows failures per-installer, and orchestrator-level failures are separate.

### Pitfall 3: Progress Counter with Non-Platform Files

**What goes wrong:** Profile lists contain files for all platforms (apt.txt, brew.txt, winget.txt). If step counter includes all, it shows "Step 3/8" on Linux but steps 4-5-6 are silently skipped (brew.txt, brew-cask.txt, winget.txt).
**Why it happens:** Profile files are platform-agnostic by design
**How to avoid:** Count only platform-relevant steps, or show "[Step 3/5] Installing APT packages..." with filtered count
**Implementation:** Pre-filter the step list based on DETECTED_OS before counting

### Pitfall 4: Bash 3.2 Compatibility on macOS

**What goes wrong:** Associative arrays (`declare -A`) fail on macOS default Bash 3.2
**Why it happens:** macOS ships Bash 3.2, associative arrays require Bash 4.0+
**How to avoid:** Use only indexed arrays (`declare -a`) and simple variables. This is already the pattern in the codebase (see install_zsh_plugins using indexed arrays with space-separated values).
**Warning signs:** "declare: -A: invalid option" errors on macOS

### Pitfall 5: setup.sh Flag Parsing Breaking Profile Argument

**What goes wrong:** `./setup.sh --dry-run developer` fails because --dry-run consumes the first argument
**Why it happens:** Naive argument parsing that doesn't separate flags from positional args
**How to avoid:** Parse flags in a while loop with shift, then treat remaining $1 as the profile/action argument. The `break` on unknown args preserves positional parameters.

### Pitfall 6: Double Failure Summary

**What goes wrong:** show_failure_summary() called twice -- once by sub-installer cleanup trap, once by setup.sh
**Why it happens:** errors.sh `cleanup()` calls show_failure_summary(), and setup.sh also calls it explicitly
**How to avoid:** Sub-installers run in separate `bash` processes, so their cleanup trap is isolated. setup.sh's own failure tracking is separate. But the errors.sh cleanup trap in setup.sh itself also fires. Need to ensure show_failure_summary() in setup.sh is replaced by the new show_completion_summary(), and the cleanup trap is updated accordingly.

## Code Examples

Verified patterns from the existing codebase:

### Flag Parsing (adapted from scripts/setup/with-profile.sh)

```bash
# In setup.sh, before main()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            export DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            export VERBOSE=true
            shift
            ;;
        -y|--unattended)
            export UNATTENDED=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            break  # Remaining arg is action/profile
            ;;
    esac
done
main "$@"
```

### DRY_RUN Guard (existing pattern from brew.sh line 64)

```bash
if [[ "${DRY_RUN:-}" == "true" ]]; then
    log_info "[DRY_RUN] Would install: $pkg"
    return 0
fi
```

### Step Counter in Orchestrator (new pattern for main.sh)

```bash
# Pre-count platform-relevant steps
local total_steps=0
local -a relevant_steps=()

while IFS= read -r pkg_file || [[ -n "$pkg_file" ]]; do
    pkg_file="${pkg_file#"${pkg_file%%[![:space:]]*}"}"
    [[ -z "$pkg_file" || "$pkg_file" == \#* ]] && continue

    case "$pkg_file" in
        apt*.txt|flatpak*.txt|snap*.txt|cargo.txt|ai-tools.txt)
            relevant_steps+=("$pkg_file")
            ((total_steps++))
            ;;
        brew*.txt|winget.txt|npm.txt)
            ;; # Skip non-platform files silently
    esac
done < "$profile_file"

# Execute with counter
local current_step=0
for pkg_file in "${relevant_steps[@]}"; do
    ((current_step++))
    log_info "[${current_step}/${total_steps}] ${pkg_file}..."
    # dispatch...
done
```

### Elapsed Time (Bash SECONDS builtin)

```bash
# At start of setup.sh main()
SECONDS=0

# At end, in completion summary
local elapsed=$SECONDS
local mins=$((elapsed / 60))
local secs=$((elapsed % 60))
log_info "Duration: ${mins}m ${secs}s"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `DRY_RUN=true ./setup.sh` (env var only) | `./setup.sh --dry-run` (flag + env var) | Phase 7 | More discoverable, documented in --help |
| `show_failure_summary()` only shows failures | Rich completion summary (installed/skipped/failed + duration) | Phase 7 | User sees full picture, not just errors |
| No step indication | `[Step X/Y]` prefix in orchestrator | Phase 7 | User knows where they are in the process |
| Silent platform-file skipping | Counted only platform-relevant steps | Phase 7 | Accurate progress without confusing skip count |

**Deprecated/outdated:**
- Legacy `scripts/setup/with-profile.sh`: Already superseded by `setup.sh`. Contains useful flag-parsing pattern to adopt but is not actively used.
- Legacy `scripts/setup/unattended-install.sh`: Contains verbose DRY_RUN patterns but is superseded.

## Inventory: DRY_RUN Support Gap Analysis

### Scripts WITH DRY_RUN support (no changes needed):

| Script | DRY_RUN Pattern | Location |
|--------|-----------------|----------|
| `src/platforms/macos/install/brew.sh` | Guard in `_brew_formula_install()` | Line 64 |
| `src/platforms/macos/install/brew-cask.sh` | Guard in `_brew_cask_install()` | Line 73 |
| `src/platforms/macos/install/homebrew.sh` | Guard in `install_homebrew()` + `configure_shell_path()` | Lines 68, 159 |
| `src/core/dotfiles.sh` | Guards in `backup_with_manifest()`, `create_dotfile_symlink()`, `unlink_dotfiles()` | Lines 72, 134, 160, 216 |
| `src/installers/dotfiles-install.sh` | Guards in `install_zsh_plugins()`, `setup_git_user()` | Lines 38, 61, 115 |
| `src/core/platform.sh` | Guard in `request_sudo()` | Line 290 |

### Scripts MISSING DRY_RUN support (need changes):

| Script | Where to Add | Mutation Points |
|--------|--------------|-----------------|
| `src/platforms/linux/install/apt.sh` | `apt_hardened_install()` and `safe_apt_update()` | `sudo apt-get install`, `sudo apt-get update` |
| `src/platforms/linux/install/flatpak.sh` | `flatpak_install()` and `ensure_flathub_remote()` | `flatpak install`, `flatpak remote-add` |
| `src/platforms/linux/install/snap.sh` | `snap_install()` | `sudo snap install` |
| `src/platforms/linux/install/cargo.sh` | `cargo_install()`, `ensure_rust_installed()`, `ensure_binstall()` | `cargo install`, `curl \| sh` |
| `src/install/rust-cli.sh` | `install_rust_tools_linux()`, `install_rust_tools_macos()`, `create_rust_symlinks()` | `sudo apt-get install`, `brew install`, `sudo ln -sf` |
| `src/install/fnm.sh` | `install_fnm()`, `install_node_lts()`, `install_global_npm()` | `curl \| bash`, `fnm install`, `npm install -g` |
| `src/install/uv.sh` | `install_uv()`, `install_python()` | `curl \| sh`, `uv python install` |
| `src/install/ai-tools.sh` | `install_ai_tool()` (npm and curl branches) | `npm install -g`, `curl \| sh` |
| `src/install/dev-env.sh` | `setup_ssh_key()` | `ssh-keygen` |

### PowerShell scripts (Windows):

| Script | Status | Notes |
|--------|--------|-------|
| `setup.ps1` | No DRY_RUN support | Would need `-DryRun` switch parameter |
| `src/platforms/windows/install/winget.ps1` | No DRY_RUN support | Would need guard in `Install-WinGetPackage` |
| `src/platforms/windows/main.ps1` | No DRY_RUN support | Would need step counting |

## Scope Recommendations

### Must-Have (UX-01 through UX-04)

1. **Flag parsing in setup.sh** -- `--dry-run`, `--verbose`, `--unattended` flags
2. **DRY_RUN guards in 9 Bash scripts** -- All mutation points get `[DRY_RUN]` prefix
3. **Step counter in Linux/macOS orchestrators** -- `[Step X/Y]` in install_profile()
4. **Completion summary** -- New `show_completion_summary()` with installed/skipped/failed/duration
5. **DRY_RUN banner** -- Prominent warning at start when dry-run active

### Nice-to-Have (if time permits)

1. **PowerShell DRY_RUN** -- `-DryRun` switch in setup.ps1 and winget.ps1
2. **Per-package progress in sub-installers** -- `[3/15]` prefix per package within apt.sh, brew.sh, etc.
3. **Duration per section** -- "APT packages: 45s", "Brew formulae: 120s" in summary

### Out of Scope

1. **Animated spinners** -- Violates NO_COLOR/non-TTY compat and zero-deps rule
2. **Parallel install progress** -- ADV-01 is v2 requirement
3. **JSON/structured output** -- Needs jq, violates zero-deps
4. **Log file generation** -- LOG_FILE support exists in logging.sh but is not in scope for Phase 7

## Plan Structure Recommendation

### Plan 07-01: Progress Feedback System (UX-01)
- Create `src/core/progress.sh` with step counter and summary tracker
- Add step counting to `src/platforms/linux/main.sh` install_profile()
- Add step counting to `src/platforms/macos/main.sh` install_profile()
- Add DRY_RUN banner display
- Pre-filter platform-relevant steps before counting

### Plan 07-02: Dry-Run Mode (UX-02)
- Add `--dry-run`/`-n` flag parsing to setup.sh (before main)
- Add `--verbose`/`-v` and `--unattended`/`-y` flags
- Add DRY_RUN guards to all 9 scripts missing them
- Ensure `[DRY_RUN]` prefix is consistent with existing pattern
- Test: `./setup.sh --dry-run developer` shows plan without mutations

### Plan 07-03: Completion Summary and One-Command Setup (UX-03, UX-04)
- Add `show_completion_summary()` to progress.sh
- Track SECONDS for duration in setup.sh
- Replace bare `show_failure_summary` + `log_banner "Setup Complete"` with rich summary
- Verify `./setup.sh` works with sensible defaults (developer profile, interactive)
- Update help text with all flags documented

## Open Questions

1. **Should sub-installer per-package progress (e.g., "[3/15] Installing git...") be part of Phase 7?**
   - What we know: Sub-installers already log "Installing: $pkg" and "Installed: $pkg" per package. Adding a counter would require passing total count or calculating it.
   - What's unclear: Is the current per-package logging sufficient for UX-01, or do users need "[3/15]" counters?
   - Recommendation: Start without per-package counters (step-level progress is sufficient). Add if user feedback indicates need.

2. **Should PowerShell (Windows) get DRY_RUN and progress support in Phase 7?**
   - What we know: Phase 6 established PS patterns. Windows has no DRY_RUN, no progress, no flag parsing.
   - What's unclear: Is Windows UX in scope for Phase 7? Roadmap says "depends on Phase 5" (Linux) not Phase 6 (Windows).
   - Recommendation: Include basic PowerShell DRY_RUN as a stretch goal but not required for Phase 7 success criteria.

3. **How should the completion summary handle the sub-process isolation problem?**
   - What we know: Installers run as `bash script.sh` (separate process). FAILED_ITEMS don't propagate back.
   - What's unclear: Should we change to `source` pattern, or track at orchestrator level?
   - Recommendation: Track at orchestrator level. Count sections dispatched, check exit codes (though all exit 0). The sub-installers print their own summaries. The top-level summary shows sections completed + total duration + any orchestrator-level issues.

## Sources

### Primary (HIGH confidence)
- Codebase analysis of 20+ files in the repository (direct code reading)
- Existing patterns verified across: setup.sh, config.sh, logging.sh, errors.sh, platform.sh, dotfiles.sh, brew.sh, brew-cask.sh, homebrew.sh, apt.sh, flatpak.sh, snap.sh, cargo.sh, rust-cli.sh, fnm.sh, uv.sh, ai-tools.sh, dev-env.sh, dotfiles-install.sh, interactive.sh, packages.sh, winget.ps1, main.ps1, setup.ps1, logging.psm1
- Legacy scripts for flag-parsing patterns: scripts/setup/with-profile.sh, scripts/setup/unattended-install.sh
- STATE.md decisions log (25 plans of accumulated decisions)

### Secondary (MEDIUM confidence)
- Bash $SECONDS builtin behavior -- well-documented in Bash manual, verified available in Bash 3.2+
- `tput cols` availability -- standard ncurses, already used in codebase for color detection

### Tertiary (LOW confidence)
- None. All findings based on direct codebase analysis.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Pure Bash builtins, no external tools needed, all verified in codebase
- Architecture: HIGH - Extending established patterns, not introducing new ones
- Pitfalls: HIGH - Identified from direct code analysis (DRY_RUN comparison, process scope, Bash 3.2 compat all verified in codebase decisions)
- Gap analysis: HIGH - Exhaustive grep of DRY_RUN across all scripts, every missing file identified

**Research date:** 2026-02-06
**Valid until:** 2026-03-06 (stable domain, patterns won't change)
