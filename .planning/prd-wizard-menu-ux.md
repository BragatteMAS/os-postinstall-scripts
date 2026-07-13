---
type: prd
title: Wizard menu UX — help callout + dry-run preview
status: shipped
source: .planning/wizard-ux-status.md (PP8, PP9)
created: 2026-06-29
shipped: 2026-06-29 (commit 3a1f2df)
tracker: local-markdown
---

# PRD — Wizard menu UX (help callout + dry-run preview)

## Problem Statement

Ao rodar o wizard de instalação, o usuário não tem, **dentro dos menus**, como
descobrir dois recursos que já existem no projeto:

- **PP8** — que pode pedir ajuda (`h`, `--help`) ou rodar em modo seguro
  (`--dry-run`). Hoje esse callout só aparece no **resumo final**
  (`src/core/progress.sh:403-406`), tarde demais — depois da instalação.
- **PP9** — que existe um **modo preview/dry-run** que mostra o que seria
  instalado sem mudar nada. Hoje só é acessível via flag de CLI
  (`./setup.sh --dry-run`), nunca como escolha no menu de perfil. Um usuário
  novo, em modo interativo, não tem como prever o impacto antes de confirmar.

## Solution

No menu de seleção de perfil (`show_menu`), o usuário passa a ver:

1. uma **linha de hint** mencionando preview e ajuda; e
2. uma **opção `p. Preview`** que liga o modo dry-run e, ao escolher um perfil
   em seguida, mostra o que seria instalado — sem aplicar nada — e volta ao menu
   para a decisão real.

Resultado: o usuário descobre e usa o dry-run no ponto de decisão, sem precisar
conhecer flags de CLI de antemão.

## User Stories

1. Como usuário de primeira viagem, quero ver no menu de perfil uma menção a
   "preview" e "ajuda", para saber que essas opções existem antes de instalar.
2. Como usuário cauteloso, quero escolher uma opção de preview no próprio menu,
   para ver o que cada perfil instalaria sem aplicar mudanças.
3. Como usuário que rodou o preview, quero voltar ao menu de perfil, para então
   escolher o perfil real com confiança.
4. Como usuário em macOS e em Linux, quero a mesma experiência de menu nas duas
   plataformas, para não reaprender a interface ao trocar de máquina.
5. Como usuário que digita uma opção inválida no menu, quero um aviso que cite a
   ajuda (`h` / `--help`), para descobrir como me orientar.
6. Como usuário em modo não-interativo (CI/`--unattended`), quero que o hint e a
   opção de preview **não** apareçam nem atrapalhem, para o fluxo automatizado
   seguir igual.
7. Como mantenedor, quero que o menu de perfil viva em **um só lugar**
   compartilhado entre as plataformas, para que um ajuste de texto não precise
   ser replicado e nunca mais divirja (regressão histórica do PP2).
8. Como mantenedor, quero o novo comportamento coberto por testes no seam já
   existente (`interactive.sh`), para travar a regressão.

## Implementation Decisions

### Seam: `wizard.sh:select_profile_interactive` (menu único, OS-independente)

**Descoberta na implementação:** já existe um menu de perfil rico e
OS-independente — `select_profile_interactive()` em `src/core/wizard.sh`
(recebe a plataforma como argumento; usado por `setup.sh:259` para os três
sistemas). Ele já traz contagem de pacotes, estimativa de tempo, default
surfaceado (`prompt_default "Choice" "2"`), passo de confirmação com "back" e
**já sinaliza DRY-RUN** quando ativo (`wizard.sh:95-96`).

Existia, em paralelo, um menu **secundário** duplicado byte-a-byte como
`show_menu()` em `macos/main.sh` e `linux/main.sh`, alcançado só quando a
`main.sh` é rodada direto (sem `setup.sh`).

**Decisão (unificação — 1 menu no projeto):** as `main.sh` passam a chamar
`select_profile_interactive "<macos|linux>"` (mesmo padrão do `setup.sh`); o
`show_menu()` duplicado é removido. Resultado: **uma única função de menu**,
OS-independente por construção. PP8/PP9 entram uma vez nela e valem para todo
caminho de entrada.

