#!/bin/bash
# generate-requirements.sh - Auto-detect and generate requirements files

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}📦 Requirements Generator${NC}"
echo -e "${BLUE}========================${NC}"
echo ""

# Function to detect project type
detect_project_type() {
    local types=()
    
    # Python
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then
        types+=("python")
    fi
    
    # Node.js
    if [ -f "package.json" ]; then
        types+=("nodejs")
    fi
    
    # Ruby
    if [ -f "Gemfile" ]; then
        types+=("ruby")
    fi
    
    # Go
    if [ -f "go.mod" ]; then
        types+=("go")
    fi
    
    # Rust
    if [ -f "Cargo.toml" ]; then
        types+=("rust")
    fi
    
    # PHP
    if [ -f "composer.json" ]; then
        types+=("php")
    fi
    
    # Java/Maven
    if [ -f "pom.xml" ]; then
        types+=("maven")
    fi
    
    # Java/Gradle
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        types+=("gradle")
    fi
    
    echo "${types[@]}"
}

# Function to generate Python requirements
generate_python_requirements() {
    echo -e "${YELLOW}🐍 Generating Python requirements...${NC}"
    
    # Create requirements directory
    mkdir -p requirements
    
    # Generate base requirements
    if command -v pip &> /dev/null; then
        pip freeze > requirements/base.txt
        echo -e "${GREEN}✓ Created requirements/base.txt${NC}"
    fi
    
    # Generate development requirements
    if [ -f "requirements-dev.txt" ]; then
        cp requirements-dev.txt requirements/development.txt
    elif command -v pipreqs &> /dev/null; then
        pipreqs . --force --savepath requirements/production.txt 2>/dev/null || true
        echo -e "${GREEN}✓ Created requirements/production.txt${NC}"
    fi
    
    # Generate pip-tools files if available
    if command -v pip-compile &> /dev/null; then
        if [ -f "requirements.in" ]; then
            pip-compile requirements.in -o requirements/locked.txt
            echo -e "${GREEN}✓ Created requirements/locked.txt with pinned versions${NC}"
        fi
    fi
    
    # Create requirements README
    cat > requirements/README.md << 'EOF'
# Python Requirements

## Files
- `base.txt` - Current environment packages (pip freeze)
- `production.txt` - Production dependencies only
- `development.txt` - Development dependencies
- `locked.txt` - Pinned versions for reproducibility

## Usage
```bash
# Install production requirements
pip install -r requirements/production.txt

# Install development requirements
pip install -r requirements/development.txt

# Install exact versions
pip install -r requirements/locked.txt
```

## Updating
```bash
# Update all packages
pip install --upgrade -r requirements/base.txt

# Generate new locked file
pip-compile requirements.in -o requirements/locked.txt
```
EOF
}

# Function to generate Node.js requirements
generate_nodejs_requirements() {
    echo -e "${YELLOW}📦 Analyzing Node.js dependencies...${NC}"
    
    if [ -f "package.json" ]; then
        mkdir -p requirements
        
        # Extract dependencies
        cat > requirements/npm-dependencies.json << EOF
{
  "generated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "node_version": "$(node --version 2>/dev/null || echo 'unknown')",
  "npm_version": "$(npm --version 2>/dev/null || echo 'unknown')",
  "dependencies": $(if command -v jq &> /dev/null; then jq '.dependencies // {}' package.json; else echo '{}'; fi),
  "devDependencies": $(if command -v jq &> /dev/null; then jq '.devDependencies // {}' package.json; else echo '{}'; fi),
  "peerDependencies": $(if command -v jq &> /dev/null; then jq '.peerDependencies // {}' package.json; else echo '{}'; fi),
  "optionalDependencies": $(if command -v jq &> /dev/null; then jq '.optionalDependencies // {}' package.json; else echo '{}'; fi)
}
EOF
        
        # Generate shrinkwrap if not exists
        if [ ! -f "package-lock.json" ] && [ ! -f "npm-shrinkwrap.json" ]; then
            npm shrinkwrap --dev
            echo -e "${GREEN}✓ Created npm-shrinkwrap.json${NC}"
        fi
        
        echo -e "${GREEN}✓ Created requirements/npm-dependencies.json${NC}"
    fi
}

