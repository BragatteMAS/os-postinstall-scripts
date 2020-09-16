#!/usr/bin/env bash 

##	+-----------------------------------+-----------------------------------+
##	|                                                                       |
##	|                        Pos Install Scrypt PROMT                       |
##	|                                                                       |
##	| Copyright (c) 2020, Bragatte <marcelobragatte@gmail.com>.             |
##	|                                                                       |
##	| This program is free software: you can redistribute it and/or modify  |
##	| it under the terms of the GNU General Public License as published by  |
##	| the Free Software Foundation, either version 3 of the License, or     |
##	| (at your option) any later version.                                   |
##	|                                                                       |
##	| This program is distributed in the hope that it will be useful,       |
##	| but WITHOUT ANY WARRANTY; without even the implied warranty of        |
##	| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         |
##	| GNU General Public License for more details.                          |
##	|                                                                       |
##	| You should have received a copy of the GNU General Public License     |
##	| along with this program. If not, see <http://www.gnu.org/licenses/>.  |
##	|                                                                       |
##	|                                                                       |
##	+-----------------------------------------------------------------------+

#NOTE: Run this script with 'sudo'
#Versão 20_POP-OS 20.04 LTS
    #Method of installation:
    #1) "sudo apt install..."
    #2) "snap install..."
    #3) "flatpak install flathub ..""
        #For example two OBStudio will be install in this script!
#Options to select the flavor environmental (choose just one option if do not want GNOME - options: Cinnamon or KDE_Kubuntu or Xfce or Mate or LXqt or Budgie)

echo -e '	\n Auto install Bragatte_mode!!!! \n	'

### ----------------------- Variable PPA & URLs ----------------------- ###
PPA_Lutris="ppa:lutris-team/lutris"

URL_PPA_Wine="https://dl.winehq.org/wine-builds/ubuntu/"
URL_Wine_key="https://dl.winehq.org/wine-builds/winehq.key"
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_Balena="https://dl.bintray.com/etcher/debian/pool/stable/e/etcher/:balena-etcher-electron_1.5.99_amd64.deb"
Dir_Downloads="$HOME/Downloads/Programs"
### ------------------------------------------------------------------- ###

### --------------------- Basic system utilities ---------------------- ###
## Removing any apt locks ##
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

## Adding / Confirming 32-bit Architecture ##
sudo dpkg --add-architecture i386

## Updating the repository ##
sudo apt update -y

### ---------- Adding 3rd Party Repositories and Snap Support --------- ###
## Wine
wget -nc "$URL_Wine_key"
sudo apt-key add winehq.key
sudo apt-add-repository "deb $URL_PPA_Wine focal main"

## Brave Browser
sudo apt install apt-transport-https curl
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update -y
sudo apt install brave-browser -y #faster/browser
## Albert searcher
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
sudo wget -nv https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_20.04/Release.key -O "/etc/apt/trusted.gpg.d/home:manuelschneid3r.asc"
sudo apt update -y
sudo apt install albert -y # global search at system
## Balena Etcher
echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
sudo apt update -y
sudo apt-get install balena-etcher-electron -y #bootable method

### ------------------------------------------------------------------- ###

### ---------------------- Installing Programs ------------------------ ###
sudo apt install snapd -y
sudo apt install flatpak -y
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

## Updating the repository ##
sudo apt update -y

## Download and install external programs .deb ##
mkdir "$DIR_DOWNLOADS"
wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"
## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb
sudo apt update -y

#repository programs##
sudo apt install synaptic #manager for Ubuntu
sudo apt install git -y #control modifications
sudo apt install stacer -y #clean and monitor programs
sudo apt install gnome-tweaks gnome-shell-extensions gnome-shell-extension-prefs chrome-gnome-shell -y # desktoip utilities
gsettings set org.gnome.desktop.interface enable-hot-corners true #displaying the overview of the shell by bringing your mouse to the upper corner of the desktop automatically
sudo apt install gdebi gufw htop  #system suporters
#Codecs
sudo apt install ubuntu-restricted-addons ubuntu-restricted-extras rar unrar p7zip-full p7zip-rar arj mpv curl
#Terminal
sudo apt install zsh -y # alternative option for bash in terminal
sudo apt install terminator #high configurtion term
sudo apt install tilix zsh -y #virtual terminal custom
#Productivity
sudo apt install timeshift -y #backup system
sudo apt install flameshot -y # capture and film screen
sudo apt install gnome-sushi -y # previsualize files pressing space
sudo apt install pavucontrol -y # multiple sounds / multiple monitors
sudo apt install simplescreenrecorder -y # capture and film screen2
sudo apt install xpad -y # sticky note application for GTK
sudo apt install make -y # support install packages
sudo apt install openssh-server -y # remotely controlling & transferring
sudo apt install winff winff-gtk2 winff-qt -y # convert vieo formats
sudo apt install rpm -y # other formats in linux
#Virtual Machine
sudo apt install virtualbox-qt -y #emulate SO version 5
    sudo adduser $USER vboxusers
## Gamers repositories and packages ##
sudo apt install steam-installer steam-devices steam:i386 -y
sudo apt install ratbagd piper -y #optional config mouse
sudo apt install lutris libvulkan1 libvulkan1:i386 -y
sudo apt install --install-recommends winehq-stable wine-stable wine-stable-i386 wine-stable-amd64 -y
sudo apt install libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

'''SNAP install'''
#Codes
sudo snap install code --classic #best IDE
#Editions
##Images
sudo snap install photogimp #patch 'Adobe' for GIMP
sudo snap install inkscape #vector graphics software
sudo snap install blender --classic #3D pipeline—model,animation,simulation,rendering.
sudo snap install gifcurry #gif creator
##Videos
sudo snap install obs-studio
sudo snap install kdenlive
##Audio
sudo snap install audacity # audio editor and recording app
#Comunication
sudo snap install rambox #join comunications
sudo snap install slack --classic #standard install comunication app
sudo snap install skype --classic #standard install comunication app
sudo snap install discord #comunication app focus on headset
sudo snap install telegram-desktop #alternative for whatsapp
#Entertaiment
sudo snap install spotify #digital music service
sudo snap install vlc #video
#Productivity
sudo snap install feedreader
sudo snap install opera
sudo snap install zotero-snap
sudo snap install bitwarden
sudo snap install homeserver
sudo snap install docker  #container environmental
    sudo groupadd docker
    sudo usermod -aG docker $USER
    # sudo apt install docker.io # alternative if fail the snap option


'''FLATPAK install flathub'''
flatpak install flathub com.obsproject.Studio -y #streaming app
flatpak install flathub org.filezillaproject.Filezilla -y #SQL manager
flatpak install flathub net.codeindustry.MasterPDFEditor -y #pdf editor
flatpak install flathub org.vim.Vim -y #text editor
flatpak install flathub info.febvre.Komikku -y #leitor comic
flatpak install flathub com.wps.Office -y #office reader for doc win
flatpak install flathub com.dropbox.Client #dropbox files manager
flatpak install flathub com.rafaelmardojai.Blanket #productivity sounds
flatpak install flathub org.librehunt.Organizer #auto order files for types
### ------------------------------------------------------------------- ###

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

EOF

sudo apt update && sudo apt upgrade && apt dist-upgrade -y
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y

echo -e '\n All done! Reboot your pc and keep walking!'
### ------------------------------------------------------------------- ####
