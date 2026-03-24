# lib/opt/appimage.sh — AppImage driver
#
# Provides helpers and driver defaults for tools distributed as Linux AppImages.
# Sourced by lib/opt.sh — do not source directly.
#
# Public functions (usable in recipe hooks):
#   tool_appimage_link              — link AppImage binary to TOOLS_BIN
#   tool_appimage_desktop           — install .desktop file and icon
#   tool_appimage_uninstall_desktop — remove .desktop file and icon
#
# Driver defaults (called by tool_run_recipe for TOOL_TYPE=appimage):
#   _tool_appimage_platform_check        — Linux-only; macOS → brew hint
#   _tool_appimage_default_post_install  — link + desktop integration
#
# No shebang — this file is sourced, not executed.

# tool_appimage_link <glob>
#
# Finds the AppImage matching <glob> in TOOLS_INSTALL_DIR, makes it executable,
# and symlinks it to TOOLS_BIN/$TOOL_CMD.
# Sets TOOL_APPIMAGE to the resolved path for use by tool_appimage_desktop.
tool_appimage_link() {
  local glob="$1"
  local appimage
  appimage="$(find "$TOOLS_INSTALL_DIR" -name "$glob" | head -n1)"
  [[ -n "$appimage" ]] || { error "AppImage not found in ${TOOLS_INSTALL_DIR}"; return 1; }
  chmod +x "$appimage"
  ln -sf "$appimage" "${TOOLS_BIN}/${TOOL_CMD}"
  TOOL_APPIMAGE="$appimage"
}

# tool_appimage_desktop <desktop_id> <exec_line>
#
# Extracts the AppImage (via --appimage-extract), installs the .desktop file and
# icon into XDG_DATA_HOME, and normalizes the Exec= line.
#
#   desktop_id  — base name of the .desktop file without extension
#                 (e.g. "com.mitchellh.ghostty", "obsidian")
#   exec_line   — replacement value for the Exec= key (e.g. "obsidian %u")
#
# Requires TOOL_APPIMAGE to be set (call tool_appimage_link first).
tool_appimage_desktop() {
  local desktop_id="$1"
  local exec_line="$2"
  local appimage="${TOOL_APPIMAGE:?TOOL_APPIMAGE not set — call tool_appimage_link first}"

  local extract_dir
  extract_dir="$(mktemp -d -t "${TOOL_CMD}-extract.XXXXXXXX")"

  (cd "$extract_dir" && "$appimage" --appimage-extract >/dev/null 2>&1) \
    || { rm -rf "$extract_dir"; error "Failed to extract AppImage"; return 1; }

  local root="${extract_dir}/squashfs-root"
  local app_dir="${XDG_DATA_HOME}/applications"
  local icon_dir="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
  install -d "$app_dir" "$icon_dir"

  local desktop_file="${root}/${desktop_id}.desktop"
  [[ -f "$desktop_file" ]] || { rm -rf "$extract_dir"; error "Desktop file not found: ${desktop_id}.desktop"; return 1; }

  # Find icon — try common extensions
  local icon_file=""
  local ext
  for ext in png svg; do
    icon_file="$(find -L "$root" -maxdepth 1 -name "${desktop_id}.${ext}" | head -n1)"
    [[ -n "$icon_file" ]] && break
  done
  [[ -n "$icon_file" ]] || { rm -rf "$extract_dir"; error "Icon not found for ${desktop_id}"; return 1; }

  local icon_basename
  icon_basename="$(basename "$icon_file")"

  install -m 0644 "$desktop_file" "${app_dir}/${desktop_id}.desktop"
  install -m 0644 "$icon_file" "${icon_dir}/${icon_basename}"

  # Normalize desktop entry: remove TryExec, point Exec to stable wrapper
  sed -i '/^TryExec=/d' "${app_dir}/${desktop_id}.desktop"
  sed -i "s|^Exec=.*\$|Exec=${exec_line}|g" "${app_dir}/${desktop_id}.desktop"

  rm -rf "$extract_dir"

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$app_dir" || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME}/icons/hicolor" || true
}

# tool_appimage_uninstall_desktop <desktop_id> [icon_ext]
#
# Removes the .desktop file and icon installed by tool_appimage_desktop.
# icon_ext defaults to "png".
tool_appimage_uninstall_desktop() {
  local desktop_id="$1"
  local icon_ext="${2:-png}"
  rm -f "${XDG_DATA_HOME}/applications/${desktop_id}.desktop"
  rm -f "${XDG_DATA_HOME}/icons/hicolor/256x256/apps/${desktop_id}.${icon_ext}"
  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" || true
}

# ---------------------------------------------------------------------------
# Driver defaults for TOOL_TYPE=appimage (called by tool_run_recipe)
# ---------------------------------------------------------------------------

# _tool_appimage_platform_check
# Default platform check for TOOL_TYPE=appimage recipes.
# AppImages are Linux-only; macOS users are directed to Homebrew.
_tool_appimage_platform_check() {
  case "$(uname -s)" in
    Linux) ;;
    Darwin)
      local brew_name="${TOOL_BREW:-$TOOL_CMD}"
      log "$TOOL_CMD" "not found. Run: brew install --cask ${brew_name}"
      exit 1
      ;;
    *) error "Unsupported OS for AppImage: $(uname -s)"; return 1 ;;
  esac
}

# _tool_appimage_default_post_install
# Default post-install for TOOL_TYPE=appimage recipes.
# Links the AppImage binary and installs desktop integration.
_tool_appimage_default_post_install() {
  local glob="${TOOL_APPIMAGE_GLOB:-*.AppImage}"
  tool_appimage_link "$glob"
  if [[ -n "${TOOL_DESKTOP_ID:-}" ]]; then
    tool_appimage_desktop "$TOOL_DESKTOP_ID" "${TOOL_DESKTOP_EXEC:-$TOOL_CMD}"
  fi
}
