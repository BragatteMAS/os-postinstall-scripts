#!/bin/bash
set -euo pipefail
IFS=$'\n\t'# monitor-dependencies.sh - Monitor and alert on dependency changes

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔍 Dependency Monitor${NC}"
echo -e "${BLUE}====================${NC}"
echo ""

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is required but not installed.${NC}"
    echo "Install with: brew install jq (macOS) or apt install jq (Ubuntu)"
    exit 1
fi

# Configuration
MONITOR_DIR=".dependency-monitor"
ALERT_FILE="$MONITOR_DIR/alerts.log"
BASELINE_FILE="$MONITOR_DIR/baseline.json"

# Create monitoring directory
mkdir -p "$MONITOR_DIR"

# Function to generate current state
generate_current_state() {
    local state_file="$MONITOR_DIR/current-state.json"
    
    cat > "$state_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'no-git')",
  "checksums": {}
}
EOF
    
    # Add checksums of dependency files
    local files=(
        "requirements.txt"
        "requirements*.txt"
        "package.json"
        "package-lock.json"
        "Cargo.toml"
        "Cargo.lock"
        "go.mod"
        "go.sum"
        "Gemfile"
        "Gemfile.lock"
        "composer.json"
        "composer.lock"
    )
    
    for pattern in "${files[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                local checksum=$(sha256sum "$file" 2>/dev/null || shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
                # Update JSON with checksum
                jq ".checksums[\"$file\"] = \"$checksum\"" "$state_file" > "$state_file.tmp"
                mv "$state_file.tmp" "$state_file"
            fi
        done
    done
    
    echo "$state_file"
}

# Function to check for changes
check_for_changes() {
    if [ ! -f "$BASELINE_FILE" ]; then
        echo -e "${YELLOW}No baseline found. Creating initial baseline...${NC}"
        cp "$(generate_current_state)" "$BASELINE_FILE"
        return 0
    fi
    
    local current_state=$(generate_current_state)
    local changes_found=0
    
    echo -e "${CYAN}Comparing with baseline...${NC}"
    
    # Compare checksums
    for file in $(jq -r '.checksums | keys[]' "$current_state"); do
        local current_checksum=$(jq -r ".checksums[\"$file\"]" "$current_state")
        local baseline_checksum=$(jq -r ".checksums[\"$file\"]" "$BASELINE_FILE")
        
        if [ "$current_checksum" != "$baseline_checksum" ]; then
            echo -e "${RED}⚠️  Changed: $file${NC}"
            echo "[$(date)] CHANGED: $file" >> "$ALERT_FILE"
            changes_found=1
            
            # Analyze specific changes
            analyze_file_changes "$file"
        fi
    done
    
    # Check for new files
    for file in $(jq -r '.checksums | keys[]' "$current_state"); do
        if ! jq -e ".checksums[\"$file\"]" "$BASELINE_FILE" > /dev/null 2>&1; then
            echo -e "${YELLOW}➕ New dependency file: $file${NC}"
            echo "[$(date)] NEW: $file" >> "$ALERT_FILE"
            changes_found=1
        fi
    done
    
    # Check for removed files
    for file in $(jq -r '.checksums | keys[]' "$BASELINE_FILE" 2>/dev/null || echo ""); do
        if ! jq -e ".checksums[\"$file\"]" "$current_state" > /dev/null 2>&1; then
            echo -e "${RED}➖ Removed dependency file: $file${NC}"
            echo "[$(date)] REMOVED: $file" >> "$ALERT_FILE"
            changes_found=1
        fi
    done
    
    return $changes_found
}

# Function to analyze specific file changes
analyze_file_changes() {
    local file=$1
    
    case "$file" in
        package*.json)
            analyze_npm_changes "$file"
            ;;
        requirements*.txt)
            analyze_pip_changes "$file"
            ;;
        Cargo.toml|Cargo.lock)
            analyze_cargo_changes "$file"
            ;;
        go.mod|go.sum)
            analyze_go_changes "$file"
            ;;
    esac
}

