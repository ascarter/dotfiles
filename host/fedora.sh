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

  overlay() { rpm-ostree install --idempotent "$@" || warn "overlay" "failed: $*"; }

  overlay git
  overlay neovim
  overlay zsh
  overlay bolt
  overlay solaar
  overlay steam-devices

  case "${XDG_CURRENT_DESKTOP:-}" in
  COSMIC)
    # Add cosmic specific overlays here if needed
    ;;
  GNOME)
    overlay gnome-tweaks
    gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
    ;;
  esac
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
