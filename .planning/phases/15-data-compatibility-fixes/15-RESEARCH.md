# Phase 15: Data & Compatibility Fixes - Research

**Researched:** 2026-02-21
**Domain:** Flatpak data files, Bash compatibility, shell strict mode, PowerShell parameter validation
**Confidence:** HIGH

## Summary

Phase 15 is a data-integrity and compatibility sweep across three domains: (1) fixing broken Flatpak application IDs in two package list files, (2) resolving the macOS Bash 3.2 chicken-and-egg problem where `verify_bash_version()` blocks setup.sh before Homebrew can install a modern Bash, and (3) applying several convergent quality fixes including universal `set -o pipefail`, PowerShell parameter validation, multiline-safe cargo check, and brew.txt corrections.

All six requirements (DATA-01 through QUAL-02) are well-scoped, low-risk data and code fixes. Prior research exists in `.planning/phases/research-flatpak-bash32.md` with a complete Flatpak ID audit and Bash 3.2 analysis. The codebase is confirmed to use zero Bash 4+ features, making the warn-not-block approach safe.

**Primary recommendation:** Split into 2 plans -- Plan 1 for data fixes (DATA-01, DATA-02, DATA-03) and Plan 2 for code fixes (COMPAT-01, QUAL-01, QUAL-02). Both are straightforward edits with clear verification criteria.

---

## Standard Stack

No new libraries or tools are introduced in this phase. All changes are edits to existing files.

### Core Technologies
| Technology | Version | Purpose | Relevance |
|-----------|---------|---------|-----------|
| Bash | 3.2+ (macOS) / 5.x (Linux) | Shell scripts | COMPAT-01 targets Bash 3.2 compatibility |
| Flatpak | Any | Package manager | DATA-01/02 fix application IDs |
| PowerShell | 5.1+ | Windows scripts | QUAL-02 PS fixes |
| Homebrew | Any | macOS package manager | QUAL-02 brew.txt edits |

### Verification Tools
| Tool | Purpose | How Used |
|------|---------|----------|
| `grep` | Verify no short Flatpak names remain | `grep -cvP '\.' flatpak.txt` should return 0 |
| ShellCheck | Validate shell script changes | Already configured via `.shellcheckrc` |
| `flatpak search` | Look up correct reverse-DNS IDs | Reference for ID corrections |

---

## Architecture Patterns

### Pattern 1: Flatpak Reverse-DNS App IDs

**What:** Flatpak requires full reverse-DNS application identifiers (e.g., `com.slack.Slack`), not short names (e.g., `slack`). Short names silently fail with `flatpak install`.

**Format rules:**
- Minimum 3 dot-separated segments: `tld.domain.AppName`
- Case-sensitive (must match Flathub exactly)
- Examples: `com.github.tchx84.Flatseal`, `org.gnome.Boxes`, `us.zoom.Zoom`

**Validation heuristic:** A valid Flatpak ID contains at least 2 dots. Any line in `flatpak*.txt` that is not a comment and has fewer than 2 dots is likely broken.

### Pattern 2: Warn-Not-Block for macOS Bash

**What:** `verify_bash_version()` currently returns 1 (blocking) when Bash < 4. On macOS, this should warn but return 0 to allow setup.sh to proceed and install Homebrew (which provides Bash 5.x).

**Why safe:** Complete audit of `src/**/*.sh` confirmed zero Bash 4+ features are used. The entire codebase runs on Bash 3.2.

**Call chain:**
```
setup.sh:main() -> verify_all() -> verify_bash_version()
  returns 1 on macOS -> verify_all returns 1 -> main exits early
```

**Fix location:** `src/core/platform.sh`, function `verify_bash_version()` (lines 115-136).

**Note:** `src/platforms/macos/main.sh` already has a `check_bash_upgrade()` function (lines 77-90) that does the correct warn-not-block behavior. But this only runs if `setup.sh` dispatches to macOS, which it never does because `verify_all()` blocks first.

### Pattern 3: Pipefail Placement for Subshell Scripts

**What:** CONVENTIONS.md mandates `set -o pipefail` in "every script", but only `setup.sh` has it. Scripts invoked via `bash script.sh` (subshell) do NOT inherit the parent's `set -o pipefail`.

