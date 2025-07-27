#!/usr/bin/env bash
# Test script for AI tools configuration integration
# Run this manually to verify the configuration system works with ai-tools.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}=== AI Tools Configuration Test ===${NC}"
echo

# Test 1: Check config loader
echo -e "${YELLOW}Test 1: Loading configuration${NC}"
source "$REPO_ROOT/scripts/utils/config-loader.sh"

# Create test configuration
TEST_CONFIG=$(mktemp -t test-config.XXXXXX.yaml)
cat > "$TEST_CONFIG" << 'EOF'
# Test configuration
user:
  name: "test-user"
  email: "test@example.com"

features:
  mcps:
    context7:
      enabled: true
    fetch:
      enabled: false
    sequential_thinking:
      enabled: true
    serena:
      enabled: true
      path: "/test/path/uv"
      repo: "/test/repo/serena"
  
  bmad:
    enabled: true
    version: "4.32.0"
    ides:
      - "cursor"
      - "claude-code"
    interactive: false
  
  shell:
    modules:
      ai_tools: true

paths:
  claude_config:
    macos: "/test/claude/macos.json"
    linux: "/test/claude/linux.json"
    windows: "/test/claude/windows.json"
EOF

# Load test config
load_config "$TEST_CONFIG"
echo -e "${GREEN}✓ Configuration loaded${NC}"

# Test 2: Check feature detection
echo -e "\n${YELLOW}Test 2: Feature detection${NC}"

# Test MCP features
for mcp in context7 fetch sequential_thinking serena; do
    if is_feature_enabled "mcps.$mcp"; then
        echo -e "${GREEN}✓ $mcp is enabled${NC}"
    else
        echo -e "${RED}✗ $mcp is disabled${NC}"
    fi
done

# Test BMAD
if is_feature_enabled "bmad"; then
    echo -e "${GREEN}✓ BMAD is enabled${NC}"
    echo "  Version: $(get_config 'features.bmad.version')"
    # Get IDE list
    local ides=""
    for key in "${!CONFIG_@}"; do
        if [[ "$key" =~ ^CONFIG_features_bmad_ides_[0-9]+$ ]]; then
            ides="$ides ${!key}"
        fi
    done
    echo "  IDEs:$ides"
else
    echo -e "${RED}✗ BMAD is disabled${NC}"
fi

# Test AI tools module
if is_feature_enabled "shell.modules.ai_tools"; then
    echo -e "${GREEN}✓ AI tools module is enabled${NC}"
else
    echo -e "${RED}✗ AI tools module is disabled${NC}"
fi

# Test 3: Check path configuration
echo -e "\n${YELLOW}Test 3: Path configuration${NC}"
echo "Claude config paths:"
echo "  macOS: $(get_config 'paths.claude_config.macos')"
echo "  Linux: $(get_config 'paths.claude_config.linux')"
echo "  Windows: $(get_config 'paths.claude_config.windows')"

# Test 4: Dry run ai-tools.sh functions
echo -e "\n${YELLOW}Test 4: AI tools functions (dry run)${NC}"

# Source ai-tools.sh in test mode
export DRY_RUN=true
source "$REPO_ROOT/scripts/install/ai-tools.sh" 2>/dev/null || true

# Test Claude config path detection
echo -n "Testing detect_claude_config_path... "
if detect_claude_config_path 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    echo "  Detected path: $CLAUDE_CONFIG_PATH"
else
    echo -e "${RED}✗${NC}"
fi

# Test 5: Generate sample Claude config
echo -e "\n${YELLOW}Test 5: Generate sample Claude configuration${NC}"
TEMP_CLAUDE_CONFIG=$(mktemp -t claude-config.XXXXXX.json)

# Simulate configure_mcps output
cat > "$TEMP_CLAUDE_CONFIG" << 'EOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "serena": {
      "command": "/test/path/uv",
      "args": ["run", "--directory", "/test/repo/serena", "serena-mcp-server"]
    }
  }
}
EOF

echo "Generated Claude configuration:"
jq . "$TEMP_CLAUDE_CONFIG"

# Test 6: BMAD installation command
echo -e "\n${YELLOW}Test 6: BMAD installation command generation${NC}"
bmad_version=$(get_config "features.bmad.version" "latest")
first_ide=""
for key in "${!CONFIG_@}"; do
    if [[ "$key" =~ ^CONFIG_features_bmad_ides_[0-9]+$ ]]; then
        if [[ -z "$first_ide" ]]; then
            first_ide="${!key}"
        fi
    fi
done

interactive=$(get_config "features.bmad.interactive" "false")
install_args="--full --ide ${first_ide:-cursor}"
if [[ "$interactive" != "true" ]]; then
    install_args="$install_args --yes"
fi

echo "BMAD installation command:"
echo "  pnpm dlx bmad-method@$bmad_version install $install_args"

# Cleanup
echo -e "\n${YELLOW}Cleaning up...${NC}"
rm -f "$TEST_CONFIG" "$TEMP_CLAUDE_CONFIG"

echo -e "\n${GREEN}=== All tests completed ===${NC}"
echo -e "${BLUE}Note: This was a dry run. No actual installations were performed.${NC}"