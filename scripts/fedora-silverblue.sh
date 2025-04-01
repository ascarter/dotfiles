#!/bin/sh

# Install script for Fedora Silverblue

set -euo pipefail

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Silverblue only" >&2
  exit 1
fi

# Verify Fedora Silverblue
. /etc/os-release
if [ "$ID" != "fedora" ] || [ "$VARIANT_ID" != "silverblue" ]; then
  echo "Fedora Silverblue only" >&2
  exit 1
fi

# TODO: Update rpm-ostree

# Install Flatpaks
flatpak install -y com.vivaldi.Vivaldi

# Install rpm overlays
rpm-ostree install gnome-tweaks zsh

# Install 1Password
sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
rpm-ostree install 1password 1password-cli

# Install Tailscale
sudo curl -L -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
rpm-ostree install tailscale

# Check to see if /usr/lib/systemd/system/tailscaled.service exists
systemctl enable --now tailscaled
sudo tailscale up --ssh --accept-routes

# Ghostty
sudo sh -c 'echo -e "[copr:copr.fedorainfracloud.org:pgdev:ghostty]\nname=Copr repo for Ghostty owned by pgdev\nbaseurl=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/fedora-\$releasever-\$basearch/\ntype=rpm-md\nskip_if_unavailable=True\ngpgcheck=1\ngpgkey=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/pubkey.gpg\nrepo_gpgcheck=0\nenabled=1\nenabled_metadata=1" > /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo'
rpm-ostree install ghostty

# Set default shell
chsh -s /usr/bin/zsh

# Adjust gnome settings
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close

# Hide Firefox
sudo cp /usr/share/applications/org.mozilla.firefox.desktop /usr/local/share/applications/
sudo sed -i "2a\\NotShowIn=GNOME;KDE" /usr/local/share/applications/org.mozilla.firefox.desktop
sudo update-desktop-database /usr/local/share/applications/

echo 'Fedora Silverblue provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'
