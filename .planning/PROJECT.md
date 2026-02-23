# OS Post-Install Scripts

## What This Is

Scripts de pos-instalacao multiplataforma (macOS, Linux, Windows) para configurar maquinas novas e manter sistemas existentes. Uma unica fonte de verdade para apps, dotfiles, configuracoes de sistema e ambiente de desenvolvimento.

## Core Value

**Facil de manter.** Simplicidade e manutenibilidade superam features e cobertura. Codigo que qualquer pessoa entende e pode modificar.

## Current State

**Shipped:** v4.2 Terminal UX Polish (2026-02-23)
**Total:** 5 milestones shipped (v1.0, v2.1, v3.0, v4.1, v4.2)
**License:** Apache 2.0

Production-ready codebase with:
- Cross-platform setup (macOS, Linux, Windows) with profile selection
- 142 tests (120 bats + 22 Pester) + lint runners (ShellCheck, PSScriptAnalyzer)
- Semantic exit codes (0/1/2) with full propagation chain
- safe_curl_sh() download-then-execute for all curl|sh sites
- Windows UX parity (DryRun, step counters, completion summary, CmdletBinding)
- Comprehensive documentation (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY)
- Fork-ready: submodule docs, test instructions, Pester prerequisites documented

## Requirements

### Shipped (v1.0 + v2.1 + v3.0 + v4.1)

- [x] Setup interativo com deteccao de OS (macOS, Linux, Windows)
- [x] Instalacao via package managers (brew, apt, winget, cargo, npm)
- [x] Dotfiles (zshrc, bashrc, gitconfig, starship)
- [x] Perfis (minimal, developer, full) com selecao interativa
- [x] UX: dry-run, progress, completion summary, colored logging
- [x] Documentacao: README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- [x] Terminal blueprint com Starship presets e p10k migration
- [x] Windows cross-platform installers (cargo, npm, ai-tools)
- [x] Flag/boolean correctness (VERBOSE, NONINTERACTIVE)
- [x] DRY cleanup (PS modules, directory consolidation, SSoT logging)
- [x] Windows parity (CLI switches, step counters, CmdletBinding)
- [x] Flatpak IDs corrigidos, Bash 3.2 macOS compatibility
- [x] Semantic exit codes (0/1/2) com propagacao completa
- [x] safe_curl_sh() para todos os curl|sh sites (ADR-009)
- [x] 142 testes (120 bats + 22 Pester + contract parity)
- [x] SECURITY.md, GitHub Release v4.0.0, Apache 2.0 license

### Out of Scope

- Rust/Zig como linguagem principal -- shell e suficiente e zero deps
- curl | bash como fluxo principal -- git clone e mais seguro
- JSON/TOML para dados -- requer parsers externos (jq, etc.)
- Suporte a distros Linux obscuras -- manter foco em Ubuntu/Debian
- GUI ou interface web -- CLI only
- Containerizacao (Docker) -- foco em bare metal
- CI/CD automation -- decisao explicita do owner (testes manuais only)

## Context

### Estado Atual

Codebase production-ready (v4.2 shipped). 5 milestones completos:
- **v1.0 MVP:** Core infra, consolidation, dotfiles, platforms, UX, docs (41 plans)
- **v2.1 Feature Completion:** Terminal blueprint, Windows installers (5 plans)
- **v3.0 Quality & Parity:** Flags, DRY, Windows parity, testing (7 plans)
- **v4.1 Production Ready:** Data fixes, exit codes, 142 tests, OSS health (9 plans)
- **v4.2 Terminal UX Polish:** Shell functions, emoji toggle, 14 agent-review fixes, portability (18 commits)

### Principios (do CLAUDE.md)

- **FAIR**: Contexto completo e replicavel
- **KISS**: Simplicidade e sofisticacao
- **DRY**: Don't Repeat Yourself
- **SSoT**: Single Source of Truth
- **OMOP**: One Method of Operation

### Stack Definido

- **Unix**: Bash/Zsh (nativo, zero deps)
- **Windows**: PowerShell (nativo)
- **Dados**: Arrays em `.sh`/`.ps1` + arquivos `.txt`
- **Sem parsers externos**: Nao usar jq, yq, etc.

### Fluxo de Uso

```bash
git clone --recurse-submodules https://github.com/bragatte/os-postinstall-scripts
cd os-postinstall-scripts
./setup.sh
```

O script detecta OS, pergunta perfil, executa. Idempotente (pode rodar multiplas vezes).

## Constraints

- **Zero dependencias externas**: So usar o que vem no OS
- **Idempotencia**: Scripts podem rodar multiplas vezes sem quebrar
- **Backward compatibility**: Manter funcionalidade existente durante migracao
- **Compatibilidade**: Bash 4+ (macOS precisa upgrade), PowerShell 5.1+

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Shell puro vs Rust/Zig | KISS: shell e a ferramenta certa para chamar package managers | Good |
| Zero deps externas | Rodar em maquina limpa sem instalar nada antes | Good |
| Migracao incremental | Sempre ter codigo funcionando durante refatoracao | Good |
| git clone como fluxo principal | Mais seguro que curl\|bash, codigo visivel antes de rodar | Good |
| Dados em .sh/.txt vs JSON | JSON precisa jq, nao e nativo em Unix | Good |
| Semantic exit codes 0/1/2 | Replace universal exit 0, preserve continue-on-failure | Good |
| safe_curl_sh() download-then-execute | Prevent partial download execution (ADR-009) | Good |
| Apache 2.0 license | Attribution requirement for forks/redistributions | Good |
| bats-core via git submodules | Portability across CI-less environments | Good |
| NO CI/CD | Owner decision -- tests are manual only | Accepted |

---
*Last updated: 2026-02-23 after v4.2 milestone*