# Function to analyze npm changes
analyze_npm_changes() {
    local file=$1
    echo -e "${CYAN}  Analyzing npm changes in $file...${NC}"
    
    if [ -f "$MONITOR_DIR/npm-deps-baseline.json" ] && [ "$file" = "package.json" ]; then
        # Extract current dependencies
        jq '.dependencies // {}, .devDependencies // {}' "$file" > "$MONITOR_DIR/npm-deps-current.json"
        
        # Compare
        if command -v npm-check &> /dev/null; then
            npm-check -u --skip-unused > "$MONITOR_DIR/npm-updates.txt" 2>&1 || true
            
            # Check for major version changes
            grep -E "major|breaking" "$MONITOR_DIR/npm-updates.txt" 2>/dev/null && \
                echo -e "${RED}    ⚠️  Major version changes detected!${NC}"
        fi
    fi
    
    # Update baseline
    [ "$file" = "package.json" ] && \
        jq '.dependencies // {}, .devDependencies // {}' "$file" > "$MONITOR_DIR/npm-deps-baseline.json"
}

# Function to analyze pip changes
analyze_pip_changes() {
    local file=$1
    echo -e "${CYAN}  Analyzing pip changes in $file...${NC}"
    
    if [ -f "$MONITOR_DIR/pip-baseline.txt" ]; then
        # Check for version changes
        diff -u "$MONITOR_DIR/pip-baseline.txt" "$file" | grep -E "^[+-]" | grep -v "^[+-]{3}" | while read line; do
            if [[ $line == +* ]]; then
                echo -e "${GREEN}    ➕ Added/Updated: ${line:1}${NC}"
                
                # Check if it's a major version change
                pkg_name=$(echo "${line:1}" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1)
                check_version_jump "$pkg_name" "$MONITOR_DIR/pip-baseline.txt" "$file"
            elif [[ $line == -* ]]; then
                echo -e "${RED}    ➖ Removed: ${line:1}${NC}"
            fi
        done
    fi
    
    # Update baseline
    cp "$file" "$MONITOR_DIR/pip-baseline.txt"
}

