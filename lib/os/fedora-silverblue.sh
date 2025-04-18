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

# Add Ghostty repository
# if ! [ -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo" ]; then
#   sudo sh -c 'echo -e "[copr:copr.fedorainfracloud.org:pgdev:ghostty]\nname=Copr repo for Ghostty owned by pgdev\nbaseurl=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/fedora-\$releasever-\$basearch/\ntype=rpm-md\nskip_if_unavailable=True\ngpgcheck=1\ngpgkey=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/pubkey.gpg\nrepo_gpgcheck=0\nenabled=1\nenabled_metadata=1" > /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo'
# fi

# Update rpm-ostree
rpm-ostree upgrade

# Install rpm overlays
rpm-ostree install --idempotent gnome-tweaks

# Update firmware
sudo fwupdmgr update

# Add minimize button to window controls
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close

echo 'Fedora Silverblue provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'
