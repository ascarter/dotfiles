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
  if [ "$ID" != "fedora" ] || [ "$VARIANT_ID" != "silverblue" ]; then
    echo "Fedora Silverblue only" >&2
    exit 1
  fi
else
  echo "Fedora Silverblue only" >&2
fi

# Add Ghostty repository
if ! [ -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo" ]; then
  sudo sh -c 'echo -e "[copr:copr.fedorainfracloud.org:pgdev:ghostty]\nname=Copr repo for Ghostty owned by pgdev\nbaseurl=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/fedora-\$releasever-\$basearch/\ntype=rpm-md\nskip_if_unavailable=True\ngpgcheck=1\ngpgkey=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/pubkey.gpg\nrepo_gpgcheck=0\nenabled=1\nenabled_metadata=1" > /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo'
fi

# Update rpm-ostree
rpm-ostree upgrade

# Install rpm overlays
rpm-ostree install --idempotent 1password 1password-cli ghostty gnome-tweaks zsh

# Update firmware
sudo fwupdmgr update

# Set default shell
usermod --shell /usr/bin/zsh $USER

# Set default applications
xdg-settings set default-web-browser com.vivaldi.Vivaldi.desktop
xdg-mime default org.gnome.Geary.desktop x-scheme-handler/mailto

# Adjust gnome settings
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close

# Install gnome extensions
if ! gnome-extensions info -q nightthemeswitcher@romainvigier.fr ; then
  xdg-open https://extensions.gnome.org/extension/2236/night-theme-switcher/
fi

echo 'Fedora Silverblue provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'