#!/usr/bin/env bash
# Compatibility wrapper - redirects to new main.sh
set -euo pipefail
IFS=$'\n\t'

echo "Note: post_install.sh has been reorganized into main.sh"
echo "Redirecting to new structure..."
echo ""

exec "$(dirname "$0")/main.sh" "$@"
