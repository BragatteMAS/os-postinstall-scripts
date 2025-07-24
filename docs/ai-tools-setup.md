# 🤖 AI Tools Setup Guide

> Setup completo para ferramentas de desenvolvimento assistido por IA, incluindo MCPs (Model Context Protocol) e BMAD Method.

## 📋 Visão Geral

Este guia explica como instalar e configurar as ferramentas de IA que potencializam o desenvolvimento com Claude Code e outros assistentes de IA.

### Componentes Instalados

1. **4 MCPs Essenciais**
   - **context7** - Documentação sempre atualizada
   - **fetch** - Requisições web inteligentes
   - **sequential-thinking** - Raciocínio estruturado
   - **serena** - Busca semântica em codebases

2. **BMAD Method**
   - Sistema completo de gerenciamento de projetos
   - Comandos slash customizados para Claude
   - Templates e estrutura otimizada

## 🚀 Instalação Rápida

### Opção 1: Via Menu Principal

```bash
./setup.sh
# Escolha opção 9: 🤖 Instalar ferramentas de IA (MCPs + BMAD)
```

### Opção 2: Instalação Direta

```bash
./install_ai_tools.sh
```

### Opção 3: One-liner

```bash
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install_ai_tools.sh | bash
```

## 📁 Estrutura de Arquivos

Após a instalação, os seguintes arquivos serão criados/modificados:

```
~/
├── Library/Application Support/Claude/     # macOS
│   └── claude_desktop_config.json         # Configuração dos MCPs
├── .config/Claude/                        # Linux
│   └── claude_desktop_config.json
├── Documents/GitHub/serena/               # Repositório do serena MCP
└── .claude/                               # Comandos BMAD (no projeto)
    └── commands/
        ├── generate-prp.md
        ├── execute-prp.md
        └── validate-patterns.md
```

## 🔧 Configuração Manual (se necessário)

### Localização do arquivo de configuração

- **macOS**: `~/Library/Application Support/Claude/claude.json`
- **Linux**: `~/.config/Claude/claude.json`
- **Windows**: `%APPDATA%\Claude\claude.json`

### Exemplo de configuração

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "serena": {
      "command": "/Users/seu-usuario/.local/bin/uv",
      "args": ["run", "--directory", "/Users/seu-usuario/Documents/GitHub/serena", "serena-mcp-server"]
    }
  }
}
```

## 🔍 Verificação da Instalação

### 1. Verificar MCPs no Claude

1. Reinicie o Claude Desktop completamente
2. Em qualquer conversa, você deve ver ferramentas com prefixo `mcp__`
3. Exemplos:
   - `mcp__context7__resolve-library-id`
   - `mcp__sequential-thinking__sequentialthinking`
   - `mcp__fetch__fetch`

### 2. Verificar BMAD Method

No diretório do seu projeto:

```bash
ls -la .claude/commands/
# Deve mostrar os arquivos de comando
```

### 3. Testar Comandos Slash

No Claude, digite:
- `/generate-prp` - Para gerar PRPs
- `/execute-prp` - Para executar implementações
- `/validate-patterns` - Para validar padrões

## 💡 Como Usar

### Context7 - Documentação Atualizada

```
# Em seus prompts, adicione:
"use context7 para React hooks"
"use context7 para Next.js 14"
```

### Sequential Thinking - Problemas Complexos

O MCP será ativado automaticamente para:
- Decomposição de problemas complexos
- Análise multi-etapas
- Revisão de raciocínio

### Serena - Busca em Codebases

Ideal para:
- Busca semântica em projetos grandes
- Encontrar implementações similares
- Navegação eficiente por código

### BMAD Method - Gestão de Projetos

1. No diretório do projeto: `bmad-method install --full`
2. Use comandos slash no Claude
3. Siga a estrutura de documentação BMAD

## 🐛 Troubleshooting

### MCPs não aparecem no Claude

1. **Verifique se o Claude foi reiniciado completamente**
   - No macOS: Cmd+Q, não apenas fechar a janela
   - No Windows/Linux: Feche todas as instâncias

2. **Verifique o arquivo de configuração**
   ```bash
   # macOS
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   
   # Linux
   cat ~/.config/Claude/claude_desktop_config.json
   ```

3. **Verifique logs de erro**
   - Abra o Console do Desenvolvedor no Claude (Cmd/Ctrl+Shift+I)
   - Procure por erros relacionados a MCP

### Erro ao instalar serena

Se o UV não for encontrado:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.cargo/env
```

### BMAD não cria pasta .claude

Execute no diretório do projeto:
```bash
pnpm dlx bmad-method@latest install --full --ide cursor
# ou
npx bmad-method@latest install --full --ide cursor
```

## 📚 Recursos Adicionais

- [Documentação do MCP](https://modelcontextprotocol.io)
- [BMAD Method](https://github.com/bmadcode/BMAD-METHOD)
- [Context7](https://context7.io)
- [UV - Python Package Manager](https://astral.sh/uv)

## 🔄 Atualizações

Para atualizar as ferramentas:

```bash
# Atualizar MCPs (automático via npx)
# Apenas reinicie o Claude

# Atualizar BMAD
pnpm dlx bmad-method@latest update

# Atualizar este script
git pull origin main
```

## 🤝 Suporte

- Issues: [GitHub Issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- Discussões: [GitHub Discussions](https://github.com/BragatteMAS/os-postinstall-scripts/discussions)

---

> **Nota:** Este setup segue as diretrizes do CLAUDE.md v2.3.0 para Context Engineering otimizado.