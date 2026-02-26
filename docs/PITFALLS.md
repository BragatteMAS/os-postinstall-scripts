# Pitfalls & Lessons Learned

Catalogo de armadilhas, gotchas e aprendizados acumulados durante o desenvolvimento do projeto (Phases 1-17). Organizado por categoria com referencia ao phase de origem.

---

## 1. Exit Codes & Error Handling

### 1.1 Trap Overwrites Exit Code
`cleanup()` chamava `exit 0` incondicionalmente, mascarando falhas reais. O `parse_flags()` fazia `exit 1` para flags invalidas, mas o EXIT trap sobrescrevia com 0.

**Fix:** Capturar `$?` no inicio do trap e usar `max(trap_exit_code, _worst_exit)`.
**Phase:** 16 | **Ref:** 16-RESEARCH.md, setup.sh:54-71

### 1.2 $? Clobbered Between Command and Check
Qualquer comando entre a execucao de um child process e a checagem de `$?` reseta o valor.

**Fix:** Capturar imediatamente: `bash script.sh; rc=$?` na mesma linha logica.
**Phase:** 16 | **Ref:** 16-RESEARCH.md

### 1.3 FAILURE_LOG Deleted Before Exit Code Computed
`cleanup_temp_dir()` deleta `$TEMP_DIR` que contem `$FAILURE_LOG`. Se `compute_exit_code()` roda depois, retorna 0.

**Fix:** Ordenar no cleanup: (1) compute code, (2) show summary, (3) cleanup temp, (4) exit.
**Phase:** 16 | **Ref:** 16-RESEARCH.md

### 1.4 PowerShell $LASTEXITCODE Stale
Se um script PS termina sem `exit N` explicito, `$LASTEXITCODE` mantem o valor do ultimo comando externo.

**Fix:** Todo script PS child DEVE terminar com `exit $code` explicito.
**Phase:** 16 | **Ref:** 16-RESEARCH.md

### 1.5 Signal Traps Masking Exit Code
Ctrl+C (SIGINT) trigava INT trap que chamava `cleanup()` que fazia `exit 0`. Convencao: SIGINT = exit 130.

**Fix:** Separar EXIT trap de INT/TERM trap. INT/TERM usam `signal_cleanup` com exit 130/143.
**Phase:** 16 | **Ref:** 16-RESEARCH.md, setup.sh:73

---

## 2. Bash Scripting

### 2.1 Readonly Variable Collision on Re-Source
`config.sh` declara `readonly DATA_DIR`. Quando `packages.sh` e re-sourced, tenta redeclarar e bash erro: "readonly variable".

**Fix:** Guard com `if [[ -z "${DATA_DIR:-}" ]]; then DATA_DIR="..."; readonly DATA_DIR; fi`
**Phase:** 12 | **Ref:** 12-RESEARCH.md

### 2.2 Dangling References After Module Consolidation
Migracao de `scripts/utils/` para `src/core/` deixa referencias orfas se nao atualizar sistematicamente.

**Fix:** `git mv` para historico + grep no projeto inteiro por paths antigos antes de commitar.
**Phase:** 02 | **Ref:** 02-RESEARCH.md

### 2.3 Source Guard Collision in Tests
Se um modulo usa `_SOURCED_FLAG` como guard, ele persiste entre testes a menos que explicitamente resetado.

**Fix:** bats-core roda cada `@test` em subshell fresco -- guards nao persistem. Usar `unset` se testar re-source.
**Phase:** 14 | **Ref:** 14-RESEARCH.md

### 2.4 SCRIPT_DIR Overwrites After load_packages()
`packages.sh` reatribui `SCRIPT_DIR` para sua propria localizacao. Caller perde referencia ao SCRIPT_DIR original.

**Fix:** Usar `LINUX_DIR` ou `MACOS_DIR` nos orchestrators em vez de SCRIPT_DIR apos source packages.sh.
**Phase:** 05 | **Ref:** 05-RESEARCH.md

---

## 3. Package Management

