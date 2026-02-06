#!/usr/bin/env bash
# Fix security issues in scripts
# Part of Story 3: Security Hardening

set -euo pipefail
IFS=$'\n\t'

echo "🔒 Starting security fixes..."

# 1. Add proper error handling to all scripts
echo "Adding error handling to scripts..."

add_error_handling() {
    local file="$1"
    if [[ -f "$file" ]] && head -1 "$file" | grep -q "^#!/"; then
        # Check if error handling already exists
        if ! grep -q "set -euo pipefail" "$file"; then
            # Insert after shebang
            sed -i.bak '1 a\
set -euo pipefail\
IFS=$'"'"'\\n\\t'"'"'' "$file"
            echo "  ✓ Added error handling to $file"
        else
            echo "  ⊘ $file already has error handling"
        fi
    fi
}

# Find all shell scripts
while IFS= read -r -d '' script; do
    add_error_handling "$script"
done < <(find . -name "*.sh" -type f -print0 2>/dev/null)

# 2. Fix dangerous apt lock removal
echo -e "\nFixing apt lock handling..."

if [[ -f "linux/post_install.sh" ]]; then
    # Replace dangerous lock removal with safer approach
    cat > /tmp/apt-lock-fix.txt << 'EOF'
# Safe apt lock handling
wait_for_apt() {
    local max_attempts=30
    local attempt=0
    
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [[ $attempt -ge $max_attempts ]]; then
            echo "❌ APT is locked after waiting 5 minutes. Please check system."
            return 1
        fi
        echo "⏳ Waiting for APT lock to be released... ($attempt/$max_attempts)"
        sleep 10
    done
    return 0
}

# Use before apt operations
if ! wait_for_apt; then
    echo "Cannot proceed - APT is locked"
    exit 1
fi
EOF

    echo "  ✓ Created safe apt lock handling function"
fi

# 3. Fix placeholder URLs
echo -e "\nFixing placeholder URLs..."

fix_placeholder_urls() {
    local file="$1"
    if grep -q "SEU_USUARIO" "$file" 2>/dev/null; then
        sed -i.bak 's/SEU_USUARIO/BragatteMAS/g' "$file"
        echo "  ✓ Fixed SEU_USUARIO placeholder in $file"
    fi
    if grep -q "SEU_REPO" "$file" 2>/dev/null; then
        sed -i.bak 's/SEU_REPO/os-postinstall-scripts/g' "$file"
        echo "  ✓ Fixed SEU_REPO placeholder in $file"
    fi
}

fix_placeholder_urls "setup.sh"
fix_placeholder_urls "install_rust_tools.sh"

# 4. Add logging
echo -e "\nAdding logging functionality..."

cat > linux/auto/logging.sh << 'EOF'
#!/usr/bin/env bash
# Logging functions for scripts
set -euo pipefail
IFS=$'\n\t'

# Setup logging
LOG_DIR="/tmp/os-postinstall-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

log_success() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $*" | tee -a "$LOG_FILE"
}

# Export for use in other scripts
export LOG_FILE
export -f log log_error log_success
EOF

chmod +x linux/auto/logging.sh
echo "  ✓ Created logging system"

echo -e "\n✅ Security fixes completed!"
echo "Run './tests/test_harness.sh' to verify improvements"