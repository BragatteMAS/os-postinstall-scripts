# Atuin setup runbook (macOS, Warp/zsh)

> One-page guide for first-time atuin setup on a Mac. Captures the
> real stumbles from a live session — each step has a "Watch out for"
> with the symptom and the fix, so you don't repeat them.
>
> **What atuin gives you:** end-to-end encrypted shell history that
> syncs across machines. Ctrl+R becomes a fuzzy-search TUI over your
> 7k+ commands, with cwd/exit-code/duration metadata.

---

## TL;DR (cola direto, em ordem)

```sh
brew install atuin
atuin register -u <seu-usuario>          # abre browser, autentica via Atuin Hub
cat ~/.local/share/atuin/key              # COPIA pro Bitwarden — chave de criptografia
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
exec zsh -l                               # recarrega o shell pra atuin init valer
atuin import zsh                          # ou: atuin import bash, atuin import fish
atuin sync
atuin status                              # confere "Last sync: <hora atual>"
```

Salve no Bitwarden:
- Username Atuin Hub
- Senha Atuin Hub
- 24 palavras BIP39 (saída de `cat ~/.local/share/atuin/key`)
- Server: `https://api.atuin.sh`

---

## 1. Instalar atuin

```sh
brew install atuin
atuin --version    # confere v18+
```

---

## 2. Registrar (criar conta no Atuin Hub)

```sh
atuin register -u <seu-usuario>
```

Em v18+ isso abre seu browser e termina o login via OAuth no Atuin
Hub. **Confirma a senha que você usar — vai precisar dela no M5.**

> **Watch out for** — `You are already authenticated with Atuin Hub. Run 'atuin logout' to log out.`
>
> Aconteceu uma vez? Já está registrado. Pula pro passo 3 direto.

> **Watch out for** — `Username, password, and email are all required for headless registration. Continuing with interactive registration.`
>
> Isso é normal: significa que vai abrir browser. Não é erro.

---

## 3. Salvar a chave de criptografia (CRÍTICO)

Atuin é E2E encrypted — o servidor armazena seu histórico cifrado e
**não tem como te entregar a chave de volta** depois. Se você perder,
perde tudo. Faz isso ANTES de qualquer outro passo:

```sh
cat ~/.local/share/atuin/key
```

Saída esperada (24 palavras estilo BIP39):
```
short during inform novel obvious town hand domain panda wave frame
item cool sound daring fog galaxy mobile park jeans genuine cruel
enforce glance
```

> **Watch out for** — `atuin key` cuspir nada visível.
>
> Em v18+ o output vai pra stdout direto, sem prompt. Se passou rápido
> ou rolou tela, perdeu de vista. Use `cat ~/.local/share/atuin/key`
> que lê o arquivo direto.

> **Watch out for** — vazar a chave em logs/chats.
>
> A chave é equivalente a uma senha-mestra do seu histórico. Não cole
> em chat público, slack, email. Se vazar e você não tem nada
> sensível ainda no servidor, faça rotação:
> ```sh
> atuin logout
> rm -rf ~/.local/share/atuin
> atuin register -u <user>     # gera nova chave
> ```

**Onde salvar:** Bitwarden secure note (texto, cabe no plano free).
Crie note `Atuin Vault` com:

```
Username: <user>
Password: <senha do Atuin Hub>
Server: https://api.atuin.sh
Encryption key (BIP39, 24 palavras):
<cole as 24 palavras aqui>
```

---

## 4. Plugar atuin no zsh

Adiciona o init no `.zshrc` (faz o atuin substituir Ctrl+R, criar a
sessão, etc.) e recarrega o shell:

```sh
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
exec zsh -l
```

`exec zsh -l` substitui o processo do shell por um zsh login novo, que
re-source o `.zshrc` completo. Confirma:

```sh
echo "$ATUIN_SESSION"
bindkey | grep '\^R'
```

Esperado:
- `ATUIN_SESSION=019dfe5...` (algum UUID, não vazio)
- `"^R" atuin-search`

> **Watch out for** — `ATUIN_SESSION` vazio mesmo depois do `exec zsh -l`.
>
> Significa que `eval "$(atuin init zsh)"` não rodou. Causas comuns:
> 1. A linha não foi escrita no `.zshrc` (verifica com `tail -3 ~/.zshrc`)
> 2. Algum `return` antes da linha aborta o resource — verifica com
>    `grep -n "^return\|^exit" ~/.zshrc`
> 3. Você editou e abriu novo terminal mas o terminal não re-source

---

## 5. Importar histórico existente do shell

Se você já tem histórico do zsh/bash pré-existente, importa pro banco
do atuin:

```sh
atuin import zsh
```

Saída esperada:
```
Importing history from /Users/<user>/.zsh_history
✓ Imported 9113 new entries
```

