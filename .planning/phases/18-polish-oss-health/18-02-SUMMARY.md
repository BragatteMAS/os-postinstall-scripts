---
phase: 18-polish-oss-health
plan: 02
subsystem: oss-health
tags: [security, github-release, readme, demo]
dependency_graph:
  requires: []
  provides: [SECURITY.md, GitHub Release v4.0.0, README demo placeholder]
  affects: [README.md, GitHub Security tab, GitHub Releases page]
tech_stack:
  added: [gh release create]
  patterns: [responsible disclosure, coordinated disclosure, dry-run preview]
key_files:
  created:
    - SECURITY.md
  modified:
    - README.md
decisions:
  - "SECURITY.md uses GitHub private vulnerability reporting (not email)"
  - "v4.0.0 tag pushed to remote before release creation (was local-only)"
  - "README demo shows dry-run minimal profile output as realistic preview"
metrics:
  duration: 2 min
  completed: 2026-02-22
---

# Phase 18 Plan 02: OSS Health Artifacts Summary

SECURITY.md with responsible disclosure via GitHub private vulnerability reporting, GitHub Release v4.0.0 with curated changelog covering phases 11-14, and README demo placeholder replaced with realistic dry-run CLI output preview.

## Completed Tasks

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create SECURITY.md and GitHub Release v4.0.0 | ffc8ebe | SECURITY.md |
| 2 | Improve README demo GIF placeholder | d642a64 | README.md |

## Task Details

### Task 1: Create SECURITY.md and GitHub Release v4.0.0

Created SECURITY.md in repo root with all required sections: Supported Versions table (v4.x supported, <4.0 not), Reporting a Vulnerability with GitHub private advisory link, What to Include checklist, Response Timeline (3/7 business days), Scope (shell scripts, package logic, dotfiles, config), Out of Scope (third-party packages, upstream tools), and Disclosure Policy (coordinated, credit reporters).

Created GitHub Release for v4.0.0 with curated changelog covering phases 11-14 highlights. The v4.0.0 tag existed locally but had not been pushed to the remote -- pushed it first (Rule 3: blocking issue), then created the release successfully.

Release URL: https://github.com/BragatteMAS/os-postinstall-scripts/releases/tag/v4.0.0

### Task 2: Improve README demo GIF placeholder

Replaced the minimal "Terminal demo recording coming soon" placeholder with a realistic dry-run output preview showing:
- The `./setup.sh --dry-run minimal` command
- DRY RUN MODE banner
- Step counters [1/3], [2/3], [3/3]
- Colored log tags [INFO], [WARN], [OK]
- Setup Complete summary with duration

Preserved recording instructions in HTML comment (updated to include exact `asciinema rec` + `agg` command). Added "Record your own demo" link pointing to CONTRIBUTING.md at repo root (verified file exists, no `docs/` prefix, no broken anchor).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] v4.0.0 tag not pushed to remote**
- **Found during:** Task 1
- **Issue:** `gh release create v4.0.0` failed because the tag existed locally but had not been pushed to the remote repository
- **Fix:** Ran `git push origin v4.0.0` to push the tag, then retried release creation
- **Files modified:** None (git operation only)
- **Commit:** N/A (tag push, not a code commit)

## Verification Results

### Task 1
- [x] `test -f SECURITY.md` -- file exists in repo root
- [x] `grep -q "Reporting a Vulnerability" SECURITY.md` -- disclosure section present
- [x] `grep -q "Supported Versions" SECURITY.md` -- version table present
- [x] `gh release view v4.0.0` -- release exists with correct title

### Task 2
- [x] `grep -q 'DRY RUN MODE' README.md` -- improved placeholder present
- [x] `grep -c 'coming soon' README.md` returns 0 -- old placeholder removed
- [x] `grep -q 'asciinema rec' README.md` -- recording instructions preserved
- [x] `grep -q '(CONTRIBUTING.md)' README.md` -- link points to repo root
- [x] `grep -c 'docs/CONTRIBUTING.md' README.md` returns 0 -- no broken link

## Awaiting Human Verification

Task 3 (checkpoint:human-verify) pending user review of:
1. SECURITY.md content and formatting
2. GitHub Release at https://github.com/BragatteMAS/os-postinstall-scripts/releases/tag/v4.0.0
3. README demo section visual appearance

## Self-Check: PASSED

- FOUND: SECURITY.md
- FOUND: README.md
- FOUND: 18-02-SUMMARY.md
- FOUND: ffc8ebe (Task 1 commit)
- FOUND: d642a64 (Task 2 commit)
