#!/bin/sh

# Verify that Flatpak is installed
if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak is not installed."
  return
fi

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak update -y

flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.vivaldi.Vivaldi
flatpak install -y flathub io.github.shiftey.Desktop
flatpak install -y flathub io.missioncenter.MissionCenter
flatpak install -y flathub io.podman_desktop.PodmanDesktop
flatpak install -y flathub org.videolan.VLC

# flatpak install -y flathub org.gnome.Geary

case "$XDG_CURRENT_DESKTOP" in
COSMIC)
  flatpak install -y flathub com.jwestall.Forecast
  flatpak install -y flathub dev.deedles.Trayscale
  flatpak install -y flathub dev.edfloreshz.Calculator
  flatpak install -y flathub io.github.cosmic_utils.Examine
  ;;
GNOME)
  flatpak install -y fedora org.gnome.Connections
  flatpak install -y fedora org.gnome.Extensions
  flatpak install -y fedora org.gnome.Loupe
  flatpak install -y fedora org.gnome.NautilusPreviewer
  flatpak install -y flathub com.mattjakeman.ExtensionManager
  ;;
esac

# Set default applications
xdg-settings set default-web-browser com.vivaldi.Vivaldi.desktop
# xdg-mime default org.gnome.Geary.desktop x-scheme-handler/mailto

# vim: set ft=sh ts=2 sw=2 et:
