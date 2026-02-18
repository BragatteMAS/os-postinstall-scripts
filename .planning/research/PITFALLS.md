# Domain Pitfalls: Quality Refactoring of a Working Shell System

**Domain:** Shell script quality refactoring (Bash + PowerShell)
**Researched:** 2026-02-18
**Confidence:** HIGH (codebase analysis + shell expertise + community patterns)
**Context:** v3.0 milestone -- improving a 7.5/10 working system to 8.5-9/10 without breaking it

---

## Framing: The Refactoring Paradox

The system works. Every pitfall below is about **breaking working functionality while trying to improve it**. The single most important principle: **each change must be independently deployable and testable.** If a refactoring change produces a regression, it must be trivially revertible without affecting other improvements.

---

## Critical Pitfalls

Mistakes that cause regressions in working functionality.

### Pitfall 1: VERBOSE Boolean Truthiness Trap

**What goes wrong:** Changing `VERBOSE` checks from `-n` (non-empty) to `== "true"` (or vice versa) creates a silent behavior change that breaks logging across the entire system.

**Current bug (confirmed in codebase):**
```bash
# config.sh line 25 -- sets VERBOSE to string "false"
VERBOSE="${VERBOSE:-false}"

# logging.sh lines 99, 113, 127, 141 -- checks if VERBOSE is non-empty
if [[ -n "${VERBOSE:-}" ]]; then
    prefix="[$(_timestamp)] "
fi

# log_debug (line 153) -- checks if VERBOSE is empty
if [[ -z "${VERBOSE:-}" ]]; then
    return 0
fi
```

Because `config.sh` sets `VERBOSE="false"`, and `logging.sh` checks `-n` (non-empty), the string `"false"` is non-empty, so **timestamps always show** and **debug messages are always visible**. This is the known VERBOSE bug.

**Why the fix is dangerous:**
1. **If you fix logging.sh to check `== "true"`:** Every script that sets `VERBOSE=anything-nonempty` to enable timestamps will silently stop working. Any user with `export VERBOSE=1` or `VERBOSE=yes` in their environment loses verbose output.
2. **If you fix config.sh to set `VERBOSE=""`:** Scripts that check `"${VERBOSE:-}" == "true"` (there are none currently, but future code might) break. Also, `export VERBOSE` exports an empty string, which is different from unset.
3. **If you change to integer (0/1):** Every `== "true"` check and every `-n`/`-z` check must change simultaneously. Missing one is a silent regression.

**The trap within the trap:** The PowerShell side uses `$env:VERBOSE -eq 'true'` consistently (logging.psm1 lines 35, 41). Unifying the convention means the Bash side must adopt `== "true"` to match. But then `VERBOSE=1` from users stops working.

**Prevention:**
1. Fix in exactly TWO commits, not one:
   - Commit A: Fix `logging.sh` to use `== "true"` consistently (4 locations: lines 99, 113, 127, 141, 153)
   - Commit B: Verify `config.sh` already uses `"false"` default -- no change needed
2. Add a deprecation bridge for non-standard values:
   ```bash
   # At top of logging.sh, after source guard
   case "${VERBOSE:-}" in
       true|false|"") ;;  # expected values
       *)
           # Normalize: any truthy value becomes "true"
           if [[ -n "${VERBOSE:-}" ]]; then
               VERBOSE="true"
           fi
           ;;
   esac
   ```
3. Test DRY_RUN output: `VERBOSE=false ./setup.sh -n` should NOT show timestamps. `VERBOSE=true ./setup.sh -n` should show timestamps.

**Detection:** Run `./setup.sh --dry-run minimal 2>&1 | head -5` -- if timestamps appear without `-v` flag, the bug persists. If timestamps disappear WITH `-v` flag, the fix broke something.

**Confidence:** HIGH -- bug confirmed by direct code inspection of config.sh:25 and logging.sh:99-153.

---

### Pitfall 2: NONINTERACTIVE/UNATTENDED Split-Brain

**What goes wrong:** Renaming `NONINTERACTIVE` to `UNATTENDED` (or vice versa) without a complete migration creates a state where some scripts respect the old name and some respect the new name. The system appears to work but interactive prompts appear in supposedly-unattended runs, or apt installs use wrong options.

