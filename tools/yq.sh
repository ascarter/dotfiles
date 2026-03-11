#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check yq

TOOL_REPO="mikefarah/yq"

# yq assets are plain binaries (no archive)
case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="yq_darwin_arm64" ;;
  x86_64-darwin)   ASSET="yq_darwin_amd64" ;;
  aarch64-linux)   ASSET="yq_linux_arm64" ;;
  x86_64-linux)    ASSET="yq_linux_amd64" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

# Plain binary was copied as the asset filename; link it as 'yq'
ln -sf "${TOOLS_INSTALL_DIR}/${ASSET}" "${TOOLS_BIN}/yq"

echo "yq installed: ${TOOLS_BIN}/yq"