> **Watch out for** — `atuin import auto` falhar silenciosamente.
>
> O comando `auto` precisa de `$HISTFILE` exportado pra detectar o
> shell. Se não tiver, ele falha sem dar erro claro. Sempre passe
> explícito (`atuin import zsh`, `atuin import bash`, etc.).

---

## 6. Sincronizar com o servidor

```sh
atuin sync
```

Esperado:
```
Re-running sync due to new records locally
Uploading 7933 records to .../history
[##########] 7933/7933 (0.0s)
Sync complete! 7934 items in history database, force: false
```

> **Watch out for** — `Failed to find $ATUIN_SESSION in the environment`.
>
> O atuin init não rodou no shell atual. Volta ao passo 4 (`exec zsh -l`)
> ou roda na hora: `eval "$(atuin init zsh)" && atuin sync`.

> **Watch out for** — `Last sync: 1969-12-31` no `atuin status`.
>
> Epoch zero = nunca sincronizou. Execute `atuin sync` de fato e
> espera completar.

---

## 7. Verificar

```sh
atuin status
```

Confere:
- `Username: <seu-usuario>`
- `Last sync: <data/hora atual>`
- `Address: https://api.atuin.sh`

```sh
atuin search docker | head -5
```

Se voltar comandos seus que envolvem docker, histórico está indexado e
buscável.

---

## 8. (Opcional) Resolver conflito Ctrl+R com Warp

Warp Terminal intercepta Ctrl+R com sua própria "Command Search" antes
do shell ver. **Atuin está funcionando**, só não está alcançável por
Ctrl+R no Warp.

**Opção A** (recomendado): muda o atalho do Warp.
Settings (`Cmd+,`) → Features → Session → "Command search" — remap pra
`Cmd+P` ou desativa.

**Opção B**: liga atuin em outra tecla. No final do `.zshrc`, depois
do `eval "$(atuin init zsh)"`:
```sh
bindkey '^E' atuin-search   # Ctrl+E em vez de Ctrl+R
```

**Opção C**: usa Terminal.app, iTerm2, Ghostty, kitty — não capturam Ctrl+R.

---

## 9. Como usar (depois de configurado)

| Ação | Como |
|---|---|
| Abrir busca | Ctrl+R (TUI fullscreen) |
| Buscar | Digita; filtro fuzzy incremental |
| Navegar | ↑ ↓ |
| Colar comando no prompt (sem executar) | Enter |
| Editar antes de executar | Tab |
| Fechar | Esc |
| Alternar global ↔ só esta sessão | Ctrl+R (de novo, dentro da TUI) |

Para ver estatísticas:
```sh
atuin stats          # contagem total + frequência
atuin search <query> # busca não-interativa
```

---

## 10. Restaurar em outra máquina

Numa máquina nova (ex: M5 após `setup.sh` que já instala atuin via
`csv:rust-shell`):

```sh
atuin login -u <seu-usuario>
# vai pedir senha + chave (24 palavras do Bitwarden)

eval "$(atuin init zsh)"
atuin sync     # puxa histórico do servidor

# torna persistente:
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
```

Pronto — Ctrl+R agora vê o histórico do M1 (e de qualquer outra máquina
que tenha sincronizado).

---

## Troubleshooting cheat-sheet

| Sintoma | Causa | Fix |
|---|---|---|
| `Already authenticated with Atuin Hub` | Já registrou antes neste host | Pula pro passo 3 |
| `Failed to find $ATUIN_SESSION` | atuin init não carregou | `eval "$(atuin init zsh)" && atuin sync` |
| `atuin import auto` faz nada | `$HISTFILE` não exportado | `atuin import zsh` (explícito) |
| `Last sync: 1969-12-31` | Nunca sincronizou de fato | `atuin sync` (precisa atuin init antes) |
| Ctrl+R abre algo errado | Warp/fzf intercepta antes | Ver §8 |
| `atuin key` parece vazio | output passou rápido | `cat ~/.local/share/atuin/key` |
| Vai migrar de máquina | Histórico só local sem sync | Garanta sync ANTES de wipe (§6) |

---

## Lições aprendidas (não repita)

1. **Salve a chave imediatamente** — antes de qualquer comando que
   possa abortar. Sem ela = história perdida.
2. **`atuin init` precisa rodar no shell antes de qualquer sync** — não
   basta o servidor ter cadastro.
3. **Multi-line com `\` continuation** quebra fácil em copy-paste de
   terminal. Use one-liners ou scripts (`tools/m1-backup-secrets.sh`).
4. **Web UI do Atuin Hub não mostra histórico** — é E2E encrypted por
   design. Verificar funcionamento sempre via CLI.
5. **Warp captura Ctrl+R antes do shell.** Se atuin "não funciona",
   primeiro confirma com `bindkey | grep '\^R'`. Se vê `atuin-search`,
   é o terminal sequestrando.
