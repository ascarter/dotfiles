#!/usr/bin/env bash

# Fedora Atomic host provisioning
#
# Installs minimal rpm-ostree overlays and installs gh-tool.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/rpm.sh"

[ "$(uname -s)" = "Linux" ] || abort "Fedora Linux only"
[ -f /etc/os-release ] || abort "Unsupported Linux distribution"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || abort "Fedora Linux only"

HOST_DIR="${DOTFILES_HOME}/host/fedora-atomic"

log "init" "Provisioning Fedora Atomic host ($VARIANT_ID)"

rpm-ostree upgrade

# Install RPM repositories from manifest
rpm_repo_list="${HOST_DIR}/rpm-repos"
if [ -f "${rpm_repo_list}" ]; then
  while IFS= read -r repo || [ -n "$repo" ]; do
    [[ "$repo" =~ ^#.*$ || -z "$repo" ]] && continue
    add_repo "$repo"
  done < "${rpm_repo_list}"
fi

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

# gh-tool — install CLI tools from GitHub releases
if command -v gh >/dev/null 2>&1; then
  if ! gh extension list 2>/dev/null | grep -q gh-tool; then
    log "gh-tool" "Installing gh-tool extension"
    gh extension install ascarter/gh-tool
  fi
  log "gh-tool" "Installing workstation tools"
  gh tool install
else
  warn "gh" "gh not found — install gh first"
fi

log "init" "Fedora Atomic provisioning complete"
log "init" "Run 'systemctl reboot' to restart"
