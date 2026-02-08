---
phase: 08-documentation
plan: 02
subsystem: docs
tags: [contributing, github-templates, community-health, shellcheck]

# Dependency graph
requires:
  - phase: 08-documentation
    plan: 01
    provides: README.md with links to CONTRIBUTING.md
provides:
  - Project-specific CONTRIBUTING.md (347 lines)
  - Updated GitHub issue templates (bug report, feature request)
  - Updated PR template with ShellCheck requirement
affects: [08-03 (link verification references these files)]

# Tech tracking
tech-stack:
  added: []
  patterns: [conventional commits guide, GitHub Flow, ShellCheck enforcement]

key-files:
  created:
    - CONTRIBUTING.md (rewritten from BMAD boilerplate)
  modified:
    - .github/ISSUE_TEMPLATE/bug_report.md
    - .github/ISSUE_TEMPLATE/feature_request.md
    - .github/pull_request_template.md
    - README.md (removed CODE_OF_CONDUCT.md reference)
    - .planning/research/PITFALLS.md (added Pitfall 14)

key-decisions:
  - "CODE_OF_CONDUCT.md removed from scope: AI content filtering blocks Contributor Covenant text generation (Pitfall 14)"
  - "CODE_OF_CONDUCT.md references removed from README.md and CONTRIBUTING.md"
  - "PR template references CONTRIBUTING.md instead of .ai/conventions/CONVENTIONS.md"
  - "ShellCheck marked as REQUIRED (bold) in PR template checklist"

patterns-established:
  - "Profile field in bug report and feature request templates"
  - "Component classification in feature request (Packages, Dotfiles, Installer, CLI/UX, Documentation)"
  - "Dry-run test step in PR template"

# Metrics
duration: multi-session
completed: 2026-02-07
---

# Phase 8 Plan 2: CONTRIBUTING.md + GitHub Templates Summary

**Project-specific CONTRIBUTING.md, updated GitHub templates with profile fields and ShellCheck enforcement**

## Performance

- **Duration:** Multi-session (content filtering interruptions)
- **Completed:** 2026-02-07
- **Tasks:** 2 of 3 completed (Task 2 descoped)
- **Files modified:** 6

## Accomplishments

- CONTRIBUTING.md rewritten from scratch: 347 lines, 11 sections, zero BMAD boilerplate
- Style guide extracted from actual codebase patterns (source guards, export -f, quoting, naming)
- Conventional Commits and GitHub Flow documented with real examples from commit history
- ShellCheck documented as mandatory requirement with install instructions and zero-warnings policy
- Bug report template updated with profile field, flags field, and --dry-run reproduction suggestion
- Feature request template updated with profile and component classification sections
- PR template updated with ShellCheck REQUIRED, CONTRIBUTING.md reference, profile tested field, dry-run test step
- AI content filtering pitfall documented as Pitfall 14 in PITFALLS.md

## Task Commits

1. **Task 1: Rewrite CONTRIBUTING.md** - `3a2ac99` (docs)
2. **Task 2: Create CODE_OF_CONDUCT.md** - DESCOPED (Pitfall 14: AI content filtering)
3. **Task 3: Update GitHub templates + cleanup** - `84eacf7` (docs)

## Files Created/Modified

- `CONTRIBUTING.md` - Complete rewrite (347 lines, 11 sections)
- `.github/ISSUE_TEMPLATE/bug_report.md` - Added profile, flags, --dry-run suggestion
- `.github/ISSUE_TEMPLATE/feature_request.md` - Added profile and component sections
- `.github/pull_request_template.md` - ShellCheck REQUIRED, CONTRIBUTING.md ref, dry-run test
- `README.md` - Removed CODE_OF_CONDUCT.md link
- `.planning/research/PITFALLS.md` - Added Pitfall 14

## Decisions Made

- CODE_OF_CONDUCT.md removed from project scope entirely after two connection drops during generation
- Pitfall 14 documents the issue for future reference: AI cannot reliably generate Contributor Covenant text
- If CODE_OF_CONDUCT.md is needed later, it should be copied manually from contributor-covenant.org

## Deviations from Plan

- Task 2 (CODE_OF_CONDUCT.md) was descoped due to AI content filtering blocking Contributor Covenant v2.1 text
- CODE_OF_CONDUCT.md references removed from README.md and CONTRIBUTING.md to avoid broken links

## Issues Encountered

- AI content filtering blocked generation of Contributor Covenant v2.1 text (contains terms about harassment, discrimination)
- Two connection drops during attempted CODE_OF_CONDUCT.md generation
- Documented as Pitfall 14 in .planning/research/PITFALLS.md

---
*Phase: 08-documentation*
*Completed: 2026-02-07*
