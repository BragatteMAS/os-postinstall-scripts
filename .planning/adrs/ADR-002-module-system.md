# ADR-002: Module System with Source Guards

**Status:** Accepted
**Date:** 2026-02-04
**Phases:** 01, 04, 05

## Context

The project has 8 core modules, 12+ installer scripts, and 3 platform orchestrators that source each other in complex dependency chains. Bash has no native module system. Without protection, a module sourced twice redefines readonly variables (crashing the script) and duplicates function definitions. Additionally, functions defined in a parent script are not available in child processes spawned via `bash script.sh`.

## Decision

A custom module system built on three patterns:

1. **Source guard** -- every module starts with:
   ```bash
   [[ -n "${_MODULE_NAME_SOURCED:-}" ]] && return 0
   readonly _MODULE_NAME_SOURCED=1
   ```

2. **Function exports** -- functions needed by child processes use `export -f function_name`

3. **Naming conventions:**
   - `UPPER_CASE` for constants and globals
   - `snake_case` for public functions
   - `_underscore_prefix` for private helpers
   - `_MODULE_NAME_SOURCED` for source guard variables

4. **Platform variable isolation** -- platform orchestrators use `LINUX_DIR` / `MACOS_DIR` instead of `SCRIPT_DIR` to avoid readonly conflicts when `packages.sh` (which also defines `SCRIPT_DIR`) is sourced

## Alternatives Considered

### Single monolithic script
- **Pros:** No sourcing issues, simple execution model
- **Cons:** 3000+ lines in one file. Untestable. Impossible to share modules across platforms. Violates DRY (Linux and macOS duplicate logging, error handling, etc.)

### Subshells for isolation (`(source module.sh)`)
- **Pros:** Complete variable isolation, no conflicts
- **Cons:** Cannot share state back to parent. Functions not available after subshell exits. Would require IPC (files, pipes) for every shared value, adding massive complexity

### Bash 4.4+ `declare -g` / nameref
- **Pros:** Cleaner scoping mechanisms
- **Cons:** macOS ships Bash 3.2. Even with `brew install bash`, requiring 4.4+ narrows compatibility unnecessarily for a module pattern that works on 3.2+

## Recommendation

The source guard pattern is a proven Bash idiom (used by `/etc/profile.d/` scripts, shell plugin systems). It costs 2 lines per module and eliminates an entire class of bugs. Combined with `export -f` and naming conventions, it provides a sufficient module system without external dependencies.

## Consequences

- **Positive:** Modules can be sourced in any order without fear of duplication. Child processes have access to exported functions. Clear naming makes ownership obvious. Works on Bash 3.2+ (macOS compatible).
- **Negative:** Every new module must remember the 2-line guard. `export -f` pollutes the environment (mitigated by `_prefix` for internals). `LINUX_DIR`/`MACOS_DIR` workaround is non-obvious to newcomers.
