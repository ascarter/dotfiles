#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check fzf

TOOL_REPO="junegunn/fzf"

case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="fzf-*-darwin_arm64.tar.gz" ;;
  x86_64-darwin)   ASSET="fzf-*-darwin_amd64.tar.gz" ;;
  aarch64-linux)   ASSET="fzf-*-linux_arm64.tar.gz" ;;
  x86_64-linux)    ASSET="fzf-*-linux_amd64.tar.gz" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

tool_link "fzf" "bin/fzf"

echo "fzf installed: ${TOOLS_BIN}/fzf"
