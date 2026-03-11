#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check serie

TOOL_REPO="lusingander/serie"

case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="serie-*-aarch64-apple-darwin.tar.gz" ;;
  x86_64-darwin)   ASSET="serie-*-x86_64-apple-darwin.tar.gz" ;;
  aarch64-linux)   ASSET="serie-*-aarch64-unknown-linux-gnu.tar.gz" ;;
  x86_64-linux)    ASSET="serie-*-x86_64-unknown-linux-gnu.tar.gz" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

tool_link "serie" "bin/serie"

echo "serie installed: ${TOOLS_BIN}/serie"
