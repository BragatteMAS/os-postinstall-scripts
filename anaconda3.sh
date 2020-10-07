###Auto install Science ToolKit
#!/usr/bin/env bash
#Do not use SUDO for this program!!!#
### ----------------------- Tools for Data Science -------------------- ###

# ---------------------------------------------------------------------- #
#Deb packages
URL_RStudio="https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.3.1093-amd64.deb"
URL_Obsidian-"https://github.com/obsidianmd/obsidian-releases/releases/download/v0.9.1/obsidian_0.9.1_amd64.snap"

### ------------------------------------------------------------------- ###
## Download and install external programs .deb ##

HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Downloads="$HOME/Downloads/Programs"
mkdir "$Dir_Downloads"
wget -c "$URL_RStudio" -P "$Dir_Downloads"
wget -c "$URL_Obsidian" -P "$Dir_Downloads"
sudo chmod 777 -R "$Dir_Downloads"
## Installing .deb packages ##
sudo dpkg -i $Dir_Downloads/*.deb
## Other peculiarities
sudo apt install snapd -y
sudo apt update -y
sudo snap install --dangerous obsidian_*.snap

### ---------------------------- After install ------------------------ ###
## Finishing, updating and cleaning##
cd /home/$SUDO_USER/
cat > .bashrc <<EOF

alias sauu='sudo apt update -y && sudo apt upgrade -y'
alias sauud='sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y'
alias clean='sudo apt autoclean && sudo apt autoremove -y'
alias apps='sudo snap refresh && flatpak update -y'
alias condaon='conda config --set auto_activate_base True'
alias condaoff='conda config --set auto_activate_base False'
alias end='sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && sudo fwupdmgr get-devices && sudo fwupdmgr get-updates && sudo fwupdmgr update'
alias rebo='reboot'

EOF

sudo add-apt-repository -r http://dl.google.com/linux/chrome/deb/

### ------------------------------------------------------------------- ###
##Anaconda##
#some prequesites for anaconda#
sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
URL_Anaconda="https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh"
HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Anaconda=$HOME/anaconda3
mkdir "$Dir_Anaconda"
sudo chmod 777 -R "$Dir_Anaconda" 
wget -c "$URL_Anaconda" -P "$Dir_Anaconda" -O ~/anaconda.sh #edit "Anaconda3-xxx" for updates"
bash $HOME/anaconda.sh -b -u -p
##-b(agree with license)-u(unsubscrive)-p(prefix home)
source $HOME/anaconda3/bin/activate ## activate base conda terminal
source $HOME/.bashrc #activate installation
conda config --set auto_activate_base true
#to not activate : conda config --set auto_activate_base false
source $HOME/anaconda3/bin/activate
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
 Exec=bash -c 'export PATH="/home/$SUDO_USER/anaconda3/bin:$PATH" && /home/$SUDO_USER/anaconda3/bin/anaconda-navigator'
 Categories=Development;Science;IDE;Qt;Education;
 Icon=/home/$SUDO_USER/anaconda3/lib/python3.8/site-packages/anaconda_navigator/static/images/anaconda.png
 Terminal=false
 StartupNotify=true
 MimeType=text/x-python;
EOF
