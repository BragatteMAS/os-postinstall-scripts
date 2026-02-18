# OS Post-Install Scripts

## What This Is

Scripts de pós-instalação multiplataforma (macOS, Linux, Windows) para configurar máquinas novas e manter sistemas existentes. Uma única fonte de verdade para apps, dotfiles, configurações de sistema e ambiente de desenvolvimento.

## Core Value

**Fácil de manter.** Simplicidade e manutenibilidade superam features e cobertura. Código que qualquer pessoa entende e pode modificar.

## Current Milestone: v3.0 Quality & Parity

**Goal:** Corrigir bugs identificados por review de especialistas, fechar gaps de feature parity Windows, elevar qualidade de código e testes.

**Target features:**
- Fix bugs reais (VERBOSE boolean, winget.txt stale, ARCHITECTURE.md drift)
- Windows feature parity (DryRun flag, step counters, completion summary, CmdletBinding)
- Code quality (DRY violations PS, consolidar diretórios, eliminar duplicações)
- Testes unitários para core modules
- Documentação (EXTRA_PACKAGES, Windows troubleshooting, terminal demo)

**Source:** Review por 4 especialistas (Shell 7.5, PowerShell 7, Architecture 7.5, UX/Docs 8) — média 7.5/10

## Requirements

### Validated (v1.0 + v2.1)

- [x] Setup interativo com detecção de OS (macOS, Linux, Windows)
- [x] Instalação via package managers (brew, apt, winget, cargo, npm)
- [x] Dotfiles (zshrc, bashrc, gitconfig, starship)
- [x] Perfis (minimal, developer, full) com seleção interativa
- [x] UX: dry-run, progress, completion summary, colored logging
- [x] Documentação: README, CONTRIBUTING, CODE_OF_CONDUCT
- [x] Terminal blueprint com Starship presets e p10k migration
- [x] Windows cross-platform installers (cargo, npm, ai-tools)

### Active

- [ ] Fix VERBOSE boolean inconsistente em logging.sh
- [ ] Unificar NONINTERACTIVE/UNATTENDED
- [ ] Windows feature parity (DryRun, step counters, summary)
- [ ] Extrair helpers PS duplicados
- [ ] Consolidar src/install/ + src/installers/
- [ ] Testes unitários para core modules
- [ ] Documentação: EXTRA_PACKAGES, Windows troubleshooting

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

Codebase funcional e completo (v2.1). Review por especialistas identificou:
- **Bugs:** VERBOSE boolean, winget.txt stale (kite.kite), ARCHITECTURE.md drift
- **Windows gap:** Sem -DryRun flag, sem step counters, sem completion summary
- **DRY violations:** Test-WinGetInstalled 3x, Test-NpmInstalled 2x, cores duplicadas em platform.sh
- **Testes:** Static validators only, sem unit tests para core modules
- **Score médio:** 7.5/10 (potencial 8.5-9/10 com fixes)
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
*Last updated: 2026-02-18 after milestone v3.0 start*
