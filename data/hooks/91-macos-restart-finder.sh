#!/usr/bin/env bash
# Hook: Restart Finder to apply defaults changes
# Platform: macOS only (filtered by naming convention)

if [[ "${DRY_RUN:-}" == "true" ]]; then
    echo "[DRY_RUN] Would restart Finder"
    exit 0
fi

killall Finder 2>/dev/null || true
