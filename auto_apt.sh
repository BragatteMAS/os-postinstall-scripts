#!/usr/bin/env bash 

echo ' \n Auto install programs with APT-get \n '

# ---------------------------------------------------------------------- #
#APT command line package used to install programs Debian/Ubuntu distros stores
# -----------------------------VARIABLES-------------------------------- #
APT_INSTALL=(
synaptic			        #System|program manager
git git-lfs     	    #System|control modifications
stacer 			          #System|clean and monitor programs
htop				          #System|memory verify
gufw				          #System|firewall for linux
timeshift 		        #System|backup
virtualbox-qt  		    #System|emulate OS	'sudo adduser $USER vboxusers'
gdebi make rpm		    #System|packages manager
nemo dolphin          #System|file manager
zsh 				          #Terminal|alternative option for bash in terminal
terminator 			      #Terminal|high configurtion term
tilix			            #Terminal|virtual terminal custom
gnome-sushi			      #Image|previsualize files pressing space Nautilus
flameshot			        #Image|capture screen
ffmpeg			          #Image|extension
simplescreenrecorder	          #Video|capture and film screen
winff winff-gtk2 winff-qt       #Video|convert formats
xpad				                    #Productivity|sticky note application for GTK
ttf-mscorefonts-installer       #Productivity|fonts for microsoft
github-desktop                  #Code import
steam lutris piper ratbagd wine	#Games|systems
openssh-server 		                                                              #System|remotely controlling & transferring
tigervnc-viewer                                                                 #System|VNC
openconnect network-manager-openconnect network-manager-openconnect-gnome       #System|VPN
openvpn network-manager-openvpn network-manager-openvpn-gnome                   #System|ProtonVPN
gnome-tweaks gnome-shell-extensions gnome-shell-extension-prefs chrome-gnome-shell  #Gnome|desktop utilities

)
# ---------------------------------------------------------------------- #
## Removing any apt locks ##
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

# ---------------------------------------------------------------------- #
## Install programs APT
for apt_program in ${APT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $apt_program; then     # Just install if nothttps://github.com/shiftkey/desktop/releases/download/release-2.5.4-linux1/GitHubDesktop-linux-2.5.4-linux1.deb exist
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
