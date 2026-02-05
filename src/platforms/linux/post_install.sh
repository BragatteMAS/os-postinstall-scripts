#!/usr/bin/env bash
#######################################
# Script: post_install.sh
# Description: Full post-installation script for Linux
# Author: Bragatte
# Date: 2026-02-05
#######################################

# NOTE: No set -e (per Phase 1 decision - conflicts with "continue on failure" strategy)

# Constants
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Source core utilities from src/core/
source "${SCRIPT_DIR}/../../core/logging.sh" || {
    echo "[ERROR] Failed to load logging.sh" >&2
    exit 1
}

source "${SCRIPT_DIR}/../../core/platform.sh" || {
    log_error "Failed to load platform.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../core/idempotent.sh" || {
    log_error "Failed to load idempotent.sh"
    exit 1
}

source "${SCRIPT_DIR}/../../core/packages.sh" || {
    log_error "Failed to load packages.sh"
    exit 1
}

# TODO: Package safety module needs migration to src/core/
# For now, define minimal stubs for safe_apt_* functions
safe_apt_update() {
    sudo apt-get update -y
}

safe_apt_install() {
    local pkg="$1"
    sudo apt-get install -y "$pkg"
}

wait_for_apt() {
    # Wait for apt lock to be free
    while sudo fuser /var/lib/dpkg/lock-frontend &>/dev/null 2>&1; do
        log_info "Waiting for apt lock..."
        sleep 2
    done
    return 0
}

log_section() {
    local title="$1"
    echo ""
    log_info "=== $title ==="
}

log_progress() {
    local current="$1"
    local total="$2"
    local msg="${3:-}"
    log_info "[$current/$total] $msg"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "Cleaning up ${SCRIPT_NAME}..."
    # Release any apt locks if we have them
    exit $exit_code
}
trap cleanup EXIT INT TERM

##	+-----------------------------------+-----------------------------------+
##	|                                                                       |
##	|                        Pos Install Scrypt                             |
##	|                                                                       |
##	| Copyright (c) 2022, Bragatte <marcelobragatte@gmail.com>.             |
##	|                                                                       |
##	| All programs are free software: you can redistribute it and/or modify |
##	| it under the terms of the GNU General Public License as published by  |
##	| the Free Software Foundation, either version 3 of the License, or     |
##	| (at your option) any later version.                                   |
##	|                                                                       |
##	| This script should be run with SUDO command.                          |
##	| Detail instructions:                                                  |
##	| <https://github.com/BragatteMAS/os-postinstall-scripts> 	          	|
##  | POP-OS 22.04 version 	- Tested 20220426				                        |
##	+-----------------------------------------------------------------------+

echo -e '\n Starting OS Post-Install Script... \n'

# -------------------------------------------------------------------------- #
# Package lists are now in data/packages/ directory:
# - apt-post.txt: APT packages for post-install
# - snap-post.txt: Snap packages for post-install
# - flatpak-post.txt: Flatpak packages for post-install
# -------------------------------------------------------------------------- #

#Deb packages
##Alternative for Flathub from Chrome released 2022
#URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

#PPA
#sudo add-apt-repository ppa:lutris-team/lutris

### --------------------- Basic system utilities ---------------------- ###
## Wait for APT locks to be free
log_section "Preparing System"
wait_for_apt

## Adding / Confirming 32-bit Architecture ##
sudo dpkg --add-architecture i386

## Updating the repository ##
log_info "Updating package lists..."
safe_apt_update

##Packages of apps for Linux
log_info "Installing package managers..."
safe_apt_install "snapd"
safe_apt_install "flatpak"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------------- #
## Install programs APT
log_section "Installing APT packages"
if load_packages "apt-post.txt"; then
    total_packages=${#PACKAGES[@]}
    current_package=0
    for apt_program in "${PACKAGES[@]}"; do
        current_package=$((current_package + 1))
        log_progress $current_package $total_packages "Installing APT packages"
        if ! safe_apt_install "$apt_program"; then
            log_warning "Failed to install $apt_program, continuing..."
        fi
    done
else
    log_warning "Could not load apt-post.txt, skipping APT packages"
fi

## Install programs SNAP
log_section "Installing Snap packages"
if load_packages "snap-post.txt"; then
    total_packages=${#PACKAGES[@]}
    current_package=0
    for snap_program in "${PACKAGES[@]}"; do
        current_package=$((current_package + 1))
        log_progress $current_package $total_packages "Installing Snap packages"
        if ! snap list "$snap_program" &>/dev/null; then
            if ! sudo snap install "$snap_program"; then
                log_warning "Failed to install $snap_program, continuing..."
            fi
        else
            log_info "Already installed: $snap_program"
        fi
    done
else
    log_warning "Could not load snap-post.txt, skipping Snap packages"
fi

## Install programs FLATPAK
log_section "Installing Flatpak packages"
if load_packages "flatpak-post.txt"; then
    total_packages=${#PACKAGES[@]}
    current_package=0
    for flat_program in "${PACKAGES[@]}"; do
        current_package=$((current_package + 1))
        log_progress $current_package $total_packages "Installing Flatpak packages"
        if ! flatpak list --app | grep -q "$flat_program"; then
            if ! flatpak install flathub "$flat_program" -y; then
                log_warning "Failed to install $flat_program, continuing..."
            fi
        else
            log_info "Already installed: $flat_program"
        fi
    done
else
    log_warning "Could not load flatpak-post.txt, skipping Flatpak packages"
fi

### --------------------------- Exceptions----------------------------- ###
## Brave Browser
sudo apt install apt-transport-https curl -y
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
safe_apt_update
safe_apt_install "brave-browser"   #faster/browser

##Github Desktop
wget -qO - https://packagecloud.io/shiftkey/desktop/gpgkey | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/shiftkey/desktop/any/ any main" > /etc/apt/sources.list.d/packagecloud-shiftky-desktop.list'
safe_apt_update
safe_apt_install "github-desktop"


### ------------------------------------------------------------------- ###
## Download and install external programs .deb -> using for Bravebrowser##
HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Downloads="$HOME/Downloads/Programs"
mkdir "$Dir_Downloads"
sudo chmod 777 -R "$Dir_Downloads"
#wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"

## Installing .deb packages ##
if ls $Dir_Downloads/*.deb 1> /dev/null 2>&1; then
    log_info "Installing downloaded .deb packages..."
    if wait_for_apt; then
        sudo dpkg -i $Dir_Downloads/*.deb
        # Fix any dependency issues
        if ! sudo apt-get install -f -y; then
            log_error "Failed to resolve dependencies"
        fi
    fi
fi
safe_apt_update

### ---------------------------- After install ------------------------ ###

# ---------------------------------------------------------------------- #

#sudo add-apt-repository --remove ppa:lutris-team/lutris
sudo add-apt-repository --remove ppa:linux/chrome/deb/

# ---------------------------------------------------------------------- #
log_section "Final System Update and Cleanup" "=" 50

safe_apt_update

log_info "Performing system upgrade..."
if wait_for_apt; then
    if sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y; then
        log_success "System upgrade completed"
    else
        log_error "System upgrade failed"
    fi
fi

log_info "Updating Snap packages..."
sudo snap refresh

log_info "Updating Flatpak packages..."
flatpak update -y

log_info "Cleaning up packages..."
if wait_for_apt; then
    sudo apt-get autoclean
    sudo apt-get autoremove -y
    log_success "Package cleanup completed"
fi
# ---------------------------------------------------------------------- #
echo '\n All done! Reboot your pc, run this script a second time to check the instalation confirmation message and keep walking!'
### ------------------------------------------------------------------- ####
