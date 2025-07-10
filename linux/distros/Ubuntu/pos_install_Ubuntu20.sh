#!/usr/bin/env bash #flexibility on different systems

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
#Versão 1.1_Ubuntu 20.04 LTS
    #Method of installation:
    #1) "sudo apt install..."
    #2) "snap install..."
    #3) "flatpak install flathub ..""
        #For example two OBStudio will be install in this script!
#Options to select the flavor environmental (choose just one option if do not want GNOME - options: Cinnamon or KDE_Kubuntu or Xfce or Mate or LXqt or Budgie)

echo -e '	\n Auto install Bragatte_mode!!!! \n	'

### ----------------------- Variable PPA & URLs ----------------------- ###
PPA_Lutris="ppa:lutris-team/lutris"
PPA_Ulauncher="ppa:agornostal/ulauncher"

URL_Ulauncher="https://github.com/Ulauncher/Ulauncher/releases/download/5.7.5/ulauncher_5.7.5_all.deb"
#URL_PPA_Albert="https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_20.04/"
#URL_Albert="https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_20.04/amd64/albert_0.16.1_amd64.deb"
URL_PPA_Wine="https://dl.winehq.org/wine-builds/ubuntu/"
URL_Wine_key="https://dl.winehq.org/wine-builds/winehq.key"
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_4K_VIDEO_DOWNLOADER="https://dl.4kdownload.com/app/4kvideodownloader_4.12.1-1_amd64.deb"
URL_Balena="https://dl.bintray.com/etcher/debian/pool/stable/e/etcher/:balena-etcher-electron_1.5.80_amd64.deb"
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
wget -nc "$URL_Wine_key"
sudo apt-key add winehq.key
sudo apt-add-repository "deb $URL_PPA_Wine focal main"
#wget -nc "$URL_Albert"
#sudo apt-key add Release.key
#sudo apt-add-repository "deb $URL_PPA_Albert /"
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
wget -nc "$URL_Ulauncher"
sudo apt-add-repository "deb $PPA_Ulauncher /"



### ------------------------------------------------------------------- ###

### ---------------------- Installing Programs ------------------------ ###
sudo apt install snapd -y
sudo apt install flatpak -y

## Updating the repository ##
sudo apt update -y

## Download and install external programs .deb ##
mkdir "$DIR_DOWNLOADS"
wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"
wget -c "$URLhttps://github.com/Ulauncher/Ulauncher/releases/download/5.7.5/ulauncher_5.7.5_all.deb"
## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb
sudo apt update -y
sudo apt install openssh-server -y # remotely controlling & transferring
sudo apt install xpad -y # sticky note application for GTK

#repository programs##
sudo apt install synaptic #manager for Ubuntu
sudo apt install git -y #control modifications
sudo apt install stacer -y #clean and monitor programs
sudo apt install gnome-sushi gnome-tweaks gnome-shell-extensions gnome-shell-extension-prefs chrome-gnome-shell -y # desktoip utilities
gsettings set org.gnome.desktop.interface enable-hot-corners true #displaying the overview of the shell by bringing your mouse to the upper corner of the desktop automatically
sudo apt install gdebi gufw htop  #system suporters
#Browsers
sudo apt install brave-browser
#Codecs
sudo apt install ubuntu-restricted-addons ubuntu-restricted-extras rar unrar p7zip-full p7zip-rar arj mpv curl

#Terminal
sudo apt install zsh -y # alternative option for bash in terminal
sudo apt install terminator #high configurtion term
sudo apt install tilix zsh -y #virtual terminal custom
#Productivity
sudo apt install flameshot -y # capture and film screen
sudo apt install gnome-sushi -y # previsualize files pressing space
sudo apt install make -y # support install packages
sudo apt install openssh-server -y # remotely controlling & transferring
sudo apt install xpad -y # sticky note application for GTK
sudo apt install simplescreenrecorder -y # capture and film screen2
sudo apt install winff winff-gtk2 winff-qt -y # convert vieo formats
sudo apt install guvcview -y # webcam app for streams
sudo apt install rpm yum -y # other formats in linux

#Virtual Machine
sudo apt install virtualbox-qt -y #emulate SO version 5
    sudo adduser $USER vboxusers
#Packages
sudo apt install python-pip -y # installs packages
sudo apt install ubuntu-restricted-extras -y

sudo apt install albert -y # global search at system


echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
sudo apt update -y
sudo apt-get install balena-etcher-electron -y

## Gamers repositories and packages ##
sudo apt install steam-installer steam-devices steam:i386 -y
sudo apt install ratbagd piper -y #optional config mouse
sudo apt install lutris libvulkan1 libvulkan1:i386 -y
sudo apt install --install-recommends winehq-stable wine-stable wine-stable-i386 wine-stable-amd64 -y
sudo apt install libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

