#!/usr/bin/env bash
# Hook: Restart Dock to apply defaults changes
# Platform: macOS only (filtered by naming convention)

if [[ "${DRY_RUN:-}" == "true" ]]; then
    echo "[DRY_RUN] Would restart Dock"
    exit 0
fi

killall Dock 2>/dev/null || true
