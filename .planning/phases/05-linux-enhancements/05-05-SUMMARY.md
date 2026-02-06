---
phase: 05-linux-enhancements
plan: 05
subsystem: installer
tags: [ai-tools, npm, ollama, claude-code, codex, gemini-cli, prefix-dispatch]

# Dependency graph
requires:
  - phase: 05-03
    provides: "interactive.sh with show_category_menu() and ask_tool()"
  - phase: 05-04
    provides: "fnm.sh for Node.js availability (npm depends on Node)"
provides:
  - "Cross-platform AI tools installer with prefix-based dispatch"
  - "AI CLI entries in ai-tools.txt (npm:claude-code, npm:codex, npm:gemini-cli, curl:ollama)"
  - "Updated developer.txt and full.txt profiles with all package file references"
affects: [05-06, linux-main]

# Tech tracking
tech-stack:
  added: [claude-code, codex, gemini-cli, ollama]
  patterns: [prefix-based-dispatch, npm-global-install, curl-installer]

key-files:
  created: [src/install/ai-tools.sh]
  modified: [data/packages/ai-tools.txt, data/packages/profiles/developer.txt, data/packages/profiles/full.txt]

key-decisions:
  - "Prefix-based dispatch: npm:/curl:/npx:/uv: prefixes route to different install methods"
  - "Bare words and npx:/uv: entries silently skipped (informational only, not installable targets)"
  - "Node.js availability checked before any npm install -g (warn + skip if missing)"
  - "npm list -g for idempotent npm check (not command -v, which may miss scoped packages)"

patterns-established:
  - "Prefix dispatch: case on ${entry%%:*} for multi-method installer"
  - "Installable filter: only npm: and curl: entries shown in interactive choose mode"
  - "API key info summary: show_ai_summary() for post-install guidance"

# Metrics
duration: 2min
completed: 2026-02-06
---

# Phase 5 Plan 5: AI Tools Installer Summary

**Cross-platform AI tools installer with prefix-based dispatch for npm (claude-code, codex, gemini-cli) and curl (ollama), with interactive selection and API key guidance**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-06T21:06:21Z
- **Completed:** 2026-02-06T21:08:32Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- AI tools installer with prefix-based dispatch (npm, curl, npx, uv) handling 4 different entry types
- Node.js availability guard before npm operations (warn + skip pattern)
- Interactive ollama model download offer and API key configuration summary
- Profile files updated with complete package file references for both platforms

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AI tools installer with prefix-based dispatch** - `a311d63` (feat)
2. **Task 2: Update ai-tools.txt and profile files** - `b1af359` (feat)

## Files Created/Modified
- `src/install/ai-tools.sh` - Cross-platform AI tools installer with prefix-based dispatch
- `data/packages/ai-tools.txt` - Added 3 npm AI CLI entries + 1 curl entry, preserved existing MCP/tool entries
- `data/packages/profiles/developer.txt` - Added apt-post.txt, ai-tools.txt, flatpak.txt, snap.txt references
- `data/packages/profiles/full.txt` - Added apt-post.txt, flatpak-post.txt, snap-post.txt references

## Decisions Made
- Prefix-based dispatch: `npm:` triggers `npm install -g`, `curl:` triggers tool-specific curl scripts, `npx:`/`uv:`/bare skip silently
- `npm list -g` used for idempotent check (scoped package names like `@anthropic-ai/claude-code` need npm-level check, not just `command -v`)
- Only installable entries (npm: and curl:) shown in interactive "choose" mode; others filtered out
- Existing ai-tools.txt entries (MCP servers, bmad-method, uv) fully preserved below new AI CLI section

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. API keys are user-specific and shown as info messages after installation.

## Next Phase Readiness
- AI tools installer ready for Linux main.sh orchestration (Phase 5 Plan 6)
- All cross-platform installers complete: rust-cli.sh, dev-env.sh (fnm.sh + uv.sh), ai-tools.sh
- Profile files now reference all package files for both platforms

---
*Phase: 05-linux-enhancements*
*Completed: 2026-02-06*
