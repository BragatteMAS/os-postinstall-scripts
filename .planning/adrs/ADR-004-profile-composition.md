# ADR-004: Profile Composition Architecture

**Status:** Accepted
**Date:** 2026-02-05
**Phases:** 02, 07

## Context

Users need different installation scopes: a minimal setup for servers, a developer setup for workstations, a full setup for personal machines. The naive approach (if-else chains per profile inside each installer) creates tight coupling between profile logic and install logic, making both harder to modify.

## Decision

Profiles are plain text files that list **package file names**, not individual packages:

- `data/packages/profiles/minimal.txt` lists `apt.txt`, `brew.txt`, `winget.txt`
- `data/packages/profiles/developer.txt` adds `cargo.txt`, `npm.txt`, `ai-tools.txt`, `flatpak.txt`, `snap.txt`, `brew-cask.txt`, `apt-post.txt`
- `data/packages/profiles/full.txt` adds `flatpak-post.txt`, `snap-post.txt`
- Platform orchestrators read the profile, then dispatch each file name to the appropriate installer via `case` statement, skipping non-platform files (Linux skips `brew.txt`, macOS skips `apt.txt`)
- `count_platform_steps()` pre-counts steps from the profile for progress display (`[Step N/M]`)

## Alternatives Considered

### Per-platform profile files (minimal-linux.txt, minimal-macos.txt)
- **Pros:** No filtering needed, each file is exactly what runs
- **Cons:** Triples the number of profile files (3 profiles x 3 platforms = 9). Adding a cross-platform package file requires editing 3+ profiles. Violates DRY

### Single profile file listing individual packages with platform tags
- **Pros:** One file per tier, maximum flexibility
- **Cons:** Mixes data formats (package names + platform metadata). Requires a parser for tags. Breaks the simplicity of `load_packages()` which expects plain package names

### Conditional logic inside installers (`if [[ "$PROFILE" == "full" ]]`)
- **Pros:** No profile files needed, logic co-located with install code
- **Cons:** Every installer must know about profiles. Adding a new profile means editing every installer. Tight coupling between profile and install concerns

## Recommendation

Composition via file lists achieves maximum decoupling. The profile says WHAT to install (file names). The orchestrator says WHERE to dispatch (platform filtering). The installer says HOW to install (package manager commands). Each concern changes independently.

## Consequences

- **Positive:** Adding a new profile is creating one text file. Adding a new package type is creating one .txt file and one installer. Platform orchestrators are thin dispatchers, not decision trees. Progress counting is accurate because it mirrors the dispatch logic.
- **Negative:** The indirection (profile -> file name -> packages) is one layer of abstraction that must be understood. A typo in a profile file (e.g., `atp.txt`) silently skips a package group. No validation that listed files exist.
