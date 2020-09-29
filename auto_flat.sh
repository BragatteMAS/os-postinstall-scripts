#!/usr/bin/env bash 

echo ' \n Auto install programs with Flathub. \n '

# ---------------------------------------------------------------------- #
#Programs select from Flathub store <https://flathub.org/home>
# -----------------------------VARIABLES-------------------------------- #
FLAT_INSTALL=(
flatseal            #System|permissions
filezilla           #System|SQL manager
boxes               #System|virtualization
Vim				          #Terminal|alternative
obsproject.Studio   #Video|streaming software
zoom				        #Video|webinars
slack			          #Comunication|team chat
skype			          #Comunication|chat support
dropbox			        #Productivity|online files manager
masterpdf 	        #Productivity|pdf-editor
ankiweb             #Productivity|Flashcards
wps 			          #Productivity|office reader for doc win
jamovi			        #Productivity|real-time, statisticial spreadsheet
openboard	          #Productivity|educational software interactive board
geogebra	          #Productivity|dynamic geometry program
blanket		          #Productivity|back environmental sounds to work
organizer	          #Productivity|shifts your files according to their filetype
meld                #Productivity|diif across files
calibre             #Productivity|reader kindle types
gitkraken           #Productivity|code commit

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
