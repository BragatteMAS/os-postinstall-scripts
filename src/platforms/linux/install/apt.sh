#!/usr/bin/env bash
#######################################
# Script: apt.sh
# Description: Install APT packages for Linux (data-driven)
# Author: Bragatte
# Date: 2026-02-05
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Source core utilities from src/core/
source "${SCRIPT_DIR}/../../../core/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${SCRIPT_DIR}/../../../core/idempotent.sh" || {
    log_error "Failed to load idempotent.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../../core/errors.sh" || {
    log_error "Failed to load errors.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../../core/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "Cleaning up ${SCRIPT_NAME}..."
    exit $exit_code
}
trap cleanup EXIT INT TERM

log_section "Auto install programs with APT-get"

# ---------------------------------------------------------------------- #
#APT command line package used to install programs Debian/Ubuntu distros stores
# -----------------------------VARIABLES APT-------------------------------- #
APT_INSTALL=(
synaptic              #System|program manager
gufw                  #System|firewall for linux
git git-lfs           #System|control modifications
stacer                #System|clean and monitor programs
htop                  #System|memory verify
timeshift             #System|backup
virtualbox-qt         #System|emulate OS	'sudo adduser $USER vboxusers'
gdebi make rpm        #System|packages manager
nemo dolphin          #System|file manager
zsh                   #Terminal|alternative option for bash in terminal
terminator            #Terminal|high configurtion term
tilix                 #Terminal|virtual terminal custom
gnome-sushi           #Image|previsualize files pressing space Nautilus
flameshot             #Image|capture screen
ffmpeg                #Image|extension
arandr                #Video|monitor settings
simplescreenrecorder  #Video|capture and film screen
winff winff-gtk2 winff-qt       #Video|convert formats
xpad                            #Productivity|sticky note application for GTK
steam lutris piper ratbagd wine #Games|systems
openssh-server                  #System|remotely controlling & transferring
tigervnc-viewer                 #System|VNC
openconnect network-manager-openconnect network-manager-openconnect-gnome           #System|VPN
openvpn network-manager-openvpn network-manager-openvpn-gnome                       #System|ProtonVPN
gnome-tweaks gnome-shell-extensions gnome-shell-extension-prefs chrome-gnome-shell  #Gnome|desktop utilities

)
# ---------------------------------------------------------------------- #
## Update package lists safely
log_info "Updating package lists before installation..."
if ! safe_apt_update; then
    log_error "Failed to update package lists. Continuing with installation..."
fi

# ---------------------------------------------------------------------- #
## Install programs APT
log_section "Installing APT packages" "-" 40

total_packages=${#APT_INSTALL[@]}
current_package=0

for apt_program in "${APT_INSTALL[@]}"; do
    current_package=$((current_package + 1))
    log_progress $current_package $total_packages "Installing packages"
    
    # Use safe installation function
    if ! safe_apt_install "$apt_program"; then
        log_warning "Failed to install $apt_program, continuing with other packages..."
    fi
done

# ---------------------------------------------------------------------- #
## Final system update and cleanup
log_section "System Update and Cleanup" "-" 40

log_info "Performing system upgrade..."
if wait_for_apt; then
    if sudo apt-get upgrade -y; then
        log_success "System upgrade completed"
    else
        log_error "System upgrade failed"
    fi
fi

log_info "Cleaning up packages..."
if wait_for_apt; then
    sudo apt-get autoclean
    sudo apt-get autoremove -y
    log_success "Package cleanup completed"
fi

log_section "Installation Complete" "=" 40
log_success "Selected packages installed with APT"
