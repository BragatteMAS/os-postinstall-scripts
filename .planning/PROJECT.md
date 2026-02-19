# OS Post-Install Scripts

## What This Is

Scripts de pós-instalação multiplataforma (macOS, Linux, Windows) para configurar máquinas novas e manter sistemas existentes. Uma única fonte de verdade para apps, dotfiles, configurações de sistema e ambiente de desenvolvimento.

## Core Value

**Fácil de manter.** Simplicidade e manutenibilidade superam features e cobertura. Código que qualquer pessoa entende e pode modificar.

## Current State

**Shipped:** v3.0 Quality & Parity (tag v4.0.0, 2026-02-18)
**Total:** 3 milestones, 14 phases, 48 plans executed

All planned work complete. Codebase is production-ready with:
- Cross-platform setup (macOS, Linux, Windows) with profile selection
- 37 unit tests + lint runners (ShellCheck, PSScriptAnalyzer)
- Windows UX parity (DryRun, step counters, completion summary)
- Comprehensive documentation (README, CONTRIBUTING, CODE_OF_CONDUCT)

## Requirements

### Shipped (v1.0 + v2.1 + v3.0)

- [x] Setup interativo com detecção de OS (macOS, Linux, Windows)
- [x] Instalação via package managers (brew, apt, winget, cargo, npm)
- [x] Dotfiles (zshrc, bashrc, gitconfig, starship)
- [x] Perfis (minimal, developer, full) com seleção interativa
- [x] UX: dry-run, progress, completion summary, colored logging
- [x] Documentação: README, CONTRIBUTING, CODE_OF_CONDUCT
- [x] Terminal blueprint com Starship presets e p10k migration
- [x] Windows cross-platform installers (cargo, npm, ai-tools)
- [x] Flag/boolean correctness (VERBOSE, NONINTERACTIVE)
- [x] DRY cleanup (PS modules, directory consolidation, SSoT logging)
- [x] Windows parity (CLI switches, step counters, CmdletBinding)
- [x] Unit tests (37 bats) + lint runners

### Next Milestone Goals

To be defined via `/gsd:new-milestone`.

### Out of Scope

- Rust/Zig como linguagem principal — shell é suficiente e zero deps
- curl | bash como fluxo principal — git clone é mais seguro
- JSON/TOML para dados — requer parsers externos (jq, etc.)
- Suporte a distros Linux obscuras — manter foco em Ubuntu/Debian
- GUI ou interface web — CLI only
- Containerização (Docker) — foco em bare metal
- CI/CD automation — decisão explícita do owner (testes manuais only)
- Pester migration para testes PS — fora do escopo v3.0

## Context

### Estado Atual

Codebase completo (v3.0 shipped). Todos os issues do review por especialistas resolvidos:
- **Bugs:** Corrigidos (VERBOSE boolean, winget.txt stale, ARCHITECTURE.md drift)
- **Windows parity:** Completa (DryRun, step counters, completion summary, CmdletBinding)
- **DRY:** Consolidado (idempotent.psm1, single install dir, SSoT logging)
- **Testes:** 37 bats unit tests + ShellCheck/PSScriptAnalyzer lint runners
- **Score estimado:** 8.5-9/10 (up from 7.5)
### Princípios (do CLAUDE.md)

- **FAIR**: Contexto completo e replicável
- **KISS**: Simplicidade é sofisticação
- **DRY**: Don't Repeat Yourself
- **SSoT**: Single Source of Truth
- **OMOP**: One Method of Operation

### Stack Definido

- **Unix**: Bash/Zsh (nativo, zero deps)
- **Windows**: PowerShell (nativo)
- **Dados**: Arrays em `.sh`/`.ps1` + arquivos `.txt`
- **Sem parsers externos**: Não usar jq, yq, etc.

### Nova Estrutura

```
os-postinstall-scripts/
├── src/
│   ├── core/          # Lógica compartilhada (loader, logger, utils)
│   ├── unix/          # macOS + Linux
│   └── windows/       # PowerShell
├── data/
│   ├── packages/      # Listas de apps (.sh, .txt)
│   ├── dotfiles/      # Configs (zshrc, gitconfig)
│   └── profiles/      # Perfis (minimal, developer, full)
├── docs/
│   ├── project/       # PRD, ROADMAP, STATUS, STORIES, PITFALLS
│   └── adr/           # Architecture Decision Records
├── tests/
├── setup.sh           # Entry point Unix
├── setup.ps1          # Entry point Windows
└── README.md
```

### Fluxo de Uso

```bash
git clone https://github.com/bragatte/os-postinstall-scripts
cd os-postinstall-scripts
./setup.sh
```

O script detecta OS, pergunta perfil, executa. Idempotente (pode rodar múltiplas vezes).

## Constraints

- **Zero dependências externas**: Só usar o que vem no OS
- **Idempotência**: Scripts podem rodar múltiplas vezes sem quebrar
- **Backward compatibility**: Manter funcionalidade existente durante migração
- **Compatibilidade**: Bash 4+ (macOS precisa upgrade), PowerShell 5.1+

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Shell puro vs Rust/Zig | KISS: shell é a ferramenta certa para chamar package managers | — Pending |
| Zero deps externas | Rodar em máquina limpa sem instalar nada antes | — Pending |
| Migração incremental | Sempre ter código funcionando durante refatoração | — Pending |
| git clone como fluxo principal | Mais seguro que curl\|bash, código visível antes de rodar | — Pending |
| Dados em .sh/.txt vs JSON | JSON precisa jq, não é nativo em Unix | — Pending |

---
*Last updated: 2026-02-18 after milestone v3.0 completion*
