#!/bin/bash
# Local linting tool for shell scripts
# Runs shellcheck locally without triggering CI/CD

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🔍 Local Shell Script Linter${NC}"
echo -e "${YELLOW}⚠️  Running locally - No CI/CD will be triggered${NC}\n"

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}❌ ShellCheck is not installed!${NC}"
    echo -e "${BLUE}Install it with:${NC}"
    echo -e "  - macOS: ${GREEN}brew install shellcheck${NC}"
    echo -e "  - Ubuntu/Debian: ${GREEN}sudo apt-get install shellcheck${NC}"
    echo -e "  - Other: Visit ${GREEN}https://github.com/koalaman/shellcheck${NC}"
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}ShellCheck version:${NC} $(shellcheck --version | grep version | cut -d' ' -f2)"
echo -e "${BLUE}Lint mode:${NC} ${LINT_MODE:-local}"

# Count scripts
total_scripts=$(find . -name "*.sh" -type f | grep -v node_modules | wc -l)
echo -e "${BLUE}Found ${total_scripts} shell scripts to check${NC}\n"

# Run shellcheck on all scripts
errors=0
warnings=0
checked=0

find . -name "*.sh" -type f | grep -v node_modules | sort | while read -r script; do
    ((checked++))
    echo -n "Checking $script... "
    
    # Run shellcheck and capture output
    if output=$(shellcheck "$script" 2>&1); then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "$output" | while IFS= read -r line; do
            if [[ $line == *"error"* ]]; then
                echo -e "  ${RED}└─ $line${NC}"
                ((errors++))
            elif [[ $line == *"warning"* ]]; then
                echo -e "  ${YELLOW}└─ $line${NC}"
                ((warnings++))
            else
                echo -e "  ${BLUE}└─ $line${NC}"
            fi
        done
    fi
done

# Summary
echo -e "\n${PURPLE}Summary:${NC}"
echo -e "Scripts checked: $checked"
echo -e "Errors found: ${errors:-0}"
echo -e "Warnings found: ${warnings:-0}"

if [ "${errors:-0}" -eq 0 ] && [ "${warnings:-0}" -eq 0 ]; then
    echo -e "\n${GREEN}✅ All scripts passed linting!${NC}"
else
    echo -e "\n${YELLOW}⚠️  Issues found. Fix them before requesting CI/CD.${NC}"
fi

echo -e "\n${BLUE}Tips:${NC}"
echo -e "- Fix errors before pushing code"
echo -e "- Consider fixing warnings for better code quality"
echo -e "- Run ${GREEN}npm run dev:lint${NC} regularly during development"
echo -e "- CI/CD must be triggered manually in GitHub Actions"