'''SNAP install'''
#Codes
sudo snap install code --classic #best IDE
sudo snap install sublime-text --classic #IDE generic
#Editions
##Images
sudo snap install photogimp #patch 'Adobe' for GIMP
sudo snap install inkscape #vector graphics software
sudo snap install blender --classic #3D pipeline—model,animation,simulation,rendering.
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

sudo snap install docker  #container environmental
    sudo groupadd docker
    sudo usermod -aG docker $USER
    # sudo apt install docker.io # alternative if fail the snap option


'''FLATPAK install flathub'''
flatpak install flathub com.obsproject.Studio -y #streaming app
flatpak install flathub com.valvesoftware.Steam -y #gaming app
flatpak install flathub org.filezillaproject.Filezilla -y #SQL manager
flatpak install flathub net.codeindustry.MasterPDFEditor -y #pdf editor
flatpak install flathub org.vim.Vim -y #text editor
flatpak install flathub info.febvre.Komikku -y #leitor comic
flatpak install flathub com.wps.Office -y #office reader for doc win
### ------------------------------------------------------------------- ###

### ----------------------- Tools for Data Science -------------------- ###

##Anaconda##
#some prequesites for anaconda#
sudo apt install python-setuptools python-dev python-numpy sextractor libusb-dev swig \ libcfitsio-dev:i386 python-gobject-2-dev python-gtk2-dev python-gdl \ python-nose python-epydoc -y
sudo apt install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

wget -c https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh -O ~/anaconda.sh #edit "Anaconda3-xxx" for updates
bash ~/anaconda.sh -b -u -p
#-b(agree with license)-u(unsubscrive)-p(prefix home)
source /home/$USER/anaconda3/bin/activate ## activate base conda terminal
source ~/.bashrc #activate installation
conda config --set auto_activate_base true
#to not activate : conda config --set auto_activate_base false
source /home/$USER/anaconda3/bin/activate
#open new terminal and wirte "anaconda-navigator#
#Create icon for launcher/desktop
#Acess the directory for apps
cd /usr/share/applications/
#!/bin/bash
cat > Anaconda-Navigator.desktop <<EOF
[Desktop Entry]
 Version=1.0
 Type=Application
 Name=Anaconda-Navigator
 GenericName=Anaconda
 Comment=Scientific Python Development Environment - Python3
 Exec=bash -c 'export PATH="/home/$USER/anaconda3/bin:$PATH" && /home/$USER/anaconda3/bin/anaconda-navigator'
 Categories=Development;Science;IDE;Qt;Education;
 Icon=/home/$USER/anaconda3/lib/python3.7/site-packages/anaconda_navigator/static/images/anaconda.png
 Terminal=false
 StartupNotify=true
 MimeType=text/x-python;
EOF
#Attention with paths, name of the images and version of python3.*#

### ------------------------------------------------------------------- ###
sudo add-apt-repository ppa:gnome3-team/gnome3 -y
sudo add-apt-repository ppa:vala-team -y
sudo add-apt-repository ppa:gnome3-team/gnome3-staging -y
sudo apt install cmake valac libgtk-3-dev libgee-0.8-dev libclutter-gtk-1.0-dev libclutter-1.0-dev libwebkit2gtk-4.0-dev libclutter-gst-3.0-dev
git clone https://github.com/cheesecakeufo/komorebi.git
cd komorebi
mkdir build && cd build
cmake .. && sudo make install && ./komorebi

### -------------------Alternative flavors for GNOME------------------- ###
'''If want to change the flavor, delete de "#" before the command line'''
sudo apt install cinnamon-desktop-environment              #Cinnamon
sudo apt kubuntu-desktop                                   #KDE_Kubuntu
sudo apt install xubuntu-desktop                           #Xfce
sudo apt install ubuntu-mate-desktop                       #MATE
sudo apt install lubuntu-desktop                           #LXqt
sudo apt install ubuntu-budgie-desktop                     #Budgie

sudo add-apt-repository ppa:leaeasy/dde                    #UbuntuDDE (Deepin)
sudo apt update 
sudo apt install dde                                       #UbuntuDDE (Deepin)

### ---------------------------- After install ------------------------ ###
## Finishing, updating and cleaning##
cd ~
cat > .bashrc <<EOF
alias sauu='sudo apt update -y && sudo apt upgrade -y'
alias sauud='sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y'
alias cleaner='sudo apt autoclean && sudo apt autoremove -y'
EOF

sudo apt update && sudo apt upgrade && apt dist-upgrade -y
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y

#install stacer
#sudo add-apt-repository ppa:oguzhaninan/stacer -y
#sudo apt-get update
#sudo apt-get install stacer -y

echo -e '\n All done! Reboot your pc and keep walking!'
### ------------------------------------------------------------------- ####