**Current state (confirmed):**

| Variable | Where Used | How Checked |
|----------|-----------|-------------|
| `UNATTENDED` | `config.sh`, `setup.sh` (flag `-y`) | `== "true"` |
| `NONINTERACTIVE` | `interactive.sh`, `apt.sh`, `dev-env.sh`, `ai-tools.sh`, `homebrew.sh` | `== "true"` |

The system has **two different variable names for the same concept**, used in different files. `setup.sh` sets `UNATTENDED=true` when `-y` is passed, but `apt.sh` checks `NONINTERACTIVE`. This means **`-y` does not propagate to apt's DEBIAN_FRONTEND or --force-confold**.

**Why the fix is dangerous:**
1. **Homebrew uses `NONINTERACTIVE=1`** (not `"true"`) -- it is a Homebrew-specific env var that the Homebrew installer itself checks. Renaming this breaks Homebrew installation (homebrew.sh line 95).
2. **DEBIAN_FRONTEND=noninteractive** is set conditionally on `NONINTERACTIVE == "true"` (apt.sh line 125). If the variable is renamed to UNATTENDED but apt.sh is missed, dpkg prompts appear during unattended installs and **hang forever** in automation.
3. **The `-y` flag sets `UNATTENDED`**, but cross-platform installers check `NONINTERACTIVE`. Without bridging, the flag only affects `setup.sh`'s dotfiles prompt (line 196), not actual package installation.

**Prevention:**
1. Do NOT rename. Instead, bridge in `config.sh`:
   ```bash
   # Bridge: UNATTENDED is the canonical name (matches CLI flag -y/--unattended)
   # NONINTERACTIVE is the legacy name used by installers
   # Both are exported; changing one updates the other
   UNATTENDED="${UNATTENDED:-false}"
   NONINTERACTIVE="${NONINTERACTIVE:-$UNATTENDED}"
   export UNATTENDED NONINTERACTIVE
   ```
2. NEVER touch the `NONINTERACTIVE=1` in homebrew.sh -- that is a Homebrew API, not your variable.
3. Migration path: Phase 1 adds bridge, Phase 2 (future) migrates all checks to UNATTENDED, Phase 3 (future) removes NONINTERACTIVE.
4. Test: `./setup.sh -y --dry-run minimal` -- every `[DRY_RUN]` line should appear, NO interactive prompts should fire.

**Detection:** Search for `NONINTERACTIVE` in src/ -- if any file checks it without the bridge being in place, the `-y` flag silently fails for that file.

**Confidence:** HIGH -- confirmed by grep: 7 files check NONINTERACTIVE, but setup.sh only sets UNATTENDED.

---

### Pitfall 3: Exit Code Change Breaks Trap Cascade

**What goes wrong:** Changing `exit 0` to `exit 1` (to properly signal failure) causes the EXIT trap in `errors.sh` to call `cleanup()` which calls `exit 0`, overriding your intended exit code. Or worse: changing the trap-registered `cleanup()` in errors.sh to not force `exit 0` causes `setup.sh`'s overridden `cleanup()` (line 51) to no longer behave consistently.

**Current architecture (confirmed):**
```
errors.sh: cleanup() { show_failure_summary; cleanup_temp_dir; exit 0; }
setup.sh:  cleanup() { ...custom logic...; exit 0; }  # OVERRIDES errors.sh
linux/main.sh: cleanup() { ...aggregate failures...; exit $exit_code; }  # DIFFERENT behavior
apt.sh: cleanup() { ...log failures...; exit $exit_code; }  # ANOTHER behavior
```

Four different `cleanup()` functions with four different exit behaviors. The trap cascade is:
1. `errors.sh` registers `trap cleanup EXIT INT TERM`
2. `setup.sh` redefines `cleanup()` and re-registers `trap cleanup EXIT INT TERM`
3. `linux/main.sh` (spawned as child via `bash`) has its OWN trap

