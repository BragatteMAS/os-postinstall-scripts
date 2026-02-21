---
phase: 15-data-compatibility-fixes
plan: 01
subsystem: flatpak-data
tags: [flatpak, reverse-dns, package-ids, data-integrity, discontinued-apps]
dependency_graph:
  requires: []
  provides: [valid-flatpak-ids, clean-package-lists]
  affects: [src/platforms/linux/install/flatpak.sh]
tech_stack:
  added: []
  patterns: [reverse-dns-flatpak-ids]
key_files:
  created: []
  modified:
    - data/packages/flatpak.txt
    - data/packages/flatpak-post.txt
decisions:
  - "Skype (com.skype.Client) removed from flatpak.txt -- archived on Flathub July 2025"
  - "TogglDesktop (com.toggl.TogglDesktop) removed from flatpak-post.txt -- discontinued, 404 on Flathub"
  - "Workflow (com.gitlab.cunidev.Workflow) removed from flatpak-post.txt -- archived Dec 2023, 404 on Flathub"
  - "MasterPDFEditor uses underscore ID: net.code_industry.MasterPDFEditor (not net.codeindustry)"
metrics:
  duration: 1 min
  completed: 2026-02-21
---

# Phase 15 Plan 01: Fix Broken Flatpak IDs Summary

Replaced 36 broken short-name Flatpak entries with valid reverse-DNS application IDs across both package list files and removed 3 discontinued apps (Skype, TogglDesktop, Workflow).

## What Was Done

### Task 1: Fix Flatpak IDs and remove discontinued apps in flatpak.txt (08a3cfd)

- Replaced 20 short-name entries (e.g., `slack` to `com.slack.Slack`, `zoom` to `us.zoom.Zoom`) with verified Flathub reverse-DNS IDs
- Removed `skype` entry (archived on Flathub July 2025), added removal comment
- Updated header comment to note full reverse-DNS format requirement
- Preserved all 4 already-correct entries: `org.gnome.Boxes`, `org.blender.Blender`, `org.videolan.VLC`, `com.wps.Office`
- Result: 23 valid entries, 0 short names

### Task 2: Fix Flatpak IDs and remove discontinued apps in flatpak-post.txt (a90d336)

- Replaced 16 short-name entries (e.g., `gpuviewer` to `io.github.arunsivaramanneo.GPUViewer`, `OnionShare` to `org.onionshare.OnionShare`) with verified Flathub reverse-DNS IDs
- Removed `com.toggl.TogglDesktop` (discontinued, 404 on Flathub), added removal comment
- Removed `com.gitlab.cunidev.Workflow` (archived Dec 2023, 404 on Flathub), added removal comment
- Updated header comment to note full reverse-DNS format requirement
- Preserved all 31 already-correct entries
- Result: 47 valid entries, 0 short names

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| Short names in flatpak.txt | 0 | 0 |
| Short names in flatpak-post.txt | 0 | 0 |
| Skype active entries | 0 | 0 |
| TogglDesktop active entries | 0 | 0 |
| Workflow active entries | 0 | 0 |
| Valid entries in flatpak.txt | ~23 | 23 |
| Valid entries in flatpak-post.txt | ~47 | 47 |
| Previously-correct entries preserved | all | all |

## Deviations from Plan

None -- plan executed exactly as written.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 08a3cfd | fix(15-01): replace 20 broken short-name Flatpak IDs in flatpak.txt |
| 2 | a90d336 | fix(15-01): replace 16 broken short-name Flatpak IDs in flatpak-post.txt |

## Self-Check: PASSED

- Both modified files verified on disk
- Both commits (08a3cfd, a90d336) verified in git log
- 0 short names in both files (all reverse-DNS valid)
- 3 discontinued apps removed (Skype, TogglDesktop, Workflow)
