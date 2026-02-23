#!/usr/bin/env bash
# Quick entry point — delegates to examples/terminal/setup.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
exec bash "${SCRIPT_DIR}/examples/terminal/setup.sh" "$@"
