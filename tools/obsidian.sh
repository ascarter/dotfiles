# Obsidian (AppImage on Linux, brew on macOS)

TOOL_CMD=obsidian
TOOL_REPO=obsidianmd/obsidian-releases

tool_platform_check() {
  case "$(uname -s)" in
    Darwin) log "obsidian" "not found. Run: brew install --cask obsidian"; exit 1 ;;
    Linux)  ;;
    *)      error "Unsupported OS: $(uname -s)"; return 1 ;;
  esac
}

tool_download() {
  local tag version
  tag="$(tool_latest_tag "$TOOL_REPO")"
  version="${tag#v}"
  case "$(uname -m)" in
    x86_64)       tool_gh_install "$TOOL_REPO" "Obsidian-${version}.AppImage" "$tag" ;;
    aarch64|arm64) tool_gh_install "$TOOL_REPO" "Obsidian-${version}-arm64.AppImage" "$tag" ;;
    *)            error "Unsupported architecture: $(uname -m)"; return 1 ;;
  esac
}

tool_post_install() {
  tool_appimage_link "Obsidian-*.AppImage"
  tool_appimage_desktop "obsidian" "obsidian %u"
}

tool_uninstall() {
  tool_appimage_uninstall_desktop "obsidian"
}
