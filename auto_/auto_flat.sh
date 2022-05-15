#!/usr/bin/env bash 

echo ' \n Auto install programs with Flathub. \n '

# ---------------------------------------------------------------------- #
#Programs select from Flathub store <https://flathub.org/home>
# -----------------------------VARIABLES FLAT-------------------------------- #
FLAT_INSTALL=(
flatseal            #System|permissions
filezilla           #System|SQL manager
org.gnome.Boxes     #System|virtualization
vim.vim             #Terminal|alternative
pavucontrol	     #Sound|Control
obsproject.Studio   #Video|streaming software
org.blender.Blender #Video|3D pipeline—model,animation,simulation,rendering
org.videolan.VLC    #Video|media player open-source
zoom                #Video|webinars
slack               #Comunication|team chat
skype               #Comunication|chat support
dropbox             #Productivity|online files manager
masterpdf           #Productivity|pdf-editor
ankiweb             #Productivity|Flashcards
com.wps.Office      #Productivity|office reader for doc win
jamovi              #Productivity|real-time, statisticial spreadsheet
openboard           #Productivity|educational software interactive board
geogebra            #Productivity|dynamic geometry program
blanket             #Productivity|back environmental sounds to work
organizer           #Productivity|shifts your files according to their filetype
meld                #Productivity|diif across files
calibre             #Productivity|reader kindle types
gitkraken           #Productivity|code commit
Epiphany	     #Productivity|browser	

)
# ---------------------------------------------------------------------- #
##Install Flatpak repository of apps for Linux
sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------------- #
## Install programs FLAT
for flat_program in ${FLAT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $flat_program; then # Just install if not exist
    flatpak install flathub "$flat_program" -y
  fi
done

# ---------------------------------------------------------------------- #
## Updating the repository ##
flatpak update -y

echo ' \n Done! Select packages install with Flathub packs. \n '
