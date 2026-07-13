# Status do backlog de UX do wizard — reconciliação

> **Versão:** 1.1
> **Data:** 2026-07-13 (v1.0: 2026-06-29)
> **Fonte de verdade do *status*** (o que está feito vs aberto).
> A pesquisa original — `research/wizard-ux.md` (v1.1, fev/2026) — permanece como
> benchmark BMAD e catálogo de padrões, mas seus line-refs e prioridades estão
> **defasados**: as releases v5.4.x→v5.6.0 entregaram a maior parte do backlog.
> Este doc reconcilia cada pain point contra o código atual (auditoria 2026-06-29).

---

## Resumo

| | Qtde | Pain points |
|---|---|---|
| ✅ **SHIPPED** | 8 | PP1, PP2, PP3, PP4, PP5, PP8, PP9, PP10 |
| 🚫 **WON'T-DO** | 2 | PP6 (código; docs entregues), PP7 |
| ⬜ **OPEN** | 0 | — |

As Etapas A e B estão **100% entregues**. PP8/PP9 foram fechados em 2026-06-29
(commit `3a1f2df`, via `.planning/prd-wizard-menu-ux.md`). PP6/PP7 foram
decididos como **won't-do** em 2026-07-13 após revisão por 3 pareceres
especialistas (Linux/apt, macOS/brew, Windows/winget) — ver seção final.
**Backlog de UX do wizard: ENCERRADO.**

---

## Tabela de reconciliação

| PP | Tema | Severidade orig. | Estado real | Evidência (arquivo:linha atual) | Nota |
|----|------|------------------|-------------|----------------------------------|------|
| **PP1** | Welcome/branding | MÉDIA | ✅ SHIPPED | `setup.sh:240-248` banner + descrição; `:247` tip de `--dry-run`; `:252` versão/OS detectado | Branding completo no início. |
| **PP2** | Descrição de perfis consistente cross-OS | ALTA | ✅ SHIPPED | `src/platforms/macos/main.sh:110-112` ≡ `src/platforms/linux/main.sh:84-86` (strings idênticas) | Drift entre plataformas eliminado. |
| **PP3** | Barra de progresso visual | ALTA | ✅ SHIPPED | `src/core/progress.sh:46-59` `show_progress()` com barra `█/░` + percentual | Substituiu o `[Step X/Y]` plano. |
| **PP4** | Timeout seguro | CRÍTICA | ✅ SHIPPED | `src/core/interactive.sh:60,90` via `prompt_default` (`src/core/prompt.sh:66-79`) com default explícito no texto | Default renderizado inline (não pode "mentir"); R0 entregue. |
| **PP5** | Resumo pós-install (sucessos + next steps) | MÉDIA | ✅ SHIPPED | `src/core/progress.sh:365-408` contagem + falhas + next steps condicionais (`h`, `h tools`, `welcome`) | Resumo rico, não só falhas. |
| **PP6** | Undo/rollback | MÉDIA | 🚫 WON'T-DO (código) + docs | `setup.sh:511` `unlink` (dotfiles); `docs/troubleshooting.md` § "How to Undo an Installation" ancorada em `package-state.txt` | Decisão 2026-07-13; motivos reais na seção final. |
| **PP7** | Retry integrado + visível | MÉDIA | 🚫 WON'T-DO | `src/core/errors.sh:41-65` `retry_with_backoff` (ops atômicas); continue-on-failure + summary | Decisão 2026-07-13: os três botões já existem — Skip é o default, Retry é re-rodar `setup.sh` (idempotente), Abort é Ctrl+C. |
| **PP8** | Help callout no wizard | MÉDIA | ✅ SHIPPED | `src/core/wizard.sh:111-114` hint de preview + `--dry-run`/`h` no menu; `:136` escolha inválida cita `--help` | Entregue em `3a1f2df` (2026-06-29). |
| **PP9** | Dry-run/preview surfaceado | ALTA | ✅ SHIPPED | `src/core/wizard.sh:123-129` opção `p` no menu → `preview_profile_packages()` (`:43-64`, read-only, volta ao menu) | Entregue em `3a1f2df`. Preview é self-contained (não toca `DRY_RUN` — o menu roda em subshell de command substitution). |
| **PP10** | Detecção de instalação anterior | MÉDIA | ✅ SHIPPED | `src/core/progress.sh:182-221` `detect_previous_install()` (chamado em `setup.sh:227`); state em `~/.config/os-postinstall/state`; section gating `mark_section_done`/`is_section_done` | Resumption completo (menu Continue/Reinstall/Fresh/Cancel). `src/core/state.sh` rastreia drift de pacotes. |

