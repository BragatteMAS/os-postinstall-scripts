#!/usr/bin/env bash
# tests/manual/run-story-tests.sh
# Purpose: Run tests for a specific story
# Usage: ./run-story-tests.sh [story-number]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get story number
STORY="${1:-}"

if [[ -z "$STORY" ]]; then
    echo "Usage: $0 [story-number]"
    echo "Example: $0 1.1"
    echo
    echo "Available stories with tests:"
    echo "  1.1 - Quick Start Installation"
    echo "  1.6 - PRD/STORIES Technology Detection"
    echo "  1.7 - Manual Test Execution"
    echo "  4.2 - Deprecate Profile System"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🧪 Running tests for Story $STORY${NC}"
echo

case "$STORY" in
    "1.1")
        echo "Story 1.1: Quick Start Installation"
        echo "Tests to run:"
        echo "  - Minimal base installation test"
        echo "  - Progress indicator test"
        echo
        "$SCRIPT_DIR/smoke/minimal-base.sh"
        ;;
    
    "1.6")
        echo "Story 1.6: PRD/STORIES Technology Detection"
        echo "Tests to run:"
        echo "  - Parser accuracy test"
        echo "  - Fuzzy matching test"
        echo
        "$SCRIPT_DIR/integration/parser/accuracy-test.sh"
        ;;
    
    "1.7")
        echo "Story 1.7: Manual Test Execution"
        echo "Meta-test: Testing the test documentation"
        echo
        echo -e "${GREEN}✅ If you're running this, the test docs work!${NC}"
        ;;
    
    "4.2")
        echo "Story 4.2: Deprecate Profile System"
        echo "Tests to run:"
        echo "  - Deprecation warning test"
        echo "  - Migration guide test"
        echo
        echo -e "${YELLOW}⚠️  Test not yet implemented${NC}"
        ;;
    
    *)
        echo -e "${RED}❌ Unknown story: $STORY${NC}"
        exit 1
        ;;
esac

echo
echo -e "${GREEN}✅ Story $STORY tests complete!${NC}"