### 3.1 Flatpak Short Names vs Full IDs
Flatpak requer IDs reverse-DNS completos (`com.slack.Slack`). Nomes curtos falham silenciosamente. **80% das entradas em flatpak.txt estavam quebradas.**

**Fix:** `flatpak search <name>` para descobrir IDs corretos. Nunca usar nomes curtos.
**Exemplos:** `slack` -> `com.slack.Slack`, `zoom` -> `us.zoom.Zoom`, `calibre` -> `com.calibre_ebook.calibre`
**Phase:** 15 | **Ref:** research-flatpak-bash32.md

### 3.2 Flatpak Discontinued Apps
Apps removidos do Flathub causam falha silenciosa: Skype (arquivado Jul 2025), TogglDesktop (404).

**Fix:** Remover entradas descontinuadas periodicamente. Verificar no Flathub antes de atualizar listas.
**Phase:** 15 | **Ref:** research-flatpak-bash32.md

### 3.3 APT Lock Contention
`apt-get install` sem lock handling falha se outro processo apt esta rodando.

**Fix:** `apt-get install -o DPkg::Lock::Timeout=60` em vez de polling manual do lock file.
**Phase:** 07 | **Ref:** ADR-007

### 3.4 Snap Reinstalls Reset Configuration
`snap install` em snap ja instalado pode resetar configuracao do app.

**Fix:** Checar idempotencia antes: `if is_installed "$pkg"; then return 0; fi`
**Phase:** 07 | **Ref:** ADR-007

---

## 4. Bash Version Compatibility

### 4.1 Bash 3.2 on macOS -- Chicken-and-Egg
macOS vem com Bash 3.2.57 (GPLv3 licensing). `verify_bash_version()` bloqueava execucao, mas Homebrew (que instala Bash 5.x) e exatamente o que o script precisa instalar.

**Fix:** Warn instead of block no macOS. O codebase inteiro e Bash 3.2 compativel (sem associative arrays, mapfile, etc).
**Phase:** 15 | **Ref:** research-flatpak-bash32.md

### 4.2 BASH_VERSINFO is Readonly
Nao e possivel mockar `BASH_VERSINFO` em testes porque e readonly. Path de falha de `verify_bash_version()` nao testavel em Bash 5.x.

**Fix:** Aceitar como limitacao. Testar apenas o path de sucesso. Documentar com skip no test.
**Phase:** 17 | **Ref:** 17-RESEARCH.md

---

## 5. curl|sh Security

### 5.1 Partial Download Execution
`curl ... | sh` interrompido no meio executa script truncado. Ex: `rm -rf /tmp/build_` cortado para `rm -rf /`.

**Fix:** `safe_curl_sh()` faz download para temp file antes de executar.
**Phase:** 16 | **Ref:** 16-RESEARCH.md, ADR-009

### 5.2 Security Theater -- SHA256 Verification
Verificar SHA256 contra hash hospedado no mesmo servidor nao e seguranca. Se o servidor e comprometido, o hash tambem e.

**Fix:** Nenhum dos 5 upstreams (rustup, cargo-binstall, fnm, uv, ollama) publica checksums estaveis. Nao implementar.
**Phase:** 16 | **Ref:** research-curl-security.md, ADR-009

### 5.3 Curl Flags -- TLS Enforcement
rustup usa `--proto '=https' --tlsv1.2`. Helper generico pode dropar essas flags.

**Fix:** `-fsSL` enforces HTTPS+TLS implicitamente. Suficiente para o caso de uso.
**Phase:** 16 | **Ref:** research-curl-security.md

### 5.4 Temp File Cleanup on Failure
Interrupcao entre download e cleanup acumula temp files.

**Fix:** `trap 'rm -f "$tmp"' RETURN` ou `trap ... EXIT` para cleanup.
**Phase:** 16 | **Ref:** research-curl-security.md

---

## 6. Flag & Boolean Handling

### 6.1 VERBOSE Boolean Comparison Incorrect
`if [[ -n "$VERBOSE" ]]` e true se VERBOSE="false". Precisa ser `== "true"`.

