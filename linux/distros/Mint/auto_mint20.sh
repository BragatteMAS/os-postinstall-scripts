#!/usr/bin/env bash 

##	+-----------------------------------+-----------------------------------+
##	|                                                                       |
##	|                        Pos Install Scrypt                             |
##	|                                                                       |
##	| Copyright (c) 2020, Bragatte <marcelobragatte@gmail.com>.             |
##	|                                                                       |
##	| All programs are free software: you can redistribute it and/or modify |
##	| it under the terms of the GNU General Public License as published by  |
##	| the Free Software Foundation, either version 3 of the License, or     |
##	| (at your option) any later version.                                   |
##	|                                                                       |
##	| This script should be run with SUDO command.                          |
##	| Detail instructions:                                                  |
##	| <https://github.com/BragatteMAS/os-postinstall-scripts>               |
##	+-----------------------------------------------------------------------+

echo ' \n Auto install Bragatte_mode for Guille Mint!!!! \n	'

# -------------------------------------------------------------------------- #
#APT command line package used to install programs Debian/Ubuntu distros stores
# -----------------------------VARIABLES APT-------------------------------- #
APT_INSTALL=(
stacer                  #System|clean and monitor programs
htop                    #System|memory verify
gdebi make rpm          #System|packages manager
terminator              #Terminal|high configurtion term
flameshot               #Image|capture screen
ffmpeg                  #Image|extension
simplescreenrecorder    #Video|capture and film screen
recoll                  #Productivity|File localizer

)
# -------------------------------------------------------------------------- #
#Programs select from SNAP store <https://snapcraft.io/store>
# -----------------------------VARIABLES SNAP------------------------------- #
#SNAP_INSTALL=(
#bitwarden         #System|password manager
#
#)
# --------------------------------------------------------------------------- #
#Programs select from Flathub store <https://flathub.org/home>
# -----------------------------VARIABLES FLAT-------------------------------- #
FLAT_INSTALL=(
org.gnome.Boxes     #System|virtualization
vim.vim             #Terminal|alternative
pavucontrol         #Sound|Control
obsproject.Studio   #Video|streaming software
org.blender.Blender #Video|3D pipeline—model,animation,simulation,rendering
org.videolan.VLC    #Video|media player open-source
inkscape            #Video|image editor
zoom                #Video|webinars
slack               #Comunication|team chat
skype               #Comunication|chat support
dropbox             #Productivity|online files manager
masterpdf           #Productivity|pdf-editor
com.wps.Office      #Productivity|office reader for doc win
meld                #Productivity|diif across files
spotify             #Sound|Music
zotero              #Productivity|Articles
notepadqq           #Productivity|Code editor
)
# ---------------------------------------------------------------------- #
#Deb packages
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_Balena="https://dl.bintray.com/etcher/debian/pool/stable/e/etcher/balena-etcher-electron_1.5.99_amd64.deb"  
URL_R="https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.3.1093-amd64.deb"

## --------------------- Basic system utilities ---------------------- ###
## Removing any apt locks ##
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

## Adding / Confirming 32-bit Architecture ##
sudo dpkg --add-architecture i386

##Packages of apps for Linux
sudo rm /etc/apt/preferences.d/nosnap.pref
## Updating the repository ##
sudo apt update -y
#sudo apt install snapd -y

sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------------- #
## Install programs APT
for apt_program in ${APT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $apt_program; then     # Just install if not exist
    apt install -y "$apt_program"               #$# Change this line if you have other distro than debian/ubuntu base
  else
    echo "[successful installation] - $apt_program"
  fi
done

## Install programs SNAP
#for snap_program in ${SNAP_INSTALL[@]}; do
#  if ! dpkg -l | grep -q $snap_program; then # Just install if not exist
#    snap install "$snap_program" 
#  fi
#done

## Install programs FLATPAK
for flat_program in ${FLAT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $flat_program; then # Just install if not exist
    flatpak install flathub "$flat_program" -y
  fi
done

### --------------------------- Exceptions----------------------------- ###
## Brave Browser
sudo apt install apt-transport-https curl -y
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update -y
sudo apt install brave-browser -y   #faster/browser

## Albert searcher
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
sudo wget -nv https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_20.04/Release.key -O "/etc/apt/trusted.gpg.d/home:manuelschneid3r.asc"
sudo apt update -y
sudo apt install albert -y          #global search at system


### ------------------------------------------------------------------- ###
## Download and install external programs .deb ##
HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Downloads="$HOME/Downloads/Programs"
mkdir "$Dir_Downloads"
sudo chmod 777 -R "$Dir_Downloads"
wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"
wget -c "$URL_Balena" -P "$Dir_Downloads"
wget -c "$URL_R" -P "$Dir_Downloads"
## Installing .deb packages ##
#sudo dpkg -i $Dir_Downloads/*.deb
#sudo apt update -y

### ---------------------------- After install ------------------------ ###
# ---------------------------------------------------------------------- #
sudo apt update && sudo apt upgrade && apt dist-upgrade -y
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y
# ---------------------------------------------------------------------- #
echo '\n All done! Reboot your pc, run this script a second time to check the instalation confirmation message and keep walking!'
### ------------------------------------------------------------------- ####

