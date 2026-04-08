# lib/appimage.sh — shared AppImage installation helpers
#
# Sourced by AppImage installer scripts under scripts/apps/.
# No shebang — this file is sourced, not executed.
#
# Provides: appimage_install (full lifecycle orchestrator)
#
# Required variables (set by caller before calling appimage_run):
#   APPIMAGE_REPO         — GitHub owner/repo (e.g. pkgforge-dev/ghostty-appimage)
#   APPIMAGE_CMD          — command name (e.g. ghostty)
#   APPIMAGE_DESKTOP_ID   — desktop file basename (e.g. com.mitchellh.ghostty)
#   APPIMAGE_DESKTOP_EXEC — Exec= line value (e.g. "ghostty --font-size=10")
#   APPIMAGE_TAG          — version tag (empty string = resolve latest)
#   APPIMAGE_ASSET_GLOB   — asset filename glob (e.g. "Ghostty-*-x86_64.AppImage")
#
# Optional variables:
#   APPIMAGE_ASSET_PATTERN    — pattern with {version} placeholder (alternative
#                               to ASSET_GLOB; requires APPIMAGE_VERSION_STRIP_V)
#   APPIMAGE_VERSION_STRIP_V  — if set to 1, strip leading "v" from tag for
#                               asset pattern substitution

# Idempotent guard
[[ -n "${_DOTFILES_APPIMAGE_LOADED:-}" ]] && return 0
_DOTFILES_APPIMAGE_LOADED=1

# Resolve the latest stable release tag via gh CLI
_appimage_resolve_tag() {
  if [[ -n "$APPIMAGE_TAG" ]]; then
    return 0
  fi

  log "$APPIMAGE_CMD" "resolving latest release..."
  APPIMAGE_TAG=$(gh release list --repo "$APPIMAGE_REPO" --limit 20 \
    --json tagName,isPrerelease,isDraft \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not)))[0].tagName // empty')
  [[ -n "$APPIMAGE_TAG" ]] || abort "Could not determine latest release for $APPIMAGE_REPO"
}

# Resolve the asset glob from a {version} pattern if needed
_appimage_resolve_asset_glob() {
  if [[ -n "${APPIMAGE_ASSET_PATTERN:-}" ]]; then
    local version="$APPIMAGE_TAG"
    if [[ "${APPIMAGE_VERSION_STRIP_V:-0}" == "1" ]]; then
      version="${version#v}"
    fi
    APPIMAGE_ASSET_GLOB="${APPIMAGE_ASSET_PATTERN//\{version\}/$version}"
  fi
}

# Download the AppImage asset to cache
_appimage_download() {
  local cache_dir="${XDG_CACHE_HOME}/appimages/${APPIMAGE_CMD}"
  mkdir -p "$cache_dir"

  log "$APPIMAGE_CMD" "downloading $APPIMAGE_REPO $APPIMAGE_TAG..."
  gh release download "$APPIMAGE_TAG" \
    --repo "$APPIMAGE_REPO" \
    --pattern "$APPIMAGE_ASSET_GLOB" \
    --dir "$cache_dir" \
    --clobber

  _APPIMAGE_DOWNLOADED=$(find "$cache_dir" -maxdepth 1 -name "$APPIMAGE_ASSET_GLOB" | head -n1)
  [[ -n "$_APPIMAGE_DOWNLOADED" ]] || abort "No asset matching $APPIMAGE_ASSET_GLOB found"
}

