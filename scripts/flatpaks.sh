#!/bin/sh

# Verify that Flatpak is installed
if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak is not installed. Please install Flatpak before running this script."
  exit 1
fi

flatpak update -y

# Install Flatseal for managing Flatpak permissions
echo "Installing fedora Flatpaks"
flatpak install -y fedora com.github.tchx84.Flatseal
flatpak install -y fedora org.gnome.Connections
flatpak install -y fedora org.gnome.Extensions
flatpak install -y fedora org.gnome.Loupe
flatpak install -y fedora org.gnome.NautilusPreviewer

echo "Installing flathub Flatpaks"
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub com.vivaldi.Vivaldi
flatpak install -y flathub io.missioncenter.MissionCenter
flatpak install -y flathub io.podman_desktop.PodmanDesktop
flatpak install -y flathub org.gnome.Geary

# Set default applications
xdg-settings set default-web-browser com.vivaldi.Vivaldi.desktop
xdg-mime default org.gnome.Geary.desktop x-scheme-handler/mailto
