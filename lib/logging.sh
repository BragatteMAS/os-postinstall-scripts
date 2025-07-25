#!/usr/bin/env bash
# lib/logging.sh - Modern path for logging utilities
# This is a wrapper that sources the original during transition

# Source the original file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"

# Add deprecation notice when sourced from old path
if [[ "${BASH_SOURCE[0]}" == *"/utils/"* ]]; then
    echo "WARNING: utils/logging.sh is deprecated. Use lib/logging.sh instead." >&2
fi