# Phase 2: Consolidation & Data Migration - Context

**Gathered:** 2026-02-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminar duplicação de código e separar código de dados seguindo o princípio DRY. Reorganizar estrutura de diretórios, extrair listas de pacotes para arquivos de dados, consolidar código duplicado entre `scripts/` e `platforms/`, e remover código deprecated.

</domain>

<decisions>
## Implementation Decisions

### Estrutura de Diretórios

- Layout de topo: `src/` + `data/` + `docs/`
- Dentro de src: `src/core/` (utilitários compartilhados) + `src/platforms/` (linux/, macos/, windows/)
- Entry point: `./setup.sh` na raiz do projeto
- Configuração do projeto: `./config.sh` na raiz
- Dados: `data/packages/` + `data/dotfiles/`
- Planning: `.planning/` permanece na raiz (convenção GSD)
- Auxiliares: `.github/` e `Makefile` na raiz, `tests/` quando necessário

**Estrutura final:**
```
./
  setup.sh            # Entry point
  config.sh           # Configuração do usuário
  Makefile            # (se necessário)
  .github/            # CI/CD
  .planning/          # Planejamento GSD
  src/
    core/             # Utilitários compartilhados (Fase 1)
    platforms/        # linux/, macos/, windows/
  data/
    packages/         # Listas de pacotes por gerenciador
    dotfiles/         # Templates por aplicação (git/, zsh/, bash/)
  docs/               # Documentação
  tests/              # (quando implementado)
```

### Formato de Listas de Pacotes

- Formato: `.txt` simples, um pacote por linha
- Comentários: linhas começando com `#` são ignoradas
- Linhas vazias: ignoradas
- Organização: por gerenciador de pacotes (apt.txt, brew.txt, brew-cask.txt, cargo.txt, npm.txt, winget.txt)
- Perfis: arquivo lista outros arquivos a incluir (sem sintaxe especial)
- Versionamento: não especificar (sempre versão mais recente)
- Validação: deixar gerenciador de pacotes reportar erros
- Dependências: confiar no gerenciador + ordem natural dos arquivos
- Condicionais: lógica no script, dados agnósticos de plataforma
- AI tools: arquivo separado (ai-tools.txt)
- Dotfiles: organização por aplicação (topic-centric)

**Exemplo de estrutura de packages:**
```
data/packages/
  apt.txt              # Pacotes apt (Linux)
  brew.txt             # Fórmulas Homebrew (macOS)
  brew-cask.txt        # Casks Homebrew (macOS)
  cargo.txt            # Ferramentas Rust
  npm.txt              # Pacotes npm globais
  winget.txt           # Pacotes WinGet (Windows)
  ai-tools.txt         # Ferramentas AI/MCP
  profiles/
    minimal.txt        # Lista: apt.txt
    developer.txt      # Lista: apt.txt, cargo.txt, npm.txt
    full.txt           # Lista: apt.txt, cargo.txt, npm.txt, ai-tools.txt
```

### Estratégia de Migração

- Ordem: estrutura → core → dados → platforms → cleanup
- Migração incremental com coexistência temporária
- Compatibilidade: atualizar imports imediatamente (sem symlinks temporários)
- Cada commit é autocontido: move + update imports + delete original
- Git mv para preservar histórico quando possível

**Sequência de migração:**
1. Criar estrutura vazia (src/, data/, docs/)
2. Migrar core (utilitários da Fase 1 para src/core/)
3. Extrair dados (criar .txt em data/packages/)
4. Migrar platforms (platforms/ → src/platforms/)
5. Atualizar entry point (setup.sh)
6. Remover diretórios legado vazios

### Tratamento de Duplicação

- Claude avalia cada arquivo duplicado com critérios definidos
- **Critérios (em ordem):** padrões Fase 1 > completude > simplicidade
- Usuário aprova decisão antes de executar
- Merge pontual quando ambas versões têm valor único

### Limpeza de Código Legado

- Timing: remover conforme migrar (não acumular lixo)
- Verificação: `rg` por referências antes de cada remoção
- Funcionalidade única: extrair para nova estrutura, depois remover legado
- Documentação: commit message detalhado lista o que foi removido
- `scripts/common/` removido em commit separado após verificar que nada referencia

### Claude's Discretion

- Implementação técnica de `load_packages()` em src/core/
- Organização interna de subpastas quando não especificado
- Ordem exata de migração de arquivos individuais
- Decisão de merge vs keep quando valores são equivalentes

</decisions>

<specifics>
## Specific Ideas

- Função genérica `load_packages()` para carregar qualquer arquivo .txt
- Perfis são simples listas de includes, não duplicam pacotes
- Padrão de commit: `refactor: move X to src/Y` com lista de imports atualizados
- grep/rg como verificação de segurança antes de deletar

</specifics>

<deferred>
## Deferred Ideas

None — discussão focou em implementação dentro do escopo da fase.

</deferred>

---

*Phase: 02-consolidation-data-migration*
*Context gathered: 2026-02-05*
