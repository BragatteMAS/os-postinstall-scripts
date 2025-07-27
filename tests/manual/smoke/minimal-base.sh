#!/usr/bin/env bash
# tests/manual/smoke/minimal-base.sh
# Purpose: Test minimal base installation completes in under 15 minutes
# When to run: After implementing quick start installation (Story 1.1)
# Expected time: 5 minutes for test, 15 minutes for installation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
START_TIME=$(date +%s)

# Educational mode
if [[ "${TEST_EDUCATION:-0}" == "1" ]]; then
    echo -e "${BLUE}📚 EDUCATION MODE ENABLED${NC}"
    echo
    echo -e "${BLUE}📖 What this test verifies:${NC}"
    echo "   - Minimal base includes only essential tools"
    echo "   - Installation completes in under 15 minutes"
    echo "   - All tools are accessible from PATH"
    echo "   - No errors during installation"
    echo
    echo -e "${BLUE}🔍 Why this matters:${NC}"
    echo "   - Quick setup improves developer experience"
    echo "   - Essential tools enable immediate productivity"
    echo "   - Error-free installation builds confidence"
    echo "   - PATH configuration prevents 'command not found'"
    echo
    echo -e "${BLUE}💡 What you're learning:${NC}"
    echo "   - How package managers work"
    echo "   - Why certain tools are 'essential'"
    echo "   - How PATH affects command availability"
    echo "   - What makes an installation 'successful'"
    echo
    read -p "Press Enter to continue with the test..."
    echo
fi

echo -e "${GREEN}🧪 Starting minimal base installation test...${NC}"
echo "Test started at: $(date)"
echo "Platform: $OSTYPE"
echo

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to format time
format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    echo "${minutes}m ${remaining_seconds}s"
}

# Step 1: Check prerequisites
echo -e "${BLUE}✅ Checking prerequisites...${NC}"

if [[ ! -f "$PROJECT_ROOT/setup.sh" ]]; then
    echo -e "${RED}❌ Error: setup.sh not found in project root${NC}"
    echo "Expected location: $PROJECT_ROOT/setup.sh"
    exit 1
fi

# Check if running in test mode (dry run)
if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo -e "${YELLOW}⚠️  Running in DRY RUN mode - no actual installation${NC}"
fi

# Step 2: Define minimal tools
echo -e "${BLUE}📋 Minimal base tools to verify:${NC}"
MINIMAL_TOOLS=(
    "zsh"      # Modern shell
    "git"      # Version control
    "curl"     # Downloads
    "wget"     # Alternative downloads
    "bat"      # Better cat
    "eza"      # Better ls
    "fd"       # Better find
    "rg"       # ripgrep - better grep
)

for tool in "${MINIMAL_TOOLS[@]}"; do
    echo "   - $tool"
done
echo

# Step 3: Check current state
echo -e "${BLUE}🔍 Checking current system state...${NC}"
already_installed=0
for tool in "${MINIMAL_TOOLS[@]}"; do
    if command_exists "$tool"; then
        echo "   ✓ $tool already installed"
        ((already_installed++))
    else
        echo "   ✗ $tool not found"
    fi
done

if [[ $already_installed -eq ${#MINIMAL_TOOLS[@]} ]]; then
    echo -e "${YELLOW}⚠️  All minimal tools already installed${NC}"
    echo "Consider running './setup.sh --clean' for a fresh test"
fi
echo

# Step 4: Run installation (or simulate)
echo -e "${BLUE}🚀 Running minimal base installation...${NC}"
INSTALL_START=$(date +%s)

if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "Simulating installation (15 seconds)..."
    sleep 15
    INSTALL_EXIT_CODE=0
else
    # Actually run the installer
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        "$PROJECT_ROOT/setup.sh" --minimal
        INSTALL_EXIT_CODE=$?
    else
        "$PROJECT_ROOT/setup.sh" --minimal 2>&1 | \
            grep -E '(Installing|Progress|Error|Warning)' || true
        INSTALL_EXIT_CODE=${PIPESTATUS[0]}
    fi
fi

INSTALL_END=$(date +%s)
INSTALL_TIME=$((INSTALL_END - INSTALL_START))

# Step 5: Verify installation
echo
echo -e "${BLUE}🔍 Verifying installation results...${NC}"

if [[ $INSTALL_EXIT_CODE -ne 0 ]]; then
    echo -e "${RED}❌ Installation failed with exit code: $INSTALL_EXIT_CODE${NC}"
    exit 1
fi

# Check each tool
failed_tools=()
for tool in "${MINIMAL_TOOLS[@]}"; do
    if command_exists "$tool"; then
        location=$(command -v "$tool")
        echo -e "   ${GREEN}✅ $tool installed${NC} at $location"
    else
        echo -e "   ${RED}❌ $tool not found after installation${NC}"
        failed_tools+=("$tool")
    fi
done

# Step 6: Check installation time
echo
echo -e "${BLUE}⏱️  Performance check...${NC}"
echo "Installation time: $(format_time $INSTALL_TIME)"

if [[ $INSTALL_TIME -gt 900 ]]; then  # 15 minutes = 900 seconds
    echo -e "${RED}❌ Installation took longer than 15 minutes${NC}"
    TEST_FAILED=1
else
    echo -e "${GREEN}✅ Installation completed within 15-minute target${NC}"
fi

# Step 7: Final results
echo
echo -e "${BLUE}📊 Test Summary${NC}"
echo "================================"
echo "Test duration: $(format_time $(($(date +%s) - START_TIME)))"
echo "Installation time: $(format_time $INSTALL_TIME)"
echo "Tools verified: $((${#MINIMAL_TOOLS[@]} - ${#failed_tools[@]}))/${#MINIMAL_TOOLS[@]}"

if [[ ${#failed_tools[@]} -eq 0 ]] && [[ ${TEST_FAILED:-0} -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests PASSED!${NC}"
    exit 0
else
    echo -e "${RED}❌ Test FAILED${NC}"
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        echo "Missing tools: ${failed_tools[*]}"
    fi
    exit 1
fi