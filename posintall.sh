#!/usr/bin/env bash

#NOTE: Run this script with 'sudo'
#Versão 0.9_Mint19.3

echo -e '	\n Auto install Bragatte_mode!!!! \n	'

### ----------------------- Variable PPA & URLs ----------------------- ###
PPA_Graphics_drivers="ppa:graphics-drivers/ppa"
PPA_Lutris="ppa:lutris-team/lutris"
PPA_Libratbag="ppa:libratbag-piper/piper-libratbag-git"
PPA_Screenrecorder="ppa:maarten-baert/simplescreenrecorder"
URL_PPA_Albert="https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_18.04/"
URL_Albert="https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_18.04/amd64/albert_0.16.1_amd64.deb"
URL_PPA_Wine="https://dl.winehq.org/wine-builds/ubuntu/"
URL_Wine_key="https://dl.winehq.org/wine-builds/winehq.key"
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_4K_VIDEO_DOWNLOADER="https://dl.4kdownload.com/app/4kvideodownloader_4.9.2-1_amd64.deb"

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
sudo apt-add-repository "$PPA_Graphics_drivers" -y	# nvidia configs
sudo add-apt-repository "$PPA_Lutris" -y		# steam configs
sudo apt-add-repository "$PPA_Libratbag" -y		# logitech configs
sudo apt-add-repository "$PPA_Screenrecorder" -y	# simplescreenrecorder
wget -nc "$URL_Wine_key"
sudo apt-key add winehq.key
sudo apt-add-repository "deb $URL_PPA_Wine bionic main"
wget -nc "$URL_Albert"
sudo apt-key add Release.key
sudo apt-add-repository "deb $URL_PPA_Albert /"

### ------------------------------------------------------------------- ###

### ---------------------- Installing Programs ------------------------ ###
sudo apt install snapd -y
sudo apt install flatpak -y

## Updating the repository ##
sudo apt update -y

## Download and install external programs .deb ##
mkdir "$DIR_DOWNLOADS"
wget -c "$URL_GOOGLE_CHROME" -P "$Dir_Downloads"
wget -c "$URL_Albert" -P "$Dir_Downloads"
wget -c "$URL_4K_VIDEO_DOWNLOADER" -P "$Dir_Downloads"

## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb
sudo apt update -y

## APT repository programs##
sudo apt install libmuparser2v5 libqt5charts5 libqt5qml5 libqt5quick5 libqt5sql5 libqt5x11extras5 libqt5sql5-sqlite libt5concurrent5
sudo apt install albert -y # global search at system
sudo apt install zsh -y # alternative option for bash in terminal
sudo apt install tmux -y # split virtual terminals
sudo apt install tilix zsh -y #virtual terminal custom
sudo apt install rpm yum -y # other formats in linux
sudo apt install flameshot -y # capture and film screen
sudo apt install simplescreenrecorder -y # capture and film screen2
sudo apt install gnome-sushi -y # previsualize files pressing space
sudo apt install winff -y # convert vieo formats
sudo apt install guvcview -y # webcam app for streams
sudo apt install make - Y # support install packages
sudo apt install openssh-server -y # remotely controlling & transferring
sudo apt install xpad -y # sticky note application for GTK
sudo apt install python-pip -y # installs packages
sudo apt install virtualbox-qt -y #emulate SO version 5
 sudo adduser $USER vboxusers
sudo apt install build-essential default-jdk libssl-dev exuberant-ctags ncurses-term ack-grep silversearcher-ag fontconfig imagemagick libmagickwand-dev software-properties-common git vim-gtk3 curl -y # programmer packages
sudo apt install htop gdebi synaptic grsync bleachbit gufw gnome-tweak-tool unity-tweak-tool -y # system suporters
sudo apt install ubunutu-restricted-extras -y
sudo apt install mint-meta-codecs -y # for MINT distro
sudo apt install nemo-dropbox -y y # for MINT distro
sudo apt-get install balena-etcher-electron

## Gamers repositories and packages ##
sudo apt install steam-installer steam-devices steam:i386 -y
sudo apt install ratbagd piper -y #optional config mouse
sudo apt install lutris libvulkan1 libvulkan1:i386 -y
sudo apt install --install-recommends winehq-stable wine-stable wine-stable-i386 wine-stable-amd64 -y
sudo apt install libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

##Instaling Flatpak packages ##
flatpak install flathub com.obsproject.Studio -y #streaming app
flatpak install flathub org.audacityteam.Audacity -y # audio editor and recording app
flatpak install flathub com.valvesoftware.Steam -y #gaming app
flatpak install flathub org.videolan.VLC -y #video
flatpak install flathub org.filezillaproject.Filezilla -y #SQL manager
flatpak install flathub net.codeindustry.MasterPDFEditor -y #pdf editor
flatpak install flathub info.febvre.Komikku -y #leitor comic
flatpak install flathub com.visualstudio.code -y
flatpak install flathub com.wps.Office -y
flatpak install flathub org.gnome.FeedReader -y
flatpak install flathub org.kde.kdenlive -y

##Instaling Snap packages ##
sudo snap install sublime-text --classic #IDE generic
sudo snap install atom --classic #IDE generic other option
sudo snap install pycharm-community --classic #IDE python
sudo snap install notepad-plus-plus #text editor (work with wine)
sudo snap install inkscape #vector graphics software
sudo snap install blender --classic #3D pipeline—model,animation,simulation,rendering.
sudo snap install photogimp #patch 'Adobe' for GIMP
sudo snap install slack --classic #standard install comunication app
sudo snap install skype --classic #standard install comunication app
sudo snap install discord #comunication app focus on headset
sudo snap install telegram-desktop #alternative for whatsapp
sudo snap install spotify #digital music service
sudo snap install angstrom # management tool
sudo snap install docker  #container environmental
 sudo groupadd docker
 sudo usermod -aG docker $USER
 # sudo apt install docker.io # alternative if fail the snap option
sudo snap install mcomix-tabetai

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

### ---------------------------- After install ------------------------ ###
## Finishing, updating and cleaning##
cd ~
cat > .bashrc <<EOF
alias sauu='sudo apt update && sudo apt upgrade'
alias sauud='sudo apt update && sudo apt upgrade && sudo apt dist-upgrade'
alias cleaner='sudo apt autoclean && sudo apt autoremove'
EOF

sudo apt update && sudo apt upgrade && apt dist-upgrade -y
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y

echo -e '\n All done! Reboot your pc and keep walking!'
### ------------------------------------------------------------------- ####
