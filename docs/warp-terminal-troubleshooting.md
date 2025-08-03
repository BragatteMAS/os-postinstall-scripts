# 🔧 Warp Terminal Troubleshooting Guide

Este guia resolve problemas específicos com o Warp Terminal e nossa configuração `.zshrc`.

## 🚨 Problema Principal

O erro que você está vendo:
```
unsetopt ZLE; WARP_SESSION_ID="$(command -p date +%s)$RANDOM"; _hostname=$(command -pv hostname >/dev/null 2>&1 && command -p hostname 2>/dev/null || command -p uname -n); _user=$(command -pv whoami >/dev/null 2>&1 && command -p whoami 2>/dev/null || echo $USER); _msg=$(printf "{\"hook\": \"InitShell\", \"value\": {\"session_id\": $WARP_SESSION_ID, \"shell\": \"zsh\", \"user\": \"%s\", \"hostname\": \"%s\"}}" "$_user" "$_hostname" | command -p od -An -v -tx1 | command -p tr -d " \n"); WARP_USING_WINDOWS_CON_PTY=false; if [ "$WARP_USING_WINDOWS_CON_PTY" = true ]; then printf '"'"'\e]9278;d;%s\x07'"'"' "$_msg"; else printf '"'"'\e\x50\x24\x64%s\x9c'"'"' "$_msg"; fi; unset _hostname _user _msg
```

**Causa:** O Warp Terminal está tentando executar seu código de inicialização, mas há conflitos com nossa configuração personalizada.

## ✅ Soluções

### Solução 1: Usar Configuração Automática (Recomendada)

Nossa configuração atualizada já inclui detecção automática do Warp Terminal. Se você está usando nossa configuração, o problema deve ser resolvido automaticamente.

### Solução 2: Configuração Manual

Se o problema persistir, adicione estas linhas no **INÍCIO** do seu `.zshrc`:

```bash
# Warp Terminal Compatibility
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    export WARP_DISABLE_AUTO_INIT=true
    export WARP_DISABLE_AUTO_TITLE=true
    export WARP_HONOR_PS1=1
    export WARP_USE_SSH_WRAPPER=0
    export WARP_DISABLE_COMPLETIONS=true
    export WARP_BOOTSTRAPPED=1

    if [[ -z "$WARP_SESSION_ID" ]]; then
        export WARP_SESSION_ID="$(date +%s)$RANDOM"
    fi
fi
```

### Solução 3: Usar Arquivo de Compatibilidade

1. Copie o arquivo `configs/shell/warp-compatibility.zsh` para seu diretório home:
```bash
cp configs/shell/warp-compatibility.zsh ~/.warp-compatibility.zsh
```

2. Adicione esta linha no início do seu `.zshrc`:
```bash
source ~/.warp-compatibility.zsh
```

## 🔧 Comandos de Diagnóstico

### Verificar Status do Warp
```bash
warp-status
```

### Resetar Configuração
```bash
warp-reset
```

### Habilitar Recursos Nativos do Warp
```bash
warp-enable
```

### Desabilitar Recursos Nativos do Warp
```bash
warp-disable
```

## 🎯 Configurações Recomendadas

### Para Usar Nossa Configuração Personalizada (Padrão)
```bash
export WARP_DISABLE_AUTO_INIT=true
export WARP_HONOR_PS1=1
export WARP_DISABLE_AUTO_TITLE=true
export WARP_USE_SSH_WRAPPER=0
export WARP_DISABLE_COMPLETIONS=true
```

### Para Usar Recursos Nativos do Warp
```bash
export WARP_DISABLE_AUTO_INIT=false
export WARP_HONOR_PS1=0
export WARP_DISABLE_AUTO_TITLE=false
export WARP_USE_SSH_WRAPPER=1
export WARP_DISABLE_COMPLETIONS=false
```

## 🚨 Problemas Comuns

### 1. Prompt Duplicado
**Sintoma:** O prompt aparece duas vezes
**Solução:** `export WARP_HONOR_PS1=1`

### 2. Completions Não Funcionam
**Sintoma:** Tab completion não funciona
**Solução:** `export WARP_DISABLE_COMPLETIONS=true`

### 3. Título da Janela Não Atualiza
**Sintoma:** O título da janela não muda
**Solução:** `export WARP_DISABLE_AUTO_TITLE=true`

### 4. SSH Não Funciona
**Sintoma:** Problemas com SSH
**Solução:** `export WARP_USE_SSH_WRAPPER=0`

## 🔄 Recarregar Configuração

Após fazer alterações:
```bash
source ~/.zshrc
```

Ou use nosso alias:
```bash
sz
```

## 📋 Checklist de Verificação

- [ ] Warp Terminal detectado corretamente
- [ ] Variáveis de ambiente configuradas
- [ ] Funções conflitantes removidas
- [ ] Prompt funcionando corretamente
- [ ] Completions funcionando
- [ ] SSH funcionando (se necessário)

## 🆘 Se Nada Funcionar

1. **Backup da configuração atual:**
```bash
cp ~/.zshrc ~/.zshrc.backup
```

2. **Usar configuração mínima:**
```bash
echo 'export WARP_DISABLE_AUTO_INIT=true' > ~/.zshrc
echo 'export WARP_HONOR_PS1=1' >> ~/.zshrc
```

3. **Reiniciar o Warp Terminal**

4. **Restaurar configuração gradualmente**

## 📞 Suporte

Se o problema persistir:
1. Execute `warp-status` e compartilhe a saída
2. Verifique se está usando a versão mais recente do Warp Terminal
3. Considere usar outro terminal temporariamente (iTerm2, Terminal.app)

---

**Última atualização:** 2025-01-28
**Versão:** 1.0.0