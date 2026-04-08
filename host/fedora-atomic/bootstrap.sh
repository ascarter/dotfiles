#!/usr/bin/env bash

# Fedora Atomic host provisioning
#
# Installs minimal rpm-ostree overlays and ensures aqua is available.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Linux" ] || abort "Fedora Linux only"
[ -f /etc/os-release ] || abort "Unsupported Linux distribution"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || abort "Fedora Linux only"

HOST_DIR="${DOTFILES_HOME}/host/fedora-atomic"

log "init" "Provisioning Fedora Atomic host ($VARIANT_ID)"

rpm-ostree upgrade

# Install overlays from manifest
overlay() { rpm-ostree install --idempotent "$@" || warn "overlay" "failed: $*"; }

overlay_pkgs="${HOST_DIR}/overlay-rpms"
if [ -f "${overlay_pkgs}" ]; then
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    overlay "$pkg"
  done < "${overlay_pkgs}"
fi

# Desktop-specific overlays
case "${XDG_CURRENT_DESKTOP:-}" in
COSMIC)
  ;;
GNOME)
  overlay gnome-tweaks
  gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
  ;;
esac

# Aqua
log "aqua" "Installing aqua"
"${DOTFILES_HOME}/bin/dotfiles" script aqua

log "init" "Fedora Atomic provisioning complete"
log "init" "Run 'systemctl reboot' to restart"