**Fix:** Sempre usar `[[ "${VERBOSE:-}" == "true" ]]` para flags booleanas.
**Phase:** 11 | **Ref:** 11-RESEARCH.md FLAG-01

### 6.2 DRY_RUN Guard Placement
`safe_curl_sh()` poderia executar em dry-run mode se guard no lugar errado.

**Fix:** DRY_RUN guard fica no caller, nao no helper. Helper e low-level e nao sabe de DRY_RUN.
**Phase:** 16 | **Ref:** 16-RESEARCH.md

### 6.3 NONINTERACTIVE vs INTERACTIVE Mismatch
Semanticas opostas em diferentes partes do codebase.

**Fix:** Bridge variable que normaliza ambos patterns. config.sh para env-var path, setup.sh para -y flag path.
**Phase:** 11 | **Ref:** 11-RESEARCH.md FLAG-02

---

## 7. Dotfiles & Symlinks

### 7.1 zsh-syntax-highlighting Loading Order
DEVE ser sourced LAST, apos todos os plugins. Antes de zsh-autosuggestions causa conflitos.

**Fix:** Ordem estrita: path, env, aliases, functions, plugins, prompt, syntax-highlighting, local.
**Phase:** 03 | **Ref:** 03-02-SUMMARY.md

### 7.2 macOS readlink -f Not Supported
macOS `readlink` nao suporta `-f` flag.

**Fix:** Fallback: `readlink -f "$path" 2>/dev/null || readlink "$path"`
**Phase:** 03 | **Ref:** 03-02-SUMMARY.md

### 7.3 Flat Backup Naming Loses Hierarchy
`~/.config/git/ignore` vira `config-git-ignore.bak.2026-02-05` -- hierarquia perdida.

**Fix:** Mitigado com `backup-manifest.txt` que tracka timestamps e paths originais.
**Phase:** 03 | **Ref:** ADR-005

---

## 8. PowerShell / Windows

### 8.1 Separate Process Context
Scripts invocados via `& "$path"` (nao dot-sourced) nao herdam estado de modulos. Cada script DEVE `Import-Module` independentemente.

**Phase:** 12 | **Ref:** 12-RESEARCH.md DRY-02

### 8.2 Execution Policy Blocking
`setup.ps1` pode nao rodar sem `-ExecutionPolicy Bypass`.

**Fix:** Documentar: `powershell -ExecutionPolicy Bypass -File .\setup.ps1`
**Phase:** 14 | **Ref:** 14-RESEARCH.md

### 8.3 Kite Package Discontinued
`kite.kite` no winget nao existe mais (Kite shut down).

**Fix:** Remover de todas as package lists (winget.txt, winget-post.txt).
**Phase:** 11 | **Ref:** 11-RESEARCH.md FLAG-03

---

## 9. Testing

### 9.1 Never Call Real Package Managers in Tests
Nunca chamar `apt install`, `brew install`, `dpkg -s` em testes. Mockar com funcoes shell.

**Fix:** `dpkg() { return 0; }` ou testar apenas o path logico.
**Phase:** 14 | **Ref:** 14-RESEARCH.md

### 9.2 Tests Must Not Depend on System State
Testes nao podem depender de pacotes realmente instalados. Devem ser environment-independent.

**Fix:** Fixtures e mocks em vez de estado real do sistema.
**Phase:** 14 | **Ref:** 14-RESEARCH.md

### 9.3 HOME Override Timing for dotfiles.sh
HOME deve ser overridden ANTES de sourcing dotfiles.sh porque BACKUP_DIR e MANIFEST_FILE sao expandidos no source-time.

**Fix:** `export HOME="$tmpdir"` antes de `source dotfiles.sh`, nao depois.
**Phase:** 17 | **Ref:** 17-RESEARCH.md Pitfall 4

### 9.4 ((count++)) Returns Exit Code 1 on Zero
Bash arithmetic `((count++))` retorna exit code 1 quando count e 0 (valor falsy).

**Fix:** Usar `count=$((count + 1))` em vez de `((count++))`.
**Phase:** 17 | **Ref:** 17-02-SUMMARY.md

