#!/usr/bin/env bash
# tools/lint.sh -- Run ShellCheck on all .sh files
# Usage: bash tools/lint.sh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
CHECKED=0

echo "=== ShellCheck ==="

# Find all .sh files in src/ and tests/ (excluding bats lib)
while IFS= read -r -d '' f; do
    CHECKED=$((CHECKED + 1))
    if shellcheck -x "$f" 2>&1; then
        echo "  OK: $(basename "$f")"
    else
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" \
    -name '*.sh' -type f \
    -not -path '*/lib/*' \
    -print0 2>/dev/null)

# Also check root-level shell scripts
for rootfile in "$PROJECT_ROOT/setup.sh" "$PROJECT_ROOT/config.sh"; do
    if [ -f "$rootfile" ]; then
        CHECKED=$((CHECKED + 1))
        if shellcheck -x "$rootfile" 2>&1; then
            echo "  OK: $(basename "$rootfile")"
        else
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# Optional: shfmt check (only if installed)
if command -v shfmt >/dev/null 2>&1; then
    echo ""
    echo "=== shfmt ==="
    echo "  (shfmt detected, but formatting check is informational only)"
fi

echo ""
echo "=== Results ==="
echo "Checked: $CHECKED file(s)"
if [ $ERRORS -eq 0 ]; then
    echo "All files passed ShellCheck."
    exit 0
else
    echo "$ERRORS file(s) had issues."
    exit 1
fi
