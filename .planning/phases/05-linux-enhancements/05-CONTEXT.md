# Phase 5: Linux Enhancements - Context

**Gathered:** 2026-02-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add feature-specific packages and enhance existing Linux support. Covers: APT hardening, Flatpak/Snap hardening, AI coding tools installation, Rust CLI tools, development environment setup (Node via fnm, Python via uv), and Linux main.sh orchestrator with profile dispatch. Cross-platform installers (fnm, uv, ai-tools) also work on macOS.

Desktop environments are OUT of scope (deferred). Docker is OUT of scope (deferred). Git config changes belong to Phase 3 dotfiles.

</domain>

<decisions>
## Implementation Decisions

### APT Hardening
- Use `apt-get` (not `apt`) for scripting stability — apt warns about unstable CLI interface
- dpkg lock handling: wait and retry with 60s timeout, checking every 5s (`-o DPkg::Lock::Timeout=60`)
- Network failure retry: 3 attempts with exponential backoff (5s, 15s, 30s)
- Log each retry attempt: `[WARN] Retry 2/3 para pacote X (falha de rede)...`
- Always run `apt-get update` before installing (silencioso: `[INFO] Atualizando cache APT...`)
- Pacote inexistente: warn e continuar, add to `FAILED_ITEMS` for summary
- No PPAs — repos oficiais only (KISS; PPAs are fragile across Ubuntu versions)
- Lock handling local to apt.sh — not core (only APT uses dpkg lock)
- Only install missing packages (idempotent, no apt upgrade)
- Data-driven only: packages from txt files, no CLI args
- Verify sudo before attempting install (reuse `verify_sudo()` from core)
- Install with recommended packages (no `--no-install-recommends` — workstation setup, not Docker)
- No cleanup (no autoremove/clean) — setup script, not maintenance tool
- No proxy support code — apt already respects `http_proxy`/`https_proxy` natively
- Two-pass install: `apt.txt` first, then `apt-post.txt` (consistent with flatpak-post/snap-post pattern)
- Use `--force-confold` for non-interactive: `DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" install`
- `DEBIAN_FRONTEND=noninteractive` only when `NONINTERACTIVE=true` (interactive mode lets dpkg ask)
- No i386 architecture support (workstation dev, not gaming)
- No apt pinning (contradicts decision [01-02]: no version checking)
- Improve existing apt.sh (not create new)

### Flatpak/Snap Hardening
- Apply same hardening pattern as APT: retry logic, idempotency, consistent logging
- Follow established `-post.txt` pattern (flatpak-post.txt, snap-post.txt already exist)

### AI/MCP Tools
- Tools: claude-code, codex (OpenAI), gemini-cli (Google), ollama (local LLM)
- All npm-based tools via `npm install -g` (consistent method: Claude, Codex, Gemini)
- Ollama via official curl script (`curl -fsSL https://ollama.com/install.sh | sh`)
- Dedicated `ai-tools.sh` installer with case-based logic per tool
- ai-tools.txt format: one name per line (consistent with project pattern)
- No MCP server installation — MCP config is per-user Claude Code config, not system setup
- No aider — 4 tools from the big 3 providers + local LLM is sufficient
- Profiles: developer + full (not minimal)
- No separate update mechanism — re-running script installs latest (npm install -g is idempotent)
- Selection model: grupo+custom ("Install AI tools? 1) All 2) Choose 3) Skip")
- Individual selection when customizing: `[S/n]` per tool
- Non-interactive mode: install all (no prompts)
- Dependency check: ai-tools.sh checks `command -v node`, warns and skips npm-based tools if missing
- Orchestrator ensures dev-env runs before ai-tools (structural guarantee)
- Verification: `command -v` only (project pattern `is_command_installed()`)
- Ollama model download: ask in interactive mode ("Download a base model? 1) llama3 2) Skip")
- No API key management — each tool has its own auth flow on first use
- Info message in summary: `[INFO] Configure API keys: ANTHROPIC_API_KEY, OPENAI_API_KEY`

### Rust CLI Tools
- Tools (6): bat, eza, fd-find, ripgrep, zoxide, delta
- Installation via apt (Linux) / brew (macOS) — no Rust/cargo dependency required
- Symlinks for Ubuntu name divergences: `ln -sf /usr/bin/batcat /usr/local/bin/bat`, `fd-find` -> `fd`
- No automatic aliases — Rust tools aliases already live in `data/dotfiles/shared/aliases.sh` (Phase 3)
- Educational message in summary showing Rust tool equivalents (bat>cat, eza>ls, etc.)
- zoxide shell integration in dotfiles: `command -v zoxide &>/dev/null && eval "$(zoxide init bash)"`
- delta config directly in `data/dotfiles/git/gitconfig` (no guard needed — git falls back to `less` if delta missing)
- bat theme: leave default (auto-detects light/dark)
- eza aliases: minimal (`--group-directories-first`) — no `--icons` (requires Nerd Font)
- Additional aliases: `ll='eza -la --group-directories-first'`, `lt='eza --tree --level=2'`
- Profiles: developer + full
- Selection model: grupo+custom (same as AI tools)
- No cargo install alternative — apt/brew is the method. Power users know `cargo install`.
- Shell completions: apt/brew packages already include them

