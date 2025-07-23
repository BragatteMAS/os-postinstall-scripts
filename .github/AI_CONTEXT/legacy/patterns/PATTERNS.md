# Common Implementation Patterns

## Script Structure Patterns

### Main Script Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="1.0.0"

# Source common functions
source "${SCRIPT_DIR}/common/functions.sh"

# Main function
main() {
    parse_arguments "$@"
    validate_environment
    execute_tasks
    cleanup
}

# Run main function
main "$@"
```

### Modular Installation Pattern
```bash
# Package list definition
declare -a APT_PACKAGES=(
    "package1"
    "package2"
    "package3"
)

# Installation function
install_apt_packages() {
    log_info "Installing APT packages..."
    
    for package in "${APT_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            log_info "Installing $package..."
            sudo apt install -y "$package" || log_error "Failed to install $package"
        else
            log_info "$package is already installed"
        fi
    done
}
```

## Error Handling Patterns

### Graceful Failure Pattern
```bash
# Function with error handling
safe_install() {
    local package="$1"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if sudo apt install -y "$package" 2>/dev/null; then
            log_success "$package installed successfully"
            return 0
        else
            log_warning "Attempt $attempt failed for $package"
            ((attempt++))
            sleep 2
        fi
    done
    
    log_error "Failed to install $package after $max_attempts attempts"
    return 1
}
```

### Cleanup Pattern
```bash
# Temporary directory management
readonly TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# File download with cleanup
download_and_install() {
    local url="$1"
    local filename="$(basename "$url")"
    local filepath="${TEMP_DIR}/${filename}"
    
    if wget -q "$url" -O "$filepath"; then
        sudo dpkg -i "$filepath"
    else
        log_error "Failed to download $url"
        return 1
    fi
}
```

## User Interaction Patterns

### Confirmation Prompt Pattern
```bash
confirm() {
    local prompt="${1:-Continue?}"
    local response
    
    while true; do
        read -r -p "$prompt [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]|"") return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Usage
if confirm "Install development tools?"; then
    install_dev_tools
fi
```

### Menu Selection Pattern
```bash
show_menu() {
    echo "Select installation type:"
    echo "1) Minimal"
    echo "2) Standard"
    echo "3) Full"
    echo "4) Custom"
    echo "0) Exit"
}

handle_menu_selection() {
    local choice
    read -r -p "Enter choice [0-4]: " choice
    
    case $choice in
        1) install_minimal ;;
        2) install_standard ;;
        3) install_full ;;
        4) install_custom ;;
        0) exit 0 ;;
        *) echo "Invalid option"; return 1 ;;
    esac
}
```

## System Detection Patterns

### Distribution Detection Pattern
```bash
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VER=$(lsb_release -sr)
    else
        log_error "Cannot detect distribution"
        exit 1
    fi
    
    echo "$OS:$VER"
}

# Usage
DISTRO=$(detect_distribution)
case $DISTRO in
    ubuntu:*) source "${SCRIPT_DIR}/distros/ubuntu.sh" ;;
    pop:*) source "${SCRIPT_DIR}/distros/popos.sh" ;;
    linuxmint:*) source "${SCRIPT_DIR}/distros/mint.sh" ;;
    *) log_error "Unsupported distribution: $DISTRO" ;;
esac
```

### Architecture Detection Pattern
```bash
detect_architecture() {
    local arch=$(uname -m)
    
    case $arch in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "armhf" ;;
        *) echo "$arch" ;;
    esac
}

# Download architecture-specific package
ARCH=$(detect_architecture)
wget "https://example.com/package_${ARCH}.deb"
```

## Package Management Patterns

### Repository Management Pattern
```bash
add_repository() {
    local repo_name="$1"
    local repo_key_url="$2"
    local repo_source="$3"
    
    # Add GPG key
    wget -qO - "$repo_key_url" | sudo apt-key add -
    
    # Add repository
    echo "$repo_source" | sudo tee "/etc/apt/sources.list.d/${repo_name}.list"
    
    # Update package list
    sudo apt update
}

