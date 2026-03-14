# yq — YAML processor (assets are plain binaries)
TOOL_CMD=yq
TOOL_REPO=mikefarah/yq
TOOL_ASSET_MACOS_ARM64="yq_darwin_arm64"
TOOL_ASSET_LINUX_ARM64="yq_linux_arm64"
TOOL_ASSET_LINUX_AMD64="yq_linux_amd64"

tool_post_install() {
  local asset
  asset="$(find "$TOOLS_INSTALL_DIR" -maxdepth 1 -type f | head -n1)"
  ln -sf "$asset" "${XDG_OPT_BIN}/yq"
}
