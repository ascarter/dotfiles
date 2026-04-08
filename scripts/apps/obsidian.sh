#!/usr/bin/env bash
#
# Install Obsidian from AppImage (Linux only).
# macOS users: brew install --cask obsidian
#
# Usage:
#   dotfiles script apps/obsidian          # install latest
#   dotfiles script apps/obsidian v1.8.0   # install specific tag
#
# Installs to:
#   ~/.local/share/appimages/obsidian/  — AppImage file
#   ~/.local/bin/obsidian               — symlink
#   ~/.local/share/applications/        — .desktop file
#   ~/.local/share/icons/               — app icon

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/appimage.sh"

APPIMAGE_REPO="obsidianmd/obsidian-releases"
APPIMAGE_CMD="obsidian"
APPIMAGE_DESKTOP_ID="obsidian"
APPIMAGE_DESKTOP_EXEC="obsidian %u"
APPIMAGE_TAG="${1:-}"
APPIMAGE_VERSION_STRIP_V=1

case "$(uname -s)" in
  Linux) ;;
  Darwin)
    if command -v obsidian >/dev/null 2>&1; then
      log "obsidian" "already installed: $(command -v obsidian)"
    else
      log "obsidian" "not found — install with: brew install --cask obsidian"
    fi
    exit 1
    ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  APPIMAGE_ASSET_PATTERN="Obsidian-{version}.AppImage" ;;
  aarch64) APPIMAGE_ASSET_PATTERN="Obsidian-{version}-arm64.AppImage" ;;
  *) abort "Unsupported architecture: $ARCH" ;;
esac

appimage_install
