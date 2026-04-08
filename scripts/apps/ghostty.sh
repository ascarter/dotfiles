#!/usr/bin/env bash
#
# Install Ghostty terminal emulator from AppImage (Linux only).
# macOS users: brew install --cask ghostty
#
# Usage:
#   dotfiles script apps/ghostty          # install latest
#   dotfiles script apps/ghostty v1.2.0   # install specific tag
#
# Installs to:
#   ~/.local/share/appimages/ghostty/   — AppImage file
#   ~/.local/bin/ghostty                — symlink
#   ~/.local/share/applications/        — .desktop file
#   ~/.local/share/icons/               — app icon

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/appimage.sh"

APPIMAGE_REPO="pkgforge-dev/ghostty-appimage"
APPIMAGE_CMD="ghostty"
APPIMAGE_DESKTOP_ID="com.mitchellh.ghostty"
APPIMAGE_DESKTOP_EXEC="ghostty --font-size=10"
APPIMAGE_TAG="${1:-}"

case "$(uname -s)" in
  Linux) ;;
  Darwin)
    if command -v ghostty >/dev/null 2>&1; then
      log "ghostty" "already installed: $(command -v ghostty)"
    else
      log "ghostty" "not found — install with: brew install --cask ghostty"
    fi
    exit 1
    ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  APPIMAGE_ASSET_GLOB="Ghostty-*-x86_64.AppImage" ;;
  aarch64) APPIMAGE_ASSET_GLOB="Ghostty-*-aarch64.AppImage" ;;
  *) abort "Unsupported architecture: $ARCH" ;;
esac

appimage_install
