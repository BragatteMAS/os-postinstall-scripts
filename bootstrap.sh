#!/usr/bin/env bash
# bootstrap.sh — Pre-requisites for os-postinstall-scripts
#
# Run BEFORE setup.sh. Installs the minimum so setup.sh can execute:
#   macOS:   Xcode CLT, Homebrew, Bash 4+
#   Linux:   git, curl, build-essential, ca-certificates (apt-based distros)
#   Windows: redirect to native PowerShell bootstrap
#
# Idempotent. Safe to run multiple times. Bash 3.2-compatible (macOS default).
#
# After this, run:  ./setup.sh

set -uo pipefail

# Color helpers (works in Bash 3.2)
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)              echo "macos" ;;
        Linux*)               echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)                    echo "unknown" ;;
    esac
}

OS=$(detect_os)
bold "os-postinstall-scripts bootstrap"
echo "Detected OS: $OS"
echo ""

# Ensure git submodules are populated
ensure_submodules() {
    if [[ -f .gitmodules ]]; then
        if git submodule status 2>/dev/null | grep -q '^-'; then
            echo "[*] Initializing git submodules..."
            git submodule update --init --recursive
            green "    OK Submodules ready"
        else
            green "[OK] Submodules already initialized"
        fi
    fi
}

# ===== macOS =====
bootstrap_macos() {
    # 1. Xcode Command Line Tools (provides git)
    if ! xcode-select -p >/dev/null 2>&1; then
        yellow "[!] Xcode Command Line Tools not installed."
        echo "    Run:  xcode-select --install"
        echo "    Then re-run this script."
        exit 1
    fi
    green "[OK] Xcode Command Line Tools present"

    # 2. Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        echo "[*] Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    green "[OK] Homebrew: $(brew --version | head -1)"

    # 3. Bash 4+
    BREW_BASH="$(brew --prefix)/bin/bash"
    if [[ ! -x "$BREW_BASH" ]]; then
        echo "[*] Installing Bash 4+..."
        brew install bash
    fi
    green "[OK] Bash 4+: $($BREW_BASH --version | head -1)"

    # 4. git (CLT provides it, but verify)
    command -v git >/dev/null 2>&1 || { red "[FAIL] git missing"; exit 1; }
    green "[OK] git: $(git --version)"

    ensure_submodules
}

# ===== Linux (Debian-family) =====
bootstrap_linux() {
    if ! command -v apt-get >/dev/null 2>&1; then
        red "[FAIL] apt-get not found. This bootstrap supports Debian/Ubuntu/Mint/Pop!_OS."
        echo "       For other distros, install git/curl/build-essential manually."
        exit 1
    fi
    green "[OK] APT-based Linux detected"

    local pkgs=(git curl build-essential ca-certificates)
    local missing=()
    local p
    for p in "${pkgs[@]}"; do
        if ! dpkg -s "$p" >/dev/null 2>&1; then
            missing+=("$p")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[*] Installing essentials: ${missing[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y "${missing[@]}"
    fi
    green "[OK] Essentials present (git, curl, build-essential)"

    ensure_submodules
}

# ===== Windows =====
bootstrap_windows() {
    red "[!] Native Windows bootstrap not implemented in Bash."
    echo "    Options:"
    echo "      1. PowerShell:  powershell -ExecutionPolicy Bypass -File windows/Bootstrap.ps1"
    echo "      2. WSL2:        run this script inside WSL2 (Linux path applies)."
    exit 1
}

# ===== Main =====
case "$OS" in
    macos)   bootstrap_macos ;;
    linux)   bootstrap_linux ;;
    windows) bootstrap_windows ;;
    *)       red "[FAIL] Unsupported OS: $OS"; exit 1 ;;
esac

echo ""
green "Bootstrap complete."
echo ""
bold "Next steps:"
echo "  ./setup.sh --dry-run        # preview what will be installed"
echo "  ./setup.sh                  # run with default profile (developer)"
echo "  ./setup.sh full             # everything: dev defaults + extras (browsers, AI editors, design)"
echo "  ./setup.sh minimal          # essentials only"
