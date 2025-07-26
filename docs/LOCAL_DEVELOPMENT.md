# Local Development Guide

> **⚠️ IMPORTANTE**: Este guia é para desenvolvimento LOCAL apenas. NENHUM comando aqui dispara CI/CD automático.

## 🎯 Filosofia

Este projeto adota uma abordagem de **CI/CD 100% manual** para conservar recursos. O `cross-env` é usado APENAS para facilitar o desenvolvimento local multi-plataforma.

## 🚀 Quick Start

```bash
# 1. Clone o repositório
git clone https://github.com/bragatte/os-postinstall-scripts.git
cd os-postinstall-scripts

# 2. Instale as ferramentas de desenvolvimento local
npm install

# 3. Verifique seu ambiente
npm run dev:check

# 4. Execute testes locais
npm run dev:test
```

## 📋 Comandos Disponíveis

### Verificação de Ambiente
```bash
npm run dev:check
```
Verifica se seu ambiente local tem as ferramentas necessárias para desenvolvimento.

### Testes Locais

#### Testar na plataforma atual:
```bash
npm run dev:test
```

#### Simular teste para plataforma específica:
```bash
npm run dev:test:linux    # Simula ambiente Linux
npm run dev:test:windows  # Simula ambiente Windows  
npm run dev:test:macos    # Simula ambiente macOS
```

> **Nota**: Estas são SIMULAÇÕES locais. Para testes reais, use o sistema operacional correspondente.

### Linting Local
```bash
npm run dev:lint
```
Executa ShellCheck em todos os scripts shell do projeto.

### Ver todos os comandos
```bash
npm run help
```

## 🔧 Estrutura do Projeto

```
os-postinstall-scripts/
├── package.json           # Scripts NPM para dev local apenas
├── tools/
│   └── local-dev/        # Ferramentas de desenvolvimento local
│       ├── check-environment.js
│       ├── test-current-platform.sh
│       ├── test-platform.sh
│       └── lint-scripts.sh
├── linux/                # Scripts para Linux
├── mac/                  # Scripts para macOS
├── windows/              # Scripts para Windows
└── profiles/             # Perfis de instalação
```

## 🌍 Cross-Platform com cross-env

O `cross-env` permite definir variáveis de ambiente de forma consistente:

```json
{
  "scripts": {
    "dev:test:linux": "cross-env OS_TARGET=linux TEST_MODE=local ./tools/local-dev/test-platform.sh"
  }
}
```

### Por que usar cross-env?

1. **Sintaxe unificada**: Funciona igual em Windows, Linux e macOS
2. **Desenvolvimento ágil**: Teste localmente antes de acionar CI/CD
3. **Economia de recursos**: Evita executar CI/CD para testes simples

### Variáveis de ambiente disponíveis:

- `TEST_MODE`: Define o modo de teste (sempre "local" para dev)
- `OS_TARGET`: Plataforma alvo para simulação (linux/windows/darwin)
- `LINT_MODE`: Modo de linting (local)
- `CHECK_MODE`: Modo de verificação (local)

## 🚫 O que NÃO fazer

1. **NÃO** espere que estes comandos disparem CI/CD
2. **NÃO** use npm scripts em produção (são apenas para desenvolvimento)
3. **NÃO** confunda simulação com teste real de plataforma

## ✅ Fluxo de Trabalho Recomendado

1. **Desenvolva localmente**
   ```bash
   # Faça suas mudanças
   vim linux/install/novo-script.sh
   
   # Teste localmente
   npm run dev:test
   npm run dev:lint
   ```

2. **Commit suas mudanças**
   ```bash
   git add .
   git commit -m "feat: add new installation script"
   ```

3. **Push para o repositório**
   ```bash
   git push origin feature/minha-feature
   ```

4. **Solicite CI/CD manual** (quando necessário)
   - Vá para GitHub Actions
   - Selecione o workflow desejado
   - Clique em "Run workflow"
   - Preencha o motivo da execução

## 🐛 Troubleshooting

### "ShellCheck não está instalado"
```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt-get install shellcheck

# Outros
# Visite: https://github.com/koalaman/shellcheck
```

### "npm: command not found"
Instale o Node.js: https://nodejs.org/

### "Permission denied" ao executar scripts
```bash
chmod +x tools/local-dev/*.sh
```

## 📚 Recursos Adicionais

- [Documentação do cross-env](https://www.npmjs.com/package/cross-env)
- [Guia de CI/CD manual](.github/TESTING_GUIDELINES.md)
- [Contribuindo para o projeto](../CONTRIBUTING.md)

## 💡 Dicas Pro

1. **Use .env.local** para configurações pessoais (não commitado)
2. **Rode `dev:lint` antes de todo commit**
3. **Teste em múltiplas plataformas** usando VMs ou containers
4. **Documente** quando e por que você solicitou CI/CD

---

> **Lembre-se**: Desenvolvimento local eficiente economiza recursos de CI/CD! 🌱