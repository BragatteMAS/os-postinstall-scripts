# Project Research Summary

**Project:** OS Post-Install Scripts
**Domain:** Cross-platform system provisioning / dotfiles management
**Researched:** 2026-02-04
**Confidence:** HIGH

## Executive Summary

This project automates fresh machine setup across Linux, macOS, and Windows using native shell scripts (Bash + PowerShell). Research shows the "pure shell approach" is optimal for zero-dependency bootstrapping, where the goal is running scripts immediately on a fresh OS without installing anything first. This positions the project between simple symlink managers (GNU Stow) and complex configuration managers (chezmoi), with unique differentiators in AI/MCP integration and intelligent tool recommendations.

The recommended approach is **data-driven modularization**: separate code (`src/`) from data (`data/packages/*.yaml`) with platform-specific implementations unified by a thin abstraction layer. Current brownfield state shows significant code duplication across `scripts/` and `platforms/` directories, with Linux at 100% completion but macOS only 20% and Windows nearly non-existent. The primary architectural cleanup involves consolidating this duplicate code into a coherent module system following industry-standard dotfiles patterns (Holman-style topic organization).

**Critical risk:** Non-idempotent scripts that corrupt configurations on re-runs. The codebase has partial idempotency but lacks consistent patterns. Other major risks include cross-platform shell incompatibility (macOS ships Bash 3.2, project requires 4.0+) and destructive operations without backups. These must be addressed in Phase 1 through shared utilities that enforce safe patterns across all platform-specific code.

## Key Findings

### Recommended Stack

The research strongly validates the current approach: **native shell scripts over external tools**. For cross-platform post-install automation, Bash 4.0+ (Unix) and PowerShell 5.1+ (Windows) provide zero bootstrap overhead while leveraging built-in platform capabilities. This eliminates the dependency hell that plagues Python/Ansible approaches and the bootstrap paradox of tools like chezmoi (which require pre-installation).

**Core technologies:**
- **Bash 4.0+**: Unix scripting (Linux, macOS) — associative arrays and modern string handling justify dropping POSIX sh compatibility. macOS users must upgrade via provided script.
- **PowerShell 5.1+**: Windows scripting — native on Windows 10+, no installation needed.
- **Native package managers**: Homebrew (macOS), APT/DNF (Linux), winget (Windows) — de facto standards, excellent ecosystems.
- **ShellCheck + shfmt**: Static analysis and formatting — industry standard for shell quality (Microsoft, GitLab use these).

**Critical decision:** NO external configuration parsers (jq, yq). Shell arrays in `.sh` files + plain text are the only zero-dependency options. YAML for package lists is acceptable if parsed minimally or converted to shell arrays during setup.

**Development quality tools:** shellcheck (linting), shfmt (formatting), bats-core (testing). These are dev-time only, not runtime dependencies.

### Expected Features

Post-install scripts have clear **table stakes** that users expect. Missing any of these makes the product feel incomplete:

**Must have (table stakes):**
- Cross-platform detection (OS, distro, version) — users switch between systems
- Package manager integration (APT, Homebrew, winget) — core value proposition
- Idempotency (safe to run multiple times) — critical for trust and reliability
- Dotfiles symlink/copy management — the "dot" in dotfiles
- One-command setup (`./setup.sh`) — "just works" experience
- Progress feedback (colors, status) — users need to know what's happening
- Error handling (graceful failures) — no silent corruption

**Current gaps:** macOS only 20% complete vs Linux 100%, Windows nearly absent, inconsistent idempotency patterns across scripts.

**Should have (competitive differentiators):**
- **PRD/STORIES parser** — unique feature, detect project tech stack and recommend tools automatically
- **Modern CLI tools first** — bat, eza, fd, ripgrep, zoxide over legacy tools (already implemented)
- **AI/MCP integration** — pre-configured Claude, context7, etc. (already implemented, bleeding edge)
- Dry-run mode — preview changes before applying (builds trust)
- Backup before changes — automatic safety net (prevents data loss)
- Parallel execution — 40%+ speed improvement potential

