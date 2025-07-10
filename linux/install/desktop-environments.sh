#!/usr/bin/env bash
# Install alternative desktop environments (flavors) for GNOME
set -euo pipefail
IFS=$'\n\t'

echo "Desktop Environment Installer"
echo "============================="
echo ""
echo "Available desktop environments:"
echo "1. Cinnamon"
echo "2. KDE Plasma (Kubuntu)"
echo "3. Xfce (Xubuntu)"
echo "4. MATE (Ubuntu MATE)"
echo "5. LXQt (Lubuntu)"
echo "6. Budgie (Ubuntu Budgie)"
echo "0. Exit"
echo ""

read -p "Select desktop environment to install (0-6): " choice

case $choice in
    1)
        echo "Installing Cinnamon desktop environment..."
        sudo apt install -y cinnamon-desktop-environment
        ;;
    2)
        echo "Installing KDE Plasma desktop..."
        sudo apt install -y kubuntu-desktop
        ;;
    3)
        echo "Installing Xfce desktop..."
        sudo apt install -y xubuntu-desktop
        ;;
    4)
        echo "Installing MATE desktop..."
        sudo apt install -y ubuntu-mate-desktop
        ;;
    5)
        echo "Installing LXQt desktop..."
        sudo apt install -y lubuntu-desktop
        ;;
    6)
        echo "Installing Budgie desktop..."
        sudo apt install -y ubuntu-budgie-desktop
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo "Installation complete! Please log out and select the new desktop environment at login."