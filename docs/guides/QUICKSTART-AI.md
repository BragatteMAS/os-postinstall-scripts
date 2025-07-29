# 🚀 QUICKSTART: AI Tools em 2 Minutos

> **TL;DR:** Configure MCPs globalmente (1x) + BMAD por projeto = Desenvolvimento turbinado com IA

## ⚡ Setup Rápido

### 1️⃣ Instalar MCPs (Uma vez apenas)

```bash
# Clone este repo se ainda não tiver
git clone https://github.com/BragatteMAS/os-postinstall-scripts
cd os-postinstall-scripts

# Execute o instalador
./install_ai_tools.sh

# Reinicie o Claude Desktop completamente (Cmd+Q no Mac)
```

### 2️⃣ Ativar BMAD em Cada Projeto

```bash
# Entre no seu projeto
cd /caminho/do/seu/projeto

# Instale BMAD
npx bmad-method@latest install --full --ide claude-code --ide cursor

# Pronto! Digite / no Claude para ver comandos
```

## ✅ Verificar Instalação

```bash
# Em qualquer lugar
./check_ai_tools.sh

# Você deve ver:
# ✅ context7 - Configured
# ✅ fetch - Configured
# ✅ sequential-thinking - Configured
# ✅ serena - Configured
# ✅ BMAD installed in current directory
```

## 🎯 Como Usar

### MCPs (Funcionam em TODOS os projetos)

| MCP | Uso | Exemplo |
|-----|-----|---------|
| **context7** | Docs atualizados | "use context7 para React 18" |
| **sequential-thinking** | Problemas complexos | Ativado automaticamente |
| **fetch** | Buscar web | "busque a doc do Next.js 14" |
| **serena** | Buscar código | "encontre implementações de auth" |

### BMAD (Por projeto)

| Comando | Função |
|---------|--------|
| `/generate-prp` | Gera especificações detalhadas |
| `/execute-prp` | Implementa com validação |
| `/validate-patterns` | Verifica padrões do projeto |

## 🔥 Workflow Completo

```bash
# 1. Novo projeto
mkdir meu-projeto && cd meu-projeto

# 2. Inicializar git
git init

# 3. Instalar BMAD
npx bmad-method@latest install --full --ide claude-code --ide cursor

# 4. Abrir no Claude e começar!
# Os MCPs já estão ativos globalmente
```

## ⚠️ Troubleshooting Rápido

### "Não vejo mcp__ nas ferramentas"
```bash
# 1. Feche TOTALMENTE o Claude (Cmd+Q)
# 2. Verifique a config
cat ~/Library/Application\ Support/Claude/claude.json
# 3. Reabra o Claude
```

### "Comandos / não aparecem"
```bash
# Execute dentro do projeto
ls -la .claude/commands/
# Se vazio, reinstale:
bmad-method install --full --force
```

### "UV não encontrado"
```bash
# Instale UV
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.cargo/env
```

## 💡 Dicas Pro

1. **Crie um alias** no seu `.zshrc`:
   ```bash
   alias ai-check="~/Documents/GitHub/os-postinstall-scripts/check_ai_tools.sh"
   alias ai-setup="npx bmad-method@latest install --full --ide cursor"
   ```

2. **Template de projeto** com BMAD pré-configurado:
   ```bash
   # Clone seu template
   git clone seu-template novo-projeto
   cd novo-projeto
   bmad-method update  # Atualiza BMAD
   ```

3. **Verifique sempre** antes de começar:
   ```bash
   ai-check  # Com o alias acima
   ```

## 🎉 Pronto!

Agora você tem:
- ✅ MCPs funcionando globalmente
- ✅ BMAD pronto para cada projeto
- ✅ Comandos rápidos de verificação
- ✅ Desenvolvimento turbinado com IA

**Próximo passo:** Abra o Claude e comece a codar com superpoderes! 🚀