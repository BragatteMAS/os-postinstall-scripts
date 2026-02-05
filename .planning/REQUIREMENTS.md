# Requirements: OS Post-Install Scripts

**Defined:** 2026-02-04
**Core Value:** Facil de manter > features

## v1 Requirements

Requirements para release inicial. Cada um mapeia para fases do roadmap.

### Core Infrastructure

- [x] **CORE-01**: Script detecta OS automaticamente (macOS, Linux, Windows)
- [x] **CORE-02**: Scripts sao idempotentes (podem rodar multiplas vezes sem quebrar)
- [x] **CORE-03**: Erros sao tratados com mensagens claras e fail gracefully
- [x] **CORE-04**: Output usa logging colorido e informativo

### Package Management

- [ ] **PKG-01**: Instalar apps via Homebrew no macOS
- [ ] **PKG-02**: Instalar apps via APT no Linux (Ubuntu/Debian)
- [ ] **PKG-03**: Instalar apps via WinGet no Windows
- [ ] **PKG-04**: Listas de apps em arquivos separados (.sh/.txt), nao hardcoded

### Dotfiles

- [ ] **DOT-01**: Symlink de configs para home (zshrc, gitconfig, etc.)
- [ ] **DOT-02**: Backup de configs existentes antes de linkar
- [ ] **DOT-03**: Configuracoes de shell (zsh/bash) incluidas
- [ ] **DOT-04**: Configuracao de git incluida

### Profiles

- [ ] **PROF-01**: Perfil minimal disponivel (essenciais apenas)
- [ ] **PROF-02**: Perfil developer disponivel (ferramentas de dev)
- [ ] **PROF-03**: Perfil full disponivel (tudo)
- [ ] **PROF-04**: Selecao interativa de perfil no setup

### User Experience

- [ ] **UX-01**: Progress feedback durante execucao (o que esta acontecendo)
- [ ] **UX-02**: Dry-run mode (--dry-run mostra o que faria sem executar)
- [ ] **UX-03**: Resumo ao final (o que foi instalado/configurado)
- [ ] **UX-04**: One-command setup (./setup.sh e pronto)

### Profile-Specific Features

- [ ] **FEAT-01**: AI/MCP integration disponivel em perfil developer/full
- [ ] **FEAT-02**: Rust CLI tools (bat, eza, fd, rg, zoxide) em perfil developer/full
- [ ] **FEAT-03**: Dev environment (Node, Python) em perfil developer/full

### Codebase Modernization

- [ ] **MOD-01**: Reestruturar para src/ + data/ + docs/
- [ ] **MOD-02**: Consolidar codigo duplicado (scripts/ + platforms/)
- [ ] **MOD-03**: Remover codigo deprecated e arquivos legados
- [ ] **MOD-04**: Documentacao: README, INSTALL, USAGE, CUSTOMIZE, CONTRIBUTING

## v2 Requirements

Deferidos para release futura. Tracked mas nao no roadmap atual.

### Advanced Features

- **ADV-01**: Parallel execution (instalar multiplos pacotes simultaneamente)
- **ADV-02**: PRD/STORIES parser (ler docs de projeto)
- **ADV-03**: Diff preview antes de aplicar mudancas
- **ADV-04**: Suporte a mais distros Linux (Arch, Fedora)

### Testing

- **TEST-01**: bats-core test framework
- **TEST-02**: CI matrix (testar em multiplos OS)
- **TEST-03**: Coverage minimo 30%

## Out of Scope

Explicitamente excluido. Documentado para prevenir scope creep.

| Feature | Reason |
|---------|--------|
| Rust/Zig como linguagem | Shell e suficiente, zero deps (ADR pendente) |
| curl \| bash como fluxo principal | git clone e mais seguro |
| JSON/TOML para dados | Requer parsers externos (jq, yq) |
| Distros Linux obscuras | Manter foco em Ubuntu/Debian |
| GUI ou interface web | CLI only, KISS |
| Containerizacao (Docker) | Foco em bare metal |
| Cloud sync de dotfiles | Complexidade desnecessaria |
| Secrets management | Fora do escopo |

## Traceability

Mapeamento de requirements para fases do roadmap.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 1: Core Infrastructure | Complete |
| CORE-02 | Phase 1: Core Infrastructure | Complete |
| CORE-03 | Phase 1: Core Infrastructure | Complete |
| CORE-04 | Phase 1: Core Infrastructure | Complete |
| MOD-01 | Phase 2: Consolidation | Pending |
| MOD-02 | Phase 2: Consolidation | Pending |
| MOD-03 | Phase 2: Consolidation | Pending |
| PKG-04 | Phase 2: Consolidation | Pending |
| DOT-01 | Phase 3: Dotfiles | Pending |
| DOT-02 | Phase 3: Dotfiles | Pending |
| DOT-03 | Phase 3: Dotfiles | Pending |
| DOT-04 | Phase 3: Dotfiles | Pending |
| PKG-01 | Phase 4: macOS | Pending |
| PROF-01 | Phase 4: macOS | Pending |
| PROF-02 | Phase 4: macOS | Pending |
| PROF-03 | Phase 4: macOS | Pending |
| PROF-04 | Phase 4: macOS | Pending |
| PKG-02 | Phase 5: Linux | Pending |
| FEAT-01 | Phase 5: Linux | Pending |
| FEAT-02 | Phase 5: Linux | Pending |
| FEAT-03 | Phase 5: Linux | Pending |
| PKG-03 | Phase 6: Windows | Pending |
| UX-01 | Phase 7: UX Polish | Pending |
| UX-02 | Phase 7: UX Polish | Pending |
| UX-03 | Phase 7: UX Polish | Pending |
| UX-04 | Phase 7: UX Polish | Pending |
| MOD-04 | Phase 8: Documentation | Pending |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0

---
*Requirements defined: 2026-02-04*
*Last updated: 2026-02-05 after Phase 1 completion*
