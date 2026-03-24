# gh — GitHub CLI
#
# Self-managed via curl + GitHub REST API so gh can bootstrap itself
# without requiring gh to already be installed. After initial install,
# run `dotfiles gitconfig` to authenticate and configure git identity.
TOOL_CMD=gh
TOOL_TYPE=custom
TOOL_REPO=cli/cli
TOOL_STRIP_COMPONENTS=1
TOOL_LINKS=(bin/gh)

# Link all man pages from the extracted archive
tool_post_install() {
  tool_link "bin/gh"

  # Symlink man pages (archive ships share/man/man1/gh*.1)
  local page
  for page in "${TOOLS_INSTALL_DIR}"/share/man/man1/gh*.1; do
    [[ -f "$page" ]] || continue
    tool_link "share/man/man1/$(basename "$page")"
  done

  # Strip quarantine on macOS (unsigned binary)
  tool_strip_quarantine "${TOOLS_INSTALL_DIR}/bin/gh"
}

# curl-based download — no gh dependency required
tool_download() {
  local repo="cli/cli"
  local name="cli"
  local state_file="${TOOLS_STATE}/${name}"

  # Resolve latest tag via GitHub REST API
  local tag
  tag="$(curl -fsSL https://api.github.com/repos/${repo}/releases/latest | \
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')" \
    || { error "tool_download: failed to query GitHub API for ${repo}"; return 1; }

  if [[ -z "$tag" ]]; then
    error "tool_download: could not determine latest tag for ${repo}"
    return 1
  fi

  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/${name}/${tag}"
  TOOLS_INSTALL_TAG="$tag"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG

  # Skip if already installed at this tag
  local installed_tag
  installed_tag="$(tool_installed_tag "$repo")"
  if [[ "$installed_tag" == "$tag" && -d "$TOOLS_INSTALL_DIR" ]]; then
    vlog "skip" "${name} at ${tag}"
    TOOLS_INSTALL_SKIPPED=1
    return 0
  fi

  # Resolve platform-specific asset URL
  local version="${tag#v}"
  local asset_name
  case "$TOOLS_PLATFORM" in
    aarch64-darwin) asset_name="gh_${version}_macOS_arm64.zip" ;;
    aarch64-linux)  asset_name="gh_${version}_linux_arm64.tar.gz" ;;
    x86_64-linux)   asset_name="gh_${version}_linux_amd64.tar.gz" ;;
    *) error "tool_download: unsupported platform ${TOOLS_PLATFORM}"; return 1 ;;
  esac

  local cache_dir="${TOOLS_CACHE}/${name}"
  local asset_file="${cache_dir}/${asset_name}"
  mkdir -p "$cache_dir" "$TOOLS_INSTALL_DIR"

  # Download asset via curl
  local url="https://github.com/${repo}/releases/download/${tag}/${asset_name}"
  log "download" "${repo} ${tag}"
  curl -fSL --progress-bar -o "$asset_file" "$url" \
    || { error "tool_download: download failed for ${url}"; return 1; }

  # Extract based on format
  if [[ "$asset_name" == *.tar.gz ]]; then
    tar -xzf "$asset_file" -C "$TOOLS_INSTALL_DIR" \
      --strip-components="${TOOL_STRIP_COMPONENTS:-0}" \
      || { error "tool_download: tar extraction failed"; return 1; }
  elif [[ "$asset_name" == *.zip ]]; then
    unzip -q -o "$asset_file" -d "$TOOLS_INSTALL_DIR" \
      || { error "tool_download: unzip extraction failed"; return 1; }
    # Strip leading directory from zip
    if [[ "${TOOL_STRIP_COMPONENTS:-0}" -gt 0 ]]; then
      local nested_dir
      nested_dir="$(find "$TOOLS_INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
      if [[ -n "$nested_dir" ]]; then
        mv "$nested_dir"/* "$TOOLS_INSTALL_DIR"/ 2>/dev/null || true
        rmdir "$nested_dir" 2>/dev/null || true
      fi
    fi
  fi

  # Record installed tag
  printf '%s\n' "$tag" > "$state_file"
  log "install" "${name} ${tag} -> ${TOOLS_INSTALL_DIR}"
}