### Dev Environment
- Node.js manager: fnm (Rust-based, fast, reads .nvmrc, consistent with Rust tools philosophy)
- Python manager: uv (all-in-one: versions, venvs, deps; CLAUDE.md already recommends)
- Install LTS versions by default: `fnm install --lts`, `uv python install`
- Global npm packages: pnpm and bun (CLAUDE.md preferences #1 and #2)
- No global pip/uv packages — uv manages per-project
- No Rust toolchain (rustup) by default — Rust CLI tools come via apt/brew
- fnm shell integration in dotfiles: `command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"`
- SSH key generation: ask in interactive mode (`Gerar SSH key para GitHub? [s/N]`), default=No
- Profiles: developer + full
- Selection model: grupo+custom (same pattern as AI tools and Rust CLI)

### UX Pattern (Universal)
- Interactive selection model: grupo+custom for ALL categories
  ```
  Install [category]? (tool1, tool2, tool3)
  1) All
  2) Choose
  3) Skip
  ```
- Select numerico (read -rp) — no fzf dependency; bash pure
- Non-interactive mode: install all without prompts
- Lightweight and performatic — FAIR process priority

### Linux main.sh Orchestrator
- Create `src/platforms/linux/main.sh` with parity to macOS main.sh
- Profile menu: minimal, developer, full (same as macOS)
- Dual-mode: CLI argument for unattended, interactive menu for manual
- Profile dispatch: reads profile file, case-match on package file names, skip non-Linux files
- Linux categories: apt.txt, apt-post.txt, flatpak.txt, flatpak-post.txt, snap.txt, snap-post.txt, cargo.txt
- Addresses STATE.md note: "Linux main.sh does not yet use profile-based dispatch"

### Minimal Profile (Linux)
- apt.txt packages only + dotfiles (shell config, git, starship)
- No AI tools, no Rust CLI tools, no dev environment

### Cross-Platform
- fnm, uv, ai-tools installers work on both Linux and macOS
- Shared installers in `src/install/` (new directory)
- Platform-specific remain in `src/platforms/{linux,macos}/install/`
- Rust CLI tools: apt on Linux, brew on macOS (add to brew.txt if not present)

### Plan Structure
- 6 plans in execution order:
  1. 05-01: APT hardening (lock, retry, confold, apt-get)
  2. 05-02: Flatpak/Snap hardening (retry, idempotency, logging)
  3. 05-03: Rust CLI tools (apt/brew install + symlinks + dotfiles integration)
  4. 05-04: Dev Environment (fnm, uv, Node LTS, Python, pnpm, bun, shell integration)
  5. 05-05: AI tools (claude-code, codex, gemini-cli, ollama + dedicated installer)
  6. 05-06: Linux main.sh orchestrator (profile menu, dispatch, macOS parity)

### Testing
- Limited and practical tests in `tests/test-linux.sh`
- Dry-run validation: `bash -n script.sh` (syntax check)
- Function unit tests: lock detection, retry logic, name→symlink mapping
- Idempotency verification: `command -v` checks for installed tools
- No real installation tests (require network + sudo)

### Claude's Discretion
- Exact retry backoff implementation details
- Lock file detection mechanism specifics
- fnm/uv curl installer URL management
- Test file structure and organization
- Script internal helper function naming
- Exact error messages wording

</decisions>

<specifics>
## Specific Ideas

- "Precisa ser leve e performatico" — FAIR process, maintenance and lightness are priority
- "Quero educar o user que rust e melhor" — educational summary showing Rust tool equivalents, not forced aliases
- "Quando darmos opcoes ao usuario pode ser como o sistema de perguntas aqui do terminal CLI do Claude" — select numerico, clean, lightweight
- Rust CLI tools must be available by default even for users who don't have/want Rust installed (hence apt/brew, not cargo)
- CLAUDE.md tool hierarchy (Rust > Legacy) should be reflected in the educational messaging
- Platform-agnostic profiles: same profile files work for both Linux and macOS (files list package filenames, platform scripts skip irrelevant ones)

</specifics>

<deferred>
## Deferred Ideas

- Docker/Docker Compose installation — complex setup (repo, GPG, group, systemd); deserves own plan/phase
- desktop-environments.sh integration — DE install is high-risk, highly opinionated, out of Phase 5 scope
- Rust toolchain (rustup) — offered as optional choice in grupo+custom but not installed by default
- aider coding assistant — 4 AI tools already cover the market; aider via pip can be added later if demand
- Git config improvements (defaultBranch=main, pull.rebase) — belongs to Phase 3 dotfiles revision
- Nerd Font installation — required for eza --icons, but font management is separate concern

</deferred>

---

*Phase: 05-linux-enhancements*
*Context gathered: 2026-02-06*
