#!/usr/bin/env bash
# Manual test for configuration system
# Run this to verify the config loader is working correctly

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}=== Configuration System Test ===${NC}\n"

# Source the config loader
source "$PROJECT_ROOT/scripts/utils/config-loader.sh"

# Test 1: Create default config if needed
echo -e "${YELLOW}Test 1: Creating default configuration...${NC}"
CONFIG_TEST_FILE="$PROJECT_ROOT/configs/settings/test-settings.yaml"
create_default_config "$CONFIG_TEST_FILE"
echo ""

# Test 2: Load configuration
echo -e "${YELLOW}Test 2: Loading configuration...${NC}"
load_config "$CONFIG_TEST_FILE"
echo ""

# Test 3: Get simple values
echo -e "${YELLOW}Test 3: Getting simple configuration values...${NC}"
echo "User name: $(get_config 'user.name')"
echo "User email: $(get_config 'user.email')"
echo "Shell profile: $(get_config 'features.shell.profile')"
echo "BMAD version: $(get_config 'features.bmad.version')"
echo ""

# Test 4: Check feature flags
echo -e "${YELLOW}Test 4: Checking feature flags...${NC}"
features=(
    "features.mcps.context7"
    "features.mcps.fetch"
    "features.mcps.sequential_thinking"
    "features.mcps.serena"
    "features.bmad"
    "features.shell.modules.rust_tools"
)

for feature in "${features[@]}"; do
    if is_feature_enabled "$feature"; then
        echo -e "  ${GREEN}✓${NC} $feature is enabled"
    else
        echo -e "  ${RED}✗${NC} $feature is disabled"
    fi
done
echo ""

# Test 5: Get list values
echo -e "${YELLOW}Test 5: Getting list values...${NC}"
echo "BMAD IDEs:"
while IFS= read -r ide; do
    echo "  - $ide"
done < <(get_config_list "features.bmad.ides")
echo ""

echo "Rust tools to install:"
while IFS= read -r tool; do
    echo "  - $tool"
done < <(get_config_list "features.tools.rust.tools")
echo ""

# Test 6: Platform-specific paths
echo -e "${YELLOW}Test 6: Platform-specific paths...${NC}"
case "$OSTYPE" in
    darwin*)
        echo "Claude config: $(get_config 'paths.claude_config.macos')"
        ;;
    linux*)
        echo "Claude config: $(get_config 'paths.claude_config.linux')"
        ;;
    msys*|cygwin*)
        echo "Claude config: $(get_config 'paths.claude_config.windows')"
        ;;
esac
echo ""

# Test 7: Validate configuration
echo -e "${YELLOW}Test 7: Validating configuration...${NC}"
if validate_config; then
    echo -e "${GREEN}All validation tests passed!${NC}"
else
    echo -e "${RED}Validation failed!${NC}"
fi
echo ""

# Test 8: Print full configuration (optional)
echo -e "${YELLOW}Test 8: Full configuration dump (optional)${NC}"
echo -n "Print full configuration? (y/N): "
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    print_config
fi

# Cleanup
echo -e "\n${YELLOW}Cleaning up test files...${NC}"
rm -f "$CONFIG_TEST_FILE"

echo -e "\n${GREEN}=== Configuration system test completed! ===${NC}"