#!/usr/bin/env bash
set -euo pipefail
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/tool.sh"

abort() { printf '%s\n' "$1" >&2; exit 1; }

if command -v ghostty >/dev/null 2>&1; then
  echo "ghostty already installed: $(command -v ghostty)"
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    echo "ghostty not found. Run: brew install --cask ghostty"
    exit 1
    ;;
  Linux)
    VERSION="1.2.3"
    ARCH="$(uname -m)"

    GHOSTTY_URL="https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v${VERSION}/Ghostty-${VERSION}-${ARCH}.AppImage"
    GHOSTTY_APP_DIR="${XDG_OPT_HOME}/ghostty"
    GHOSTTY_APP="${GHOSTTY_APP_DIR}/Ghostty-${VERSION}-${ARCH}.AppImage"
    GHOSTTY_BIN="${TOOLS_BIN}/ghostty"

    APP_DIR="${XDG_DATA_HOME}/applications"
    ICON_DIR="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
    DESKTOP_DST="${APP_DIR}/com.mitchellh.ghostty.desktop"
    ICON_DST="${ICON_DIR}/com.mitchellh.ghostty.png"
    META_DIR="${GHOSTTY_APP_DIR}/meta"
    ASSET_STAMP="${META_DIR}/desktop-assets.stamp"
    ASSET_ID="${VERSION}-${ARCH}"

    install -d "$GHOSTTY_APP_DIR" "$TOOLS_BIN" "$APP_DIR" "$ICON_DIR" "$META_DIR"

    # Download only if missing (simple "locked" behavior)
    if [[ ! -f "$GHOSTTY_APP" ]]; then
      tmp_app="$(mktemp "${GHOSTTY_APP}.tmp.XXXXXXXX")" || abort "Failed to create temp file for Ghostty download"
      curl -fsSL -o "$tmp_app" "$GHOSTTY_URL" || abort "Failed to download Ghostty AppImage"
      install -m 0755 "$tmp_app" "$GHOSTTY_APP"
      rm -f "$tmp_app"
    fi

    # Stable entrypoint
    ln -sf "$GHOSTTY_APP" "$GHOSTTY_BIN"

    if [[ ! -f "$DESKTOP_DST" || ! -f "$ICON_DST" || ! -f "$ASSET_STAMP" || "$(cat "$ASSET_STAMP")" != "$ASSET_ID" ]]; then
      EXTRACT_DIR="$(mktemp -d -t appimage-extract.ghostty.XXXXXXXX)" || abort "Failed to create temp dir"
      cleanup() { rm -rf "$EXTRACT_DIR"; }
      trap cleanup EXIT

      (
        cd "$EXTRACT_DIR"
        "$GHOSTTY_APP" --appimage-extract >/dev/null 2>&1 || abort "Failed to extract Ghostty AppImage"
      )

      ROOT="${EXTRACT_DIR}/squashfs-root"
      DESKTOP_SRC="${ROOT}/com.mitchellh.ghostty.desktop"
      ICON_SRC="${ROOT}/com.mitchellh.ghostty.png"

      [[ -f "$DESKTOP_SRC" ]] || abort "Desktop file not found in AppImage: $DESKTOP_SRC"
      [[ -f "$ICON_SRC" ]] || abort "Icon not found in AppImage: $ICON_SRC"

      install -m 0644 "$DESKTOP_SRC" "$DESKTOP_DST"
      install -m 0644 "$ICON_SRC" "$ICON_DST"

      # Normalize desktop entry:
      # - remove TryExec
      # - set Exec to stable wrapper
      sed -i '/^TryExec=/d' "$DESKTOP_DST"
      sed -i 's|^Exec=.*$|Exec=ghostty --font-size=10|g' "$DESKTOP_DST"

      printf '%s\n' "$ASSET_ID" > "$ASSET_STAMP"
    fi

    # Best-effort cache updates (don't fail the install if absent)
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME}/icons/hicolor" || true

    printf 'Ghostty %s installed\n' "$VERSION"
    ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac
