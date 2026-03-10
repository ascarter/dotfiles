#!/usr/bin/env bash

# Fedora host provisioning script

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

[ "$(uname -s)" = "Linux" ] || abort "Fedora Linux only"

[ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
. /etc/os-release

[ "${ID:-}" = "fedora" ] || abort "Fedora Linux only"

log "init" "Provisioning Fedora host ($VARIANT_ID)"

case "$VARIANT_ID" in
silverblue | cosmic-atomic)
  log "init" "Fedora Atomic variant detected"

  rpm-ostree upgrade

  # Install rpm overlays
  rpm-ostree install --idempotent git
  rpm-ostree install --idempotent neovim
  rpm-ostree install --idempotent zsh
  rpm-ostree install --idempotent bolt
  rpm-ostree install --idempotent solaar
  rpm-ostree install --idempotent steam-devices

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
  log "init" "Fedora Server detected"
  sudo dnf install -y dnf-plugins-core curl git
  sudo dnf upgrade -y
  ;;

workstation | wsl)
  log "init" "Fedora Workstation/WSL detected"
  sudo dnf install -y dnf-plugins-core @development-tools curl git zsh
  sudo dnf upgrade -y
  ;;

*)
  warn "init" "Fedora $VARIANT_ID not fully supported"
  sudo dnf install -y curl git
  sudo dnf upgrade -y
  ;;
esac

log "init" "Fedora provisioning complete"
log "init" "Run 'systemctl reboot' to restart"
