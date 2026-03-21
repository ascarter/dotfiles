# btm — terminal system monitor
TOOL_CMD=btm
TOOL_REPO=ClementTsang/bottom
TOOL_ASSET_MACOS_ARM64="bottom_aarch64-apple-darwin.tar.gz"
TOOL_ASSET_LINUX_ARM64="bottom_aarch64-unknown-linux-gnu.tar.gz"
TOOL_ASSET_LINUX_AMD64="bottom_x86_64-unknown-linux-gnu.tar.gz"
TOOL_LINKS=(btm)
TOOL_MAN_PAGES=(btm.1)
TOOL_COMPLETIONS=(completion/_btm)

# Man page ships as a separate release asset, not inside the platform tarball.
tool_download() {
  local asset
  asset="$(_tool_resolve_asset)"
  tool_gh_install "$TOOL_REPO" "$asset"
  [[ "${TOOLS_INSTALL_SKIPPED:-0}" -eq 0 ]] || return 0

  local cache_dir="${TOOLS_CACHE}/bottom"
  gh release download "$TOOLS_INSTALL_TAG" \
    --repo "$TOOL_REPO" \
    --pattern "manpage.tar.gz" \
    --dir "$cache_dir" \
    --clobber
  tar -xzf "${cache_dir}/manpage.tar.gz" -C "$TOOLS_INSTALL_DIR"
  gunzip -f "${TOOLS_INSTALL_DIR}/btm.1.gz"
}
