#!/usr/bin/env bash
# Simple test to verify file structure

echo "=== Testing Migration Structure ==="
echo ""

# Test 1: Check if directories exist
echo "1. Directory Structure:"
[[ -d "utils" ]] && echo "✅ utils/ exists" || echo "❌ utils/ missing"
[[ -d "lib" ]] && echo "✅ lib/ exists" || echo "❌ lib/ missing"
[[ -L "lib/utils" ]] && echo "✅ lib/utils symlink exists" || echo "❌ lib/utils symlink missing"
[[ -d "installers" ]] && echo "✅ installers/ exists" || echo "❌ installers/ missing"

echo ""
echo "2. Critical Files:"
[[ -f "utils/logging.sh" ]] && echo "✅ utils/logging.sh exists" || echo "❌ utils/logging.sh missing"
[[ -f "utils/package-manager-safety.sh" ]] && echo "✅ utils/package-manager-safety.sh exists" || echo "❌ missing"
[[ -f "lib/logging.sh" ]] && echo "✅ lib/logging.sh exists" || echo "❌ lib/logging.sh missing"

echo ""
echo "3. Symlink Test:"
if [[ -L "lib/utils" ]]; then
    target=$(readlink "lib/utils")
    echo "✅ lib/utils -> $target"
    [[ -f "lib/utils/logging.sh" ]] && echo "✅ lib/utils/logging.sh accessible" || echo "❌ not accessible"
fi

echo ""
echo "4. Entry Points:"
[[ -x "setup.sh" ]] && echo "✅ setup.sh executable" || echo "❌ setup.sh not executable"
[[ -x "install_ai_tools.sh" ]] && echo "✅ install_ai_tools.sh executable" || echo "❌ not executable"

echo ""
echo "5. Git Status:"
git status --porcelain | head -5

echo ""
echo "=== Structure Test Complete ==="