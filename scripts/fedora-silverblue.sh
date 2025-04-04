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

# Add 1Password repository
if ! [ -f /etc/yum.repos.d/1password.repo ]; then
  sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
fi

# Add Tailscale repository
if ! [ -f /etc/yum.repos.d/tailscale.repo ]; then
  sudo curl -L -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
fi

# Add Ghostty repository
if ! [ -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo" ]; then
  sudo sh -c 'echo -e "[copr:copr.fedorainfracloud.org:pgdev:ghostty]\nname=Copr repo for Ghostty owned by pgdev\nbaseurl=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/fedora-\$releasever-\$basearch/\ntype=rpm-md\nskip_if_unavailable=True\ngpgcheck=1\ngpgkey=https://download.copr.fedorainfracloud.org/results/pgdev/ghostty/pubkey.gpg\nrepo_gpgcheck=0\nenabled=1\nenabled_metadata=1" > /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:pgdev:ghostty.repo'
fi

# Update rpm-ostree
rpm-ostree upgrade

# Install rpm overlays
rpm-ostree install --idempotent 1password 1password-cli ghostty gnome-tweaks tailscale terminus-fonts-console zsh

# Update firmware
sudo fwupdmgr update

# Install Flatpaks
flatpak update -y
flatpak install -y com.vivaldi.Vivaldi
flatpak install -y com.valvesoftware.Steam

# Set default shell
usermod --shell /usr/bin/zsh $USER

# Configure TTY for hidpi
if ! [ -f /etc/vconsole.config.orig ]; then
  sudo cp /etc/vconsole.conf /etc/vconsole.conf.orig
  sudo sh -c 'echo -e "KEYMAP=\"us\"\nFONT=\"ter-132n\"" > /etc/vconsole.conf'
fi

# Configure Grub for hidpi
# sudo sh -c 'echo -e "set gfxmode=1024x768\ninsmod gfxterm\nset gfxpayload=keep\nterminal_input gfxterm\nterminal_output gfxterm" > /boot/grub2/user.cfg'

# Adjust gnome settings
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close

# Enable tailscale
if command -v tailscaled > /dev/null 2>&1; then
  systemctl enable --now tailscaled
  sudo tailscale up --ssh --accept-routes
fi

echo 'Fedora Silverblue provisioning complete'
echo 'Run "systemctl reboot" to start a reboot'
echo 'Run "sudo tailscale up --sh --accept-routes" to start Tailscale'