**Why changing exit codes is dangerous:**
1. **ADR-001 explicitly mandates "always exit 0"**: Changing this contradicts a deliberate architectural decision. The rationale is sound -- 90/100 packages installed is still valuable; a non-zero exit code suggests total failure.
2. **setup.sh's cleanup runs on ANY exit**: If a sub-script starts returning non-zero, and setup.sh's cleanup checks `$?`, the meaning of "failure" changes from "the script crashed" to "some packages failed", which is very different.
3. **Child processes via `bash script.sh`**: The exit code from apt.sh/flatpak.sh propagates to linux/main.sh. Currently linux/main.sh ignores it (no `|| record_failure`). Changing apt.sh to exit 1 means linux/main.sh's `$?` changes, which affects its cleanup trap.
4. **Trap execution order**: When you `exit 1` inside a trap handler, it triggers... the same trap. Bash prevents infinite recursion but the behavior is subtle. The `exit 0` in cleanup() prevents this issue -- changing it requires understanding re-entrant trap behavior.

**Prevention:**
1. Do NOT change the "always exit 0" policy for top-level scripts (setup.sh, linux/main.sh, macos/main.sh). ADR-001 is correct for this use case.
2. For sub-scripts (apt.sh, snap.sh), exit codes are already fine: they exit 0 with failure summary. The caller (linux/main.sh) uses FAILURE_LOG for cross-process tracking.
3. If exit codes must change (e.g., for hard prereqs like "winget not found"), isolate it:
   ```bash
   # Only exit non-zero for HARD prerequisites, before any work begins
   if ! command -v winget &>/dev/null; then
       log_error "WinGet not found"
       exit 1  # OK: nothing to clean up, no packages attempted
   fi
   # After this point, always exit 0 per ADR-001
   ```
4. Write a test that verifies: `./setup.sh --dry-run minimal; echo $?` always returns 0.

**Detection:** `grep -rn "exit [^0]" src/` -- any non-zero exit after the prerequisite section is a potential cascade breaker.

**Confidence:** HIGH -- confirmed by reading four cleanup() implementations and ADR-001.

---

### Pitfall 4: PowerShell Module Scope Isolation in Multi-Process Architecture

**What goes wrong:** Extracting shared PowerShell helpers into a module (e.g., consolidating 3x `Test-WinGetInstalled` into one) works when the module is imported in the current process, but child processes spawned with `&` operator cannot see module functions or `$script:` scoped variables.

**Current architecture (confirmed):**
```
setup.ps1
  Import-Module logging.psm1, errors.psm1    # Module scope: setup.ps1 process
  & main.ps1                                   # NEW process scope
    Import-Module logging.psm1, packages.psm1, errors.psm1  # Must re-import
    & winget.ps1                               # ANOTHER new process scope
      Import-Module logging.psm1, packages.psm1, errors.psm1  # Must re-import AGAIN
```

Each `& script.ps1` creates a new scope. Module `$script:` variables (like `$script:FailedItems` in errors.psm1) are **per-process**. This is why the codebase already uses `$env:FAILURE_LOG` for cross-process failure tracking.

**Why extracting shared functions is dangerous:**
1. **DRY violation fix creates new bug**: Moving `Test-WinGetInstalled` to a shared module means every script that calls it must `Import-Module` the shared module. If one script forgets, the function is undefined and the script crashes.
2. **Module re-import with `-Force`**: Currently every script does `Import-Module ... -Force`. This resets `$script:` state. If you add a shared state module, `-Force` clears accumulated data.
3. **Environment variable bridge is the only cross-process channel**: `$env:DRY_RUN`, `$env:VERBOSE`, `$env:FAILURE_LOG` work across processes because they are environment variables. Module-scoped variables do NOT propagate.
4. **Import timing**: If a shared module imports logging.psm1 in its module manifest, and the calling script also imports logging.psm1, you can get double-initialization or version conflicts.