**Which scripts are invoked as subshells:**
```
setup.sh (has pipefail)
  -> bash linux/main.sh (MISSING)
  -> bash macos/main.sh (MISSING)
    -> bash linux/install/apt.sh (MISSING)
    -> bash linux/install/flatpak.sh (MISSING)
    -> bash linux/install/snap.sh (MISSING)
    -> bash linux/install/cargo.sh (MISSING)
    -> bash macos/install/homebrew.sh (MISSING)
    -> bash macos/install/brew.sh (MISSING)
    -> bash macos/install/brew-cask.sh (MISSING)
    -> bash src/install/dev-env.sh (MISSING)
    -> bash src/install/rust-cli.sh (MISSING)
    -> bash src/install/ai-tools.sh (MISSING)
```

**Core modules (sourced, not subshelled) -- do NOT need pipefail:**
- `src/core/logging.sh` (sourced)
- `src/core/errors.sh` (sourced)
- `src/core/platform.sh` (sourced)
- `src/core/packages.sh` (sourced)
- `src/core/idempotent.sh` (sourced)
- `src/core/interactive.sh` (sourced)
- `src/core/progress.sh` (sourced)
- `src/core/dotfiles.sh` (sourced)
- `src/install/dotfiles-install.sh` (sourced via `source`)
- `src/install/fnm.sh` (sourced by dev-env.sh)
- `src/install/uv.sh` (sourced by dev-env.sh)
- `config.sh` (sourced)

**Placement:** After the shebang, before any other code. Each script already has a comment line `# NOTE: No set -e (per Phase 1 decision...)`. The `set -o pipefail` goes right after the shebang, before that comment.

**Bash 3.2 compatibility:** `set -o pipefail` is available since Bash 3.0. Safe on all targets.

### Pattern 4: tools/lint.sh Exception

`tools/lint.sh` uses `set -euo pipefail` (stricter than the project convention). This is intentional -- lint runners are utility scripts, not setup scripts. They should fail fast. Do NOT change this file.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Flatpak ID lookup | Custom validation regex | `flatpak search <name>` | Official tool, always current |
| Bash version detection | Custom version parser | `BASH_VERSINFO[0]` | Built-in, reliable |
| PS parameter validation | Manual string checks | `[ValidateSet()]` attribute | PowerShell built-in, enforced at call time |

---

## Detailed Findings by Requirement

### DATA-01: Fix flatpak.txt IDs

**File:** `data/packages/flatpak.txt`
**Current state:** 24 entries total, 4 correct, 20 broken (short names or wrong format).

**Complete replacement map (from prior research, verified against Flathub):**

| Line | Current | Correct ID |
|------|---------|------------|
| 7 | `flatseal` | `com.github.tchx84.Flatseal` |
| 8 | `filezilla` | `org.filezillaproject.Filezilla` |
| 12 | `vim.vim` | `org.vim.Vim` |
| 15 | `pavucontrol` | `org.pulseaudio.pavucontrol` |
| 18 | `obsproject.Studio` | `com.obsproject.Studio` |
| 21 | `zoom` | `us.zoom.Zoom` |
| 24 | `slack` | `com.slack.Slack` |
| 25 | `skype` | `com.skype.Client` (REMOVE -- see DATA-03) |
| 28 | `dropbox` | `com.dropbox.Client` |
| 31 | `masterpdf` | `net.code_industry.MasterPDFEditor` |
| 33 | `calibre` | `com.calibre_ebook.calibre` |
| 36 | `ankiweb` | `net.ankiweb.Anki` |
| 37 | `geogebra` | `org.geogebra.GeoGebra` |
| 38 | `openboard` | `ch.openboard.OpenBoard` |
| 41 | `blanket` | `com.rafaelmardojai.Blanket` |
| 42 | `organizer` | `org.librehunt.Organizer` |
| 43 | `meld` | `org.gnome.meld` |
| 44 | `gitkraken` | `com.axosoft.GitKraken` |
| 47 | `jamovi` | `org.jamovi.jamovi` |
| 50 | `Epiphany` | `org.gnome.Epiphany` |

**Confidence:** HIGH -- verified against Flathub repositories in prior research.

### DATA-02: Fix flatpak-post.txt IDs

**File:** `data/packages/flatpak-post.txt`
**Current state:** 49 entries total, 31 correct, 16 broken, 2 removed (TogglDesktop + Workflow).

**Replacement map:**

