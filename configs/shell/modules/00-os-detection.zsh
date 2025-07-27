#!/bin/zsh
# ==============================================================================
# Module: OS Detection
# Description: Detects the operating system and sets global variables
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ OPERATING SYSTEM DETECTION                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true    ## Running on macOS
    IS_LINUX=false
    
    # Detect macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_MAJOR_VERSION=$(echo "$MACOS_VERSION" | cut -d'.' -f1)
    
    # Detect architecture
    if [[ "$(uname -m)" == "arm64" ]]; then
        IS_ARM64=true
        IS_INTEL=false
    else
        IS_ARM64=false
        IS_INTEL=true
    fi
else
    IS_MACOS=false
    IS_LINUX=true    ## Running on Linux
    
    # Detect Linux distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        LINUX_DISTRO="$ID"
        LINUX_VERSION="$VERSION_ID"
    fi
fi

# Export for use in other modules
export IS_MACOS IS_LINUX IS_ARM64 IS_INTEL
export MACOS_VERSION MACOS_MAJOR_VERSION
export LINUX_DISTRO LINUX_VERSION