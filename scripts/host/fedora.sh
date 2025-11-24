#!/bin/sh

# Fedora host provisioning script

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

# Verify Linux
[ "$(uname -s)" == "Linux" ] || abort "Fedora Linux only"

if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

[ "$ID" == "fedora" ] || abort "Fedora Linux only"

echo "Provisioning Fedora host ($VARIANT_ID)"

# Update firmware
if command -v fwupdmgr >/dev/null 2>&1; then
  "Updating firmware..."
  sudo fwupdmgr refresh --force
  sudo fwupdmgr update
fi

case "$VARIANT_ID" in
silverblue | cosmic-atomic)
  echo "Fedora Atomic variant detected"

  # Add Tailscale RPM repository
  # curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo | sudo tee /etc/yum.repos.d/tailscale.repo

  rpm-ostree upgrade

  # Install rpm overlays
  rpm-ostree install --idempotent tailscale zsh

  # Set zsh as default shell
  # chsh -s /bin/zsh "$USER"

  # Tailscale enable and start on reboot via systemd
  # sudo systemctl enable --now tailscaled

  case "${XDG_CURRENT_DESKTOP:-}" in
  COSMIC)
    # Add cosmic specific overlays here if needed
    ;;
  GNOME)
    rpm-ostree install --idempotent gnome-tweaks
    gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
    ;;
  esac

  # Update flatpaks
  if command -v flatpak >/dev/null 2>&1; then
    flatpak update -y
  fi
  ;;

server)
  echo "Fedora Server detected"
  sudo dnf install -y dnf-plugins-core curl git
  sudo dnf upgrade -y
  ;;

workstation | wsl)
  echo "Fedora Workstation/WSL detected"
  sudo dnf install -y dnf-plugins-core @development-tools curl git zsh
  sudo dnf upgrade -y
  ;;

*)
  echo "Fedora $VARIANT_ID not fully supported"
  sudo dnf install -y curl git
  sudo dnf upgrade -y
  ;;
esac

echo "Fedora provisioning complete"
echo "Run 'systemctl reboot' to restart"
