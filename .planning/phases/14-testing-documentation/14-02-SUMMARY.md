---
phase: 14-testing-documentation
plan: 02
subsystem: readme-documentation
tags: [documentation, readme, extra-packages, skip-packages, windows-troubleshooting, DOC-01, DOC-02]
dependency_graph:
  requires: []
  provides: [extra-packages-docs, skip-packages-docs, windows-troubleshooting-complete]
  affects: [README.md]
tech_stack:
  added: []
  patterns: [honest-documentation, details-collapsible-format]
key_files:
  created: []
  modified:
    - README.md
decisions:
  - "EXTRA_PACKAGES/SKIP_PACKAGES documented with honest note that no installer consumes them yet"
  - "Troubleshooting uses existing collapsible <details> pattern with Problem/Solution structure"
metrics:
  duration: 1 min
  completed: 2026-02-18
---

# Phase 14 Plan 02: README Documentation Gaps Summary

Add EXTRA_PACKAGES/SKIP_PACKAGES documentation and Windows troubleshooting sections to README.md, closing DOC-01 and DOC-02 from v3.0 expert review.

## What Was Done

### Task 1: Add EXTRA_PACKAGES and SKIP_PACKAGES documentation (ecf43c0)

Added "Environment variables" subsection to the README Customization section:

- **Table** documenting both variables with type, default, and description
- **Usage examples** showing EXTRA_PACKAGES, SKIP_PACKAGES, and combined usage
- **Honest note** explaining these are declared in `config.sh` (lines 36-41) as hooks but no installer reads them automatically -- avoids misleading users per research Pitfall 6

Inserted after "Creating a custom profile" and before "Adding dotfiles" to maintain section flow.

### Task 2: Add Windows Troubleshooting sections (f198cac)

Added two new collapsible troubleshooting items using the existing `<details>` pattern:

1. **PowerShell execution policy** -- Documents the "scripts disabled" error with two solutions: `-ExecutionPolicy Bypass` (recommended, session-only) and `Set-ExecutionPolicy RemoteSigned` (permanent)
2. **PATH not updated after WinGet install** -- Documents the stale PATH issue with two solutions: reopen PowerShell (simplest) and inline PATH refresh command

Both use the existing Problem/Solution structure. The Troubleshooting section now has 7 collapsible items (5 original + 2 new), with 3 covering Windows scenarios.

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| EXTRA_PACKAGES occurrences | >= 3 | 3 |
| SKIP_PACKAGES occurrences | >= 3 | 3 |
| ExecutionPolicy occurrences | >= 2 | 5 |
| PATH not updated occurrences | >= 1 | 1 |
| Total `<details>` in README | 12 | 12 |
| Honest note about integration | present | present |

## Deviations from Plan

**[Minor] Troubleshooting `<details>` count:** Plan stated "6 total (4 existing + 2 new)" but the actual existing count was 5 items (Bash 3.2, APT lock, Permission denied, Homebrew PATH, WinGet not recognized), making the real total 7 (5 + 2). No impact on deliverables -- just a count discrepancy in the plan text.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | ecf43c0 | docs(14-02): add EXTRA_PACKAGES and SKIP_PACKAGES documentation to README |
| 2 | f198cac | docs(14-02): add Windows troubleshooting sections for execution policy and PATH |

## Self-Check: PASSED

- README.md exists on disk
- 14-02-SUMMARY.md exists on disk
- Commit ecf43c0 verified in git log
- Commit f198cac verified in git log
- All 6 verification checks pass