### 9.5 uname Mock Must Dispatch on $1
Mock de `uname` precisa tratar `-s` (OS) e `-m` (arch) separadamente.

**Fix:** `uname() { case "$1" in -s) echo "Linux";; -m) echo "x86_64";; esac; }`
**Phase:** 17 | **Ref:** 17-RESEARCH.md Pitfall 1

---

## 10. Architecture

### 10.1 ARCHITECTURE.md vs ADR-001 Contradiction
ARCHITECTURE.md diz "set -euo pipefail at top of every script" mas ADR-001 diz "No set -e anywhere".

**Fix:** Atualizar ARCHITECTURE.md para refletir decisao real: "No set -e. pipefail quando necessario."
**Phase:** 11 | **Ref:** 11-RESEARCH.md FLAG-04

### 10.2 EXTRA_PACKAGES/SKIP_PACKAGES Declared But Unused
Declaradas em config.sh como arrays vazios, nunca consumidas por nenhum installer.

**Fix:** Documentar honestamente como "declared for future use" ou implementar consumo.
**Phase:** 14 | **Ref:** 14-RESEARCH.md

---

## 11. Senior Dev Review (v4.2 Post-Audit)

### 11.1 cargo.txt Silently Skipped on macOS
`macos/main.sh` skipped `cargo.txt` with a debug log, even though `cargo.sh` is cross-platform (uses `cargo install`, no Linux-specific code). Result: cargo packages never installed on macOS.

**Fix:** Moved `cargo.sh` from `src/platforms/linux/install/` to `src/install/` (shared cross-platform location). Updated both `linux/main.sh` and `macos/main.sh` to dispatch cargo.txt. Updated `count_platform_steps()` to count cargo.txt for macOS.
**Phase:** Post v4.2 audit

### 11.2 Stale SCRIPT_DIR Comment in Platform Orchestrators
`linux/main.sh` and `macos/main.sh` had comments saying "packages.sh overwrites SCRIPT_DIR" — but packages.sh was already fixed (uses `_PACKAGES_DIR` internally). Comments were misleading.

**Fix:** Updated comments to explain the real reason: avoiding readonly collisions across sourced scripts.
**Phase:** Post v4.2 audit

### 11.3 Trap Chain Clarity (setup.sh vs platform main.sh)
`setup.sh` defines a cleanup trap, then calls `bash "$linux_main"` which defines its own. Not a bug (subshell isolation), but the comment "prevent double summary" didn't explain the architecture.

**Fix:** Replaced comment with clear explanation of orchestrator/subshell trap architecture and FAILURE_LOG cross-process propagation.
**Phase:** Post v4.2 audit

### 11.4 verify_all() Appeared Undefined — False Positive
`setup.sh` calls `verify_all()` which lives in `src/core/platform.sh:299`. The source chain (`setup.sh` → `config.sh` → `platform.sh`) loads it correctly. No fix needed.
**Phase:** Post v4.2 audit (documented only)

### 11.5 terminal-setup.sh Root Wrapper — Not Orphan
`terminal-setup.sh` at project root is a 1-line convenience wrapper: `exec bash terminal/setup.sh "$@"`. Intentional design for easy `bash terminal-setup.sh` invocation.
**Phase:** Post v4.2 audit (documented only)

---

## Summary

| Categoria | Count | Severidade |
|-----------|-------|------------|
| Exit Codes / Error Handling | 5 | CRITICAL |
| Bash Scripting | 4 | HIGH |
| Package Management | 4 | HIGH |
| Bash Version Compatibility | 2 | MEDIUM |
| curl\|sh Security | 4 | MEDIUM |
| Flag & Boolean Handling | 3 | HIGH |
| Dotfiles & Symlinks | 3 | MEDIUM |
| PowerShell / Windows | 3 | HIGH |
| Testing | 5 | MEDIUM |
| Architecture | 2 | MEDIUM |
| Senior Dev Review (v4.2) | 5 | MEDIUM |
| **Total** | **40** | |

---
*Compiled from Phases 1-17 research, plans, summaries, verifications, and ADRs*
*Last updated: 2026-02-25*
