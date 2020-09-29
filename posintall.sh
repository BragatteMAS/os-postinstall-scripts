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
##    |  <https://github.com/BragatteMAS/Linux_posintall_script>              |                                                       |
##	+-----------------------------------------------------------------------+

echo ' \n Auto install Bragatte_mode!!!! \n	'

# -------------------------------------------------------------------------- #
#APT command line package used to install programs Debian/Ubuntu distros stores
# -----------------------------VARIABLES APT-------------------------------- #
APT_INSTALL=(
synaptic  #System|program manager
git git-lfs  #System|control modifications
stacer  #System|clean and monitor programs
htop  #System|memory verify
gufw  #System|firewall for linux
timeshift   #System|backup
virtualbox-qt  		    #System|emulate OS	'sudo adduser $USER vboxusers'
gdebi make rpm		    #System|packages manager
nemo dolphin          #System|file manager
zsh 				          #Terminal|alternative option for bash in terminal
terminator 			      #Terminal|high configurtion term
tilix			            #Terminal|virtual terminal custom
gnome-sushi			      #Image|previsualize files pressing space Nautilus
flameshot			        #Image|capture screen
ffmpeg			          #Image|extension
arandr                          #Video|monitor settings
simplescreenrecorder	          #Video|capture and film screen
winff winff-gtk2 winff-qt       #Video|convert formats
xpad				                    #Productivity|sticky note application for GTK
github-desktop                  #Code import
steam lutris piper ratbagd wine	#Games|systems
openssh-server 		                                                              #System|remotely controlling & transferring
tigervnc-viewer                                                                 #System|VNC
openconnect network-manager-openconnect network-manager-openconnect-gnome       #System|VPN
openvpn network-manager-openvpn network-manager-openvpn-gnome                   #System|ProtonVPN
gnome-tweaks gnome-shell-extensions gnome-shell-extension-prefs chrome-gnome-shell  #Gnome|desktop utilities

)
# -------------------------------------------------------------------------- #
#Programs select from SNAP store <https://snapcraft.io/store>
# -----------------------------VARIABLES SNAP------------------------------- #
SNAP_INSTALL=(
bitwarden		  	  #System|password manager
code		 		      #Terminal|best IDE
audacity 			    #Sound|audio editor and recording app
spotify			      #Sound|digital music service
photogimp	 		    #Image|patch 'Adobe' for GIMP
inkscape 			    #Image|vector graphics software
blender --classic #Image|3D pipeline—model,animation,simulation,rendering
gifcurry 			    #Image|gif creator
obs-studio		    #Video|Edition
kdenlive			    #Video|Edition
vlc				        #Video|Viewer
discord 			    #Comunication|interaction/gamer chat
telegram-desktop 	#Comunication|alternative for whatsapp
rambox 			      #Comunication|join different systems of comunication
opera			        #Productivity|browser
todoist			      #Productivity|Task manager
foliate			      #Productivity|ebook viewer
feedreader			  #Productivity|RSS
zotero-snap			  #Productivity|References
homeserver		    #Productivity|Share folders in urls
docker  			    #Productivity|container environmental 'sudo groupadd docker' && 'sudo usermod -aG docker $USER'
nextcloud-desktop #Productivity|file synced
pymol-oss         #Research

)
# --------------------------------------------------------------------------- #
#Programs select from Flathub store <https://flathub.org/home>
# -----------------------------VARIABLES FLAT-------------------------------- #
FLAT_INSTALL=(
flatseal            #System|permissions
filezilla           #System|SQL manager
boxes               #System|virtualization
vim.vim				          #Terminal|alternative
obsproject.Studio   #Video|streaming software
zoom				        #Video|webinars
slack			          #Comunication|team chat
skype			          #Comunication|chat support
dropbox			        #Productivity|online files manager
masterpdf 	        #Productivity|pdf-editor
ankiweb             #Productivity|Flashcards
wps 			          #Productivity|office reader for doc win
jamovi			        #Productivity|real-time, statisticial spreadsheet
openboard	          #Productivity|educational software interactive board
geogebra	          #Productivity|dynamic geometry program
blanket		          #Productivity|back environmental sounds to work
organizer	          #Productivity|shifts your files according to their filetype
meld                #Productivity|diif across files
calibre             #Productivity|reader kindle types
gitkraken           #Productivity|code commit

)
# ---------------------------------------------------------------------- #
#Deb packages
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_Balena="https://dl.bintray.com/etcher/debian/pool/stable/e/etcher/balena-etcher-electron_1.5.99_amd64.deb"  #att with inexistent ":" insert in the middle of url
URL_RStudio="https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.3.1093-amd64.deb"
URL_ttf="http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.8_all.deb"
#PPA
sudo add-apt-repository ppa:lutris-team/lutris
# ---------------------------------------------------------------------- #
#Appimages
APP_Balena="https://github.com/balena-io/etcher/releases/download/v1.5.109/balena-etcher-electron-1.5.109-linux-x64.zip"

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
  if ! dpkg -l | grep -q $apt_program; then     # Just install if nothttps://github.com/shiftkey/desktop/releases/download/release-2.5.4-linux1/GitHubDesktop-linux-2.5.4-linux1.deb exist
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

### ------------------------------------------------------------------- ###
## Download and install external programs .deb ##
HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Downloads="$HOME/Downloads/Programs"
mkdir "$Dir_Downloads"
wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"
wget -c "$URL_RStudio" -P "$Dir_Downloads"
wget -c "$URL_Balena" -P "$Dir_Downloads"
wget -c "$APP_Balena" -P "$Dir_Downloads"
wget -c "$URL_ttf" -P "$Dir_Downloads"

## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb
sudo ACCEPT_EULA=Y apt-get install ttf-mscorefonts-installer -y
sudo apt update -y
sudo apt -f install #Comand for using appimages with double click

### ---------------------------- After install ------------------------ ###
## Finishing, updating and cleaning##
cd ~
cat > .bashrc <<EOF
export TERM=xterm-256color 
tput setaf 2
tput -T linux setaf 2
tput -T xterm setaf 2
blue=$(tput setaf 33);
aquablue=$(tput setaf 45);
blue2=$(tput setaf 39);
orange=$(tput setaf 166);
yellow=$(tput setaf 228);
green=$(tput setaf 71);
white=$(tput setaf 15);
bold=$(tput bold);
reset=$(tput sgr0);
PS1="\[${bold}\]";
PS1+="\[${aquablue}\]\t "; #time
PS1+="\[${blue2}\]\u"; #username
#PS1+="\[${white}\] at ";
#PS1+="\[${blue}\]\h"; #host
PS1+="\[${white}\] in";
PS1+="\[${green}\] \w "; #wortking directory
PS1+="\n";
PS1+="\[${white}\]\$ \[${reset}\]"; #'$' (and reset color)
export PS1
alias sauu='sudo apt update -y && sudo apt upgrade -y'
alias sauud='sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y'
alias clean='sudo apt autoclean && sudo apt autoremove -y'
alias apps='sudo snap refresh && flatpak update -y'
alias condaon='conda config --set auto_activate_base True'
alias condaoff='conda config --set auto_activate_base False'
alias end='sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && sudo fwupdmgr get-devices && sudo fwupdmgr get-updates && sudo fwupdmgr update && sudo reboot now'
EOF

sudo apt update && sudo apt upgrade && apt dist-upgrade -y
sudo snap refresh
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y

echo '\n All done! Reboot your pc, run this script a second time to check the instalation confirmation message and keep walking!'
### ------------------------------------------------------------------- ####
