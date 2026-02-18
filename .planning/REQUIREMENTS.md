# Requirements: OS Post-Install Scripts

**Defined:** 2026-02-04
**Core Value:** Facil de manter > features

## v1 Requirements (Complete)

All 22 requirements from v1.0 + v2.1 milestones — COMPLETE.

### Core Infrastructure

- [x] **CORE-01**: Script detecta OS automaticamente (macOS, Linux, Windows)
- [x] **CORE-02**: Scripts sao idempotentes (podem rodar multiplas vezes sem quebrar)
- [x] **CORE-03**: Erros sao tratados com mensagens claras e fail gracefully
- [x] **CORE-04**: Output usa logging colorido e informativo

### Package Management

- [x] **PKG-01**: Instalar apps via Homebrew no macOS
- [x] **PKG-02**: Instalar apps via APT no Linux (Ubuntu/Debian)
- [x] **PKG-03**: Instalar apps via WinGet no Windows
- [x] **PKG-04**: Listas de apps em arquivos separados (.sh/.txt), nao hardcoded

### Dotfiles

- [x] **DOT-01**: Symlink de configs para home (zshrc, gitconfig, etc.)
- [x] **DOT-02**: Backup de configs existentes antes de linkar
- [x] **DOT-03**: Configuracoes de shell (zsh/bash) incluidas
- [x] **DOT-04**: Configuracao de git incluida

### Profiles

- [x] **PROF-01**: Perfil minimal disponivel (essenciais apenas)
- [x] **PROF-02**: Perfil developer disponivel (ferramentas de dev)
- [x] **PROF-03**: Perfil full disponivel (tudo)
- [x] **PROF-04**: Selecao interativa de perfil no setup

### User Experience

- [x] **UX-01**: Progress feedback durante execucao (o que esta acontecendo)
- [x] **UX-02**: Dry-run mode (--dry-run mostra o que faria sem executar)
- [x] **UX-03**: Resumo ao final (o que foi instalado/configurado)
- [x] **UX-04**: One-command setup (./setup.sh e pronto)

### Profile-Specific Features

- [x] **FEAT-01**: AI/MCP integration disponivel em perfil developer/full
- [x] **FEAT-02**: Rust CLI tools (bat, eza, fd, rg, zoxide) em perfil developer/full
- [x] **FEAT-03**: Dev environment (Node, Python) em perfil developer/full

### Codebase Modernization

- [x] **MOD-01**: Reestruturar para src/ + data/ + docs/
- [x] **MOD-02**: Consolidar codigo duplicado (scripts/ + platforms/)
- [x] **MOD-03**: Remover codigo deprecated e arquivos legados
- [x] **MOD-04**: Documentacao: README, INSTALL, USAGE, CUSTOMIZE, CONTRIBUTING

## v3.0 Requirements

Requirements para milestone Quality & Parity. Cada um mapeia para fases do roadmap.

### Flag & Boolean Correctness

- [ ] **FLAG-01**: VERBOSE check usa `== "true"` em vez de `-n` em logging.sh (fix boolean bug)
- [ ] **FLAG-02**: NONINTERACTIVE/UNATTENDED unificados via bridge em config.sh (fix propagation bug)
- [ ] **FLAG-03**: Remover kite.kite do winget.txt (pacote descontinuado 2022)
- [ ] **FLAG-04**: ARCHITECTURE.md corrigido para refletir decisao real (no set -e per ADR-001)

### Structure & DRY

- [ ] **DRY-01**: Extrair Test-WinGetInstalled e Test-NpmInstalled para idempotent.psm1 compartilhado
- [ ] **DRY-02**: Consolidar src/install/ e src/installers/ em um unico diretorio
- [ ] **DRY-03**: Eliminar definicoes de cor duplicadas em platform.sh, usar logging.sh como SSoT
- [ ] **DRY-04**: Resolver DATA_DIR dual readonly com guard -z em packages.sh

### Windows Parity

- [ ] **WPAR-01**: setup.ps1 aceita -DryRun, -Verbose, -Unattended como switches CLI
- [ ] **WPAR-02**: main.ps1 mostra [Step X/Y] em cada dispatch (step counters)
- [ ] **WPAR-03**: setup.ps1 mostra completion summary com profile, platform, duracao, falhas
- [ ] **WPAR-04**: Todos os scripts PS usam [CmdletBinding()] para suporte nativo -Verbose/-Debug

### Testing & Documentation

- [ ] **TEST-01**: Unit tests para core modules via bats-core (logging, errors, idempotent, packages)
- [ ] **TEST-02**: Lint runners locais (tools/lint.sh com ShellCheck + tools/lint.ps1 com PSScriptAnalyzer)
- [ ] **DOC-01**: README documenta EXTRA_PACKAGES e SKIP_PACKAGES na secao Customization
- [ ] **DOC-02**: README inclui secao Windows Troubleshooting (execution policy, WinGet, PATH)

## Future Requirements

Deferidos para releases futuras. Tracked mas nao no roadmap atual.

### Advanced Features

- **ADV-01**: Parallel execution (instalar multiplos pacotes simultaneamente)
- **ADV-02**: Diff preview antes de aplicar mudancas
- **ADV-03**: Suporte a mais distros Linux (Arch, Fedora)

### Testing Evolution

- **TEVO-01**: bats-core test coverage para platform.sh e progress.sh
- **TEVO-02**: Pester migration para testes PowerShell (quando PS file count > 15)
- **TEVO-03**: Profile validation tests (typo protection para .txt references)

## Out of Scope

Explicitamente excluido. Documentado para prevenir scope creep.

| Feature | Reason |
|---------|--------|
| Rust/Zig como linguagem | Shell e suficiente, zero deps |
| curl \| bash como fluxo principal | git clone e mais seguro |
| JSON/TOML para dados | Requer parsers externos (jq, yq) |
| Distros Linux obscuras | Manter foco em Ubuntu/Debian |
| GUI ou interface web | CLI only, KISS |
| Containerizacao (Docker) | Foco em bare metal |
| CI/CD automation | Decisao explicita do owner |
| Pester migration | PS surface area < 15 files |
| Exit code changes (0→1) | ADR-001 correto, risco de trap cascade |
| ShouldProcess/WhatIf nativo | Quebraria padrao cross-platform DRY_RUN |
| Terminal demo recording | Deferido (precisa asciinema + agg setup) |

## Traceability

Mapeamento de requirements para fases do roadmap. Atualizado durante criacao do roadmap.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FLAG-01 | — | Pending |
| FLAG-02 | — | Pending |
| FLAG-03 | — | Pending |
| FLAG-04 | — | Pending |
| DRY-01 | — | Pending |
| DRY-02 | — | Pending |
| DRY-03 | — | Pending |
| DRY-04 | — | Pending |
| WPAR-01 | — | Pending |
| WPAR-02 | — | Pending |
| WPAR-03 | — | Pending |
| WPAR-04 | — | Pending |
| TEST-01 | — | Pending |
| TEST-02 | — | Pending |
| DOC-01 | — | Pending |
| DOC-02 | — | Pending |

**Coverage:**
- v3.0 requirements: 16 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 16

---
*Requirements defined: 2026-02-04*
*v3.0 requirements added: 2026-02-18 after specialist review*
