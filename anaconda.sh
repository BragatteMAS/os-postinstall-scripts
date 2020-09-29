###Auto install Anaconda 
#!/usr/bin/env bash
#Use SUDO user for this program!!!#
### ----------------------- Tools for Data Science -------------------- ###

##Anaconda##
#some prequesites for anaconda#
sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
URL_Anaconda="https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh"
HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
Dir_Anaconda="$HOME/anaconda3"
mkdir "$Dir_Anaconda"
sudo chmod 777 -R "$Dir_Anaconda" 
wget -c "$URL_Anaconda" -P "$Dir_Anaconda" -O ~/anaconda.sh #edit "Anaconda3-xxx" for updates"
bash ~/anaconda.sh -b -u -p
##-b(agree with license)-u(unsubscrive)-p(prefix home)
source $HOME/anaconda3/bin/activate ## activate base conda terminal
source $HOME/.bashrc #activate installation
conda config --set auto_activate_base true
#to not activate : conda config --set auto_activate_base false
source $HOME/anaconda3/bin/activate
#open new terminal and wirte "anaconda-navigator#
#Create icon for launcher/desktop
#Acess the directory for apps
#cd /usr/share/applications/

sudo apt install python-setuptools python-dev python-numpy sextractor libusb-dev swig \ libcfitsio-dev:i386 python-gobject-2-dev python-gtk2-dev python-gdl \ python-nose python-epydoc -y
sudo apt install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386 -y

wget -c https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh -O ~/anaconda.sh #edit "Anaconda3-xxx" for updates
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
 Icon=/home/$USER/anaconda3/lib/python3.8/site-packages/anaconda_navigator/static/images/anaconda.png
 Terminal=false
 StartupNotify=true
 MimeType=text/x-python;
EOF
#Attention with paths, name of the images and version of python3.*#