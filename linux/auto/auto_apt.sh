#!/usr/bin/env bash 

echo ' \n Auto install programs with APT-get \n '

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
## Removing any apt locks ##
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

# ---------------------------------------------------------------------- #
## Install programs APT
for apt_program in ${APT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $apt_program; then     # Just install if not exist
    apt install -y "$apt_program"               #$# Change this line if you have other distro than debian/ubuntu base
  else
    echo "[successful installation] - $apt_program"
  fi
done

# ---------------------------------------------------------------------- #
## Updating the repository ##
sudo apt update && sudo apt upgrade && apt dist-upgrade -y
sudo apt autoclean
sudo apt autoremove -y

echo ' \n Done! Selected packages install with APT. \n '