# Install AppImage to permanent location and create symlink
_appimage_install() {
  local install_dir="${XDG_DATA_HOME}/appimages/${APPIMAGE_CMD}"
  mkdir -p "$install_dir" "$XDG_BIN_HOME"

  rm -f "${install_dir}"/*.AppImage
  mv "$_APPIMAGE_DOWNLOADED" "$install_dir/"
  _APPIMAGE_INSTALLED="${install_dir}/$(basename "$_APPIMAGE_DOWNLOADED")"
  chmod +x "$_APPIMAGE_INSTALLED"

  ln -sf "$_APPIMAGE_INSTALLED" "${XDG_BIN_HOME}/${APPIMAGE_CMD}"
  log "$APPIMAGE_CMD" "linked ${XDG_BIN_HOME}/${APPIMAGE_CMD}"
}

# Extract AppImage and install .desktop file + icon
_appimage_desktop_integrate() {
  _APPIMAGE_EXTRACT_DIR=$(mktemp -d -t "${APPIMAGE_CMD}-extract.XXXXXXXX")
  trap 'rm -rf "$_APPIMAGE_EXTRACT_DIR"' EXIT

  (cd "$_APPIMAGE_EXTRACT_DIR" && "$_APPIMAGE_INSTALLED" --appimage-extract >/dev/null 2>&1) \
    || { warn "$APPIMAGE_CMD" "AppImage extraction failed — skipping desktop integration"
         rm -rf "$_APPIMAGE_EXTRACT_DIR"; trap - EXIT; return 0; }

  local root="${_APPIMAGE_EXTRACT_DIR}/squashfs-root"
  local app_dir="${XDG_DATA_HOME}/applications"
  local icon_dir="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
  install -d "$app_dir" "$icon_dir"

  # .desktop file
  local desktop_file="${root}/${APPIMAGE_DESKTOP_ID}.desktop"
  if [[ -f "$desktop_file" ]]; then
    install -m 0644 "$desktop_file" "${app_dir}/${APPIMAGE_DESKTOP_ID}.desktop"
    sed -i '/^TryExec=/d' "${app_dir}/${APPIMAGE_DESKTOP_ID}.desktop"
    sed -i "s|^Exec=.*$|Exec=${APPIMAGE_DESKTOP_EXEC}|g" "${app_dir}/${APPIMAGE_DESKTOP_ID}.desktop"
    log "$APPIMAGE_CMD" "installed .desktop file"
  fi

  # Icon (prefer png, fall back to svg)
  local icon_file=""
  for ext in png svg; do
    icon_file=$(find -L "$root" -maxdepth 1 -name "${APPIMAGE_DESKTOP_ID}.${ext}" | head -n1)
    [[ -n "$icon_file" ]] && break
  done
  if [[ -n "$icon_file" ]]; then
    install -m 0644 "$icon_file" "${icon_dir}/$(basename "$icon_file")"
    log "$APPIMAGE_CMD" "installed icon"
  fi

  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$app_dir" 2>/dev/null || true

  rm -rf "$_APPIMAGE_EXTRACT_DIR"
  trap - EXIT
}

# Full lifecycle: resolve → check version → download → install → desktop integrate
appimage_install() {
  : "${XDG_BIN_HOME:=$HOME/.local/bin}"
  : "${XDG_DATA_HOME:=$HOME/.local/share}"
  : "${XDG_STATE_HOME:=$HOME/.local/state}"
  : "${XDG_CACHE_HOME:=$HOME/.cache}"

  _appimage_resolve_tag
  _appimage_resolve_asset_glob

  # Compare resolved tag against installed version
  local state_dir="${XDG_STATE_HOME}/appimages/${APPIMAGE_CMD}"
  local version_file="${state_dir}/version"
  if [[ -f "$version_file" ]]; then
    local installed_tag
    installed_tag=$(<"$version_file")
    if [[ "$installed_tag" == "$APPIMAGE_TAG" ]]; then
      log "$APPIMAGE_CMD" "up to date: $APPIMAGE_TAG"
      return 0
    fi
    log "$APPIMAGE_CMD" "updating $installed_tag → $APPIMAGE_TAG"
  else
    log "$APPIMAGE_CMD" "installing $APPIMAGE_TAG"
  fi

  _appimage_download
  _appimage_install
  _appimage_desktop_integrate

  # Record installed version
  install -d "$state_dir"
  printf '%s\n' "$APPIMAGE_TAG" > "$version_file"

  success "$APPIMAGE_CMD $APPIMAGE_TAG installed"
}
