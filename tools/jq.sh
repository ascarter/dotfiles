#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v jq >/dev/null 2>&1; then
  echo "jq already installed: $(command -v jq)"
  exit 0
fi

TOOL_REPO="jqlang/jq"

# jq assets are plain binaries (no archive)
case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="jq-macos-arm64" ;;
  x86_64-darwin)   ASSET="jq-macos-amd64" ;;
  aarch64-linux)   ASSET="jq-linux-arm64" ;;
  x86_64-linux)    ASSET="jq-linux-amd64" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

# Plain binary was copied as the asset filename; link it as 'jq'
ln -sf "${TOOLS_INSTALL_DIR}/${ASSET}" "${TOOLS_BIN}/jq"

echo "jq installed: ${TOOLS_BIN}/jq"
