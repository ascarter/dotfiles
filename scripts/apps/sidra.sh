#!/usr/bin/env bash
#
# Install Sidra, an Apple Music desktop client, from AppImage (Linux x86_64 only).
# macOS/Windows users: download the installer from
# https://github.com/wimpysworld/sidra/releases
#
# Usage:
#   dotfiles script apps/sidra          # install latest
#   dotfiles script apps/sidra 0.3.5    # install specific tag
#
# Installs to:
#   ~/.local/share/appimages/sidra/  — AppImage file
#   ~/.local/bin/sidra               — symlink
#   ~/.local/share/applications/     — .desktop file
#   ~/.local/share/icons/            — app icon (Apple Music icon, not Sidra's default)

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/appimage.sh"

APPIMAGE_REPO="wimpysworld/sidra"
APPIMAGE_CMD="sidra"
APPIMAGE_DESKTOP_ID="sidra"
APPIMAGE_DESKTOP_EXEC="sidra %U"
APPIMAGE_TAG="${1:-}"
APPIMAGE_ASSET_GLOB="Sidra-linux-x86_64.AppImage"

case "$(uname -s)" in
  Linux) ;;
  Darwin)
    if command -v sidra >/dev/null 2>&1; then
      log "sidra" "already installed: $(command -v sidra)"
    else
      log "sidra" "not found — download the .dmg from: https://github.com/wimpysworld/sidra/releases"
    fi
    exit 0
    ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ;;
  *) abort "Unsupported architecture: $ARCH (Sidra only ships a Linux x86_64 AppImage)" ;;
esac

appimage_install

: "${XDG_DATA_HOME:=$HOME/.local/share}"
icon_dir="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
install -d "$icon_dir"

icon_src=$(curl -fsSL https://music.apple.com/manifest.json | jq -r '.icons[] | select(.purpose=="any") | .src' | head -n1)
if [ -n "$icon_src" ] && curl -fsSL "https://music.apple.com/${icon_src}" -o "${icon_dir}/sidra.png.tmp"; then
  mv "${icon_dir}/sidra.png.tmp" "${icon_dir}/sidra.png"
  log "sidra" "installed Apple Music icon"
else
  rm -f "${icon_dir}/sidra.png.tmp"
  warn "sidra" "could not fetch Apple Music icon — keeping default"
fi

command -v gtk-update-icon-cache >/dev/null 2>&1 \
  && gtk-update-icon-cache -f -t "${XDG_DATA_HOME}/icons/hicolor" 2>/dev/null || true
