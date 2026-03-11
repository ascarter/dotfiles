# jq — JSON processor (assets are plain binaries)
TOOL_CMD=jq
TOOL_REPO=jqlang/jq
TOOL_ASSET_MACOS_ARM64="jq-macos-arm64"
TOOL_ASSET_MACOS_AMD64="jq-macos-amd64"
TOOL_ASSET_LINUX_ARM64="jq-linux-arm64"
TOOL_ASSET_LINUX_AMD64="jq-linux-amd64"

tool_post_install() {
  local asset
  asset="$(find "$TOOLS_INSTALL_DIR" -maxdepth 1 -type f | head -n1)"
  ln -sf "$asset" "${XDG_OPT_BIN}/jq"
}