**Prevention:**
1. Keep shared functions in `.psm1` modules but **do not use `$script:` state across processes**. Continue using `$env:` for cross-process communication.
2. For DRY consolidation of `Test-WinGetInstalled` (appears 3x in cargo.ps1), put it in `packages.psm1` where `Read-PackageFile` already lives. But require explicit import in every script that uses it.
3. Add a module manifest (.psd1) to declare dependencies:
   ```powershell
   # packages.psd1
   @{
       RequiredModules = @('logging')
       FunctionsToExport = @('Read-PackageFile', 'Test-WinGetInstalled')
   }
   ```
4. Test: Run `setup.ps1 -Profile developer` -- verify that winget, cargo, npm, and ai-tools all see the shared functions.

**Detection:** `Get-Command Test-WinGetInstalled -ErrorAction SilentlyContinue` inside each script -- if null, the module was not imported.

**Confidence:** HIGH -- confirmed by reading scope chain in setup.ps1 -> main.ps1 -> winget.ps1 and PowerShell scope documentation.

Sources:
- [PowerShell Scope Documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes)
- [Import-Module -Scope Local issues](https://github.com/PowerShell/PowerShell/issues/20114)
- [$script: scope not propagated on script invocation](https://github.com/PowerShell/PowerShell/issues/19039)

---

### Pitfall 5: Directory Merge Breaks Source Paths and Test Assertions

**What goes wrong:** Merging `src/install/` (5 cross-platform scripts) and `src/installers/` (1 dotfiles script) breaks:
1. All relative `source` paths in the moved scripts
2. All `bash "${INSTALL_DIR}/script.sh"` calls from orchestrators
3. Test assertions that check directory existence
4. Test assertions that check file paths

**Current references to these directories (confirmed):**

| Reference | File | Line Pattern |
|-----------|------|-------------|
| `INSTALL_DIR="${LINUX_DIR}/../../install"` | linux/main.sh:48 | Relative path from platform dir |
| `bash "${INSTALL_DIR}/dev-env.sh"` | linux/main.sh:130 | Dispatches to cross-platform installer |
| `bash "${INSTALL_DIR}/rust-cli.sh"` | linux/main.sh:134 | Dispatches to cross-platform installer |
| `bash "${INSTALL_DIR}/ai-tools.sh"` | linux/main.sh:188 | Dispatches to cross-platform installer |
| `source "${SCRIPT_DIR}/src/installers/dotfiles-install.sh"` | setup.sh:143,148,200 | Dotfiles loaded directly |
| `test_directory_exists "src/install"` | tests/test_harness.sh:133 | Structure assertion |
| `test_directory_exists "src/installers"` | tests/test_harness.sh:134 | Structure assertion |
| `test_script_exists "src/install/rust-cli.sh"` | tests/test_harness.sh:53 | File assertion |
| `assert_pass "rust-cli.sh syntax" bash -n src/install/rust-cli.sh` | tests/test-linux.sh:54 | Syntax check |
| `assert_pass "dev-env.sh syntax" bash -n src/install/dev-env.sh` | tests/test-linux.sh:55 | Syntax check |
| Similar for fnm.sh, uv.sh, ai-tools.sh | tests/test-linux.sh:56-58 | Syntax checks |

**Why the merge is dangerous:**
1. **13+ hardcoded path references** must all change atomically. Missing one means a script can not find its dependency and crashes at runtime.
2. **The internal `source` paths within the moved scripts** also reference `../core/` or `../../core/`. If the nesting depth changes, these break silently (source failure returns non-zero but no `set -e` means execution continues with undefined functions).
3. **Test harness uses relative paths from project root**. Moving files changes these paths. The test harness itself has `set -euo pipefail` (unlike the main scripts), so a broken path assertion exits immediately.
4. **Git history**: A `git mv` preserves history better than delete+create, but only if done without modifications in the same commit.

**Prevention:**
1. **Do not merge directories.** Instead, pick a canonical name and create a symlink:
   ```bash
   # Rename src/installers/ to src/install/ (since install/ has 5 files vs 1)
   git mv src/installers/dotfiles-install.sh src/install/dotfiles-install.sh
   rmdir src/installers/  # or git rm the CLAUDE.md if present
   ```
2. If merging is required, do it in exactly three commits:
   - Commit A: `git mv` only (no content changes)
   - Commit B: Update all path references (source paths, INSTALL_DIR, test assertions)
   - Commit C: Run tests, verify clean
3. Use `grep -rn "install/" src/ tests/ setup.sh` to find ALL references before AND after the move.
4. Update tests FIRST (make them expect new paths), then move files. This way test failure confirms the move worked.

**Detection:** After merge, run `bash tests/test_harness.sh` and `bash tests/test-linux.sh` -- both should pass. If either fails, a path was missed.

**Confidence:** HIGH -- all 13+ references confirmed by grep of codebase.

---

## Moderate Pitfalls

### Pitfall 6: export -f Fragility When Refactoring Functions

**What goes wrong:** Moving a function from one file to another (e.g., consolidating logging aliases) breaks `export -f` declarations. The function is defined in a different source file than where `export -f` is called, or the function is defined after the `export -f` call.

**Current pattern (confirmed):**
```bash
# logging.sh exports 15 functions at the bottom
export -f setup_colors
export -f log_ok log_error log_warn log_info log_debug log_banner
export -f log log_success log_warning info error warning success
export -f _strip_colors _timestamp _write_log
```

**Why it matters during refactoring:**
1. `export -f` only works if the function is defined IN THE CURRENT SHELL. If you refactor a function to a different file that gets sourced by a different module, the original `export -f` will export an undefined function (silently -- no error).
2. The `source` vs `bash` distinction is critical: `source script.sh` runs in the current shell (exported functions available), `bash script.sh` spawns a child (only `export -f`'d functions available). Currently linux/main.sh dispatches via `bash "${INSTALL_DIR}/script.sh"` -- those child processes rely on `export -f`.
3. Removing backward-compatibility aliases (line 184-190 in logging.sh: `log()`, `success()`, `error()`, etc.) could break scripts that use the old names. Grep first.

**Prevention:**
1. Before removing any function alias, `grep -rn "functionname" src/` to verify zero callers.
2. Keep `export -f` declarations in the same file as the function definitions. Never split them.
3. If moving functions between files, move the `export -f` line too.
4. Test cross-process visibility: `bash -c 'type log_ok'` after sourcing the module.

**Detection:** `bash -c 'source config.sh && source src/core/logging.sh && type log_ok && type log && type success'` -- all should resolve.

**Confidence:** HIGH -- confirmed by code structure and shell semantics.

Sources:
- [Bash Export Command](https://codefather.tech/blog/bash-export-command/)
- [Propagating Shell Functions](https://docstore.mik.ua/orelly/unix3/upt/ch29_13.htm)

---

### Pitfall 7: DRY_RUN Guard Ordering Regression

**What goes wrong:** While refactoring, the DRY_RUN guard gets placed BEFORE the idempotency check instead of AFTER. This means DRY_RUN output shows already-installed packages as "would install", making the dry-run output misleading.

**Current correct pattern (per ADR-007):**
```bash
# CORRECT: idempotency check first, then DRY_RUN
if is_apt_installed "$pkg"; then return 0; fi        # 1. Already done?
if [[ "${DRY_RUN}" == "true" ]]; then                 # 2. Would we do it?
    log_info "[DRY_RUN] Would install $pkg"; return 0
fi
sudo apt-get install "$pkg"                            # 3. Do it
```

**The regression scenario:** During refactoring, someone extracts a shared `install_package()` function and puts DRY_RUN first for "simplicity":
```bash
# WRONG: DRY_RUN before idempotency
if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "[DRY_RUN] Would install $pkg"; return 0  # Lies about already-installed packages
fi
if is_apt_installed "$pkg"; then return 0; fi
```

**Consequences:** Users run `--dry-run` and see 100 packages "would be installed", when 90 are already there. They estimate 30 minutes of work and clear their schedule. The actual run takes 3 minutes. Trust in dry-run erodes.

**Prevention:**
1. Document the pattern in a comment at the top of every installer:
   ```bash
   # Pattern: IDEMPOTENCY -> DRY_RUN -> MUTATION (per ADR-007)
   ```
2. Add a test: `DRY_RUN=true bash src/platforms/linux/install/apt.sh 2>&1 | grep -c "Would"` -- count should be less than total packages (some already installed).
3. When extracting shared functions, copy the ADR-007 comment into the function docstring.

**Detection:** Compare `DRY_RUN=true` output with `DRY_RUN=false` output. The dry-run should skip already-installed packages just like the real run.

**Confidence:** HIGH -- ADR-007 explicitly documents this ordering. The risk is forgetting it during extraction.

---

### Pitfall 8: Source Guard Collision During Module Consolidation

**What goes wrong:** Two files that previously had independent source guards get merged, and the resulting file either has duplicate guards (first one wins, second code block skipped) or a single guard that doesn't match old references.

**Current source guards (confirmed):**
```bash
# Each core module has its own guard:
_CONFIG_SOURCED, _ERRORS_SOURCED, _LOGGING_SOURCED, _IDEMPOTENT_SOURCED,
_PACKAGES_SOURCED, _INTERACTIVE_SOURCED, _PROGRESS_SOURCED, _PLATFORM_SOURCED
```

**Why it matters:**
1. If you merge `interactive.sh` into another module, any script that checks `_INTERACTIVE_SOURCED` before sourcing will think the module is not loaded (because the guard variable name changed).
2. If two merged files both define `readonly _SOURCED=1`, the second `readonly` fails because it is already set. With no `set -e`, this is silent but logged to stderr.
3. Scripts that do conditional sourcing (e.g., errors.sh line 19: `if [[ -z "${_LOGGING_SOURCED:-}" ]]`) depend on exact guard variable names.

**Prevention:**
1. When merging modules, keep ALL old guard variables. Add the new one:
   ```bash
   # Prevent multiple sourcing (supports both old and new names)
   [[ -n "${_NEW_MODULE_SOURCED:-}" ]] && return 0
   readonly _NEW_MODULE_SOURCED=1
   # Backward compat: set old guards so conditional sourcing still works
   : "${_OLD_MODULE_A_SOURCED:=1}"
   : "${_OLD_MODULE_B_SOURCED:=1}"
   ```
2. Search for all references to the guard variable before removing it: `grep -rn "_INTERACTIVE_SOURCED" src/`
3. Consider: is the merge actually necessary? If modules are small and focused, merging may violate KISS.

**Detection:** After merging, `source config.sh && source src/core/newmodule.sh && source src/core/newmodule.sh` -- the second source should be a no-op (return 0 immediately).

**Confidence:** HIGH -- confirmed by reading all 8 source guard patterns in src/core/.

---

### Pitfall 9: Adding Unit Tests That Depend on System State

**What goes wrong:** Tests that check "is git installed" or "is apt available" pass on the developer's machine but fail on clean CI, other contributors' machines, or different platforms. Tests become flaky and are ignored.

**Current test approach (confirmed):**
```bash
# test_harness.sh uses set -euo pipefail (strict)
# test-linux.sh uses assert_pass/assert_fail on grep/bash-n
# All tests are static (syntax, patterns, anti-patterns) -- no runtime tests
```

**Shell testing anti-patterns to avoid:**
1. **Testing external commands**: `assert_pass "git works" git --version` fails in containers without git. Test your code, not the system.
2. **Sourcing production code in test**: `source src/core/logging.sh` in a test file means the test inherits global state (color variables, exported functions). If the test changes VERBOSE, it persists.
3. **Not isolating test environment**: Shell tests share the process environment. One test setting `DRY_RUN=true` affects all subsequent tests unless explicitly cleaned up.
4. **Testing with real package managers**: Running `apt install` in tests is slow, requires root, modifies system state, and is non-deterministic.
5. **Mixing bash -n (syntax) with functional tests**: Syntax checks are cheap and reliable. Functional tests need mocking. Putting both in one file makes the entire suite slow.

**Prevention for this project:**
1. Keep the current static test pattern (syntax checks, pattern assertions) as the primary test suite.
2. For new unit tests of core functions, create a test isolation wrapper:
   ```bash
   # tests/lib/test_setup.sh
   setup_test_env() {
       export DRY_RUN="false"
       export VERBOSE="false"
       export UNATTENDED="false"
       export NONINTERACTIVE="false"
       export FAILURE_LOG=""
       FAILED_ITEMS=()
   }
   ```
3. Test functions, not scripts. Source `logging.sh` and test `log_ok` output, not `./setup.sh` end-to-end.
4. Use bats-core for new tests (TAP-compliant, good isolation via `setup()`/`teardown()`). Keep existing tests as-is.
5. Never test `is_apt_installed` against real apt. Instead, mock `dpkg`:
   ```bash
   # Mock dpkg for testing
   dpkg() { return 1; }  # pretend nothing is installed
   export -f dpkg
   ```

**Detection:** Tests that require `sudo`, network access, or specific installed packages are system-dependent and will break on other machines.

**Confidence:** MEDIUM -- based on bats-core documentation and shell testing community patterns. No project-specific test failures yet.

Sources:
- [Testing Bash Scripts with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide)
- [bats-core documentation](https://bats-core.readthedocs.io/)
- [Cross-Platform BATS Issues](https://blog.shukebeta.com/2025/09/02/git-bash-test-compatibility-a-deep-dive-into-cross-platform-bats-issues/)

---

## Minor Pitfalls

### Pitfall 10: Color Variable Scope Leak During Refactoring

**What goes wrong:** `logging.sh` exports color variables globally (`export RED GREEN YELLOW BLUE GRAY NC` on line 204). Moving `setup_colors()` to a shared location or calling it at a different time means color variables are set before terminal detection, or are empty when expected to have values.

**Why it matters:** `setup_colors()` is called at source-time (line 195). If logging.sh is sourced before the terminal is connected (e.g., in a subshell), colors are empty. If sourced after terminal is connected, they are set. Refactoring source order can flip this silently.

**Prevention:** Keep `setup_colors` call at the bottom of logging.sh. Do not move it to an init function that might be called at a different time.

**Confidence:** MEDIUM -- theoretical risk, not currently broken.

---

### Pitfall 11: README and Documentation Path Drift

**What goes wrong:** Renaming directories or files causes documentation (README.md, CONTRIBUTING.md, inline comments, ADRs) to reference non-existent paths. Users following documentation get lost.

**Prevention:** After ANY file move, run `grep -rn "old/path" *.md .planning/ docs/` and update all references. Include documentation updates in the same commit as the file move.

**Confidence:** HIGH -- ARCHITECTURE.md drift already identified in review.

---

### Pitfall 12: Windows DRY_RUN Parity Creates New Inconsistency

**What goes wrong:** Adding a `-DryRun` switch to `setup.ps1` that maps to `$env:DRY_RUN` could create a case sensitivity issue. PowerShell environment variables are case-insensitive on Windows but case-sensitive when read by WSL/bash from the same environment.

**Prevention:** Always use `$env:DRY_RUN` (uppercase) in PowerShell to match the Bash convention. Never introduce `$env:DryRun` (mixed case) even though PowerShell convention favors PascalCase.

**Confidence:** MEDIUM -- depends on whether WSL interop is in scope.

---

## Phase-Specific Warnings

| Change Type | Phase | Likely Pitfall | Severity | Mitigation |
|-------------|-------|---------------|----------|------------|
| Fix VERBOSE boolean | Phase 1 (Bug fixes) | Pitfall 1: truthiness trap | CRITICAL | Fix logging.sh checks to `== "true"`, add normalization bridge |
| Unify NONINTERACTIVE/UNATTENDED | Phase 1 (Bug fixes) | Pitfall 2: split-brain | CRITICAL | Bridge in config.sh, do NOT rename homebrew.sh's usage |
| Extract shared PS functions | Phase 2 (DRY) | Pitfall 4: scope isolation | CRITICAL | Import-Module in every consumer, test cross-process |
| Merge install/ + installers/ | Phase 2 (Consolidation) | Pitfall 5: 13+ broken paths | CRITICAL | git mv + update all refs atomically, test harness first |
| Add unit tests | Phase 3 (Quality) | Pitfall 9: system-dependent tests | MODERATE | Test functions not scripts, mock externals, bats-core |
| Fix exit codes | Phase 1 (Bug fixes) | Pitfall 3: trap cascade | CRITICAL | Keep exit 0 per ADR-001, only non-zero for hard prereqs |
| Refactor shared functions (Bash) | Phase 2 (DRY) | Pitfall 6: export -f breakage | MODERATE | Keep export -f with function, grep callers before removing aliases |
| Add DRY_RUN guard consistency | Phase 2 (Quality) | Pitfall 7: ordering regression | MODERATE | Comment pattern in every installer, test dry-run accuracy |
| Consolidate modules | Phase 2 (DRY) | Pitfall 8: source guard collision | MODERATE | Keep old guard variables as aliases |
| Update documentation | Phase 3 (Docs) | Pitfall 11: path drift | LOW | grep old paths in all .md files |

## Recommended Change Ordering

Based on dependency analysis and risk:

1. **VERBOSE fix first** (Pitfall 1) -- smallest change, biggest observable improvement, zero dependencies on other changes
2. **NONINTERACTIVE bridge second** (Pitfall 2) -- enables `-y` flag to actually work, changes only config.sh
3. **Directory merge third** (Pitfall 5) -- must happen before test improvements (otherwise test paths change twice)
4. **PowerShell DRY consolidation fourth** (Pitfall 4) -- isolated to Windows, does not affect Bash side
5. **Unit tests last** (Pitfall 9) -- tests should be written against the final directory structure and variable conventions
6. **Exit code changes: do not do** (Pitfall 3) -- ADR-001 is correct, the review recommendation to change exit codes is wrong for this architecture

## Sources

**Bash Boolean Handling:**
- [Best Practice to Represent Boolean Value in Shell Script](https://www.baeldung.com/linux/shell-script-boolean-type-variable) -- STRING vs INTEGER conventions
- [Mastering Boolean Values in Bash](https://www.greasyguide.com/linux/use-boolean-value-in-bash/) -- pitfalls of string comparison
- [How to Declare Bash Boolean Variable](https://kodekloud.com/blog/declare-bash-boolean-variable-in-shell-script/) -- consistency requirements

**PowerShell Scope and Modules:**
- [about_Scopes - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes?view=powershell-7.5) -- official scope documentation
- [$script: scope not propagated](https://github.com/PowerShell/PowerShell/issues/19039) -- known issue with & operator
- [Import-Module -Scope Local issues](https://github.com/PowerShell/PowerShell/issues/20114) -- nested script module removal
- [Module Scope in PowerShell](https://mikefrobbins.com/2017/06/08/what-is-this-module-scope-in-powershell-that-you-speak-of/) -- practical guide

**Shell Testing:**
- [Testing Bash Scripts with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide) -- practical guide
- [bats-core documentation](https://bats-core.readthedocs.io/) -- official docs
- [Cross-Platform BATS Issues](https://blog.shukebeta.com/2025/09/02/git-bash-test-compatibility-a-deep-dive-into-cross-platform-bats-issues/) -- Windows/macOS pitfalls

**Exit Codes and Traps:**
- [Exit a Bash Script: exit 0 and exit 1 Explained](https://codefather.tech/blog/exit-bash-script/) -- downstream impact
- [Trap Command and Cleaning Up](https://codesignal.com/learn/courses/bash-script-error-handling/lessons/trap-command-and-cleaning-up) -- trap behavior
- [Leveraging Exit Codes for Better Bash Scripts](https://thelinuxcode.com/bash-script-returns-different-return-codes-exit/) -- pipeline implications

**Directory Refactoring:**
- [Git Move Files: Practical Renames and History Preservation](https://thelinuxcode.com/git-move-files-practical-renames-refactors-and-history-preservation-in-2026/) -- safe git mv patterns

**Project-Specific:**
- ADR-001: Error Resilience (.planning/adrs/ADR-001-error-resilience.md) -- "always exit 0" rationale
- ADR-007: Idempotency Safety (.planning/adrs/ADR-007-idempotency-safety.md) -- three-layer guard ordering
- CONCERNS.md (.planning/codebase/CONCERNS.md) -- known tech debt catalog
- STATE.md (.planning/STATE.md) -- v3.0 review findings