| Line | Current | Correct ID |
|------|---------|------------|
| 9 | `flatseal` | `com.github.tchx84.Flatseal` |
| 13 | `filezilla` | `org.filezillaproject.Filezilla` |
| 16 | `gpuviewer` | `io.github.arunsivaramanneo.GPUViewer` |
| 19 | `OnionShare` | `org.onionshare.OnionShare` |
| 29 | `pavucontrol` | `org.pulseaudio.pavucontrol` |
| 51 | `obsproject.Studio` | `com.obsproject.Studio` |
| 63 | `zoom` | `us.zoom.Zoom` |
| 66 | `slack` | `com.slack.Slack` |
| 78 | `dropbox` | `com.dropbox.Client` |
| 83 | `calibre` | `com.calibre_ebook.calibre` |
| 84 | `openboard` | `ch.openboard.OpenBoard` |
| 88 | `fontfinder` | `io.github.mmstick.FontFinder` |
| 97 | `meld` | `org.gnome.meld` |
| 99 | `com.toggl.TogglDesktop` | REMOVE (see DATA-03) |
| 106 | `blanket` | `com.rafaelmardojai.Blanket` |
| 109 | `organizer` | `org.librehunt.Organizer` |
| 124 | `geogebra` | `org.geogebra.GeoGebra` |

**Confidence:** HIGH -- same source as DATA-01.

### DATA-03: Remove Discontinued Apps

**TogglDesktop:**
- `com.toggl.TogglDesktop` returns 404 on Flathub. App discontinued.
- Present in `flatpak-post.txt` line 99.
- Action: Remove the entry entirely.

**Skype:**
- `com.skype.Client` repository archived on Flathub (July 2025).
- Present in `flatpak.txt` as `skype` (line 25).
- Present in `flatpak-post.txt` -- NOT present (already absent).
- Action: Remove the `skype` entry from `flatpak.txt` and add a comment noting archival.

**Workflow:**
- `com.gitlab.cunidev.Workflow` GitHub repository archived Dec 12, 2023. Flathub API returns 404.
- Present in `flatpak-post.txt` line 100.
- Action: Remove the entry entirely. No direct replacement on Flathub.

**MasterPDFEditor ID correction:**
- Research had `net.codeindustry.MasterPDFEditor` — this is WRONG (404 on Flathub).
- Correct ID is `net.code_industry.MasterPDFEditor` (underscore between "code" and "industry").
- Present in `flatpak.txt` as `masterpdf` (line 31).

**Confidence:** HIGH -- Flathub status verified via live API check (2026-02-21).

### COMPAT-01: verify_bash_version() warn-not-block on macOS

**File:** `src/core/platform.sh`, function `verify_bash_version()` (lines 115-136).

**Current behavior:**
```bash
if [[ "$major" -lt 4 ]]; then
    log_error "Bash version ... is too old. Version 4.0+ is required."
    # ... prints upgrade instructions
    return 1  # BLOCKS execution
fi
```

**Required behavior:**
```bash
if [[ "$major" -lt 4 ]]; then
    if [[ "${DETECTED_OS:-}" == "macos" ]]; then
        log_warn "Bash $DETECTED_BASH detected. Homebrew will install Bash 5.x."
        log_warn "After setup, upgrade: brew install bash"
        return 0  # WARN only -- allow execution
    fi
    log_error "Bash version ... is too old. Version 4.0+ is required."
    # ... Linux-specific upgrade instructions
    return 1
fi
```

**Dependencies:** `DETECTED_OS` must be set before `verify_bash_version()` is called. Checking `verify_all()`: it calls `detect_platform` first if `DETECTED_OS` is empty (line 298), then calls `verify_bash_version()` (line 314). So `DETECTED_OS` is always available. Safe.

**Note on macos/main.sh:** The existing `check_bash_upgrade()` function in `src/platforms/macos/main.sh` (lines 77-90) already does warn-not-block. After this fix, both the entry point (`setup.sh` via `verify_all`) and the macOS handler will warn consistently. The `check_bash_upgrade()` function becomes redundant but harmless -- it provides a second reminder. Removing it is optional and out of scope.

**Confidence:** HIGH -- direct code analysis, no external dependencies.

### QUAL-01: set -o pipefail in all subshell scripts

**Scripts that need `set -o pipefail` added (12 files):**

1. `src/platforms/linux/main.sh`
2. `src/platforms/macos/main.sh`
3. `src/platforms/linux/install/apt.sh`
4. `src/platforms/linux/install/flatpak.sh`
5. `src/platforms/linux/install/snap.sh`
6. `src/platforms/linux/install/cargo.sh`
7. `src/platforms/macos/install/homebrew.sh`
8. `src/platforms/macos/install/brew.sh`
9. `src/platforms/macos/install/brew-cask.sh`
10. `src/install/dev-env.sh`
11. `src/install/rust-cli.sh`
12. `src/install/ai-tools.sh`

