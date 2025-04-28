#!/bin/sh

# Install script for Fedora Silverblue

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Silverblue only" >&2
  exit 1
fi

# Verify Fedora Silverblue
if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

if [ "$ID" != "fedora" ] || [ "$VARIANT_ID" != "silverblue" ]; then
  echo "Fedora Silverblue only" >&2
  exit 1
fi

# Update rpm-ostree
rpm-ostree upgrade

# Install rpm overlays
rpm-ostree install --idempotent gnome-tweaks

# Update firmware
sudo fwupdmgr refresh --force
sudo fwupdmgr update

# Add minimize button to window controls
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close

echo 'Fedora Silverblue provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'
