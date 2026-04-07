#!/usr/bin/env bash
#
# Install Ghostty terminal emulator from AppImage (Linux only).
# macOS users: brew install --cask ghostty
#
# Usage:
#   dotfiles script appimage/ghostty          # install latest
#   dotfiles script appimage/ghostty v1.2.0   # install specific tag
#
# Installs to:
#   ~/.local/share/appimages/ghostty/   — AppImage file
#   ~/.local/bin/ghostty                — symlink
#   ~/.local/share/applications/        — .desktop file
#   ~/.local/share/icons/               — app icon

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

REPO="pkgforge-dev/ghostty-appimage"
CMD="ghostty"
DESKTOP_ID="com.mitchellh.ghostty"
DESKTOP_EXEC="ghostty --font-size=10"
TAG="${1:-}"

: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

APPIMAGE_DIR="${XDG_DATA_HOME}/appimages/${CMD}"
CACHE_DIR="${XDG_CACHE_HOME}/appimages/${CMD}"

# ---------- platform check ----------

case "$(uname -s)" in
  Linux) ;;
  Darwin)
    log "$CMD" "AppImages are Linux-only. Run: brew install --cask ghostty"
    exit 1
    ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ASSET_GLOB="Ghostty-*-x86_64.AppImage" ;;
  aarch64) ASSET_GLOB="Ghostty-*-aarch64.AppImage" ;;
  *) abort "Unsupported architecture: $ARCH" ;;
esac

# ---------- resolve version ----------

if [[ -z "$TAG" ]]; then
  log "$CMD" "resolving latest release..."
  TAG=$(gh release list --repo "$REPO" --limit 20 \
    --json tagName,isPrerelease,isDraft \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not)))[0].tagName // empty')
  [[ -n "$TAG" ]] || abort "Could not determine latest release for $REPO"
fi

log "$CMD" "version: $TAG"

# ---------- download ----------

mkdir -p "$CACHE_DIR" "$APPIMAGE_DIR" "$XDG_BIN_HOME"

log "$CMD" "downloading $REPO $TAG..."
gh release download "$TAG" \
  --repo "$REPO" \
  --pattern "$ASSET_GLOB" \
  --dir "$CACHE_DIR" \
  --clobber

APPIMAGE_FILE=$(find "$CACHE_DIR" -maxdepth 1 -name "$ASSET_GLOB" | head -n1)
[[ -n "$APPIMAGE_FILE" ]] || abort "No asset matching $ASSET_GLOB found"

# ---------- install ----------

# Move AppImage to permanent location
rm -f "${APPIMAGE_DIR}"/*.AppImage
mv "$APPIMAGE_FILE" "$APPIMAGE_DIR/"
INSTALLED="${APPIMAGE_DIR}/$(basename "$APPIMAGE_FILE")"
chmod +x "$INSTALLED"

# Symlink to PATH
ln -sf "$INSTALLED" "${XDG_BIN_HOME}/${CMD}"
log "$CMD" "linked ${XDG_BIN_HOME}/${CMD}"

# ---------- desktop integration ----------

EXTRACT_DIR=$(mktemp -d -t "${CMD}-extract.XXXXXXXX")
cleanup() { rm -rf "$EXTRACT_DIR"; }
trap cleanup EXIT

(cd "$EXTRACT_DIR" && "$INSTALLED" --appimage-extract >/dev/null 2>&1) \
  || { warn "$CMD" "AppImage extraction failed — skipping desktop integration"; exit 0; }

ROOT="${EXTRACT_DIR}/squashfs-root"
APP_DIR="${XDG_DATA_HOME}/applications"
ICON_DIR="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
install -d "$APP_DIR" "$ICON_DIR"

# .desktop file
DESKTOP_FILE="${ROOT}/${DESKTOP_ID}.desktop"
if [[ -f "$DESKTOP_FILE" ]]; then
  install -m 0644 "$DESKTOP_FILE" "${APP_DIR}/${DESKTOP_ID}.desktop"
  sed -i '/^TryExec=/d' "${APP_DIR}/${DESKTOP_ID}.desktop"
  sed -i "s|^Exec=.*$|Exec=${DESKTOP_EXEC}|g" "${APP_DIR}/${DESKTOP_ID}.desktop"
  log "$CMD" "installed .desktop file"
fi

# Icon
ICON_FILE=""
for ext in png svg; do
  ICON_FILE=$(find -L "$ROOT" -maxdepth 1 -name "${DESKTOP_ID}.${ext}" | head -n1)
  [[ -n "$ICON_FILE" ]] && break
done
if [[ -n "$ICON_FILE" ]]; then
  install -m 0644 "$ICON_FILE" "${ICON_DIR}/$(basename "$ICON_FILE")"
  log "$CMD" "installed icon"
fi

command -v update-desktop-database >/dev/null 2>&1 \
  && update-desktop-database "$APP_DIR" 2>/dev/null || true

success "Ghostty $TAG installed"
