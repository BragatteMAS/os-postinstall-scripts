#!/usr/bin/env bash
#######################################
# terminal-setup.sh
# Wrapper — delegates to terminal/setup.sh
#
# Usage:
#   bash terminal-setup.sh                # full install (everything)
#   bash terminal-setup.sh --interactive  # wizard mode (choose components)
#   bash terminal-setup.sh --dry-run      # preview changes
#   bash terminal-setup.sh --migrate      # include p10k migration
#
# From: https://github.com/BragatteMAS/os-postinstall-scripts
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -f "${SCRIPT_DIR}/terminal/setup.sh" ]]; then
    exec bash "${SCRIPT_DIR}/terminal/setup.sh" "$@"
fi

echo "Error: terminal/setup.sh not found." >&2
echo "This wrapper requires the terminal/ directory." >&2
echo "Clone the full repo: git clone https://github.com/BragatteMAS/os-postinstall-scripts" >&2
exit 1
