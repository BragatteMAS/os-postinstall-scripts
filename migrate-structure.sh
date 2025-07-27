#!/usr/bin/env bash
# migrate-structure.sh - Reorganize repository structure
# This script migrates the repository to a cleaner, more organized structure
# Author: Bragatte, M.A.S
# Version: 1.0.0

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}🚀 Starting repository structure migration...${NC}"

# Create backup
BACKUP_DIR=".backup-structure-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}📦 Creating backup in $BACKUP_DIR...${NC}"
mkdir -p "$BACKUP_DIR"

# Function to create directory if it doesn't exist
create_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo -e "${GREEN}✓${NC} Created $dir"
    fi
}

# Function to move file/directory safely
move_safely() {
    local src="$1"
    local dst="$2"
    
    if [[ -e "$src" ]]; then
        # Create destination directory if needed
        local dst_dir=$(dirname "$dst")
        create_dir "$dst_dir"
        
        # Backup original
        cp -r "$src" "$BACKUP_DIR/" 2>/dev/null || true
        
        # Move file
        mv "$src" "$dst"
        echo -e "${GREEN}✓${NC} Moved $src → $dst"
    else
        echo -e "${YELLOW}⚠${NC} Skipped $src (not found)"
    fi
}

# Function to create symlink for compatibility
create_symlink() {
    local target="$1"
    local link="$2"
    
    if [[ -e "$target" ]] && [[ ! -e "$link" ]]; then
        ln -s "$target" "$link"
        echo -e "${GREEN}✓${NC} Created symlink $link → $target"
    fi
}

echo -e "\n${BLUE}📁 Creating new directory structure...${NC}"

# Create main directories
create_dir "scripts/install"
create_dir "scripts/setup"
create_dir "scripts/utils"
create_dir "platforms/linux"
create_dir "platforms/macos"
create_dir "platforms/windows"
create_dir "configs/profiles"
create_dir "configs/templates/git"
create_dir "configs/shell"
create_dir "docs/guides"
create_dir "docs/architecture"
create_dir "docs/contributing"
create_dir "tests/unit"
create_dir "tests/integration"
create_dir "tools/dev"
create_dir "tools/check"
create_dir "tools/update"
create_dir "share/examples"
create_dir "share/exports"

echo -e "\n${BLUE}📦 Moving install scripts...${NC}"
move_safely "install_ai_tools.sh" "scripts/install/ai-tools.sh"
move_safely "install_bmad.sh" "scripts/install/bmad.sh"
move_safely "install_rust_tools.sh" "scripts/install/rust-tools.sh"
move_safely "install_product_focused_git.sh" "scripts/install/git-focused.sh"

echo -e "\n${BLUE}📦 Moving setup scripts...${NC}"
move_safely "setup.sh" "scripts/setup/main.sh"
move_safely "setup-with-profile.sh" "scripts/setup/with-profile.sh"
move_safely "setup-ai-project.sh" "scripts/setup/ai-project.sh"

echo -e "\n${BLUE}📦 Consolidating utilities...${NC}"
# Merge logging.sh files
if [[ -f "lib/logging.sh" ]] || [[ -f "utils/logging.sh" ]]; then
    cat > "scripts/utils/logging.sh" << 'EOF'
#!/usr/bin/env bash
# Consolidated logging utilities
# Merged from lib/logging.sh and utils/logging.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Export functions
export -f log log_error log_warning log_success
EOF
    chmod +x "scripts/utils/logging.sh"
    echo -e "${GREEN}✓${NC} Created consolidated scripts/utils/logging.sh"
fi

move_safely "utils/package-manager-safety.sh" "scripts/utils/package-safety.sh"
move_safely "utils/profile-loader.sh" "scripts/utils/profile-loader.sh"

# Remove old directories
[[ -d "lib" ]] && rm -rf "lib"
[[ -d "utils" ]] && rm -rf "utils"

