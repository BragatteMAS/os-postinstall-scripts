#!/usr/bin/env bash
# Test script to verify migration compatibility

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing Path Migration Compatibility ==="
echo ""

echo "1. Testing old path (utils/):"
if [[ -f "${SCRIPT_DIR}/utils/logging.sh" ]]; then
    source "${SCRIPT_DIR}/utils/logging.sh"
    echo "✅ utils/logging.sh works"
    log_info "Test message from old path"
else
    echo "❌ utils/logging.sh not found"
fi

echo
echo "2. Testing new path (lib/):"
if source "${SCRIPT_DIR}/lib/logging.sh" 2>/dev/null; then
    echo "✅ lib/logging.sh works"
    log_success "Test message from new path"
else
    echo "❌ lib/logging.sh failed"
fi

echo
echo "3. Testing symlink path (lib/utils/):"
if source "${SCRIPT_DIR}/lib/utils/logging.sh" 2>/dev/null; then
    echo "✅ lib/utils/logging.sh works"
    log_warning "Test message from symlink path"
else
    echo "❌ lib/utils/logging.sh failed"
fi

echo
echo "4. Testing critical scripts still work:"

# Test setup.sh help
if bash "${SCRIPT_DIR}/setup.sh" --help >/dev/null 2>&1; then
    echo "✅ setup.sh --help works"
else
    echo "❌ setup.sh --help failed"
fi

# Test install_ai_tools.sh exists and is executable
if [[ -x "${SCRIPT_DIR}/install_ai_tools.sh" ]]; then
    echo "✅ install_ai_tools.sh is executable"
else
    echo "❌ install_ai_tools.sh not found or not executable"
fi

echo
echo "=== Migration Compatibility Test Complete ==="