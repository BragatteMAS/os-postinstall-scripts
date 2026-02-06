# OS Post-Install Scripts

## What This Is

Scripts de pós-instalação multiplataforma (macOS, Linux, Windows) para configurar máquinas novas e manter sistemas existentes. Uma única fonte de verdade para apps, dotfiles, configurações de sistema e ambiente de desenvolvimento.

## Core Value

**Fácil de manter.** Simplicidade e manutenibilidade superam features e cobertura. Código que qualquer pessoa entende e pode modificar.

## Requirements

### Validated

- Setup interativo com detecção de OS — existing
- Instalação de pacotes via package managers (brew, apt, winget) — existing
- Configuração de dotfiles (zshrc, bashrc, gitconfig) — existing
- Perfis de instalação (minimal, developer, full) — existing

### Active

- [ ] Reestruturar codebase: `src/` + `data/` + `docs/`
- [ ] Consolidar código duplicado (`scripts/` + `platforms/`)
- [ ] Extrair dados de apps para arquivos simples (`.sh`, `.txt`)
- [ ] Setup funcional no macOS com nova estrutura
- [ ] Setup funcional no Linux com nova estrutura
- [ ] Setup funcional no Windows com nova estrutura
- [ ] Documentação: README, INSTALL, USAGE, CUSTOMIZE, CONTRIBUTING
- [ ] ADRs para decisões arquiteturais
- [ ] Remover código legado e arquivos deprecated

### Out of Scope

- Rust/Zig como linguagem principal — shell é suficiente e zero deps (ADR para explorar futuramente)
- curl | bash como fluxo principal — git clone é mais seguro
- JSON/TOML para dados — requer parsers externos (jq, etc.)
- Suporte a distros Linux obscuras — manter foco em Ubuntu/Debian
- GUI ou interface web — CLI only
- Containerização (Docker) — foco em bare metal

## Context

### Estado Atual

Codebase funcional mas com problemas significativos:
- **Duplicação**: `scripts/install/` e `platforms/*/install/` fazem coisas similares
- **Desorganização**: 12+ arquivos .md na raiz
- **Código deprecated**: `scripts/common/` marcado como deprecated mas ainda existe
- **Testes**: Cobertura ~5%, sem framework real
- **macOS**: ~20% implementado vs Linux 100%
- **Backup dentro do repo**: `.agent-os/` com backup completo

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
*Last updated: 2026-02-04 after initialization*
