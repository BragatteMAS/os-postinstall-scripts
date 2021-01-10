#!/usr/bin/env bash 

##	+-----------------------------------+-----------------------------------+
##	|                                                                       |
##	|                        Pos Install Scrypt                             |
##	|                                                                       |
##	| Copyright (c) 2021, Bragatte <marcelobragatte@gmail.com>.             |
##	|                                                                       |
##	| All programs are free software: you can redistribute it and/or modify |
##	| it under the terms of the GNU General Public License as published by  |
##	| the Free Software Foundation, either version 3 of the License, or     |
##	| (at your option) any later version.                                   |
##	|                                                                       |
##	| This script should be run with SUDO command.                          |
##	| Detail instructions:                                                  |
##	| <https://github.com/BragatteMAS/Linux_posintall_script>               |
##	+-----------------------------------------------------------------------+

echo ' \n Auto install Bragatte_mode!!!! \n	'

# -------------------------------------------------------------------------- #
#APT command line package used to install programs Debian/Ubuntu distros stores
# -----------------------------VARIABLES APT-------------------------------- #
APT_INSTALL=(
synaptic              #System|program manager
neofetch              #System|verify info term
gufw                  #System|firewall for linux
git git-lfs           #System|control modifications
stacer                #System|clean and monitor programs
alacritty             #System|GPU enhanced terminal
htop                  #System|memory verify
timeshift             #System|backup
virtualbox-qt         #System|emulate OS	'sudo adduser $USER vboxusers'
gdebi make rpm        #System|packages manager
nemo dolphin          #System|file manager
zsh                   #Terminal|alternative option for bash in terminal
terminator            #Terminal|high configurtion term
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
# -------------------------------------------------------------------------- #
#Programs select from SNAP store <https://snapcraft.io/store>
# -----------------------------VARIABLES SNAP------------------------------- #
SNAP_INSTALL=(
bitwarden         #System|password manager
audacity          #Sound|audio editor and recording app
spotify           #Sound|digital music service
photogimp         #Image|patch 'Adobe' for GIMP
inkscape          #Image|vector graphics software
gifcurry          #Image|gif creator
kdenlive          #Video|Edition
discord           #Comunication|interaction/gamer chat
telegram-desktop  #Comunication|alternative for whatsapp
rambox            #Comunication|join different systems of comunication
chromium          #Productivity|browser
todoist           #Productivity|Task manager
foliate           #Productivity|ebook viewer
feedreader        #Productivity|RSS
zotero-snap       #Productivity|References
homeserver        #Productivity|Share folders in urls
docker            #Productivity|container environmental 'sudo groupadd docker' && 'sudo usermod -aG docker $USER'
qsnapstore        #Productivity|Snap store improved
pymol-oss         #Research
weka-james-carroll #ML

)
# --------------------------------------------------------------------------- #
#Programs select from Flathub store <https://flathub.org/home>
# -----------------------------VARIABLES FLAT-------------------------------- #
FLAT_INSTALL=(
flatseal            #System|permissions
filezilla           #System|SQL manager
org.gnome.Boxes     #System|virtualization
pavucontrol	        #Sound|Control
obsproject.Studio   #Video|streaming software
org.blender.Blender #Video|3D pipeline—model,animation,simulation,rendering
org.videolan.VLC    #Video|media player open-source
zoom                #Video|webinars
slack               #Comunication|team chat
skype               #Comunication|chat support
dropbox             #Productivity|online files manager
masterpdf           #Productivity|pdf-editor
com.wps.Office      #Productivity|office reader for doc win
jamovi              #Productivity|real-time, statisticial spreadsheet
openboard           #Productivity|educational software interactive board
geogebra            #Productivity|dynamic geometry program
blanket             #Productivity|back environmental sounds to work
organizer           #Productivity|shifts your files according to their filetype
meld                #Productivity|diif across files
calibre             #Productivity|reader kindle types
gitkraken           #Productivity|code commit
nz.mega.MEGAsync    #Productivity|storage
com.github.calo001.fondo  ##Productivity|wallpapers
)
# ---------------------------------------------------------------------- #
#Deb packages
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_Balena="https://dl.bintray.com/etcher/debian/pool/stable/e/etcher/balena-etcher-electron_1.5.99_amd64.deb"  #att with inexistent ":" insert in the middle of url
URL_Iriun="http://iriun.gitlab.io/iriunwebcam.deb"

#PPA
#sudo add-apt-repository ppa:lutris-team/lutris

### --------------------- Basic system utilities ---------------------- ###
## Removing any apt locks ##
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

## Adding / Confirming 32-bit Architecture ##
sudo dpkg --add-architecture i386

## Updating the repository ##
sudo apt update -y

##Packages of apps for Linux
sudo apt install snapd -y

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
for snap_program in ${SNAP_INSTALL[@]}; do
  if ! dpkg -l | grep -q $snap_program; then # Just install if not exist
    snap install "$snap_program" 
  fi
done

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

##Github Desktop
wget -qO - https://packagecloud.io/shiftkey/desktop/gpgkey | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/shiftkey/desktop/any/ any main" > /etc/apt/sources.list.d/packagecloud-shiftky-desktop.list'
sudo apt-get update
sudo apt install github-desktop -y

## --classic options for SNAP packs need to run separated
sudo snap install code --classic	#Terminal|best IDE
sudo snap install alacritty --classic #Terminal with GPU 

### ------------------------------------------------------------------- ###
## Download and install external programs .deb ##
HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Downloads="$HOME/Downloads/Programs"
mkdir "$Dir_Downloads"
sudo chmod 777 -R "$Dir_Downloads"
wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"
wget -c "$URL_Balena" -P "$Dir_Downloads"
wget -c "$URL_Iriun" -P "$Dir_Downloads"

## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb
sudo apt update -y

### ---------------------------- After install ------------------------ ###

# ---------------------------------------------------------------------- #

#sudo add-apt-repository --remove ppa:lutris-team/lutris
sudo add-apt-repository --remove ppa:linux/chrome/deb/

# ---------------------------------------------------------------------- #
sudo apt update && sudo apt upgrade && apt dist-upgrade -y
sudo snap refresh
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y
# ---------------------------------------------------------------------- #
echo '\n All done! Reboot your pc, run this script a second time to check the instalation confirmation message and keep walking!'
### ------------------------------------------------------------------- ####

