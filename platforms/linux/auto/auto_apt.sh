#!/usr/bin/env bash 
set -euo pipefail
IFS=$'\n\t'

# Source safe package manager operations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source safety module
if [[ -f "${ROOT_DIR}/utils/package-manager-safety.sh" ]]; then
    source "${ROOT_DIR}/utils/package-manager-safety.sh"
else
    echo "[ERROR] Required safety module not found: ${ROOT_DIR}/utils/package-manager-safety.sh" >&2
    exit 1
fi

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
    if sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y; then
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
