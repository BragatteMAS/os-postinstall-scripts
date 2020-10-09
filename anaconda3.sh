#!/usr/bin/env bash
###Auto install anaconda 
#Use SUDO user for this program!!!#
### ----------------------- Tools for Data Science -------------------- ###

##Anaconda##
sudo apt install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 -y

wget -c https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh -O /home/$SUDO_USER/anaconda.sh #edit "Anaconda3-xxx" for updates
bash /home/$SUDO_USER/anaconda.sh -b -u -p /home/$SUDO_USER/anaconda3
#-b(agree with license)-u(unsubscrive)-p(prefix home)
sudo chmod -R 777 /home/$SUDO_USER/anaconda3

source /home/$LOGNAME/anaconda3/bin/activate ## activate base conda terminal
source /home/$LOGNAME/.bashrc #activate installation
conda config --set auto_activate_base true
#to not activate : conda config --set auto_activate_base false
source /home/$LOGNAME/anaconda3/bin/activate

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