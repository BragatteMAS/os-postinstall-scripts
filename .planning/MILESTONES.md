# Milestones

## v4.2 Terminal UX Polish -- SHIPPED 2026-02-23

**Commits:** 18 | **Files:** 23 changed (+1,848/-351) | **Tag:** v4.2.0

**Delivered:** Terminal UX polish via 2 rounds of multi-agent review. Shell functions system, emoji toggle, cross-platform portability, 14 HIGH+MEDIUM safety/UX fixes, dpkg reliability.

Key accomplishments:
- Terminal setup promoted to root with MAS Oceanic Theme + shell functions
- Removed cat=bat and diff=delta POSIX-shadowing aliases (pipe-breaking)
- Cross-platform portability: bash, zsh, sh/dash guard, macOS, Linux, WSL
- 14 HIGH+MEDIUM fixes from multi-agent review (leigo, power user, dev, UX)
- Emoji toggle with locale auto-detection (TERMINAL_EMOJI env var)
- dpkg -s for reliable Linux package detection

Archive: [v4.2-ROADMAP.md](milestones/v4.2-ROADMAP.md) | [v4.2-REQUIREMENTS.md](milestones/v4.2-REQUIREMENTS.md)

---

## v4.1 Production Ready -- SHIPPED 2026-02-22

**Phases:** 15-18 | **Plans:** 9 | **Commits:** 38 | **Files:** 84 changed (+9,868/-168)

**Delivered:** Production-ready codebase with semantic exit codes, 142 tests (120 bats + 22 Pester), secure curl|sh handling, SECURITY.md, Apache 2.0 license, and fork-ready documentation.

Key accomplishments:
- Fixed 36 broken Flatpak IDs + Bash 3.2 macOS compatibility
- Semantic exit codes (0/1/2) with full propagation chain
- safe_curl_sh() download-then-execute for all curl|sh sites
- 120 bats tests + 22 Pester tests (142 total, up from 37)
- SECURITY.md + GitHub Release v4.0.0 + Apache 2.0 license
- Fork-ready documentation (submodule init, test instructions, Pester prereqs)

Archive: [v4.1-ROADMAP.md](milestones/v4.1-ROADMAP.md) | [v4.1-REQUIREMENTS.md](milestones/v4.1-REQUIREMENTS.md)

---

## v3.0 Quality & Parity -- SHIPPED 2026-02-18

**Phases:** 11-14 | **Plans:** 7 | **Tag:** v4.0.0

Archive: [v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md) | [v3.0-REQUIREMENTS.md](milestones/v3.0-REQUIREMENTS.md)

---

## v2.1 Feature Completion -- SHIPPED 2026-02-17

**Phases:** 9-10.1 | **Plans:** 5

---

## v1.0 MVP -- SHIPPED 2026-02-08

**Phases:** 1-8.2 | **Plans:** 41

---
*Total: 5 milestones shipped*
