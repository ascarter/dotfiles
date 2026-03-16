# Ghostty terminal (AppImage on Linux, brew on macOS)

TOOL_CMD=ghostty
TOOL_REPO=pkgforge-dev/ghostty-appimage

tool_platform_check() {
  case "$(uname -s)" in
    Darwin) log "ghostty" "not found. Run: brew install --cask ghostty"; exit 1 ;;
    Linux)  ;;
    *)      error "Unsupported OS: $(uname -s)"; return 1 ;;
  esac
}

tool_download() {
  local arch
  arch="$(uname -m)"
  tool_gh_install "$TOOL_REPO" "Ghostty-*-${arch}.AppImage"
}

tool_post_install() {
  local arch appimage
  arch="$(uname -m)"
  appimage="$(find "$TOOLS_INSTALL_DIR" -name "Ghostty-*-${arch}.AppImage" | head -n1)"
  [[ -n "$appimage" ]] || { error "AppImage not found in ${TOOLS_INSTALL_DIR}"; return 1; }
  chmod +x "$appimage"
  ln -sf "$appimage" "${TOOLS_BIN}/ghostty"

  # Extract desktop assets from AppImage
  local extract_dir
  extract_dir="$(mktemp -d -t ghostty-extract.XXXXXXXX)"

  (cd "$extract_dir" && "$appimage" --appimage-extract >/dev/null 2>&1) \
    || { rm -rf "$extract_dir"; error "Failed to extract AppImage"; return 1; }

  local root="${extract_dir}/squashfs-root"
  local app_dir="${XDG_DATA_HOME}/applications"
  local icon_dir="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
  install -d "$app_dir" "$icon_dir"

  [[ -f "${root}/com.mitchellh.ghostty.desktop" ]] || { rm -rf "$extract_dir"; error "Desktop file not found in AppImage"; return 1; }
  [[ -f "${root}/com.mitchellh.ghostty.png" ]] || { rm -rf "$extract_dir"; error "Icon not found in AppImage"; return 1; }

  install -m 0644 "${root}/com.mitchellh.ghostty.desktop" "${app_dir}/com.mitchellh.ghostty.desktop"
  install -m 0644 "${root}/com.mitchellh.ghostty.png" "${icon_dir}/com.mitchellh.ghostty.png"

  # Normalize desktop entry: remove TryExec, point Exec to stable wrapper
  sed -i '/^TryExec=/d' "${app_dir}/com.mitchellh.ghostty.desktop"
  sed -i 's|^Exec=.*$|Exec=ghostty --font-size=10|g' "${app_dir}/com.mitchellh.ghostty.desktop"

  rm -rf "$extract_dir"

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$app_dir" || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME}/icons/hicolor" || true
}

tool_uninstall() {
  rm -f "${XDG_DATA_HOME}/applications/com.mitchellh.ghostty.desktop"
  rm -f "${XDG_DATA_HOME}/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png"
  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" || true
}
