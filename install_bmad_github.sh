#!/usr/bin/env bash
# Install BMAD in .github/AI_TOOLKIT structure

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Installing BMAD in .github/AI_TOOLKIT structure...${NC}"

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    echo "Please run this from your project root"
    exit 1
fi

# Create structure
mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
mkdir -p .github/AI_TOOLKIT/{agents,commands,templates,workflows,config}
mkdir -p .github/PROJECT_DOCS/adrs

# Install BMAD to temporary location
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Install BMAD
if command -v pnpm &> /dev/null; then
    pnpm dlx bmad-method@latest install --full --ide cursor
else
    npx bmad-method@latest install --full --ide cursor
fi

# Move to correct location
cd - > /dev/null
if [[ -d "$TEMP_DIR/.bmad-core" ]]; then
    mv "$TEMP_DIR/.bmad-core"/* .github/AI_TOOLKIT/ 2>/dev/null || true
fi

# Clean up
rm -rf "$TEMP_DIR"

# Create location config
cat > .github/AI_TOOLKIT/config/location.yaml << 'CONFIG'
bmad:
  root: .github/AI_TOOLKIT
  agents: .github/AI_TOOLKIT/agents
  commands: .github/AI_TOOLKIT/commands
CONFIG

# Link CLAUDE.md if exists
if [[ -f "$HOME/CLAUDE.md" ]]; then
    ln -sf "$HOME/CLAUDE.md" .github/METHODS/CLAUDE.md
fi

echo -e "${GREEN}✅ BMAD installed in .github/AI_TOOLKIT${NC}"
echo -e "${YELLOW}📝 Don't forget to run: ./migrate_to_github.sh${NC}"
