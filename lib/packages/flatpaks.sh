#!/bin/sh

install() {
  # Verify that Flatpak is installed
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "Flatpak is not installed."
    return
  fi

  flatpak update -y

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
}

uninstall() {
  echo "Flatpak uninstall not supported"
}

info() {
  if command -v flatpak >/dev/null 2>&1; then
    flatpak list
  else
    echo "Flatpak is not installed."
  fi
}

doctor() {
  info
}
