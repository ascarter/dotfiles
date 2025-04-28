#!/bin/sh

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Workstation only" >&2
  exit 1
fi

# Verify Fedora Workstation
. /etc/os-release
if [ "$ID" != "fedora" ] || [ "$VARIANT_ID" != "workstation" ]; then
  echo "Fedora Workstation only" >&2
  exit 1
fi

sudo dnf install -y dnf-plugins-core @development-tools curl git zsh

# Update firmware
sudo fwupdmgr refresh --force
sudo fwupdmgr update

echo 'Fedora Workstation provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'