# Function to check version jumps
check_version_jump() {
    local package=$1
    local old_file=$2
    local new_file=$3
    
    local old_version=$(grep -E "^$package[=<>]" "$old_file" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+" | head -1)
    local new_version=$(grep -E "^$package[=<>]" "$new_file" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+" | head -1)
    
    if [ -n "$old_version" ] && [ -n "$new_version" ]; then
        local old_major=$(echo "$old_version" | cut -d'.' -f1)
        local new_major=$(echo "$new_version" | cut -d'.' -f1)
        
        if [ "$old_major" != "$new_major" ]; then
            echo -e "${RED}      ⚠️  Major version change: $package $old_version → $new_version${NC}"
            echo "[$(date)] MAJOR_VERSION_CHANGE: $package $old_version → $new_version" >> "$ALERT_FILE"
        fi
    fi
}

# Function to check security vulnerabilities
check_security_vulnerabilities() {
    echo -e "${CYAN}🔒 Checking for security vulnerabilities...${NC}"
    
    # Python
    if [ -f "requirements.txt" ] && command -v safety &> /dev/null; then
        echo -e "${YELLOW}  Checking Python packages...${NC}"
        safety check --json > "$MONITOR_DIR/python-vulnerabilities.json" 2>&1 || true
        
        if [ -s "$MONITOR_DIR/python-vulnerabilities.json" ]; then
            local vuln_count=$(jq '. | length' "$MONITOR_DIR/python-vulnerabilities.json" 2>/dev/null || echo "0")
            if [ "$vuln_count" -gt 0 ]; then
                echo -e "${RED}    ⚠️  Found $vuln_count vulnerabilities!${NC}"
                echo "[$(date)] SECURITY: $vuln_count Python vulnerabilities found" >> "$ALERT_FILE"
            fi
        fi
    fi
    
    # Node.js
    if [ -f "package.json" ] && command -v npm &> /dev/null; then
        echo -e "${YELLOW}  Checking npm packages...${NC}"
        npm audit --json > "$MONITOR_DIR/npm-vulnerabilities.json" 2>&1 || true
        
        local vuln_count=$(jq '.metadata.vulnerabilities.total' "$MONITOR_DIR/npm-vulnerabilities.json" 2>/dev/null || echo "0")
        if [ "$vuln_count" -gt 0 ]; then
            echo -e "${RED}    ⚠️  Found $vuln_count vulnerabilities!${NC}"
            echo "[$(date)] SECURITY: $vuln_count npm vulnerabilities found" >> "$ALERT_FILE"
        fi
    fi
}

# Function to generate report
generate_report() {
    echo -e "${CYAN}📊 Generating dependency report...${NC}"
    
    cat > "$MONITOR_DIR/dependency-report.md" << EOF
# Dependency Monitoring Report

> Generated: $(date +%Y-%m-%d %H:%M:%S)

## Summary
- Last check: $(date)
- Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'no-git')
- Changes detected: $(grep -c "$(date +%Y-%m-%d)" "$ALERT_FILE" 2>/dev/null || echo "0")

## Recent Alerts
$(tail -20 "$ALERT_FILE" 2>/dev/null || echo "No recent alerts")

## Security Status
$(if [ -f "$MONITOR_DIR/python-vulnerabilities.json" ]; then
    echo "### Python"
    echo "Vulnerabilities: $(jq '. | length' "$MONITOR_DIR/python-vulnerabilities.json" 2>/dev/null || echo "unknown")"
fi)

$(if [ -f "$MONITOR_DIR/npm-vulnerabilities.json" ]; then
    echo "### Node.js"
    echo "Vulnerabilities: $(jq '.metadata.vulnerabilities.total' "$MONITOR_DIR/npm-vulnerabilities.json" 2>/dev/null || echo "unknown")"
fi)

## Recommendations
1. Review all major version changes before updating
2. Check security vulnerabilities immediately
3. Update license analysis after changes
4. Test thoroughly after any updates

## For CI/CD Integration
Add this to your pipeline:
\`\`\`bash
bash .ai/scripts/monitor-dependencies.sh --check
\`\`\`
EOF
    
    echo -e "${GREEN}✓ Report generated: $MONITOR_DIR/dependency-report.md${NC}"
}

# Function to setup git hooks
setup_git_hooks() {
    echo -e "${CYAN}🔧 Setting up git hooks...${NC}"
    
    local hook_file=".git/hooks/pre-commit-dependencies"
    
    if [ -d ".git/hooks" ]; then
        cat > "$hook_file" << 'EOF'
#!/bin/bash
# Check for dependency changes before commit

echo "Checking dependencies..."
bash .ai/scripts/monitor-dependencies.sh --quick-check

if [ $? -ne 0 ]; then
    echo "⚠️  Dependency changes detected!"
    echo "Run: bash .ai/scripts/analyze-licenses.sh"
    echo "Continue anyway? (y/n)"
    read -r response
    [ "$response" = "y" ] || exit 1
fi
EOF
        chmod +x "$hook_file"
        echo -e "${GREEN}✓ Git hook installed${NC}"
    fi
}

# Main execution
case "${1:-}" in
    --check)
        # CI mode - exit with error if changes detected
        check_for_changes
        exit $?
        ;;
    --quick-check)
        # Quick check for git hooks
        check_for_changes
        ;;
    --setup-hooks)
        setup_git_hooks
        ;;
    *)
        # Full monitoring
        check_for_changes
        check_security_vulnerabilities
        generate_report
        
        echo ""
        echo -e "${GREEN}✅ Monitoring complete!${NC}"
        echo -e "${BLUE}💡 To update baseline: cp $MONITOR_DIR/current-state.json $BASELINE_FILE${NC}"
        ;;
esac