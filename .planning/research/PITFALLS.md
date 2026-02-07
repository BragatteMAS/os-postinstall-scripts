# Domain Pitfalls

**Domain:** Post-install scripts / Dotfiles management
**Researched:** 2026-02-04
**Confidence:** HIGH (combination of domain research + codebase analysis)

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Non-Idempotent Scripts

**What goes wrong:** Scripts that assume a clean slate fail on re-runs. Duplicate entries accumulate in config files (e.g., duplicate PATH exports, aliases). Files get overwritten without backup.

**Why it happens:** Developers test on fresh systems, not systems where the script ran before. Logic like `echo 'export PATH...' >> ~/.zshrc` appends every time.

**Consequences:**
- Shell startup becomes slow with duplicate entries
- Config files become corrupted/unmaintainable
- Users lose custom configurations on re-run
- Support burden increases ("why is my PATH 50 entries long?")

**Prevention:**
- Check before appending: `grep -q 'pattern' file || echo 'line' >> file`
- Use markers: `# BEGIN os-postinstall` / `# END os-postinstall` and replace between them
- Check if package already installed before installing
- Make backup before modifying ANY user file

**Detection:**
- Test script twice in a row on same system
- Check if config files grow on each run
- Look for `>>` without corresponding guard checks

**Phase to address:** Phase 1 (Core Infrastructure) - establish idempotent patterns in shared utilities

---

### Pitfall 2: Cross-Platform Shell Incompatibility

**What goes wrong:** Scripts using Bash 4+ features fail on macOS (ships with Bash 3.2 from 2006). GNU vs BSD tool differences cause silent failures. Zsh vs Bash assumptions break scripts.

**Why it happens:** macOS default bash is ancient due to GPL v3 licensing. GNU and BSD implementations of common tools (sed, xargs, readlink) behave differently. Linux defaulting to Bash while macOS defaults to Zsh creates confusion.

