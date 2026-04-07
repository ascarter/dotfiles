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

if [ -f "${HOST_DIR}/overlay-packages.txt" ]; then
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    overlay "$pkg"
  done < "${HOST_DIR}/overlay-packages.txt"
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
AQUA_BIN="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin"
if ! command -v aqua >/dev/null 2>&1 && ! [ -x "${AQUA_BIN}/aqua" ]; then
  log "aqua" "Installing aqua"
  curl -sSfL https://raw.githubusercontent.com/aquaproj/aqua-installer/v4.0.2/aqua-installer | bash
fi
export PATH="${AQUA_BIN}:${PATH}"
if command -v aqua >/dev/null 2>&1; then
  log "aqua" "Installing workstation tools"
  aqua i -a
else
  warn "aqua" "aqua installation failed"
fi

log "init" "Fedora Atomic provisioning complete"
log "init" "Run 'systemctl reboot' to restart"
