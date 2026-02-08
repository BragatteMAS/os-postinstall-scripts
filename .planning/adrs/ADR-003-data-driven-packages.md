# ADR-003: Data-Driven Package Architecture

**Status:** Accepted
**Date:** 2026-02-04
**Phases:** 02, 05, 06

## Context

The initial codebase had package lists hardcoded as Bash arrays inside installer scripts. Adding a package meant editing shell code, understanding array syntax, and risking merge conflicts. Different installers had different formats. There was no single place to see "what gets installed."

## Decision

Packages are defined in plain text files under `data/packages/`, one package per line:

- `#` lines are comments, blank lines are ignored
- 12 files total: `apt.txt`, `apt-post.txt`, `brew.txt`, `brew-cask.txt`, `cargo.txt`, `npm.txt`, `winget.txt`, `flatpak.txt`, `flatpak-post.txt`, `snap.txt`, `snap-post.txt`, `ai-tools.txt`
- `load_packages()` in `src/core/packages.sh` reads any file into a `PACKAGES` array with whitespace trimming and comment filtering
- Multi-method installers use prefix dispatch: `npm:package`, `curl:url`, `npx:package`, `uv:package` -- a `case` on `${entry%%:*}` routes to the correct install method
- Classic Snap confinement declared via `classic:package-name` prefix in data files

## Alternatives Considered

### Hardcoded Bash arrays in installer scripts
- **Pros:** No file I/O, everything in one place per installer
- **Cons:** Adding a package requires editing shell code. Non-developers cannot contribute. Merge conflicts on array edits. No separation between data and logic

### JSON or YAML configuration
- **Pros:** Structured, supports metadata (version, description, dependencies)
- **Cons:** Requires `jq` or `yq` as dependency. Overhead for what is fundamentally a list of names. Violates KISS. Bash has no native JSON parser

### Ansible playbooks / declarative config
- **Pros:** Industry standard for provisioning, handles idempotency natively
- **Cons:** Requires Python + Ansible installed (chicken-and-egg on fresh OS). Massive overhead for a dotfiles project. Violates project principle "open source > paid services, lightweight"

## Recommendation

Plain text is the simplest format that works. A contributor adds a package by appending one line to a text file -- no code knowledge required. The prefix dispatch pattern (`npm:`, `curl:`) extends the format for multi-method installers without breaking the one-per-line simplicity.

## Consequences

- **Positive:** Adding a package is a 1-line text edit. Non-developers can contribute. Data is greppable, diffable, countable (`wc -l`). Clear separation of data and logic. `load_packages()` is reused by all 12 installers.
- **Negative:** No metadata per package (version pinning, description, conditional install). Prefix syntax (`npm:`, `classic:`) is a convention, not enforced by a schema. Typos in package names are only caught at install time.