**Consequences:**
- Scripts that work on Linux fail silently or crash on macOS
- Associative arrays (`declare -A`) don't work on macOS default bash
- `readlink -f` fails on macOS (BSD doesn't support `-f`)
- `sed -i` requires different syntax (GNU: `sed -i ''`, BSD: `sed -i ''`)
- `xargs` with empty input runs command on macOS but not on GNU

**Prevention:**
- Use `#!/usr/bin/env bash` shebang for portability
- Avoid bashisms for critical paths, or detect and adapt
- Test on both platforms in CI
- Document Bash 4+ requirement and provide upgrade path (e.g., `scripts/setup/upgrade-bash.sh`)
- Abstract platform differences: create wrapper functions for `sed -i`, `readlink`, etc.

**Detection:**
- Run `shellcheck` with POSIX compliance
- Test on macOS with default `/bin/bash` (3.2)
- Look for `declare -A`, `${var,,}`, `${!array[@]}`, `[[ ]]` vs `[ ]`

**Phase to address:** Phase 1 (Core Infrastructure) - create platform abstraction layer in `src/core/`

---

### Pitfall 3: Secrets and Sensitive Data in Repository

**What goes wrong:** API keys, tokens, or personal paths get committed. Dotfiles containing credentials (SSH configs, gitconfig with tokens) end up public.

**Why it happens:** Git tracks files that users intended to be local-only. Template files get filled with real credentials. `.gitignore` misses sensitive patterns.

**Consequences:**
- Security breach (credentials exposed)
- Credentials scraped by bots within seconds
- Compliance violations
- Reputation damage

**Prevention:**
- Use `.example` files for templates (e.g., `.env.example`)
- Add comprehensive `.gitignore` patterns for secrets
- Use `git-secrets` or `gitleaks` pre-commit hooks
- Never store credentials directly; use environment variables or secret managers
- Audit with `git log --all --full-history -- "**/secret*" "**/.env" "**/credentials*"`

**Detection:**
- Pre-commit hooks that scan for patterns (API keys, tokens)
- Regular audits of committed files
- Look for hardcoded paths, usernames, or emails

**Phase to address:** Phase 1 (Security) - add `.gitignore` patterns and pre-commit hook

---

### Pitfall 4: Destructive Operations Without Backup

**What goes wrong:** Script overwrites user's customized configs without asking or backing up. Symlink creation fails because target file exists. User loses hours/days of customization.

**Why it happens:** Assuming fresh install. Using `cp` instead of checking first. Not implementing backup strategy.

**Consequences:**
- User data loss
- Loss of trust in the tool
- Support burden ("how do I get my config back?")
- Users abandon tool rather than risk their setup

**Prevention:**
- ALWAYS create timestamped backup before modifying: `cp file file.backup-$(date +%Y%m%d-%H%M%S)`
- Prompt before overwriting (in interactive mode)
- Keep backup location documented and accessible
- Implement recovery command: `./setup.sh --restore`

**Detection:**
- Check for `cp`, `mv`, `ln -sf` without preceding backup logic
- Test on system with existing customizations
- Review file operations in code

**Phase to address:** Phase 1 (Core Infrastructure) - backup utilities in shared library

---

## Moderate Pitfalls

Mistakes that cause delays or technical debt.

### Pitfall 5: Zsh Configuration Performance

**What goes wrong:** Shell startup takes 2-5+ seconds. Every new terminal feels sluggish. Users blame the dotfiles and stop using them.

**Why it happens:** Oh-My-Zsh with many plugins. NVM/rbenv/pyenv initialization on every shell start. Compinit running on every startup without caching. Synchronous network calls (theme updates, etc.).

**Consequences:**
- Poor user experience
- Users disable features or abandon config
- Perceived as "bloated"

**Prevention:**
- Lazy-load version managers: `zstyle ':omz:plugins:nvm' lazy yes`
- Cache completion with `zcompdump`: check age before rebuilding
- Minimize plugins (5-10 max)
- Profile startup: `time zsh -i -c exit`
- Use async loading where possible

**Detection:**
- Measure startup time in CI
- Profile with `zsh -xv 2>&1 | ts -i "%.s"`
- Target: < 500ms startup time

**Phase to address:** Phase 3 (Shell Configuration) - implement lazy loading and caching

---

### Pitfall 6: Package Manager Lock Handling

**What goes wrong:** Scripts fail when another process has apt/dpkg locked. Impatient scripts forcefully remove locks, corrupting dpkg database.

**Why it happens:** Automatic updates run in background. Previous script failed mid-operation. User ran apt in another terminal.

**Consequences:**
- Script failures that confuse users
- Corrupted package database if locks removed forcefully
- Hours spent recovering system

**Prevention:**
- Wait for locks with timeout (current `package-safety.sh` does this well)
- NEVER remove lock files programmatically
- Show clear message about what's happening
- Provide guidance for stuck locks

**Detection:**
- Test with background `apt update` running
- Verify script doesn't use `rm /var/lib/dpkg/lock*`
- Check for proper timeout handling

**Phase to address:** Already partially addressed - verify coverage across all installers

---

### Pitfall 7: Hardcoded Paths

**What goes wrong:** Scripts assume paths like `/home/username` but fail on macOS (`/Users/`) or custom HOME. Cargo at `~/.cargo` vs Homebrew at `/opt/homebrew` vs `/usr/local`.

**Why it happens:** Testing only on developer's machine. Copy-pasting path strings. Not using variables.

**Consequences:**
- Scripts fail on different OS or user setup
- Difficult to debug ("works on my machine")

**Prevention:**
- Use `$HOME` instead of `/home/username`
- Detect architecture: Apple Silicon Homebrew is `/opt/homebrew`, Intel is `/usr/local`
- Use `command -v` to find tool locations
- Abstract paths in variables at script top

**Detection:**
- Grep for hardcoded paths: `/home/`, `/Users/`, `/usr/local/bin`
- Test on multiple users/systems
- shellcheck warns about some cases

**Phase to address:** Phase 1 (Core Infrastructure) - path abstraction utilities

---

### Pitfall 8: Missing Error Handling

**What goes wrong:** Script continues after critical failures. Partial installations leave system in broken state. Users don't know what failed.

**Why it happens:** Not using `set -e`. Not checking return codes. Optimistic assumptions about command success.

**Consequences:**
- Silent failures
- Partial/broken installations
- Difficult debugging

**Prevention:**
- Use `set -euo pipefail` at script start
- Check return codes for critical operations
- Provide meaningful error messages
- Log all operations for debugging

**Detection:**
- Look for missing `set -e`
- Check if critical commands have error handling
- Test failure scenarios (no network, no sudo, disk full)

**Phase to address:** Phase 1 (Core Infrastructure) - error handling patterns

---

### Pitfall 9: Code Duplication Across Platforms

**What goes wrong:** Same logic implemented differently in `scripts/install/` and `platforms/linux/install/`. Fixes applied to one location but not the other. Behavior diverges over time.

**Why it happens:** Organic growth without clear architecture. Different developers working on different areas. Lack of shared utilities.

**Consequences:**
- Maintenance burden doubles/triples
- Inconsistent behavior across platforms
- Bugs fixed in one place remain in others
- Difficult onboarding for contributors

**Prevention:**
- Extract shared logic to `src/core/`
- Keep platform-specific code minimal and focused
- Regular deduplication audits
- Single Source of Truth (SSoT) principle from PROJECT.md

**Detection:**
- Compare similar files with `diff`
- Look for functions with same name in multiple files
- Track if changes propagate to all locations

**Phase to address:** Phase 2 (Consolidation) - primary goal of refactoring

---

### Pitfall 10: Incomplete Feature Parity

**What goes wrong:** Linux 100% complete, macOS 20%, Windows minimal. Users try cross-platform but hit walls. Documentation promises features not implemented everywhere.

**Why it happens:** Developer uses Linux primarily. Testing matrix exponential. Platform-specific knowledge gaps.

**Consequences:**
- Frustrated users on non-primary platform
- Bug reports for "missing" features
- Reputation as unreliable cross-platform tool

**Prevention:**
- Feature matrix in documentation showing what works where
- CI testing on all platforms
- Prioritize feature parity over new features
- Document known limitations clearly

**Detection:**
- Track implemented features per platform
- User bug reports for platform X
- Test installation end-to-end on all platforms

**Phase to address:** Phase 4 (macOS) and Phase 5 (Windows) - platform completion

---

## Minor Pitfalls

Mistakes that cause annoyance but are fixable.

### Pitfall 11: Curl | Bash Security Concerns

**What goes wrong:** Users asked to pipe untrusted content to shell. Security-conscious users refuse. Corporate environments block this pattern.

**Why it happens:** Convenient for quick install. Common pattern in many tools.

**Prevention:**
- Prefer `git clone` as primary method (current approach is good)
- Provide curl | bash as alternative, not primary
- Show script content before execution option
- Sign releases

**Detection:**
- Check documentation for which method is promoted first

**Phase to address:** Documentation phase - ensure git clone is primary

---

### Pitfall 12: Emoji and Unicode in Shell Scripts

**What goes wrong:** Emojis render as boxes on some terminals. Log output breaks when piped. Older systems lack Unicode support.

**Why it happens:** Modern terminals handle Unicode well. Testing only in fancy terminals.

**Consequences:**
- Broken display on some systems
- Confusing output
- Log files with encoding issues

**Prevention:**
- Keep emojis in interactive output only, not in logs
- Provide `--no-color --no-emoji` flag
- Test in basic terminals (TTY, SSH, old term emulators)

**Detection:**
- Run in `TERM=dumb` environment
- Check logs for Unicode

**Phase to address:** Phase 1 (Logging) - conditional emoji output

---

### Pitfall 13: Assuming Root/Sudo Available

**What goes wrong:** Scripts fail in containers, restricted environments, or when sudo times out. User can't complete setup.

**Why it happens:** Assuming traditional desktop environment. Not testing in containers.

**Consequences:**
- Script hangs waiting for password
- Fails in Docker/CI environments
- Incomplete installation

**Prevention:**
- Check for sudo only when needed
- Provide rootless alternatives where possible
- Support `--no-sudo` mode for user-space only install
- Cache sudo credentials at start with single prompt

**Detection:**
- Test in Docker without sudo
- Test with expired sudo cache

**Phase to address:** Phase 1 (Core) - sudo detection utilities

---

### Pitfall 14: AI Content Filtering Blocks Legitimate Policy Documents

**What goes wrong:** AI coding assistants (Claude, Copilot, etc.) refuse to generate or crash when writing standard community documents like Contributor Covenant CODE_OF_CONDUCT.md. The document contains terms about harassment, discrimination, and inappropriate behavior that trigger content safety filters.

**Why it happens:** Content filtering systems flag policy language about prohibited behaviors (harassment, sexual content, etc.) without distinguishing governance documents from harmful content.

**Consequences:**
- Automated execution pipelines break mid-task (Tasks 2-3 of Plan 08-02 never executed)
- Connection drops or silent failures with no error message
- Developer loses context and must restart session
- Legitimate community health files cannot be AI-generated

**Prevention:**
- Write CODE_OF_CONDUCT.md manually or copy from contributor-covenant.org
- Never rely on AI to generate policy documents with sensitive terminology
- If using AI workflows (GSD, etc.), mark policy document tasks as `type="manual"`
- Keep these files outside automated execution plans

**Detection:**
- AI session crashes or hangs during document generation
- Partial plan execution (some tasks complete, others silently skipped)
- Connection resets when generating specific file content

**Observed:** 2026-02-07, Phase 08-02 Task 2. Claude Code session dropped twice attempting to write Contributor Covenant v2.1. Task was removed from scope; CODE_OF_CONDUCT.md excluded from project.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Core Infrastructure | Non-idempotent patterns | Establish idempotent utilities first, require usage |
| Core Infrastructure | Cross-platform incompatibility | Create abstraction layer with platform detection |
| Consolidation | Code duplication | Clear single source of truth, deprecate duplicates |
| Shell Config | Zsh performance | Benchmark startup, lazy loading from start |
| macOS Support | Bash 3.2 compatibility | Test with default macOS bash |
| macOS Support | Homebrew path differences | Detect Apple Silicon vs Intel |
| Windows Support | PowerShell vs Bash differences | Separate PowerShell scripts, not shims |
| Testing | Cross-platform CI | GitHub Actions matrix with all 3 OS |
| Testing | Idempotency verification | Run tests twice, compare state |

## Sources

**Dotfiles Management:**
- [Dotfiles - ArchWiki](https://wiki.archlinux.org/title/Dotfiles)
- [The Ultimate Guide to Mastering Dotfiles](https://www.daytona.io/dotfiles/ultimate-guide-to-dotfiles)
- [GitHub does dotfiles](https://dotfiles.github.io/)
- [Dotfiles Management - mitxela.com](https://mitxela.com/projects/dotfiles_management)

**Shell Script Portability:**
- [Shell Script Best Practices - The Sharat's](https://sharats.me/posts/shell-script-best-practices/)
- [Differences Between MacOS and Linux Scripting](https://dev.to/aghost7/differences-between-macos-and-linux-scripting-74d)
- [Designing Scripts for Cross-Platform Deployment - Apple](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/PortingScriptstoMacOSX/PortingScriptstoMacOSX.html)
- [Portability Issues - TLDP](https://tldp.org/LDP/abs/html/portabilityissues.html)

**Idempotency:**
- [Idempotent Scripts Required - Microsoft Learn](https://learn.microsoft.com/en-us/archive/blogs/gertd/idempotent-scripts-required)
- [How to write idempotent Bash scripts - Hacker News](https://news.ycombinator.com/item?id=29483070)
- [brew install idempotent - GitHub Issue](https://github.com/Homebrew/brew/issues/11393)

**Security:**
- [Shell Script Security Practices](https://moldstud.com/articles/p-shell-scripting-security-how-to-protect-your-scripts-from-vulnerabilities)
- [Writing Secure Shell Scripts - Linux Journal](https://www.linuxjournal.com/content/writing-secure-shell-scripts)
- [Shell Script Security - Apple Developer](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/ShellScriptSecurity/ShellScriptSecurity.html)

**Zsh Performance:**
- [Speeding Up My Shell - Matthew J. Clemente](https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/)
- [Fix slow ZSH startup due to NVM](https://dev.to/thraizz/fix-slow-zsh-startup-due-to-nvm-408k)
- [Speeding up zsh and Oh-My-Zsh - JonLuca's Blog](https://blog.jonlu.ca/posts/speeding-up-zsh)

**Testing:**
- [CI your MacOS dotfiles with GitHub Actions](https://mattorb.com/ci-your-dotfiles-with-github-actions/)
- [Testing dotfiles with Test Kitchen and InSpec](https://www.jamesridgway.co.uk/testing-dotfiles-with-test-kitchen-and-inspec/)
- [ashishb/dotfiles - GitHub (CI testing example)](https://github.com/ashishb/dotfiles)

**Chezmoi/Stow Comparison:**
- [Why use chezmoi?](https://www.chezmoi.io/why-use-chezmoi/)
- [Exploring Tools For Managing Your Dotfiles](https://gbergatto.github.io/posts/tools-managing-dotfiles/)
