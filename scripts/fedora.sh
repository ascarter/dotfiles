#!/bin/sh

# Install script for Fedora

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Linux only" >&2
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

if [ "$ID" != "fedora" ]; then
  echo "Fedora Linux only" >&2
  exit 1
fi

# Update firmware
sudo fwupdmgr refresh --force
sudo fwupdmgr update

case "$VARIANT_ID" in
silverblue | cosmic-atomic)
  # Update rpm-ostree
  rpm-ostree upgrade

  # Install rpm overlays
  case "$XDG_CURRENT_DESKTOP" in
  COSMIC)
    # Add cosmic specific overlays
    ;;
  GNOME)
    rpm-ostree install --idempotent gnome-tweaks

    # Add minimize button to window controls
    gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
    ;;
  esac
  ;;
server)
  sudo dnf install -y dnf-plugins-core curl git
  ;;
workstation | wsl)
  sudo dnf install -y dnf-plugins-core @development-tools curl git zsh
  ;;
*)
  echo "Fedora $VARIANT_ID not supported"
  exit 1
  ;;
esac

echo 'Fedora provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'

# vim: set ft=sh ts=2 sw=2 et:
