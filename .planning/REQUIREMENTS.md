# Requirements: v4.1 Production Ready

**Defined:** 2026-02-19
**Source:** v3.0 Review Panel (5 specialists, media 7.8/10) + TEVO future requirements
**Core Value:** Production-ready para uso real por outros — robustez, seguranca, testes

---

## Data & Compatibility

- [x] **DATA-01**: Corrigir Flatpak IDs em flatpak.txt (20 de 24 entradas com nomes curtos invalidos)
- [x] **DATA-02**: Corrigir Flatpak IDs em flatpak-post.txt (16 de 47 entradas com nomes curtos invalidos)
- [x] **DATA-03**: Remover apps descontinuados (com.toggl.TogglDesktop removido do Flathub, com.skype.Client arquivado)
- [x] **COMPAT-01**: verify_bash_version() faz warn (nao block) no macOS — resolve chicken-and-egg com Homebrew
- [x] **QUAL-01**: `set -o pipefail` em todos os scripts executados como subshell (CONVENTIONS.md diz "every script" mas so setup.sh tem)
- [x] **QUAL-02**: Fixes menores convergentes: ValidateSet no -Profile (PS), Test-CargoInstalled multiline-safe, remover `node` de brew.txt (conflito com fnm), adicionar `fzf` a brew.txt

## Exit Codes & Security

- [x] **EXIT-01**: Exit codes semanticos: 0=sucesso, 1=falha parcial, 2=falha critica pre-flight (constantes em errors.sh/errors.psm1)
- [x] **EXIT-02**: Propagacao de exit codes: child scripts retornam codigo baseado em FAILED_ITEMS, parents trackam worst exit code
- [x] **SEC-01**: safe_curl_sh() helper — download-then-execute para prevenir partial download execution (5 call sites)
- [x] **SEC-02**: ADR-009 documentando trust model para curl|sh (HTTPS-only, sem checksum — padrao da industria)

## Test Expansion - Bash

- [x] **TEST-03**: bats tests para platform.sh (~15-18 tests: mock uname, detect_platform, verify_bash_version, verify_package_manager)
- [x] **TEST-04**: bats tests para progress.sh (~10-12 tests: show_dry_run_banner, count_platform_steps, show_completion_summary)
- [x] **TEST-05**: bats tests para dotfiles.sh (~18-22 tests: path_to_backup_name, create_dotfile_symlink, backup_with_manifest em tmpdir)
- [x] **TEST-06**: bats tests para interactive.sh (~6-8 tests: non-interactive paths de show_category_menu e ask_tool)
- [x] **TEST-07**: Profile validation tests (~4-6 tests: todos os .txt referenciados em profiles existem, sem orfaos)
- [x] **TEST-08**: Integration test setup.sh --dry-run (~5-8 tests: dry-run developer/minimal/full, --help, unknown flag)
- [x] **TEST-09**: Contract file Bash/PS parity (api-parity.txt + tests verificando que funcoes exportadas tem equivalente)

## Polish & OSS Health

- [ ] **TEST-10**: Pester tests para PS modules (~15-20 tests: logging.psm1, errors.psm1, packages.psm1, progress.psm1)
- [ ] **OSS-01**: SECURITY.md no root do repositorio (responsible disclosure policy)
- [ ] **OSS-02**: GitHub Releases formatados a partir das tags existentes (v4.0.0 no minimo)
- [ ] **OSS-03**: Demo GIF com asciinema + agg (ou placeholder melhorado no README)

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| SHA256 verification para curl\|sh | Upstreams nao publicam checksums para scripts |
| GPG signature verification | Requer gpg, keyring, key rotation — complexidade excessiva |
| Pester para idempotent.psm1 | Requer mock de winget/npm/cargo reais — setup complexo |
| TTY simulation para interactive.sh | Requer expect/unbuffer — dep pesada para valor marginal |
| CI/CD automation | Decisao explicita do owner (permanente) |
| Novas features (parallel exec, diff preview, mais distros) | Scope deste milestone e robustez, nao features |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 15 | Complete |
| DATA-02 | Phase 15 | Complete |
| DATA-03 | Phase 15 | Complete |
| COMPAT-01 | Phase 15 | Complete |
| QUAL-01 | Phase 15 | Complete |
| QUAL-02 | Phase 15 | Complete |
| EXIT-01 | Phase 16 | Complete |
| EXIT-02 | Phase 16 | Complete |
| SEC-01 | Phase 16 | Complete |
| SEC-02 | Phase 16 | Complete |
| TEST-03 | Phase 17 | Complete |
| TEST-04 | Phase 17 | Complete |
| TEST-05 | Phase 17 | Complete |
| TEST-06 | Phase 17 | Complete |
| TEST-07 | Phase 17 | Complete |
| TEST-08 | Phase 17 | Complete |
| TEST-09 | Phase 17 | Complete |
| TEST-10 | Phase 18 | Pending |
| OSS-01 | Phase 18 | Pending |
| OSS-02 | Phase 18 | Pending |
| OSS-03 | Phase 18 | Pending |

**Coverage:**
- Total requirements: 21
- Mapped to phases: 21/21
- Unmapped: 0

---
*Requirements defined: 2026-02-19 from v3.0 review panel + TEVO backlog*
