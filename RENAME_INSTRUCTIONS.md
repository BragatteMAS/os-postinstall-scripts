# Instruções para Renomear o Repositório

## Nome Atual
`os-postinstall-scripts`

## Novo Nome Recomendado
`os-postinstall-scripts`

## Passo a Passo para Renomeação

### 1. No GitHub (Interface Web)

1. Acesse o repositório: https://github.com/BragatteMAS/os-postinstall-scripts
2. Clique em **Settings** (Configurações)
3. Na seção **General**, você verá o campo **Repository name**
4. Mude de `os-postinstall-scripts` para `os-postinstall-scripts`
5. Clique em **Rename**

**Nota**: O GitHub automaticamente criará redirecionamentos do nome antigo para o novo.

### 2. Atualizar Referências Locais

Execute o script que foi criado:

```bash
# No diretório do projeto
./update_repository_name.sh
```

Este script irá:
- Mostrar todos os arquivos que contêm o nome antigo
- Pedir confirmação antes de fazer mudanças
- Atualizar todas as referências nos arquivos
- Atualizar a URL do remote git

### 3. Verificar e Commitar Mudanças

```bash
# Verificar as mudanças
git status
git diff

# Se tudo estiver correto
git add -A
git commit -m "feat: rename repository to os-postinstall-scripts

- Fix typo in original name (posintall -> postinstall)
- Better represent multi-OS support
- Follow modern naming conventions
- Update all internal references"

# Push para o repositório
git push origin main
```

### 4. Atualizar Referências Externas

Se você tem referências ao repositório em outros lugares, atualize:

- Blog posts
- Fóruns
- Documentação externa
- Links em outros repositórios

### 5. Notificar a Comunidade (Opcional)

Crie uma issue ou discussão informando sobre a mudança:

```markdown
# Repositório Renomeado para os-postinstall-scripts

Olá pessoal!

Para melhor refletir o escopo do projeto e corrigir o typo no nome original, 
o repositório foi renomeado de `os-postinstall-scripts` para `os-postinstall-scripts`.

## O que mudou?
- Nome do repositório
- URLs (mas o GitHub redireciona automaticamente)

## O que NÃO mudou?
- Todo o código e funcionalidade
- Histórico de commits
- Issues e PRs existentes

## Por que mudar?
1. Corrigir o typo (posintall → postinstall)
2. Refletir suporte multi-OS (Linux, Windows, futuro macOS)
3. Seguir convenções modernas de nomenclatura

Obrigado pela compreensão!
```

## Benefícios da Mudança

✅ **Nome correto** sem typos
✅ **Mais descritivo** sobre o escopo real
✅ **SEO melhor** para descoberta
✅ **Profissional** e moderno
✅ **Redirecionamento automático** do GitHub

## Possíveis Impactos

⚠️ Scripts antigos que clonam o repo precisarão atualizar a URL
⚠️ Documentação externa precisará ser atualizada
⚠️ Bookmarks precisarão ser atualizados (mas redirecionam)

## Verificação Final

Após a renomeação, verifique:

1. [ ] O novo URL funciona: https://github.com/BragatteMAS/os-postinstall-scripts
2. [ ] O URL antigo redireciona corretamente
3. [ ] Clone com novo nome funciona: `git clone https://github.com/BragatteMAS/os-postinstall-scripts`
4. [ ] Issues e PRs ainda estão acessíveis
5. [ ] GitHub Pages (se houver) ainda funciona