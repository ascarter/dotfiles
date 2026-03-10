#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v tree-sitter >/dev/null 2>&1; then
  echo "tree-sitter already installed: $(command -v tree-sitter)"
  exit 0
fi

TOOL_REPO="tree-sitter/tree-sitter"

# tree-sitter assets are .gz compressed binaries (not tar.gz)
# lib/tool.sh gunzip handler decompresses to a file named after the repo ("tree-sitter")
case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="tree-sitter-macos-arm64.gz" ;;
  x86_64-darwin)   ASSET="tree-sitter-macos-x64.gz" ;;
  aarch64-linux)   ASSET="tree-sitter-linux-arm64.gz" ;;
  x86_64-linux)    ASSET="tree-sitter-linux-x64.gz" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

# lib/tool.sh gunzip handler creates TOOLS_INSTALL_DIR/tree-sitter
ln -sf "${TOOLS_INSTALL_DIR}/tree-sitter" "${TOOLS_BIN}/tree-sitter"

echo "tree-sitter installed: ${TOOLS_BIN}/tree-sitter"