**Scripts that do NOT need it (sourced modules, not subshells):**
- `config.sh` (sourced by setup.sh)
- `src/core/*.sh` (all sourced, never run as subshell)
- `src/install/fnm.sh` (sourced by dev-env.sh, has main guard)
- `src/install/uv.sh` (sourced by dev-env.sh, has main guard)
- `src/install/dotfiles-install.sh` (sourced by setup.sh)

**Special case -- `tools/lint.sh`:** Already has `set -euo pipefail` (stricter). Leave as-is.

**Special case -- `src/platforms/linux/post_install.sh`:** Deprecated stub. Only echoes deprecation message and exits. No pipeline risk. Skip.

**Special case -- test scripts (`tests/*.sh`):** These are test harnesses, not setup scripts. Out of scope for this requirement.

**Placement pattern:**
```bash
#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: name.sh
# ...
```

Insert `set -o pipefail` as line 2, immediately after the shebang.

**Note:** `fnm.sh` and `uv.sh` are primarily sourced (they have main guards), but they CAN be run directly. When sourced, `set -o pipefail` in them would affect the sourcing shell. However, `set -o pipefail` is already the convention per CONVENTIONS.md, and setup.sh already sets it. Adding it to fnm.sh and uv.sh is safe but not required by the success criteria ("scripts executed as subshell"). Recommend EXCLUDING them to minimize scope.

**Confidence:** HIGH -- direct `grep` verified current state; CONVENTIONS.md is explicit.

### QUAL-02: Convergent Minor Fixes

**QUAL-02a: ValidateSet for -Profile parameter in setup.ps1**

**File:** `setup.ps1`, line 21.
**Current:** `[string]$Profile = 'developer'`
**Required:** `[ValidateSet('minimal', 'developer', 'full')][string]$Profile = 'developer'`

This enforces profile names at the PowerShell parameter binding level, giving a clear error message if an invalid profile is passed.

**Also applies to:** `src/platforms/windows/main.ps1`, line 14.
**Current:** `[string]$Profile = ''`
**Note:** main.ps1 accepts empty string (interactive mode) plus valid profiles. Use `[ValidateSet('', 'minimal', 'developer', 'full')]` to allow both modes.

**Confidence:** HIGH -- PowerShell ValidateSet is well-established.

**QUAL-02b: Test-CargoInstalled multiline-safe**

**File:** `src/platforms/windows/core/idempotent.psm1`, function `Test-CargoInstalled` (lines 54-75).

**Current:**
```powershell
$output = cargo install --list 2>$null
if ($output -match "^$([regex]::Escape($PackageName)) ") {
    return $true
}
```

**Problem:** `cargo install --list` returns multiline output. `$output` is an array of strings. The `-match` operator on an array tests each element and returns matching elements (truthy if any match), but `^` anchoring on a string array doesn't work as expected in all PS versions.

