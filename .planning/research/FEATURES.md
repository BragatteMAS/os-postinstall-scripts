# Feature Landscape

**Domain:** Post-install scripts / dotfiles management
**Researched:** 2026-02-04
**Confidence:** MEDIUM (WebSearch + official docs cross-referenced)

## Executive Summary

Post-install scripts and dotfiles managers solve the "fresh machine" problem: getting a new system to a productive state quickly and reproducibly. The ecosystem spans from simple symlink managers (GNU Stow) to full declarative systems (Nix/home-manager).

**Key insight:** Users want minimal cognitive overhead. They do not want to learn a complex system just to set up their machine. The winning approach is "sensible defaults + easy customization."

---

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| **Cross-platform detection** | Users switch between Mac/Linux/Windows | Low | Implemented | Must auto-detect OS, distro, version |
| **Package manager integration** | Core value prop - install tools | Medium | Partial | APT strong, Homebrew weak, winget minimal |
| **Idempotency** | Scripts must be safe to run multiple times | Medium | Partial | Some scripts lack proper checks |
| **Dotfiles symlink/copy** | The "dot" in dotfiles | Low | Implemented | zshrc, gitconfig managed |
| **Git integration** | Version control for configs | Low | Implicit | Not managed as first-class feature |
| **One-command setup** | "Just works" experience | Low | Implemented | `./setup.sh` exists |
| **Progress feedback** | Users need to know what's happening | Low | Implemented | Colors, banners, status messages |
| **Error handling** | Graceful failures, not silent corruption | Medium | Partial | `set -euo pipefail` used but inconsistent |
| **Documentation** | How to use, customize, contribute | Low | Good | Extensive docs in `/docs/` |
| **Minimal base option** | Not everyone wants everything | Low | Planned | PRD mentions deprecating heavy profiles |

### Table Stakes Analysis

**Current gaps:**
1. **macOS parity** - Only ~20% implemented vs Linux 100%
2. **Windows support** - Nearly non-existent (~0%)
3. **Consistent idempotency** - Some scripts lack proper "already installed" checks