**Defer (v2+):**
- Machine-specific templating (complexity overkill)
- Secrets encryption (use external tools like 1Password)
- Remote bootstrap via curl | bash (security risk, out of scope)

**Competitive position:** More capable than symlink managers (Stow, Dotbot), simpler than configuration managers (chezmoi, Nix), lighter than infrastructure automation (Ansible), with unique AI/MCP integration.

### Architecture Approach

Research recommends **separating code, data, and documentation** following industry patterns from successful dotfiles projects (Holman, YADM, chezmoi). The target structure follows platform-layered organization:

**Major components:**

1. **Core layer (`src/core/`)** — Platform-agnostic utilities (logging, platform detection, config parsing, error handling). These are leaf dependencies used by everything else.

2. **Platform layers (`src/unix/`, `src/linux/`, `src/macos/`, `src/windows/`)** — Specific implementations with thin abstraction layer. Platform router in bootstrap directs to appropriate implementation.

3. **Data layer (`data/packages/`, `data/profiles/`, `data/dotfiles/`)** — Declarative YAML package lists, installation profiles, configuration files. Logic and data are cleanly separated.

4. **Topic-centric dotfiles (`data/dotfiles/git/`, `data/dotfiles/zsh/`)** — Holman-style organization where files named `*.symlink` get symlinked to `$HOME`, `*.zsh` get auto-sourced, `install.sh` runs during bootstrap.

**Key patterns:**
- **Data-driven package lists**: YAML files declare packages, shell scripts install them (separation of concerns)
- **Platform abstraction**: Common `pkg_install()` interface, platform-specific implementations
- **Main function pattern**: Google Shell Style — wrap logic in `main()`, use `local` variables, single entry point
- **Graceful degradation**: Dotfiles work even when optional tools missing (check `command -v tool` before using)

**Anti-patterns to avoid:** Hardcoded package lists in scripts (current issue), duplicated platform detection, relative path gymnastics, scripts >100 lines without functions, platform-specific code in core.

### Critical Pitfalls

Research and codebase analysis reveal pitfalls that cause rewrites or major issues:

1. **Non-idempotent scripts** — Scripts that append to config files on every run create duplicate entries (PATH, aliases), slow shell startup, corrupt configs. **Prevention:** Check before appending with `grep -q` guards, use markers (`# BEGIN/END os-postinstall`), check if package already installed, backup before ANY modification. **When to address:** Phase 1 — establish idempotent patterns in shared utilities.

2. **Cross-platform shell incompatibility** — macOS ships Bash 3.2 (from 2006), project requires 4.0+ for associative arrays. GNU vs BSD tool differences (sed, xargs, readlink) cause silent failures. **Prevention:** Use `#!/usr/bin/env bash`, test on both platforms, abstract platform differences in wrapper functions, document Bash 4+ requirement with upgrade script. **When to address:** Phase 1 — create platform abstraction layer.

3. **Destructive operations without backup** — Overwriting user configs without asking or backing up causes data loss and trust destruction. **Prevention:** ALWAYS create timestamped backup before modifying (`file.backup-$(date +%Y%m%d-%H%M%S)`), prompt in interactive mode, implement `--restore` command. **When to address:** Phase 1 — backup utilities in shared library.

4. **Secrets in repository** — Dotfiles containing credentials (SSH configs, gitconfig tokens) end up committed. **Prevention:** `.example` files for templates, comprehensive `.gitignore`, pre-commit hooks (git-secrets, gitleaks), never store credentials directly. **When to address:** Phase 1 — security hardening.

5. **Code duplication across platforms** — Same logic in `scripts/install/` and `platforms/linux/install/` diverges over time. Fixes applied to one location but not others. **Prevention:** Extract shared logic to `src/core/`, keep platform-specific code minimal, regular deduplication audits. **When to address:** Phase 2 — primary goal of consolidation refactor.

