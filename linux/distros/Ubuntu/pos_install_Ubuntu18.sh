#!/usr/bin/env bash

#NOTE: Run this script with 'sudo'
#Versão 0.8

echo -e '	\n Auto install Bragatte_mode!!!! \n	'

### ----------------------- Variable PPA & URLs ----------------------- ###
PPA_Timeshift="ppa:teejee2008/ppa"
PPA_Graphics_drivers="ppa:graphics-drivers/ppa"
PPA_Lutris="ppa:lutris-team/lutris"
PPA_Libratbag="ppa:libratbag-piper/piper-libratbag-git"
PPA_Screenrecorder="ppa:maarten-baert/simplescreenrecorder"


URL_Wine_key="https://dl.winehq.org/wine-builds/winehq.key"
URL_PPA_Wine="https://dl.winehq.org/wine-builds/ubuntu/"
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_Albert="https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_18.04/amd64/albert_0.16.1_amd64.deb"
URL_PPA_Albert="https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_18.04/"
URL_SIMPLE_NOTE="https://github.com/Automattic/simplenote-electron/releases/download/v1.8.0/Simplenote-linux-1.8.0-amd64.deb"
URL_4K_VIDEO_DOWNLOADER="https://dl.4kdownload.com/app/4kvideodownloader_4.9.2-1_amd64.deb"
URL_INSYNC="https://d2t3ff60b2tol4.cloudfront.net/builds/insync_3.0.20.40428-bionic_amd64.deb"

URL_Chimera="https://www.cgl.ucsf.edu/chimera/cgi-bin/secure/chimera-get.py?file=linux_x86_64/chimera-1.14-linux_x86_64.bin"
URL_ChimeraX="https://www.rbvi.ucsf.edu/chimerax/download.html/file=ubuntu-18.04/ucsf-chimerax_0.9_amd64.deb"

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
sudo apt-add-repository "$PPA_Timeshift" -y		# timeshift
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
wget -c "$URL_SIMPLE_NOTE" -P "$Dir_Downloads"
wget -c "$URL_4K_VIDEO_DOWNLOADER" -P "$Dir_Downloads"
wget -c "$URL_INSYNC" -P "$Dir_Downloads"
wget -c "$URL_Chimera" -P "$Dir_Downloads"
wget -c "$URL_ChimeraX" -P "$Dir_Downloads"

## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb

## APT repository programs##
sudo apt install albert -y # global search at system
sudo apt install zsh -y # alternative option for bash in terminal
sudo apt install tmux -y # split virtual terminals 
sudo apt install tilix zsh -y #virtual terminal custom
sudo apt install rpm yum -y # other formats in linux
sudo apt install flameshot -y # capture and film screen
sudo apt install simplescreenrecorder -y # capture and film screen2
sudo apt install timeshift -y # backup of our Linux system
sudo apt install gnome-sushi -y # previsualize files pressing space
sudo apt install winff -y # convert vieo formats
sudo apt install guvcview -y # webcam app for streams
sudo apt install make - Y # support install packages
sudo apt install openssh-server -y # remotely controlling & transferring
sudo apt install audacity -y # digital audio editor and recording app
sudo apt install xpad -y # sticky note application for GTK
sudo apt install python-pip -y # installs packages
sudo apt install wps-office -y # use office files at linux
sudo apt install virtualbox -y #emulate SO version 5
 sudo adduser $USER vboxusers
sudo apt install build-essential default-jdk libssl-dev exuberant-ctags ncurses-term ack-grep silversearcher-ag fontconfig imagemagick libmagickwand-dev software-properties-common git vim-gtk3 curl -y # programmer packages
sudo apt install htop gdebi synaptic grsync bleachbit gufw gnome-tweak-tool unity-tweak-tool -y # system suporters
sudo apt install ubunutu-restricted-extras -y 
sudo apt install mint-meta-codecs -y # for MINT distro
sudo apt install nemo-dropbox -yy # for MINT distro

## Gamers repositories and packages ##
# sudo apt install steam-installer steam-devices steam:i386 -y
#sudo apt install ratbagd piper -y #optional config mouse
# sudo apt install lutris libvulkan1 libvulkan1:i386 -y
#sudo apt install --install-recommends winehq-stable wine-stable wine-stable-i386 wine-stable-amd64 -y
#sudo apt install libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