**Sources:**
- [chezmoi comparison table](https://www.chezmoi.io/comparison-table/)
- [dotfiles.github.io utilities](https://dotfiles.github.io/utilities/)
- [Arch Wiki dotfiles](https://wiki.archlinux.org/title/Dotfiles)

---

## Differentiators

Features that set product apart. Not expected, but valued when present.

| Feature | Value Proposition | Complexity | Priority | Notes |
|---------|-------------------|------------|----------|-------|
| **Intelligent recommendations** | PRD/STORIES parser suggests tools | High | High | Unique differentiator - detect project needs |
| **Modern CLI tools first** | bat, eza, fd, ripgrep, zoxide | Medium | High | Already implemented - major value add |
| **AI/MCP integration** | Pre-configured Claude, context7, etc. | Medium | High | Already implemented - bleeding edge |
| **Profile deprecation → recommendations** | Replace rigid profiles with smart suggestions | Medium | High | Planned - reduces cognitive overhead |
| **Parallel execution** | Faster setup through concurrency | High | Medium | Not implemented - could cut time 40%+ |
| **Dry-run mode** | Preview changes before applying | Medium | Medium | Not implemented - builds trust |
| **Diff preview** | Show exactly what will change | Medium | Medium | chezmoi has this - builds confidence |
| **Backup before changes** | Automatic safety net | Low | Medium | Not implemented - prevents disasters |
| **Rollback capability** | Undo changes if something breaks | High | Low | Git provides partial solution |
| **Machine-specific templates** | Same dotfile, different values per machine | High | Low | chezmoi/yadm strength - may be overkill |
| **Secrets encryption** | Store sensitive values safely | High | Low | chezmoi integrates 1Password - complex |
| **Remote bootstrap** | `curl \| bash` installation | Low | Low | Explicitly out of scope (security) |

### Differentiator Analysis

**High-value, unique differentiators:**
1. **PRD/STORIES parser** - No other tool does this. Detects project tech stack and recommends tools.
2. **AI/MCP integration** - Bleeding edge. Pre-configured agents for development.
3. **Modern CLI-first philosophy** - Rust tools over legacy (bat > cat, eza > ls).

**Common differentiators we could add:**
1. **Dry-run mode** - Low effort, high trust-building
2. **Backup before changes** - Simple tarball of files about to be modified
3. **Parallel execution** - Significant speed improvement

**Sources:**
- [chezmoi why use](https://www.chezmoi.io/why-use-chezmoi/)
- [YADM features](https://yadm.io/)
- [Hacker News dotfiles discussion](https://news.ycombinator.com/item?id=41453264)

---

## Anti-Features

Features to explicitly NOT build. Common mistakes in this domain.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **curl \| bash as primary flow** | Security risk - code runs before inspection | Use `git clone` - user sees code first |
| **Complex profile taxonomy** | Users don't fit boxes; causes analysis paralysis | Minimal base + smart recommendations |
| **GUI/web interface** | Adds complexity, fragile, scope creep | CLI only - composable, scriptable |
| **Cloud sync built-in** | Scope creep, security concerns | Git is the sync mechanism |
| **Exotic distro support** | Maintenance burden > value | Focus on Ubuntu/Debian, macOS |
| **Automated testing on install** | Can interfere with system operations | Manual, on-demand tests only |
| **JSON/TOML for config data** | Requires jq/external parsers | Shell arrays + .txt files (zero deps) |
| **Heavy templating engine** | Complexity for edge cases | Simple variable substitution if needed |
| **Secrets management built-in** | Complex, security-critical, out of scope | Recommend external tools (1Password, etc.) |
| **Version management built-in** | nvm/pyenv/rbenv exist and work well | Install and configure them, don't replace |
| **Containerization (Docker setup)** | Different problem domain | Focus on bare metal provisioning |

### Anti-Feature Rationale

**From project principles (CLAUDE.md):**
- **KISS**: Complexity is the enemy
- **Zero dependencies**: Must run on fresh machine
- **Open source > paid services**: Don't couple to commercial tools

**From PRD explicit out-of-scope:**
- Rust/Zig as main language (shell is right tool)
- curl | bash as primary (security)
- JSON/TOML (needs parsers)
- Exotic distros (maintenance burden)
- GUI/web interface

**Sources:**
- Project PRD.md and PROJECT.md
- [Bootstrap best practices](https://dotfiles.github.io/bootstrap/)
- [Nix vs Ansible discussion](https://discourse.nixos.org/t/nixos-vs-ansible/16757)

---

## Feature Dependencies

```
Prerequisite Features:
----------------------
Cross-platform detection
        |
        v
Package manager integration
        |
        +---> macOS (Homebrew)
        +---> Linux (APT/DNF)
        +---> Windows (winget)
        |
        v
Dotfiles management
        |
        v
Tool installation
        |
        +---> Modern CLI tools (bat, eza, fd, rg, zoxide)
        +---> Dev environments (Python, Node, Rust)
        +---> AI/MCP tooling (Claude, context7)

Optional Enhancement Chain:
---------------------------
Dry-run mode --> Diff preview --> Backup --> Rollback
                                    |
                                    v
                          Confidence in running scripts

Intelligence Chain:
-------------------
PRD/STORIES parser --> Technology detection --> Smart recommendations
```

---

## MVP Recommendation

For MVP (brownfield cleanup), prioritize:

### Must Have (Phase 1)
1. **Restructure codebase** - `src/` + `data/` + `docs/` (consolidation)
2. **Consistent idempotency** - All scripts safe to rerun
3. **macOS parity** - Bring to 45% (equal with Linux)
4. **Cross-platform package lists** - Data-driven, not code-driven
5. **Minimal base installer** - Just the essentials, fast

### Should Have (Phase 2)
1. **Dry-run mode** - Preview what will happen
2. **Backup before changes** - Simple tarball safety net
3. **PRD/STORIES parser** - Unique differentiator
4. **Basic Windows support** - 10% via winget

### Could Have (Phase 3)
1. **Parallel execution** - Speed optimization
2. **Diff preview** - Show exact changes
3. **Intelligent recommendations engine** - AI-assisted suggestions

### Won't Have (Explicit)
- curl | bash bootstrap
- GUI interface
- Built-in secrets management
- Heavy templating
- Cloud sync
- Exotic distro support

---

## Competitive Landscape Summary

| Tool | Approach | Strengths | Weaknesses | Our Differentiation |
|------|----------|-----------|------------|---------------------|
| **chezmoi** | Single binary, templates | Feature-rich, cross-platform, secrets | Learning curve, file renaming | Simpler, no renaming needed |
| **YADM** | Git wrapper | Familiar to git users, lightweight | Limited features vs chezmoi | More features than yadm, simpler than chezmoi |
| **GNU Stow** | Symlink farm | Dead simple, reversible | No templating, no encryption | We do more (packages, tools) |
| **Dotbot** | YAML config | Declarative, extensible | Just links files | We install packages and tools |
| **Nix/home-manager** | Declarative | Reproducible, powerful | Steep learning curve | Much simpler entry |
| **Ansible** | Automation | Industrial strength | Overkill for personal | Right-sized for individuals |

**Our position:** More than a symlink manager (Stow), simpler than a configuration manager (chezmoi), lighter than infrastructure automation (Ansible), with unique AI/MCP integration.

---

## Sources

### HIGH Confidence (Official docs)
- [chezmoi.io comparison table](https://www.chezmoi.io/comparison-table/)
- [chezmoi.io why use](https://www.chezmoi.io/why-use-chezmoi/)
- [YADM official site](https://yadm.io/)
- [dotfiles.github.io](https://dotfiles.github.io/)

### MEDIUM Confidence (Community consensus)
- [Hacker News dotfiles discussion](https://news.ycombinator.com/item?id=41453264)
- [Hacker News YADM vs chezmoi](https://news.ycombinator.com/item?id=39975247)
- [NixOS vs Ansible discussion](https://discourse.nixos.org/t/nixos-vs-ansible/16757)
- [BigGo dotfiles comparison](https://biggo.com/news/202412191324_dotfile-management-tools-comparison)

### LOW Confidence (Individual articles)
- [Daniel Schmidt chezmoi setup](https://danielmschmidt.de/posts/2024-07-28-dev-env-setup-with-chezmoi/)
- [Medium dotfiles secrets](https://medium.com/@htoopyaelwin/organizing-your-dotfiles-managing-secrets-8fd33f06f9bf)
- [Security Boulevard env vars](https://securityboulevard.com/2025/12/are-environment-variables-still-safe-for-secrets-in-2026/)

---

## Recommendations for Roadmap

### Phase 1: Foundation (Cleanup)
- Restructure to `src/` + `data/` + `docs/`
- Consolidate duplicate code
- Ensure all scripts are idempotent
- Bring macOS to 45% parity

### Phase 2: Core Features
- Implement dry-run mode (trust building)
- Add backup before changes (safety net)
- Build PRD/STORIES parser (unique value)
- Basic Windows winget support

### Phase 3: Polish
- Parallel execution (performance)
- Intelligent recommendations (AI differentiation)
- Diff preview (transparency)

### Explicit Non-Goals
- Do not add templating complexity
- Do not add secrets management
- Do not build GUI
- Do not support curl | bash

---

*Research completed: 2026-02-04*
*Confidence: MEDIUM - Multiple sources cross-referenced, some gaps in verification*
