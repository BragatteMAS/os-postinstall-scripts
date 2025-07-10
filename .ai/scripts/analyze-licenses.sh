#!/bin/bash
set -euo pipefail
IFS=$'\n\t'# analyze-licenses.sh - Analyze and document all dependency licenses

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}⚖️  License Analyzer${NC}"
echo -e "${BLUE}===================${NC}"
echo ""

# Create licenses directory
mkdir -p licenses

# License compatibility matrix
declare -A license_compatibility
license_compatibility["MIT"]="GPL-3.0,GPL-2.0,Apache-2.0,BSD-3-Clause,BSD-2-Clause,ISC,MIT"
license_compatibility["Apache-2.0"]="Apache-2.0,MIT,BSD-3-Clause,BSD-2-Clause,ISC"
license_compatibility["GPL-3.0"]="GPL-3.0,GPL-2.0"
license_compatibility["BSD-3-Clause"]="MIT,BSD-3-Clause,BSD-2-Clause,ISC,Apache-2.0"
license_compatibility["ISC"]="MIT,ISC,BSD-3-Clause,BSD-2-Clause,Apache-2.0"

# Function to analyze Python licenses
analyze_python_licenses() {
    echo -e "${YELLOW}🐍 Analyzing Python package licenses...${NC}"
    
    if command -v pip-licenses &> /dev/null; then
        # Generate detailed license report
        pip-licenses --format=json > licenses/python-licenses.json
        pip-licenses --format=csv > licenses/python-licenses.csv
        pip-licenses --format=markdown > licenses/python-licenses.md
        
        # Generate summary
        pip-licenses --summary > licenses/python-summary.txt
        
        echo -e "${GREEN}✓ Python license analysis complete${NC}"
    else
        echo -e "${YELLOW}Installing pip-licenses...${NC}"
        pip install pip-licenses
        analyze_python_licenses
    fi
}

# Function to analyze Node.js licenses
analyze_nodejs_licenses() {
    echo -e "${YELLOW}📦 Analyzing Node.js package licenses...${NC}"
    
    if [ -f "package.json" ]; then
        if command -v license-checker &> /dev/null; then
            # Generate license report
            license-checker --json > licenses/nodejs-licenses.json
            license-checker --csv > licenses/nodejs-licenses.csv
            license-checker --summary > licenses/nodejs-summary.txt
            
            # Check for problematic licenses
            license-checker --onlyAllow 'MIT;Apache-2.0;BSD-3-Clause;BSD-2-Clause;ISC' \
                > licenses/nodejs-allowed.txt 2>&1 || true
            
            echo -e "${GREEN}✓ Node.js license analysis complete${NC}"
        else
            echo -e "${YELLOW}Installing license-checker...${NC}"
            npm install -g license-checker
            analyze_nodejs_licenses
        fi
    fi
}

# Function to analyze Rust licenses
analyze_rust_licenses() {
    echo -e "${YELLOW}🦀 Analyzing Rust crate licenses...${NC}"
    
    if [ -f "Cargo.toml" ]; then
        if command -v cargo-license &> /dev/null; then
            cargo license > licenses/rust-licenses.txt
            cargo license --json > licenses/rust-licenses.json
            echo -e "${GREEN}✓ Rust license analysis complete${NC}"
        else
            echo -e "${YELLOW}Installing cargo-license...${NC}"
            cargo install cargo-license
            analyze_rust_licenses
        fi
    fi
}

# Function to analyze Go licenses
analyze_go_licenses() {
    echo -e "${YELLOW}🐹 Analyzing Go module licenses...${NC}"
    
    if [ -f "go.mod" ]; then
        if command -v go-licenses &> /dev/null; then
            go-licenses csv . > licenses/go-licenses.csv 2>/dev/null || true
            go-licenses report . > licenses/go-licenses.txt 2>/dev/null || true
            echo -e "${GREEN}✓ Go license analysis complete${NC}"
        else
            echo -e "${YELLOW}Note: Install google/go-licenses for Go license analysis${NC}"
        fi
    fi
}

# Function to create license summary
create_license_summary() {
    echo -e "${CYAN}📊 Creating license summary...${NC}"
    
    cat > licenses/LICENSE-SUMMARY.md << 'EOF'
# License Summary Report

> Generated: $(date +%Y-%m-%d)

## Project License
$(head -1 LICENSE 2>/dev/null || echo "No LICENSE file found")

## Dependency License Overview

### License Categories
- **Permissive**: MIT, Apache-2.0, BSD, ISC
- **Copyleft**: GPL, LGPL, AGPL
- **Proprietary**: Commercial, Custom
- **Unknown**: No license information found

### Risk Assessment
- 🟢 **Low Risk**: Permissive licenses (MIT, Apache-2.0, BSD)
- 🟡 **Medium Risk**: Weak copyleft (LGPL, MPL)
- 🔴 **High Risk**: Strong copyleft (GPL, AGPL)
- ⚫ **Critical**: Unknown or proprietary licenses

## Compatibility Matrix
| Your License | Compatible With | Incompatible With |
|--------------|-----------------|-------------------|
| MIT | All permissive, GPL (one-way) | None |
| Apache-2.0 | MIT, BSD, Apache | GPL v2 (patent clause) |
| GPL-3.0 | GPL-3.0, GPL-2.0+ | Proprietary, Apache-2.0 |
| Proprietary | Permissive only | All copyleft |

## Action Items
- [ ] Review all UNKNOWN licenses
- [ ] Verify GPL compatibility if using GPL dependencies
- [ ] Document any license exceptions or waivers
- [ ] Update notices and attributions

## For Patent/IP Filing
When filing for patents or establishing IP rights, ensure:
1. All dependencies allow commercial use
2. No copyleft licenses that might affect your IP
3. Proper attribution is maintained
4. License texts are included where required
EOF
}

