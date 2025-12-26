#!/bin/sh

# Ghostty

set -eu

abort() {
  printf -ru2 '%s\n' "$1"
  exit 1
}

case "$(uname -s)" in
  Darwin)
    echo "Use Homebrew to install Ghossty on macOS"
    echo "brew install --cask ghostty"
    exit 0
    ;;
  Linux)
    # Download the latest AppImage package from releases
    : XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    : XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
    VERSION="1.2.3"
    ARCH="$(uname -m)"
    GHOSTTY_URL="https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v${VERSION}/Ghostty-${VERSION}-${ARCH}.AppImage"
    GHOSTTY_APP_DIR="${XDG_DATA_HOME}/ghostty"
    GHOSTTY_APP="${GHOSTTY_APP_DIR}/Ghostty-${VERSION}-${ARCH}.AppImage"
    mkdir -p "${GHOSTTY_APP_DIR}" || abort "Failed to create Ghostty app directory"
    curl -fsSL -o "${GHOSTTY_APP}" ${GHOSTTY_URL} || abort "Failed to download Ghostty AppImage"
    chmod +x "${GHOSTTY_APP}"
    install "${GHOSTTY_APP}" "${XDG_BIN_HOME}/ghostty"

    # Extract desktop file
    EXTRACT_DIR="$(mktemp -d -t appimage-extract.ghostty.XXXXXXXX)" || abort "Failed to create temporary extraction directory"
    pushd "${EXTRACT_DIR}"
    "${GHOSTTY_APP}" --appimage-extract >/dev/null 2>&1 || abort "Failed to extract Ghostty AppImage"
    popd
    ROOT="${EXTRACT_DIR}/squashfs-root"
    DESKTOP_SRC="${ROOT}/com.mitchellh.ghostty.desktop"
    ICON_SRC="${ROOT}/com.mitchellh.ghostty.png"
    DESKTOP_DST="${XDG_DATA_HOME}/applications/com.mitchellh.ghostty.desktop"
    ICON_DST="${XDG_DATA_HOME}/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png"
    cp "${DESKTOP_SRC}" "${DESKTOP_DST}"
    cp "${ICON_SRC}" "${ICON_DST}"

    # Remove TryExec if present
    sed -i '/^TryExec=/d' "$DESKTOP_DST"

    # Force Exec= for the main entry
    sed -i "s|^Exec=.*$|Exec=${GHOSTTY_APP} --gtk-single-instance=true|g" "$DESKTOP_DST"

    rm -rf "${EXTRACT_DIR}"

    update-desktop-database "${XDG_DATA_HOME}/applications"
    gtk-update-icon-cache -f -t "${XDG_DATA_HOME}/icons/hicolor"

    printf "Ghostty ${VERSION} installed\n" "${VERSION}"
    ;;
esac
