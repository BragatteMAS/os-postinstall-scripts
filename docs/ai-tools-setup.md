# 🤖 AI Development Tools Setup Guide

Este guia detalha a instalação e configuração das ferramentas de desenvolvimento assistido por IA para o projeto os-postinstall-scripts.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [MCPs (Model Context Protocol)](#mcps-model-context-protocol)
- [BMAD Method](#bmad-method)
- [Instalação](#instalação)
- [Verificação](#verificação)
- [Uso](#uso)
- [Troubleshooting](#troubleshooting)

## 🎯 Visão Geral

O sistema integra duas tecnologias principais:

1. **MCPs (Model Context Protocol)**: Ferramentas que estendem as capacidades do Claude
2. **BMAD Method**: Sistema de gerenciamento de projetos otimizado para IA

## 🔌 MCPs (Model Context Protocol)

### O que são MCPs?

MCPs são servidores locais que fornecem funcionalidades extras ao Claude, permitindo:
- Acesso a documentação sempre atualizada
- Busca semântica em codebases
- Raciocínio estruturado
- Requisições web inteligentes

### MCPs Incluídos

#### 1. **context7** - Documentação Sempre Atualizada
- Acessa documentação oficial de qualquer biblioteca
- Evita código baseado em dados desatualizados
- Uso: Adicione `use context7` ao seu prompt

#### 2. **fetch** - Requisições Web Inteligentes
- Busca e analisa conteúdo web
- Converte HTML em markdown estruturado
- Processa informações de sites

#### 3. **sequential-thinking** - Raciocínio Estruturado
- Decomposição de problemas complexos
- Auto-correção durante o raciocínio
- Revisão de decisões anteriores

#### 4. **serena** - Busca Semântica em Código
- Economia massiva de tokens
- Compreensão contextual do código
- Navegação eficiente em projetos grandes

### Configuração do claude.json

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
      "command": "/Users/[seu-usuario]/.local/bin/uv",
      "args": ["run", "--directory", "/Users/[seu-usuario]/Documents/GitHub/serena", "serena-mcp-server"]
    }
  }
}
```

## 📚 BMAD Method

### O que é BMAD?

BMAD Method v4.31.0 é um sistema de gerenciamento de projetos que:
- Estrutura projetos para colaboração efetiva com IA
- Define padrões de documentação (PRD, STORIES, STATUS)
- Fornece agentes especializados para diferentes tarefas

### Estrutura BMAD

```
projeto/
├── .github/
│   └── AI_TOOLKIT/
│       ├── agents/          # Agentes especializados
│       ├── commands/        # Comandos personalizados
│       └── config/          # Configurações
├── PRD.md                   # Product Requirements Document
├── STORIES.md               # User Stories
└── STATUS.md                # Status do projeto
```

### Agentes Disponíveis

- **dev.md**: Desenvolvimento geral
- **test.md**: Criação de testes
- **doc.md**: Documentação
- **review.md**: Revisão de código

## 🚀 Instalação

### Método 1: Via Setup Principal

```bash
./setup.sh
# Escolha opção 9: 🤖 Instalar ferramentas de IA (MCPs + BMAD)
```

### Método 2: Instalação Direta

```bash
./install_ai_tools.sh
```

### Método 3: One-liner

```bash
curl -sSL https://raw.githubusercontent.com/BragatteMAS/os-postinstall-scripts/main/install_ai_tools.sh | bash
```

## ✅ Verificação

### Verificar Instalação Completa

```bash
./check_ai_tools.sh
```

### Verificação Manual

1. **MCPs**: Verifique se aparecem ferramentas com prefixo `mcp__` no Claude
2. **BMAD**: Verifique se existe `.github/AI_TOOLKIT/` em novos projetos
3. **UV**: Execute `uv --version`

## 💡 Uso

### Usando MCPs no Claude

1. **Context7 para documentação**:
   ```
   Como usar React hooks? use context7
   ```

2. **Sequential Thinking para problemas complexos**:
   ```
   use sequential-thinking para resolver este algoritmo complexo
   ```

3. **Serena para buscar código**:
   ```
   use serena para encontrar implementações de autenticação
   ```

### Usando BMAD em Projetos

1. **Inicializar projeto**:
   ```bash
   bmad init
   ```

2. **Usar agentes**:
   ```
   @agent:dev implemente a feature X
   ```

## 🔧 Troubleshooting

### MCPs não aparecem no Claude

1. Reinicie o Claude completamente
2. Verifique o arquivo claude.json
3. Execute `./check_ai_tools.sh` para diagnóstico

### BMAD não funciona

1. Verifique se npm está instalado
2. Confirme a versão: `bmad --version`
3. Reinstale: `npm install -g bmad-method@latest`

### Serena não conecta

1. Verifique se UV está instalado: `uv --version`
2. Confirme o clone do repositório serena
3. Teste manualmente: `uv run --directory ~/Documents/GitHub/serena serena-mcp-server`

## 📍 Localização dos Arquivos

- **claude.json**: 
  - macOS: `~/Library/Application Support/Claude/claude.json`
  - Linux: `~/.config/Claude/claude.json`
  - Windows: `%APPDATA%\Claude\claude.json`

- **Serena**: `~/Documents/GitHub/serena`
- **BMAD**: Instalado globalmente via npm

## 🤝 Suporte

- Issues: [GitHub Issues](https://github.com/BragatteMAS/os-postinstall-scripts/issues)
- Discussões: [GitHub Discussions](https://github.com/BragatteMAS/os-postinstall-scripts/discussions)

---

> 💡 Esta documentação é parte do projeto os-postinstall-scripts.
>
> **Built with ❤️ by Bragatte, M.A.S**