echo -e "\n${BLUE}📦 Moving platform-specific code...${NC}"
# Linux platform
if [[ -d "linux" ]]; then
    cp -r linux/* "platforms/linux/" 2>/dev/null || true
    rm -rf "linux"
    echo -e "${GREEN}✓${NC} Moved linux/ → platforms/linux/"
fi

# macOS platform
if [[ -d "mac" ]]; then
    cp -r mac/* "platforms/macos/" 2>/dev/null || true
    rm -rf "mac"
    echo -e "${GREEN}✓${NC} Moved mac/ → platforms/macos/"
fi

# Windows platform
if [[ -d "windows" ]]; then
    cp -r windows/* "platforms/windows/" 2>/dev/null || true
    rm -rf "windows"
    echo -e "${GREEN}✓${NC} Moved windows/ → platforms/windows/"
fi

echo -e "\n${BLUE}📦 Moving configurations...${NC}"
# Profiles
if [[ -d "profiles" ]]; then
    cp -r profiles/* "configs/profiles/" 2>/dev/null || true
    rm -rf "profiles"
    echo -e "${GREEN}✓${NC} Moved profiles/ → configs/profiles/"
fi

# Git templates
if [[ -d "global-git-templates" ]]; then
    cp -r global-git-templates/* "configs/templates/git/" 2>/dev/null || true
    rm -rf "global-git-templates"
    echo -e "${GREEN}✓${NC} Moved global-git-templates/ → configs/templates/git/"
fi

# Shell configs
move_safely "zshrc" "configs/shell/zshrc"
move_safely "zshrc_rust_integration.zsh" "configs/shell/zshrc-rust.zsh"

echo -e "\n${BLUE}📦 Moving tools...${NC}"
move_safely "check_ai_tools.sh" "tools/check/ai-tools.sh"
move_safely "update_bmad.sh" "tools/update/bmad.sh"

# Move local-dev tools
if [[ -d "tools/local-dev" ]]; then
    cp -r tools/local-dev/* "tools/dev/" 2>/dev/null || true
    rm -rf "tools/local-dev"
    echo -e "${GREEN}✓${NC} Moved tools/local-dev/ → tools/dev/"
fi

echo -e "\n${BLUE}📦 Reorganizing documentation...${NC}"
# Move non-essential markdown files from root to docs
for file in QUICKSTART-AI.md PRODUCT_FOCUSED_COMMITS.md MIGRATION_PT_EN.md CLAUDE-EXTENDED.md; do
    if [[ -f "$file" ]]; then
        move_safely "$file" "docs/guides/$file"
    fi
done

# Move docs subdirectories
if [[ -d "docs/plans" ]]; then
    mv docs/plans "docs/architecture/"
    echo -e "${GREEN}✓${NC} Moved docs/plans/ → docs/architecture/plans/"
fi

if [[ -d "docs/agentic-tools" ]]; then
    mv docs/agentic-tools "docs/guides/"
    echo -e "${GREEN}✓${NC} Moved docs/agentic-tools/ → docs/guides/agentic-tools/"
fi

echo -e "\n${BLUE}🔗 Creating compatibility symlinks...${NC}"
# Create symlinks in root for backward compatibility
create_symlink "scripts/setup/main.sh" "setup.sh"
create_symlink "configs/shell/zshrc" ".zshrc"

# Create README in each main directory
echo -e "\n${BLUE}📝 Creating README files...${NC}"

cat > "scripts/README.md" << 'EOF'
# Scripts Directory

This directory contains all executable scripts organized by function.

## Structure

- `install/` - Installation scripts for various tools
- `setup/` - System setup and configuration scripts
- `utils/` - Shared utility functions and helpers

## Usage

All scripts can be executed directly or through the main `setup.sh` in the root directory.
EOF

cat > "platforms/README.md" << 'EOF'
# Platform-Specific Code

This directory contains platform-specific implementations.

## Supported Platforms

- `linux/` - Linux distributions (Ubuntu, Fedora, Arch, etc.)
- `macos/` - macOS specific scripts and configurations
- `windows/` - Windows PowerShell scripts and batch files

Each platform directory maintains its own structure and documentation.
EOF

cat > "configs/README.md" << 'EOF'
# Configuration Files

Central location for all configuration files.

## Structure

- `profiles/` - Installation profiles (YAML)
- `templates/` - Reusable templates (git hooks, etc.)
- `shell/` - Shell configurations (zshrc, bashrc, etc.)

## Usage

These configurations are loaded by the setup scripts as needed.
EOF

echo -e "${GREEN}✓${NC} Created README files"

echo -e "\n${BLUE}🔄 Updating script imports...${NC}"
# Update source/import paths in scripts
find scripts -name "*.sh" -type f -exec sed -i.bak \
    -e 's|source.*utils/logging\.sh|source "${SCRIPT_DIR}/../utils/logging.sh"|g' \
    -e 's|source.*lib/logging\.sh|source "${SCRIPT_DIR}/../utils/logging.sh"|g' \
    -e 's|\.\./\.\./utils/|../utils/|g' \
    {} \;

# Remove backup files
find scripts -name "*.sh.bak" -type f -delete

echo -e "\n${GREEN}✅ Migration completed successfully!${NC}"
echo -e "\n${YELLOW}📋 Next steps:${NC}"
echo "1. Review the new structure"
echo "2. Test that all scripts still work"
echo "3. Update any documentation references"
echo "4. Commit the changes with tag v3.0.0"
echo -e "\n${BLUE}💾 Backup saved in: $BACKUP_DIR${NC}"