# Function to generate Rust requirements
generate_rust_requirements() {
    echo -e "${YELLOW}🦀 Analyzing Rust dependencies...${NC}"
    
    if [ -f "Cargo.toml" ]; then
        mkdir -p requirements
        
        # Use cargo tree to get full dependency tree
        if command -v cargo &> /dev/null; then
            cargo tree > requirements/cargo-tree.txt
            echo -e "${GREEN}✓ Created requirements/cargo-tree.txt${NC}"
            
            # Generate detailed manifest
            cargo metadata --format-version 1 > requirements/cargo-metadata.json
            echo -e "${GREEN}✓ Created requirements/cargo-metadata.json${NC}"
        fi
    fi
}

# Function to generate Go requirements
generate_go_requirements() {
    echo -e "${YELLOW}🐹 Analyzing Go dependencies...${NC}"
    
    if [ -f "go.mod" ]; then
        mkdir -p requirements
        
        # List all dependencies
        go list -m all > requirements/go-dependencies.txt
        echo -e "${GREEN}✓ Created requirements/go-dependencies.txt${NC}"
        
        # Generate detailed module info
        go mod graph > requirements/go-mod-graph.txt
        echo -e "${GREEN}✓ Created requirements/go-mod-graph.txt${NC}"
    fi
}

# Function to generate universal requirements
generate_universal_requirements() {
    echo -e "${YELLOW}📋 Generating universal requirements format...${NC}"
    
    mkdir -p requirements
    
    # Create SBOM (Software Bill of Materials) template
    cat > requirements/SBOM.json << EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$(hostname)")",
  "version": 1,
  "metadata": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "tools": [
      {
        "vendor": "Custom",
        "name": "requirements-generator",
        "version": "1.0.0"
      }
    ],
    "component": {
      "type": "application",
      "name": "$(basename $(pwd))",
      "version": "$(git describe --tags --always 2>/dev/null || echo '0.0.1')"
    }
  },
  "components": []
}
EOF
    
    echo -e "${GREEN}✓ Created requirements/SBOM.json template${NC}"
}

# Main execution
echo -e "${CYAN}🔍 Detecting project types...${NC}"
project_types=($(detect_project_type))

if [ ${#project_types[@]} -eq 0 ]; then
    echo -e "${RED}❌ No recognized project type found${NC}"
    echo -e "${YELLOW}Creating generic requirements structure...${NC}"
    generate_universal_requirements
else
    echo -e "${GREEN}✓ Detected: ${project_types[*]}${NC}"
    echo ""
    
    # Generate requirements for each type
    for type in "${project_types[@]}"; do
        case $type in
            python)
                generate_python_requirements
                ;;
            nodejs)
                generate_nodejs_requirements
                ;;
            rust)
                generate_rust_requirements
                ;;
            go)
                generate_go_requirements
                ;;
            *)
                echo -e "${YELLOW}⚠️  No specific handler for $type yet${NC}"
                ;;
        esac
    done
fi

# Always generate universal format
generate_universal_requirements

# Create main requirements README
cat > requirements/README.md << 'EOF'
# Project Requirements

> Generated: $(date +%Y-%m-%d)

## Overview
This directory contains all dependency information for the project.

## Contents
- Language-specific requirement files
- SBOM.json - Software Bill of Materials
- License analysis reports

## Updating Requirements
Run `bash .ai/scripts/generate-requirements.sh` to regenerate all files.

## License Compliance
Run `bash .ai/scripts/analyze-licenses.sh` to check license compatibility.
EOF

echo ""
echo -e "${GREEN}✅ Requirements generation complete!${NC}"
echo -e "${BLUE}📁 Files created in ./requirements/${NC}"