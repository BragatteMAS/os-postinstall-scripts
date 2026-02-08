# ADR-006: Cross-Platform Dispatch Strategy

**Status:** Accepted
**Date:** 2026-02-05
**Phases:** 01, 04, 06

## Context

The project targets Linux (Debian-based), macOS (Intel + Apple Silicon), and Windows 10/11. These platforms have fundamentally different shells (Bash vs PowerShell), package managers (APT/Snap/Flatpak vs Homebrew vs WinGet), and filesystem conventions. A strategy is needed to share what can be shared while respecting platform differences.

## Decision

Single entry point with platform dispatch:

- `setup.sh` (Bash) is the entry point for Linux and macOS. Detects OS via `uname -s`, dispatches to `src/platforms/{linux,macos}/main.sh`
- `setup.ps1` (PowerShell) is a separate entry point for Windows, dispatching to `src/platforms/windows/main.ps1`
- Shared logic lives in `src/core/` (8 Bash modules) -- used by Linux and macOS but not Windows
- Windows has its own core modules (`src/platforms/windows/core/`) in PowerShell (.psm1): `logging.psm1`, `errors.psm1`, `packages.psm1`
- Cross-platform tool installers (`src/install/`) are Bash scripts used by both Linux and macOS
- Architecture detection: `uname -m` differentiates `arm64` (Apple Silicon, `/opt/homebrew`) from `x86_64` (Intel, `/usr/local`)
- Profile files are platform-agnostic; orchestrators filter by relevance at dispatch time

## Alternatives Considered

### Separate repositories per platform
- **Pros:** Complete isolation, no cross-platform complexity
- **Cons:** Duplicates shared logic (profiles, dotfiles, package lists). Three repos to maintain. User must find the right repo. Violates DRY and SSoT

### Bash everywhere (WSL for Windows)
- **Pros:** One language, one codebase, shared modules
- **Cons:** Requires WSL installed on Windows (chicken-and-egg). WinGet is a native Windows tool, not accessible from WSL by default. Forces users into WSL when they may want native Windows tooling. Not all Windows users want or can install WSL

### Ansible / Chef / Puppet
- **Pros:** Built for cross-platform provisioning, declarative, idempotent by design
- **Cons:** Requires Python/Ruby installed on fresh OS (chicken-and-egg). Massive dependency for a dotfiles project. Steep learning curve for contributors. Violates "lightweight and performant" principle

### Single polyglot script with platform detection
- **Pros:** One file to rule them all
- **Cons:** Bash and PowerShell are fundamentally different languages. Embedding both in one file is not possible. A wrapper script that calls the right one is effectively what `setup.sh` already does

## Recommendation

The dispatch pattern mirrors how operating systems work: a thin entry point routes to platform-specific handlers. Bash modules are shared between Linux and macOS (95% overlap). Windows gets its own PowerShell implementation following the same patterns (profiles, idempotency, error tracking) but in its native language.

## Consequences

- **Positive:** Each platform uses its native language and tools. Shared logic (profiles, dotfiles, package lists in `data/`) is truly shared. Contributors work in familiar territory. Architecture detection handles Intel/ARM transparently.
- **Negative:** Windows core modules duplicate Bash core module patterns in PowerShell (logging, errors, packages). Changes to shared patterns must be applied in two languages. Windows feature parity lags behind Linux/macOS (fewer installers).