**Moderate pitfalls:** Zsh performance issues (lazy-load version managers, cache completions), package manager lock handling (wait, don't force), hardcoded paths (use `$HOME`, detect Homebrew location), missing error handling (`set -euo pipefail`), incomplete feature parity across platforms.

## Implications for Roadmap

Based on research, the brownfield cleanup should follow dependency-driven phases:

### Phase 1: Core Infrastructure
**Rationale:** Foundation must be solid before building platform-specific code. Core utilities are leaf dependencies with no dependencies themselves but everything depends on them. Addressing critical pitfalls (idempotency, backups, error handling) here prevents propagating bad patterns to platform code.

**Delivers:**
- `src/core/logging.sh` — consistent output formatting, emoji handling
- `src/core/platform.sh` — OS/distro detection (replaces duplicated detection logic)
- `src/core/utils.sh` — idempotent file operations, backup utilities, error handling
- `src/core/config-loader.sh` — YAML parsing (if needed) or shell array sourcing

**Addresses features:**
- Error handling (table stakes)
- Progress feedback (table stakes)
- Cross-platform detection (table stakes)

**Avoids pitfalls:**
- Non-idempotent scripts (Pitfall 1) — utilities enforce safe patterns
- Destructive operations without backup (Pitfall 3) — backup utils required
- Missing error handling (Pitfall 8) — `set -euo pipefail` patterns
- Platform-specific code in core (Anti-pattern 5) — clear boundaries

**Research flag:** Standard patterns, well-documented — skip `/gsd:research-phase`

### Phase 2: Consolidation & Data Migration
**Rationale:** With core utilities established, consolidate duplicate code currently scattered across `scripts/` and `platforms/`. Migrate hardcoded package lists to YAML in `data/packages/`. This addresses the primary brownfield cleanup goal and sets foundation for platform parity work.

**Delivers:**
- Unified platform abstraction (`src/unix/packages.sh`, `src/linux/apt.sh`)
- Data-driven package lists (`data/packages/core.yaml`, `data/packages/rust-cli.yaml`)
- Deprecation of duplicate code in old locations
- Single bootstrap entry point (`src/core/bootstrap.sh`)

**Addresses features:**
- Package manager integration (table stakes) — unified, maintainable
- Minimal base option (table stakes) — profiles reference package files

**Avoids pitfalls:**
- Code duplication across platforms (Pitfall 9) — consolidation eliminates
- Hardcoded package lists (Anti-pattern 1) — migration to YAML
- Duplicated platform detection (Anti-pattern 2) — uses Phase 1 utilities

**Research flag:** Standard patterns — skip `/gsd:research-phase`

### Phase 3: Dotfiles Management
**Rationale:** With core and package installation solid, tackle dotfiles using Holman-style topic organization. This is independent of package installation and can be built after consolidation completes.

**Delivers:**
- Topic-centric dotfiles structure (`data/dotfiles/git/`, `data/dotfiles/zsh/`)
- Symlink manager (`src/unix/shell-setup.sh`)
- File extension conventions (`.symlink`, `.zsh`, `path.zsh`, `completion.zsh`)
- Graceful degradation (configs work without optional tools)

**Addresses features:**
- Dotfiles symlink/copy (table stakes)
- Git integration (table stakes)

**Avoids pitfalls:**
- Zsh performance (Pitfall 5) — lazy loading from start
- Hardcoded paths (Pitfall 7) — use variables

**Research flag:** Well-documented patterns (Holman) — skip `/gsd:research-phase`

### Phase 4: macOS Parity
**Rationale:** Linux implementation provides reference patterns. macOS shares Unix base but has platform-specific needs (Homebrew, system defaults, Bash upgrade). Current 20% → target 45%+ to match Linux.

**Delivers:**
- `src/macos/brew.sh` — Homebrew operations (NONINTERACTIVE mode)
- `src/macos/defaults.sh` — System preferences automation
- `src/macos/cask.sh` — GUI application installation
- Bash 4+ upgrade script (already exists, integrate)

**Addresses features:**
- Cross-platform detection (completing table stakes)
- Package manager integration for macOS

**Avoids pitfalls:**
- Cross-platform shell incompatibility (Pitfall 2) — test with Bash 3.2, provide upgrade
- Hardcoded paths (Pitfall 7) — detect Intel vs Apple Silicon Homebrew paths
- Incomplete feature parity (Pitfall 10) — target 45%

**Research flag:** Homebrew automation patterns well-documented — skip `/gsd:research-phase`

### Phase 5: Windows Foundation
**Rationale:** After Unix platforms mature, tackle Windows. Separate PowerShell scripts, not Bash-via-WSL shims. Current 0% → target 10% (basic winget functionality).

**Delivers:**
- `src/windows/winget.ps1` — WinGet package installation
- Windows entry point (`install.ps1`)
- Basic package list support

**Addresses features:**
- Cross-platform detection (completing for all 3 platforms)
- Package manager integration for Windows

**Avoids pitfalls:**
- PowerShell vs Bash differences (Phase-specific warning) — separate implementations
- Incomplete feature parity (Pitfall 10) — establish foundation

**Research flag:** WinGet is new, may need `/gsd:research-phase` for best practices

### Phase 6: Differentiators & Polish
**Rationale:** After core functionality solid across platforms, add unique features that set this project apart from competitors.

**Delivers:**
- Dry-run mode (`--dry-run` flag)
- PRD/STORIES parser (intelligent recommendations)
- Backup before changes (timestamped safety net)
- Parallel execution (performance optimization)

**Addresses features:**
- Dry-run mode (differentiator)
- PRD/STORIES parser (unique differentiator)
- Backup before changes (differentiator)
- Parallel execution (differentiator)

**Avoids pitfalls:**
- Secrets in repository (Pitfall 4) — parser must not recommend committing secrets

**Research flag:** PRD/STORIES parser is novel — consider `/gsd:research-phase` for implementation patterns

### Phase 7: Testing & Documentation
**Rationale:** Final phase ensures quality and maintainability. CI matrix across platforms, bats tests for core utilities, comprehensive documentation.

**Delivers:**
- GitHub Actions matrix (Ubuntu, macOS, Windows)
- bats-core tests for core utilities
- Idempotency verification (run twice, compare state)
- Usage, contribution, troubleshooting docs

**Addresses features:**
- Documentation (table stakes)

**Avoids pitfalls:**
- Cross-platform CI (Phase-specific warning) — matrix testing catches incompatibilities
- Idempotency verification (Phase-specific warning) — automated testing

**Research flag:** Testing strategies well-documented — skip `/gsd:research-phase`

### Phase Ordering Rationale

**Dependency-driven:** Phase 1 (Core) has no dependencies but everything depends on it. Phase 2 (Consolidation) depends on Phase 1 utilities. Phases 3-5 (Dotfiles, macOS, Windows) can partially parallelize as they're platform-specific. Phase 6 (Differentiators) requires stable foundation. Phase 7 (Testing) validates everything.

**Risk-mitigation driven:** Critical pitfalls (non-idempotency, destructive operations, cross-platform incompatibility) addressed in Phase 1-2 before they propagate to platform implementations. This prevents rework.

**Architecture-driven:** Separates code (Phase 1-2), data (Phase 2), and platform implementations (Phase 3-5) following research-recommended patterns. Topic-centric dotfiles (Phase 3) implemented as separate system.

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 5 (Windows):** WinGet is relatively new (2020), best practices still emerging. Consider `/gsd:research-phase winget` for automation patterns, idempotency handling.
- **Phase 6 (PRD/STORIES parser):** Novel feature, no existing implementations found. Consider `/gsd:research-phase prd-parser` for parsing strategies, tech stack detection algorithms.

**Phases with standard patterns (skip research):**
- **Phase 1 (Core):** Shell scripting patterns well-documented (Google Style Guide, shellcheck)
- **Phase 2 (Consolidation):** Standard refactoring, data-driven architecture documented
- **Phase 3 (Dotfiles):** Holman-style organization extensively documented
- **Phase 4 (macOS):** Homebrew automation well-documented, many examples
- **Phase 7 (Testing):** bats-core and GitHub Actions matrix patterns well-established

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official documentation verified (Homebrew, shellcheck, winget), project already using recommended stack |
| Features | MEDIUM | Based on competitive analysis (chezmoi, YADM) and community discussions, not direct user research |
| Architecture | HIGH | Multiple authoritative sources (Holman, Google Shell Style, Arch Wiki), patterns proven in production dotfiles |
| Pitfalls | HIGH | Combination of documented issues (Microsoft, Apple dev docs) and codebase analysis revealing current problems |

**Overall confidence:** HIGH

Research methodology combined official documentation (Bash, Homebrew, PowerShell), authoritative guides (Google Shell Style, Microsoft Engineering Playbook), established dotfiles projects (Holman, YADM, chezmoi), and direct codebase analysis. Cross-referencing multiple sources for each recommendation increases confidence.

### Gaps to Address

**Windows implementation details:** Research covered WinGet basics but lacks depth on enterprise scenarios, silent installation patterns, and handling Windows-specific quirks (UAC, path separators, PowerShell execution policies). Plan for discovery during Phase 5 implementation.

**PRD/STORIES parser specifics:** Research validated the concept but didn't find existing implementations. Parsing strategy (regex vs AST), technology detection heuristics, and recommendation engine design need exploration during Phase 6 planning. Consider spike story.

**Performance optimization:** Research identified that parallel execution could yield 40%+ speedup but didn't detail implementation strategies for shell scripts (background jobs, wait patterns, error aggregation). May need deeper research during Phase 6.

**Secrets management:** Research recommended against building it in, but didn't fully explore how to guide users toward solutions (1Password CLI, git-crypt, etc.). Documentation phase should research recommendations.

## Sources

### PRIMARY (HIGH confidence)

**Official Documentation:**
- [Homebrew Installation](https://docs.brew.sh/Installation) — NONINTERACTIVE mode for automation
- [Microsoft WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/) — Official winget automation guide
- [ShellCheck](https://www.shellcheck.net/) — Static analysis documentation
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) — Main function pattern, best practices

**Authoritative Guides:**
- [Microsoft Engineering Playbook - Bash Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/bash/) — shellcheck/shfmt CI integration
- [GitLab Shell Scripting Standards](https://docs.gitlab.com/development/shell_scripting_guide/) — Enterprise shell guidelines
- [Arch Wiki - Dotfiles](https://wiki.archlinux.org/title/Dotfiles) — Comprehensive dotfiles management patterns

### SECONDARY (MEDIUM confidence)

**Established Projects:**
- [Holman Dotfiles](https://github.com/holman/dotfiles) — Topic-centric organization pattern
- [chezmoi Comparison Table](https://www.chezmoi.io/comparison-table/) — Feature comparison across tools
- [chezmoi Why Use](https://www.chezmoi.io/why-use-chezmoi/) — When configuration managers make sense
- [YADM](https://yadm.io/) — Alternative architecture approach

**Community Consensus:**
- [dotfiles.github.io](https://dotfiles.github.io/) — Curated dotfiles resources
- [Hacker News dotfiles discussion](https://news.ycombinator.com/item?id=41453264) — Community perspectives
- [Hacker News YADM vs chezmoi](https://news.ycombinator.com/item?id=39975247) — Tool comparison discussion

### TERTIARY (LOW confidence)

**Individual Implementations:**
- [Daniel Schmidt chezmoi setup](https://danielmschmidt.de/posts/2024-07-28-dev-env-setup-with-chezmoi/) — Personal setup patterns
- [Medium dotfiles secrets](https://medium.com/@htoopyaelwin/organizing-your-dotfiles-managing-secrets-8fd33f06f9bf) — Secrets handling approaches
- [Modular Bash Architecture Guide](https://medium.com/mkdir-awesome/the-ultimate-guide-to-modularizing-bash-script-code-f4a4d53000c2) — Modularization patterns

**Platform-Specific:**
- [Differences Between MacOS and Linux Scripting](https://dev.to/aghost7/differences-between-macos-and-linux-scripting-74d) — Portability issues
- [Apple Shell Scripting Guide](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/PortingScriptstoMacOSX/PortingScriptstoMacOSX.html) — macOS-specific considerations

---
*Research completed: 2026-02-04*
*Ready for roadmap: yes*
