# Ghostty terminal (AppImage on Linux, brew on macOS)

TOOL_CMD=ghostty
TOOL_REPO=pkgforge-dev/ghostty-appimage

tool_externally_managed() {
  [[ "$(uname -s)" == Darwin ]]
}

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
  local arch
  arch="$(uname -m)"
  tool_appimage_link "Ghostty-*-${arch}.AppImage"
  tool_appimage_desktop "com.mitchellh.ghostty" "ghostty --font-size=10"
}

tool_uninstall() {
  tool_appimage_uninstall_desktop "com.mitchellh.ghostty"
}