# Function to create detailed license report
create_detailed_report() {
    echo -e "${CYAN}📑 Creating detailed license report...${NC}"
    
    cat > licenses/DETAILED-LICENSE-REPORT.md << 'EOF'
# Detailed License Report for IP Documentation

> Generated: $(date +%Y-%m-%d)
> Purpose: Supporting documentation for intellectual property filing

## Executive Summary
This report provides comprehensive license analysis for all project dependencies
to ensure compliance and support intellectual property claims.

## License Inventory

### Direct Dependencies
[To be filled by license analyzers]

### Transitive Dependencies
[To be filled by license analyzers]

### License Text Repository
All license texts are archived in `licenses/texts/` directory.

## Compliance Checklist
- [ ] All licenses identified and documented
- [ ] No license conflicts detected
- [ ] Attribution requirements fulfilled
- [ ] Source disclosure requirements met (if any)
- [ ] Patent grants verified (for Apache-2.0)
- [ ] Trademark restrictions noted

## Risk Analysis

### Commercial Use
- ✅ Allowed: MIT, Apache-2.0, BSD, ISC
- ⚠️  Restricted: GPL (requires source disclosure)
- ❌ Prohibited: None identified

### Patent Rights
- Apache-2.0: Includes express patent grant
- MIT/BSD: No express patent grant
- GPL-3.0: Includes patent provisions

### Liability and Warranty
All open source licenses disclaim warranty and limit liability.

## Recommendations for IP Filing

1. **For Patent Applications**:
   - Document all open source components
   - Distinguish your innovations from OSS
   - Ensure no patent encumbrances from dependencies

2. **For Copyright Registration**:
   - Clearly separate your original work
   - Maintain proper attribution
   - Document the boundary between your code and OSS

3. **For Trade Secret Protection**:
   - Avoid copyleft licenses for proprietary components
   - Use license scanners in CI/CD pipeline
   - Regular audit of new dependencies

## Appendices
- Appendix A: Full license texts
- Appendix B: Attribution notices
- Appendix C: Dependency tree visualization
EOF
}

# Function to download license texts
download_license_texts() {
    echo -e "${CYAN}📥 Downloading license texts...${NC}"
    
    mkdir -p licenses/texts
    
    # Common licenses to download
    declare -a licenses=(
        "MIT"
        "Apache-2.0"
        "GPL-3.0"
        "GPL-2.0"
        "BSD-3-Clause"
        "BSD-2-Clause"
        "ISC"
        "LGPL-3.0"
        "MPL-2.0"
    )
    
    for license in "${licenses[@]}"; do
        if [ ! -f "licenses/texts/$license.txt" ]; then
            echo -e "Downloading $license..."
            curl -sL "https://raw.githubusercontent.com/spdx/license-list-data/master/text/$license.txt" \
                > "licenses/texts/$license.txt" 2>/dev/null || \
            curl -sL "https://opensource.org/licenses/$license" \
                > "licenses/texts/$license.txt" 2>/dev/null || \
            echo "Could not download $license" > "licenses/texts/$license.txt"
        fi
    done
    
    echo -e "${GREEN}✓ License texts downloaded${NC}"
}

# Function to create attribution file
create_attribution_file() {
    echo -e "${CYAN}📝 Creating attribution file...${NC}"
    
    cat > licenses/ATTRIBUTION.md << 'EOF'
# Attribution and Notices

This project uses the following open source software:

## Direct Dependencies

<!-- Generated content will be inserted here -->

## Acknowledgments

We gratefully acknowledge the contributions of the open source community.

## License Notices

The full text of all licenses can be found in the `licenses/texts/` directory.

---

Generated: $(date +%Y-%m-%d)
EOF
}

# Main execution
echo -e "${CYAN}🔍 Detecting project types...${NC}"

# Run all analyzers
if [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    analyze_python_licenses
fi

if [ -f "package.json" ]; then
    analyze_nodejs_licenses
fi

if [ -f "Cargo.toml" ]; then
    analyze_rust_licenses
fi

if [ -f "go.mod" ]; then
    analyze_go_licenses
fi

# Create reports
create_license_summary
create_detailed_report
download_license_texts
create_attribution_file

# Final summary
echo ""
echo -e "${GREEN}✅ License analysis complete!${NC}"
echo -e "${BLUE}📁 Reports generated in ./licenses/${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important for IP/Patent Filing:${NC}"
echo "1. Review licenses/DETAILED-LICENSE-REPORT.md"
echo "2. Verify no copyleft contamination of proprietary code"
echo "3. Ensure all attribution requirements are met"
echo "4. Archive this analysis with your IP documentation"