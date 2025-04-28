#!/bin/sh

# Install script for Fedora Cosmic Atomic

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Cosmic Atomic only" >&2
  exit 1
fi

# Verify Fedora Cosmic Atomic
if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

if [ "$ID" != "fedora" ] || [ "$VARIANT_ID" != "cosmic-atomic" ]; then
  echo "Fedora Cosmic Atomic only" >&2
  exit 1
fi

# Update rpm-ostree
rpm-ostree upgrade

# Update firmware
sudo fwupdmgr refresh
sudo fwupdmgr update

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo 'Run fprintd-enroll to add fingerprint'

echo 'Fedora Cosmic Atomic provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'