##Instaling Flatpak packages ##
flatpak install flathub com.obsproject.Studio -y

##Instaling Snap packages ##
sudo snap install sublime-text --classic #IDE generic
sudo snap install atom --classic #IDE generic other option
sudo snap install pycharm-community --classic #IDE python
sudo snap install notepad-plus-plus #text editor (work with wine)
sudo snap install simplenote #keep notes
sudo snap install inkscape #vector graphics software
sudo snap install blender-tpaw #3D pipeline—modeling, animation, simulation, rendering.
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
### ------------------------------------------------------------------- ###

### ----------------------- Tools for Data Science -------------------- ###
#Recomended download the files first only for this "chimera*" programs
#sudo apt install ucsf-chimerax_0.9_amd64.deb -y
#sudo apt install chimera-1.14-linux_x86_64.bin -y

##Anaconda##
#some prequesites for anaconda#
sudo apt install python-setuptools python-dev python-numpy sextractor libusb-dev swig \ libcfitsio-dev:i386 python-gobject-2-dev python-gtk2-dev python-gdl \ python-nose python-epydoc -y
sudo apt install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

wget -c https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh -O ~/anaconda.sh #edit "Anaconda3-xxx" for updates
sudo bash ~/anaconda.sh -b -u -p
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

##ASDF - CLI tool that can manage multiple language runtime versions on a per-project basis
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.4
#''' https://asdf-vm.com/#/core-manage-asdf-vm?id=install-asdf-vm https://github.com/asdf-vm/asdf '''
#check the last version#
#git clone https://github.com/asdf-vm/asdf.git ~/.asdf
#cd ~/.asdf
#git checkout "$(git describe --abbrev=0 --tags)"

#Bash
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

#Zsh
#echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
#echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc

sudo apt install \
  automake autoconf libreadline-dev \
  libncurses-dev libssl-dev libyaml-dev \
  libxslt-dev libffi-dev libtool unixodbc-dev \
  unzip curl

asdf update
#After restart terminal, could install pluggins for different languages
#asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git #ruby
#asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git #nodejs / javascript
#bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
#asdf plugin-add golang https://github.com/kennyp/asdf-golang.git #golang
#asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git #erlang
#sudo apt -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop
#asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
#asdf plugin-add kotlin https://github.com/missingcharacter/asdf-kotlin.git #kotlin
#asdf plugin-add crystal https://github.com/marciogm/asdf-crystal.git # crystal
#sudo apt -y install postgresql-10 postgresql-contrib postgresql-server-dev-10 redis-server libhiredis-dev memcached libmemcached-dev #Data banks...

## Programs with alternative versions - specific demand ##
#Albert
#sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_18.04/ /' > /etc/apt/sources.list.d/home:manuelschneid3r.list"
#wget -nv https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_18.04/Release.key -O Release.key
#sudo apt-key add - < Release.key
#sudo apt-get update
#sudo apt-get install albert
 # Ref: https://software.opensuse.org/download.html?project=home:manuelschneid3r&package=albert #
 
 #Balena Etcher
 #echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
 #sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
 #sudo apt-get update
 #sudo apt-get install balena-etcher-electron 
 
 #VirtualBox 6.0
 #wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
 #sudo apt update
 #sudo apt install virtualbox-6.0 -y #emulate SO
 #sudo adduser $USER vboxusers

### ------------------------------------------------------------------- ###


### ---------------------------- After install ------------------------ ###
## Finishing, updating and cleaning##
sudo apt update && sudo apt upgrade && apt dist-upgrade -y
alias sauu='sudo apt update && sudo apt upgrade'
alias sauud='sudo apt update && sudo apt upgrade && sudo apt dist-upgrade'
flatpak update -y
sudo apt autoclean
sudo apt autoremove -y
alias cleaner='sudo apt autoclean && sudo apt autoremove'
echo -e '\n All done! Reboot your pc and keep walking!'
### ------------------------------------------------------------------- ####
