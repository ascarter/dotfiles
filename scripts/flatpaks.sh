#!/bin/sh

# Verify that Flatpak is installed
if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak is not installed. Please install Flatpak before running this script."
  exit 1
fi

flatpak update -y

# Install Flatseal for managing Flatpak permissions
echo "Installing essential Flatpaks..."
flatpak install -y com.github.tchx84.Flatseal
flatpak install -y com.mattjakeman.ExtensionManager
flatpak install -y io.missioncenter.MissionCenter
flatpak install -y io.podman_desktop.PodmanDesktop
flatpak install -y org.gnome.Connections
flatpak install -y org.gnome.Loupe
flatpak install -y org.gnome.NautilusPreviewer

echo "Installing Flatpaks from Flathub..."
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub com.vivaldi.Vivaldi
flatpak install -y flathub io.github.shiftkey.Desktop
flatpak install -y flathub org.gnome.Geary