- **Seam único:** `src/core/wizard.sh`, coberto por `tests/test-core-wizard.bats`.
- **Mudança de comportamento (aceita):** o caminho direto `bash main.sh` ganha
  contagem/confirmação/default — upgrade, não regressão. O caminho via
  `setup.sh` (que passa o perfil como arg → `main.sh` unattended) é inalterado.

### PP8 — help callout no menu

Adicionar a `select_profile_interactive` uma linha de hint (preview + ajuda,
`h`/`--dry-run`) e citar a ajuda no caso de escolha inválida (o `*)` já existe
em `wizard.sh:84-88`). Suprimir em modo não-interativo onde aplicável.

### PP9 — opção de preview (dry-run) no menu

Adicionar a opção `p` ao prompt de escolha de `select_profile_interactive`:
`p` **liga o modo preview** (`DRY_RUN=true`) e re-renderiza o menu (o bloco de
confirmação já mostra "Mode: DRY-RUN" em `wizard.sh:95-96`); ao confirmar um
perfil, o caminho `install_profile` roda em dry-run (cada sub-script já checa
`DRY_RUN` no ponto de mutação).

- **Reuso, não código novo:** aproveita `DRY_RUN`, o aviso de dry-run já
  presente em `wizard.sh`, e `show_dry_run_banner`/`install_profile`. Nenhum
  motor de preview novo.
- **Decisão de design (preview = toggle):** `p` é um *toggle de modo*, não um
  preview de um perfil pré-fixado — evita "preview de qual perfil?" e reusa o
  loop existente do menu (que já tem "back"). _Alternativa descartada:_ `p`
  perguntar qual perfil prever.
- **⚠️ Divergência na implementação (`3a1f2df`):** o design "toggle de
  `DRY_RUN`" era **inviável** — `select_profile_interactive` roda em subshell
  de command substitution (`profile=$(...)`), então um `DRY_RUN=true` setado
  ali nunca alcançaria o shell pai que instala. A implementação final adotou a
  alternativa antes descartada: `p` pergunta qual perfil prever
  (`prompt_default`, default `2`) e chama `preview_profile_packages()` —
  listagem read-only e self-contained para stderr, que volta ao menu sem tocar
  `DRY_RUN`. O dry-run de instalação completa segue via flag `--dry-run`
  (citada no hint do menu).

## Testing Decisions

- **O que é bom teste:** asserta comportamento externo da função de menu — dado
  um input, qual escolha normalizada sai e qual texto é mostrado — não detalhes
  de implementação.
- **Módulo testado:** `src/core/wizard.sh` via `tests/test-core-wizard.bats`
  (criado na unificação; cobre o mapeamento escolha→perfil, default, cancelar).
- **Prior art:** os testes de `show_category_menu`/`ask_tool` em
  `test-core-interactive.bats` (mesmo padrão de simular input e assertar
  retorno) e o estilo datado-por-versão de `test-regressions.bats`. Usar
  `run --separate-stderr` para isolar o valor (stdout) do menu (stderr).
- **Casos mínimos:** (a) menu lista a opção de preview e o hint; (b) escolher `p`
  resulta na escolha normalizada `preview` e liga `DRY_RUN`; (c) escolha inválida
  cita a ajuda; (d) em `NONINTERACTIVE`, hint/preview não quebram o fluxo;
  (e) 1/2/3/0 continuam mapeando para minimal/developer/full/exit.

## Out of Scope

- PP6 (uninstall/rollback de pacotes) e PP7 (prompt interativo Retry/Skip/Abort)
  — fora deste PRD; baixo valor / contestados (ver `wizard-ux-status.md`).
- Multiselect interativo, CSV-driven install de sistema, dependências novas
  (`gum`/`fzf`/`dialog`) — Etapa C, não aqui.
- Mudança no comportamento de dry-run dos sub-scripts — já existe e é reusado
  como está.

## Further Notes

- Sem CI (decisão do projeto): validação é `bats tests/*.bats` + `tools/lint.sh`
  manual. ShellCheck zero-warning é requisito.
- Tracker: markdown local (`.planning/`), não GitHub Issues — coerente com o
  modo solo/sem-cerimônia do repo.
