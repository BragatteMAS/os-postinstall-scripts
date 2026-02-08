# Architecture

**Analysis Date:** 2026-02-08

## Pattern Overview

**Overall:** Layered Bash module system with data-driven package management and platform-specific orchestrators.

**Key Characteristics:**
- Single entry point (`setup.sh`) detects OS and delegates to platform orchestrators
- Data-driven: package lists in `data/packages/*.txt`, loaded by `src/core/packages.sh`
- Profile composition: `data/packages/profiles/*.txt` define which package lists to include
- Core modules in `src/core/` provide cross-cutting utilities (logging, errors, idempotency)
- Platform isolation in `src/platforms/<os>/`

## Layers

**Entry/CLI:**
- Location: `setup.sh`, `config.sh`
- Contains: CLI flag parsing (--dry-run, --verbose, --profile), platform dispatch
- Depends on: Core modules

**Core Modules:**
- Location: `src/core/`
- Contains: platform.sh, logging.sh, errors.sh, idempotent.sh, packages.sh, progress.sh, dotfiles.sh
- Depends on: Nothing (foundational layer)
- Used by: All other layers

**Platform Orchestrators:**
- Location: `src/platforms/<os>/main.sh`
- Contains: OS-specific menu/flow, delegates to install scripts
- Depends on: Core modules, data files

**Package Installers:**
- Location: `src/platforms/<os>/install/` (OS-specific) + `src/install/` (cross-platform)
- Contains: Package manager handlers that load from data files
- Depends on: Core modules (packages.sh, logging.sh)

**Data Layer:**
- Location: `data/packages/`, `data/dotfiles/`
- Contains: Package lists (txt), dotfiles (shell configs, git config, starship)
- Depends on: Nothing (pure data)

## Data Flow

**Installation Flow:**

1. User runs `./setup.sh [--profile developer] [--dry-run]`
2. `setup.sh` sources `config.sh` and `src/core/platform.sh`
3. Platform detected via `detect_os()` → delegates to `src/platforms/<os>/main.sh`
4. Orchestrator sources core modules and calls install scripts
5. Install scripts call `load_packages()` from `src/core/packages.sh`
6. `load_packages()` reads `data/packages/<manager>.txt` → passes to package manager
7. Progress tracked via `src/core/progress.sh` step counter
8. Failures tracked via `src/core/errors.sh` with cleanup traps

**Profile Resolution:**

1. Profile file `data/packages/profiles/developer.txt` lists package files to include
2. Each listed file (e.g., `apt`, `cargo`) maps to `data/packages/<name>.txt`
3. Platform orchestrator iterates profile entries and calls appropriate installers

## Entry Points

**Primary:** `setup.sh` - Bash entry with CLI flags
**Windows:** `setup.ps1` - PowerShell entry
**Direct:** `src/platforms/<os>/main.sh` - Platform-specific entry
**Tools:** `src/install/*.sh` - Individual tool installers (can run standalone)

## Error Handling

**Strategy:** Fail-fast with tracking; continue on non-critical failures.

**Patterns:**
- `set -euo pipefail` at top of every script
- `src/core/errors.sh`: trap-based cleanup, failure log file, summary at end
- `src/core/idempotent.sh`: skip already-installed packages
- `DRY_RUN` mode: preview all operations without execution

## Cross-Cutting Concerns

**Logging:** `src/core/logging.sh` - color auto-detection, log_info/warn/error/success
**Progress:** `src/core/progress.sh` - step N/M counter with DRY_RUN banner
**Idempotency:** `src/core/idempotent.sh` - is_installed(), needs_update() guards

---

*Architecture analysis: 2026-02-08*
