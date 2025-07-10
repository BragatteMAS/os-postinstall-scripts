#!/bin/bash
set -euo pipefail
IFS=$'\n\t'# setup-scripts.sh - Ensure all scripts are properly configured

set -e

echo "🔧 Setting up scripts..."

# Make all scripts executable
chmod +x .ai/scripts/*.sh 2>/dev/null || true

# Check for missing shebangs
for script in .ai/scripts/*.sh; do
    if [ -f "$script" ]; then
        if ! head -1 "$script" | grep -q "^#!/bin/bash"; then
            echo "⚠️  Missing shebang in $script"
        fi
    fi
done

echo "✅ Scripts setup complete"