# Usage
add_repository "vscode" \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main"
```

### Multi-Package Manager Pattern
```bash
install_package() {
    local package="$1"
    local method="${2:-auto}"
    
    case $method in
        apt)
            sudo apt install -y "$package"
            ;;
        snap)
            sudo snap install "$package"
            ;;
        flatpak)
            flatpak install -y flathub "$package"
            ;;
        auto)
            # Try multiple methods
            if command -v apt &> /dev/null; then
                sudo apt install -y "$package" 2>/dev/null || return 1
            elif command -v snap &> /dev/null; then
                sudo snap install "$package" 2>/dev/null || return 1
            elif command -v flatpak &> /dev/null; then
                flatpak install -y flathub "$package" 2>/dev/null || return 1
            fi
            ;;
    esac
}
```

## Configuration Patterns

### Dotfile Management Pattern
```bash
install_dotfiles() {
    local source_dir="${SCRIPT_DIR}/dotfiles"
    local backup_dir="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Process each dotfile
    for file in "$source_dir"/.*; do
        [ -f "$file" ] || continue
        
        local basename=$(basename "$file")
        local target="${HOME}/${basename}"
        
        # Backup existing file
        if [ -f "$target" ]; then
            cp "$target" "$backup_dir/"
            log_info "Backed up $basename"
        fi
        
        # Install new dotfile
        cp "$file" "$target"
        log_info "Installed $basename"
    done
}
```

### Service Configuration Pattern
```bash
configure_service() {
    local service_name="$1"
    local config_file="$2"
    
    # Stop service if running
    if systemctl is-active --quiet "$service_name"; then
        sudo systemctl stop "$service_name"
    fi
    
    # Apply configuration
    sudo cp "$config_file" "/etc/${service_name}/"
    
    # Reload and restart service
    sudo systemctl daemon-reload
    sudo systemctl enable "$service_name"
    sudo systemctl start "$service_name"
    
    # Verify service is running
    if systemctl is-active --quiet "$service_name"; then
        log_success "$service_name configured and started"
    else
        log_error "$service_name failed to start"
        return 1
    fi
}
```

## Progress and Logging Patterns

### Progress Bar Pattern
```bash
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\rProgress: ["
    printf "%${completed}s" | tr ' ' '='
    printf "%$((width - completed))s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    [ $current -eq $total ] && echo
}

# Usage
total_packages=${#PACKAGES[@]}
for i in "${!PACKAGES[@]}"; do
    install_package "${PACKAGES[$i]}"
    show_progress $((i + 1)) $total_packages
done
```

### Logging Pattern
```bash
# Initialize log file
readonly LOG_FILE="${HOME}/.local/log/${SCRIPT_NAME}.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function with file output
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output with colors
    case $level in
        INFO) echo -e "${GREEN}[INFO]${NC} $message" ;;
        WARN) echo -e "${YELLOW}[WARN]${NC} $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
    esac
    
    # File output
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}
```

## Performance Patterns

### Parallel Installation Pattern
```bash
# Install packages in parallel
install_parallel() {
    local -a pids=()
    
    for package in "${PACKAGES[@]}"; do
        (
            install_package "$package" &>/dev/null
            echo "$package:$?"
        ) &
        pids+=($!)
    done
    
    # Wait for all background jobs
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Check results
    for result in $(jobs -p | xargs -I {} cat /proc/{}/fd/1 2>/dev/null); do
        local package="${result%:*}"
        local status="${result#*:}"
        
        if [ "$status" -eq 0 ]; then
            log_success "$package installed"
        else
            log_error "$package failed"
        fi
    done
}
```

### Caching Pattern
```bash
# Cache expensive operations
declare -A CACHE

get_package_version() {
    local package="$1"
    
    # Check cache first
    if [ -n "${CACHE[$package]}" ]; then
        echo "${CACHE[$package]}"
        return
    fi
    
    # Expensive operation
    local version=$(apt-cache show "$package" 2>/dev/null | grep Version | head -1 | cut -d' ' -f2)
    
    # Store in cache
    CACHE[$package]="$version"
    echo "$version"
}
```

## Testing Patterns

### Self-Test Pattern
```bash
run_self_tests() {
    local failed=0
    
    # Test: Required commands available
    for cmd in wget curl git; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            ((failed++))
        fi
    done
    
    # Test: Write permissions
    if ! touch "${HOME}/.test_write" 2>/dev/null; then
        log_error "No write permissions in home directory"
        ((failed++))
    else
        rm -f "${HOME}/.test_write"
    fi
    
    # Test: Internet connectivity
    if ! ping -c 1 google.com &>/dev/null; then
        log_warning "No internet connectivity detected"
    fi
    
    return $failed
}

# Run tests before main execution
if ! run_self_tests; then
    log_error "Self-tests failed"
    exit 1
fi
```

### Dry Run Pattern
```bash
# Global dry run flag
DRY_RUN=${DRY_RUN:-false}

# Wrapper for dangerous operations
execute() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] $*"
    else
        "$@"
    fi
}

# Usage
execute sudo apt install -y package
execute rm -rf /some/directory
```