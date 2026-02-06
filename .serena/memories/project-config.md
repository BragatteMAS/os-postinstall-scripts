# os-postinstall-scripts - Configuração

## Linguagem Real

**ATENÇÃO:** Serena detecta TypeScript, mas projeto é **Bash/Shell**.

| Tipo | Quantidade |
|------|------------|
| `.sh` | 56 |
| `.zsh` | 15 |
| `.md` | 57 |
| `.yaml` | 9 |
| `.ps1` | 1 |

## Ferramentas Prioritárias (CLAUDE.md)

### Rust Tools > Legado (OBRIGATÓRIO)

| USAR | NÃO USAR | Função |
|------|----------|--------|
| `bat` | `cat` | Visualizar arquivos |
| `fd` | `find` | Buscar arquivos |
| `rg` | `grep` | Buscar conteúdo |
| `eza` | `ls` | Listar diretórios |
| `delta` | `diff` | Comparar arquivos |
| `z` | `cd` | Navegar diretórios |

### Serena - Uso Recomendado

Para Bash/Shell, análise simbólica é limitada. Usar:

- `search_for_pattern` - busca regex
- `find_file` - localizar arquivos
- `replace_content` - edição com regex
- `read_file` - leitura

**Evitar:** `find_symbol`, `get_symbols_overview` (não otimizados para shell)

### Padrões Shell neste Projeto

- Funções: `function nome() { }` ou `nome() { }`
- Buscar funções: `rg "^(function\s+)?\w+\s*\(\)" --type sh`
- Buscar sources: `rg "^(source|\.)\s+" --type sh`