**Fix:** Join lines before matching, or use `-contains`-style check:
```powershell
$output = (cargo install --list 2>$null) -join "`n"
if ($output -match "(?m)^$([regex]::Escape($PackageName)) ") {
    return $true
}
```

Or more reliably, filter lines explicitly:
```powershell
$installed = cargo install --list 2>$null | Where-Object { $_ -match "^\S" }
$found = $installed | Where-Object { $_ -match "^$([regex]::Escape($PackageName)) " }
return [bool]$found
```

**Confidence:** MEDIUM -- the current code likely works in practice because `-match` on arrays does test each element. But the explicit join + `(?m)` multiline flag is more robust and intention-clear. The requirement text says "multiline-safe" so apply the fix.

**QUAL-02c: Remove `node` from brew.txt**

**File:** `data/packages/brew.txt`, line 36.
**Current:** `node` is listed under "Development - Languages".
**Problem:** The project uses `fnm` (Fast Node Manager) to manage Node.js versions. Having `node` in brew.txt causes conflicts -- Homebrew's node and fnm's node fight over the PATH.
**Action:** Remove the `node` line. Add a comment explaining why.

**Confidence:** HIGH -- fnm is the designated Node.js manager (see `src/install/fnm.sh`).

**QUAL-02d: Add `fzf` to brew.txt**

**File:** `data/packages/brew.txt`.
**Action:** Add `fzf` under an appropriate section (Terminal - Tools or similar).
**Rationale:** `fzf` is a standard fuzzy finder used by many shell plugins and Rust CLI tool integrations (zoxide, atuin, etc.).

**Confidence:** HIGH -- standard tool in the modern CLI ecosystem.

---

## Common Pitfalls

### Pitfall 1: Case-Sensitive Flatpak IDs
**What goes wrong:** Using `org.gnome.meld` instead of `org.gnome.Meld` (or vice versa) causes silent install failure.
**Why it happens:** Flatpak IDs are case-sensitive and don't always follow predictable patterns.
**How to avoid:** Use the exact IDs from the prior research audit. Verify any questionable IDs with `flatpak search`.
**Warning signs:** Flatpak install returns non-zero with "No matching refs found".

### Pitfall 2: Pipefail + Exit 0 Interaction
**What goes wrong:** Adding `set -o pipefail` could theoretically cause scripts to exit differently if a pipeline fails.
**Why it happens:** With pipefail, `cmd1 | cmd2` returns the exit code of the failing command in the pipe, not just cmd2.
**How to avoid:** The project convention is "always exit 0" (ADR-001). Scripts already guard individual commands with `if ! cmd; then record_failure; fi`. Pipefail only affects unguarded pipelines.
**Warning signs:** Audit each script for unguarded pipeline usage. In practice, the scripts in this project rarely use pipelines in their main logic -- they use `command -v foo &>/dev/null` (not a pipe) and `flatpak list | grep` (which is always inside a function with its own return).

### Pitfall 3: DETECTED_OS Timing in verify_bash_version
**What goes wrong:** If `DETECTED_OS` is not set when `verify_bash_version()` is called, the macOS check fails.
**Why it happens:** Could happen if someone calls `verify_bash_version()` before `detect_platform()`.
**How to avoid:** `verify_all()` calls `detect_platform` first. Use `${DETECTED_OS:-}` with empty-string fallback in the check. On Linux, `DETECTED_OS` being unset means the macOS branch is not taken, so the hard-fail behavior is preserved. Safe.

### Pitfall 4: ValidateSet Blocking Empty String
**What goes wrong:** Adding `[ValidateSet('minimal', 'developer', 'full')]` to `main.ps1`'s `$Profile` parameter would reject the empty string, breaking interactive mode.
**Why it happens:** `main.ps1` uses `$Profile = ''` as the "no profile = show menu" signal.
**How to avoid:** Include empty string in the ValidateSet: `[ValidateSet('', 'minimal', 'developer', 'full')]`.

---

## Code Examples

### Example 1: verify_bash_version() with macOS Warn

```bash
# Source: src/core/platform.sh (proposed change)
verify_bash_version() {
    local major="${BASH_VERSINFO[0]:-0}"

    if [[ "$major" -lt 4 ]]; then
        if [[ "${DETECTED_OS:-}" == "macos" ]]; then
            log_warn "Bash ${DETECTED_BASH} detected (version 4.0+ recommended)"
            log_warn "Homebrew will install Bash 5.x. Upgrade after setup:"
            echo "  brew install bash"
            echo "  sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'"
            echo "  chsh -s /opt/homebrew/bin/bash"
            return 0  # Allow execution to continue
        fi
        log_error "Bash version $DETECTED_BASH is too old. Version 4.0+ is required."
        echo ""
        echo "Upgrade instructions:"
        if [[ "${DETECTED_OS:-}" == "linux" ]]; then
            echo "  sudo apt update && sudo apt install bash"
        else
            echo "  Please upgrade Bash to version 4.0 or later"
        fi
        echo ""
        return 1
    fi

    return 0
}
```

### Example 2: Pipefail Placement

```bash
#!/usr/bin/env bash
set -o pipefail
#######################################
# Script: flatpak.sh
# Description: Install Flatpak packages for Linux (data-driven)
# ...
```

### Example 3: ValidateSet for Profile

```powershell
# setup.ps1
param(
    [ValidateSet('minimal', 'developer', 'full')]
    [string]$Profile = 'developer',
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Unattended,
    [switch]$Help
)
```

### Example 4: Test-CargoInstalled Multiline-Safe

```powershell
function Test-CargoInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $output = (cargo install --list 2>$null) -join "`n"
    if ($output -match "(?m)^$([regex]::Escape($PackageName)) ") {
        return $true
    }

    return $false
}
```

---

## Verification Strategy

### DATA-01 Verification
```bash
# Count non-comment, non-empty lines without at least 2 dots
grep -v '^#' data/packages/flatpak.txt | grep -v '^$' | grep -cvP '\.'
# Expected: 0 (all lines have dots)

