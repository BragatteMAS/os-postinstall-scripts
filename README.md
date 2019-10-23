# Linux_posintall_script
Scripts for preparing linux environmental.

Pos-install scripts are made to execute after install linux SO (example:UBUNTU).
  This scripts will install programs autonomously.
  
  1. Save the file with name.sh - example: posintall.sh
  2. In the directory (/home/$USER/Downloads) execute the script in "sudo" mode with "./" command
  
    example: 2.1 sudo chmod 777 posintall_script.sh
             2.2 sudo ./posintall_script.sh

 ### P.S.: Sometimes an error with "anaconda-navigator" occur, subscribing the "$USER" with "root" ###
 #To solve this issue, edit the file at sudo in the terminal with gedit or nano.
 
    example:    
    cd /usr/share/applications/
    sudo gedit Anaconda-Navigator
             
    correction:
    Exec=bash -c 'export PATH="/home/$USER/Downloads/anaconda3/bin:$PATH" && /home/$USER/anaconda3/bin/anaconda-navigator'
    Categories=Development;Science;IDE;Qt;Education;
    Icon=/home/$USER/anaconda3/lib/python3.7/site-packages/anaconda_navigator/static/images/anaconda.png
   
And save the edited file.
### Done! ###
 
 Versions should works for Debian / Ubuntu / Mint with litlle adaptation.
 
 Tested 23/10/19 at Mint 19.02 & Ubuntu 18.04 = status ok
  
