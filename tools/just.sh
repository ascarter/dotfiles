#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/tool.sh"

if command -v just >/dev/null 2>&1; then
  echo "just already installed: $(command -v just)"
  exit 0
fi

TOOL_REPO="casey/just"

case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="just-*-aarch64-apple-darwin.tar.gz" ;;
  x86_64-darwin)   ASSET="just-*-x86_64-apple-darwin.tar.gz" ;;
  aarch64-linux)   ASSET="just-*-aarch64-unknown-linux-musl.tar.gz" ;;
  x86_64-linux)    ASSET="just-*-x86_64-unknown-linux-musl.tar.gz" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

tool_link "just" "bin/just"

# Man page
if [[ -f "${TOOLS_INSTALL_DIR}/just.1" ]]; then
  mkdir -p "${TOOLS_SHARE}/man/man1"
  ln -sf "${TOOLS_INSTALL_DIR}/just.1" "${TOOLS_SHARE}/man/man1/just.1"
fi

# Shell completions
for comp_file in just.bash just.zsh; do
  if [[ -f "${TOOLS_INSTALL_DIR}/${comp_file}" ]]; then
    mkdir -p "${TOOLS_SHARE}/completions"
    ln -sf "${TOOLS_INSTALL_DIR}/${comp_file}" "${TOOLS_SHARE}/completions/${comp_file}"
  fi
done

echo "just installed: ${TOOLS_BIN}/just"