### Etapa C (backlog avançado) — também parcialmente entregue

| Rec. | Item | Estado real | Nota |
|------|------|-------------|------|
| R10 | CSV-driven packages | 🟡 PARTIAL | `data/packages.csv` já existe (catálogo de 52 Rust tools). Scripts de install de sistema (apt/brew) ainda não 100% CSV-driven. |
| R11 | CLI flags completas | 🟡 ~SHIPPED | `setup.sh` já tem `--help`, `--dry-run`, `--verbose`, `--profile`/posicional, `--unattended`. |

---

## Decisão final — PP6/PP7 won't-do (2026-07-13)

Decisão do owner após revisão por **3 pareceres especialistas por OS**
(Linux/apt-snap-flatpak, macOS/Homebrew, Windows/winget), todos com inspeção
do código real. Veredito unânime (3/3) nos dois itens.

### PP6 — Uninstall de pacotes: won't-do (código) + docs entregues

**Correção de premissa:** a justificativa anterior ("package managers não
distinguem instalado-pelo-script vs já-existia") estava **errada para este
repo** — `save_package_state` (`src/core/state.sh`) só grava após o guard de
idempotência + install com sucesso, então `~/.config/os-postinstall/package-state.txt`
já é a lista exata do que o script instalou de novo.

Os motivos **reais** do won't-do:

- **Cobertura parcial do tracking:** cargo (`src/core/csv.sh` não chama
  `save_package_state`), dev-env (fnm/mise/uv), npm globals e installers
  `curl|sh` não entram no state; Windows não tem state tracking nenhum. Um
  rollback ~60% confiável cria falsa confiança — pior que nenhum.
- **Linux:** `apt-get remove` arrasta reverse-dependencies; o primitivo honesto
  é `apt-mark auto` + `autoremove`, que é decisão humana, não script.
- **macOS:** `brew uninstall --cask` apaga o `.app` com dados do usuário;
  `brew bundle cleanup` é semanticamente invertido (removeria pacotes pessoais).
- **Windows:** uninstall silencioso não é garantido (EXE/NSIS abrem GUI mesmo
  com `--silent`); e um comando só-Windows quebraria a paridade cross-OS.
- Ecossistema maduro (strap, thoughtbot/laptop, brew bundle) é aditivo — nenhum
  desinstala.

**Meio-termo entregue:** `docs/troubleshooting.md` § "How to Undo an
Installation" — ancorada no `package-state.txt`, receitas por manager com os
primitivos corretos, limites documentados. Prevenção (`--dry-run`, preview `p`,
confirmação) + docs honestas > reversão automática.

### PP7 — Prompt Retry/Skip/Abort: won't-do

Os três botões **já existem** na arquitetura: **Skip** é o comportamento default
(continue-on-failure + `record_failure` + summary), **Retry** é re-rodar
`setup.sh` (idempotente — pula o que instalou, re-tenta só o que falhou; os
classifiers já dão esse hint), **Abort** é Ctrl+C (com `signal_cleanup`).
Agravantes: as falhas são majoritariamente determinísticas (retry interativo
falharia igual); prompt no meio quebra `--unattended` e o precedente da v5.4.7;
no Windows a dor real (installer pendurado) ocorre *antes* de qualquer prompt
existir — o sucessor correto lá seria timeout por job, não prompt.

**Sucessores registrados (se a dor se materializar):** timeout por pacote no
Windows + ramo `3010|reboot` no classificador do winget. Nenhum é um prompt.

---

## Procedência

- Decisão PP6/PP7 (2026-07-13): 3 pareceres de agentes especialistas por OS, cada um com inspeção independente do código (state.sh, errors.sh, apt/snap/flatpak/brew/brew-cask/winget installers).
- Auditoria de código read-only (2026-06-29), line-refs verificados no código atual — não no doc de fev/2026.
- Cross-check com `CHANGELOG.md` (v5.4.0→v5.6.0) e `docs/REFACTOR-SELECTORS.md`.
- Suíte `bats tests/*.bats` (217 casos) e `tools/lint.sh` como verificação de comportamento.
