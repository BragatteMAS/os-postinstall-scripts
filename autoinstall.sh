#!/usr/bin/env bash
# ---------------------------------------------------------------------- #
#APT
## program name used in sudo method

DIRETORIO_DOWNLOADS="$HOME/Downloads/programs"

APT_INSTALL=(
  libvulkan1
  libvulkan1:i386
  libgnutls30:i386
  libldap-2.4-2:i386
  libgpg-error0:i386
  libxml2:i386
  libasound2-plugins:i386\x 
  libsdl2-2.0-0:i386
  libfreetype6:i386
  libdbus-1-3:i386
  libsqlite3-0:i386
  
)

## Install programs apt
for apt_program in ${APT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $apt_program; then # Just install if not exist
    apt install "$apt_program" -y
  else
    echo "[successful installation] - $apt_program"
  fi
done

# ---------------------------------------------------------------------- #
#SNAP
## program name used in SNAP store
 SNAP_INSTALL=(
  foliate
  homeserver
  gifcurry

)

## Install programs apt
for snap_program in ${SNAP_INSTALL[@]}; do
  if ! dpkg -l | grep -q $snap_program; then # Just install if not exist
    snap install "$snap_program" -y
  else
    echo "[successful installation] - $snap_program"
  fi
done
# ---------------------------------------------------------------------- #
#Flatpak
## program name used in Flathub
 FLAT_INSTALL=(
  com.valvesoftware.Steam
  
  org.freedesktop.Piper
  com.valvesoftware.Steam
  com.github.johnfactotum.Foliate
  org.jamovi.jamovi
  ch.openboard.OpenBoard
  org.geogebra.GeoGebra
  com.rafaelmardojai.Blanket
  org.librehunt.Organizer
  
)

## Install programs apt
for flat_program in ${FLAT_INSTALL[@]}; do
  if ! dpkg -l | grep -q $flat_program; then # Just install if not exist
    flatpak install flathub "$flat_program" -y
  else
    echo "[successful installation] - $flat_program"
  fi
done
