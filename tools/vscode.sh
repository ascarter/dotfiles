# Visual Studio Code (brew on macOS, tarball on Linux)

TOOL_CMD=code
TOOL_BREW=visual-studio-code

tool_externally_managed() {
  return 0
}

tool_platform_check() {
  case "$(uname -s)" in
    Darwin) log "vscode" "not found. Run: brew install --cask visual-studio-code"; exit 1 ;;
    Linux)  ;;
    *)      error "Unsupported OS: $(uname -s)"; return 1 ;;
  esac
}

tool_download() {
  command -v jq >/dev/null 2>&1 || { error "jq is required for VS Code metadata"; return 1; }

  local arch vscode_os
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)  vscode_os="linux-x64" ;;
    aarch64|arm64) vscode_os="linux-arm64" ;;
    *)             error "Unsupported architecture: $arch"; return 1 ;;
  esac

  local sha_json
  sha_json="$(mktemp)"

  log "download" "resolving VS Code metadata..."
  curl -fLso "$sha_json" "https://code.visualstudio.com/sha" \
    || { rm -f "$sha_json"; error "Failed to fetch VS Code metadata"; return 1; }

  local url expected_sha
  url="$(jq -r --arg os "$vscode_os" \
    '.products[] | select(.build == "stable" and .platform.os == $os) | .url' \
    "$sha_json" | head -n1)"
  expected_sha="$(jq -r --arg os "$vscode_os" \
    '.products[] | select(.build == "stable" and .platform.os == $os) | .sha256hash' \
    "$sha_json" | head -n1)"
  rm -f "$sha_json"

  [[ -n "$url" && "$url" != "null" ]] || { error "Could not resolve VS Code URL for ${vscode_os}"; return 1; }
  [[ -n "$expected_sha" && "$expected_sha" != "null" ]] || { error "Could not resolve VS Code SHA for ${vscode_os}"; return 1; }

  # Use truncated SHA as pseudo-tag for cellar versioning
  local name="vscode"
  local short_sha="${expected_sha:0:12}"
  local state_file="${TOOLS_STATE}/${name}"
  local installed_sha
  installed_sha="$(cat "$state_file" 2>/dev/null || echo none)"

  if [[ "$installed_sha" == "$short_sha" && -d "${TOOLS_CELLAR}/${name}/${short_sha}" ]]; then
    TOOLS_INSTALL_SKIPPED=1
    vlog "skip" "vscode at ${short_sha}"
    return 0
  fi

  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/${name}/${short_sha}"
  TOOLS_INSTALL_TAG="$short_sha"
  mkdir -p "$TOOLS_INSTALL_DIR"

  log "download" "VS Code ${short_sha}"
  local archive
  archive="$(mktemp)"
  curl -fLso "$archive" "$url" \
    || { rm -f "$archive"; error "Failed to download VS Code"; return 1; }

  # Verify checksum
  local actual_sha
  if command -v sha256sum >/dev/null 2>&1; then
    actual_sha="$(sha256sum "$archive" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$archive" | awk '{print $1}')"
  else
    rm -f "$archive"; error "No SHA-256 tool found"; return 1
  fi
  [[ "$actual_sha" == "$expected_sha" ]] || { rm -f "$archive"; error "Checksum verification failed"; return 1; }

  tar -xzf "$archive" -C "$TOOLS_INSTALL_DIR" --strip-components=1 \
    || { rm -f "$archive"; error "Failed to extract archive"; return 1; }
  rm -f "$archive"

  # Verify expected binaries exist
  [[ -x "${TOOLS_INSTALL_DIR}/code" ]] || { error "Extracted package missing 'code' binary"; return 1; }
  [[ -x "${TOOLS_INSTALL_DIR}/bin/code" ]] || { error "Extracted package missing 'bin/code' CLI launcher"; return 1; }

  printf '%s\n' "$short_sha" > "$state_file"
  log "install" "vscode ${short_sha} -> ${TOOLS_INSTALL_DIR}"
}

tool_post_install() {
  ln -sf "${TOOLS_INSTALL_DIR}/bin/code" "${TOOLS_BIN}/code"

  # Desktop entry (Linux only)
  local app_dir="${XDG_DATA_HOME}/applications"
  install -d "$app_dir"
  cat > "${app_dir}/code.desktop" <<DESKTOP
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=${TOOLS_INSTALL_DIR}/code --unity-launch %F
TryExec=${TOOLS_INSTALL_DIR}/code
Icon=${TOOLS_INSTALL_DIR}/resources/app/resources/linux/code.png
StartupNotify=true
StartupWMClass=Code
Type=Application
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=${TOOLS_INSTALL_DIR}/code --new-window %F
Icon=${TOOLS_INSTALL_DIR}/resources/app/resources/linux/code.png
DESKTOP

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$app_dir" || true
}

tool_uninstall() {
  rm -f "${XDG_DATA_HOME}/applications/code.desktop"
  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" || true
}