# More precise: lines with fewer than 2 dots
grep -v '^#' data/packages/flatpak.txt | grep -v '^$' | awk -F. 'NF<3' | wc -l
# Expected: 0
```

### DATA-02 Verification
```bash
grep -v '^#' data/packages/flatpak-post.txt | grep -v '^$' | awk -F. 'NF<3' | wc -l
# Expected: 0
```

### DATA-03 Verification
```bash
grep -i 'toggl' data/packages/flatpak-post.txt | wc -l  # Expected: 0
grep -i 'skype' data/packages/flatpak.txt | wc -l  # Expected: 0
```

### COMPAT-01 Verification
- Manual inspection: `verify_bash_version()` returns 0 when `DETECTED_OS == macos` and `BASH_VERSINFO[0] < 4`.
- Existing tests (if any) or manual test: mock `BASH_VERSINFO[0]=3` and `DETECTED_OS=macos`, confirm no `return 1`.

### QUAL-01 Verification
```bash
# All scripts invoked as subshell should have pipefail
for f in src/platforms/linux/main.sh src/platforms/macos/main.sh \
         src/platforms/linux/install/apt.sh src/platforms/linux/install/flatpak.sh \
         src/platforms/linux/install/snap.sh src/platforms/linux/install/cargo.sh \
         src/platforms/macos/install/homebrew.sh src/platforms/macos/install/brew.sh \
         src/platforms/macos/install/brew-cask.sh \
         src/install/dev-env.sh src/install/rust-cli.sh src/install/ai-tools.sh; do
    head -3 "$f" | grep -q 'set -o pipefail' || echo "MISSING: $f"
done
# Expected: no output (all present)
```

### QUAL-02 Verification
- `setup.ps1`: `grep 'ValidateSet' setup.ps1` returns match.
- `idempotent.psm1`: `Test-CargoInstalled` uses `-join` or `(?m)` multiline matching.
- `brew.txt`: `grep '^node$' data/packages/brew.txt` returns no match.
- `brew.txt`: `grep '^fzf$' data/packages/brew.txt` returns match.

---

## Open Questions (RESOLVED 2026-02-21)

All three open questions resolved via live Flathub API verification:

1. **com.wps.Office** — **RESOLVED: VALID**. Verified on Flathub API. Keep entry.

2. **com.gitlab.cunidev.Workflow** — **RESOLVED: REMOVED**. GitHub repo archived Dec 2023, Flathub API returns 404. Entry must be removed from flatpak-post.txt (added to DATA-03 scope).

3. **org.librehunt.Organizer** — **RESOLVED: VALID**. Verified on Flathub API. ID is correct.

---

## Sources

### Primary (HIGH confidence)
- `.planning/phases/research-flatpak-bash32.md` -- Complete Flatpak ID audit and Bash 3.2 analysis (2026-02-19)
- `src/core/platform.sh` -- Direct code inspection of verify_bash_version() and verify_all()
- `src/platforms/macos/main.sh` -- check_bash_upgrade() reference implementation
- `.planning/codebase/CONVENTIONS.md` -- "Every script starts with set -o pipefail" convention
- All `src/**/*.sh` files -- grep for `set -o pipefail` (only setup.sh has it)
- `setup.ps1`, `src/platforms/windows/main.ps1` -- Direct code inspection of -Profile parameter
- `src/platforms/windows/core/idempotent.psm1` -- Direct code inspection of Test-CargoInstalled
- `data/packages/brew.txt` -- Direct inspection (node present, fzf absent)

### Secondary (MEDIUM confidence)
- Flathub repository URLs listed in research-flatpak-bash32.md -- verified at research time (2026-02-19)

### Tertiary (LOW confidence)
- None. All findings verified from primary sources.

---

## Metadata

**Confidence breakdown:**
- Flatpak ID corrections: HIGH -- prior detailed audit exists with Flathub verification
- Bash 3.2 compatibility: HIGH -- complete feature audit confirms zero Bash 4+ usage
- Pipefail placement: HIGH -- simple grep + code structure analysis
- PowerShell fixes: HIGH (ValidateSet) / MEDIUM (Test-CargoInstalled multiline behavior)
- brew.txt changes: HIGH -- fnm/node conflict is well-documented in codebase

**Research date:** 2026-02-21
**Valid until:** 2026-03-21 (stable domain, low churn rate)
