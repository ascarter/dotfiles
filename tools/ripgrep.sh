#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check rg

TOOL_REPO="BurntSushi/ripgrep"

case "$TOOLS_PLATFORM" in
  aarch64-darwin)  ASSET="ripgrep-*-aarch64-apple-darwin.tar.gz" ;;
  x86_64-darwin)   ASSET="ripgrep-*-x86_64-apple-darwin.tar.gz" ;;
  aarch64-linux)   ASSET="ripgrep-*-aarch64-unknown-linux-gnu.tar.gz" ;;
  x86_64-linux)    ASSET="ripgrep-*-x86_64-unknown-linux-gnu.tar.gz" ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

tool_gh_install "$TOOL_REPO" "$ASSET"

# The tarball extracts to a subdirectory: ripgrep-<tag>-<triple>/
# Find the rg binary within the install dir
rg_bin="$(find "$TOOLS_INSTALL_DIR" -name "rg" -type f | head -n1)"
[[ -n "$rg_bin" ]] || { echo "rg binary not found in $TOOLS_INSTALL_DIR" >&2; exit 1; }
rg_rel="${rg_bin#$TOOLS_INSTALL_DIR/}"

tool_link "$rg_rel" "bin/rg"

# Man page
man_page="$(find "$TOOLS_INSTALL_DIR" -name "rg.1" | head -n1)"
if [[ -n "$man_page" ]]; then
  man_rel="${man_page#$TOOLS_INSTALL_DIR/}"
  mkdir -p "${TOOLS_SHARE}/man/man1"
  ln -sf "$man_page" "${TOOLS_SHARE}/man/man1/rg.1"
fi

# Shell completions
for comp_file in bash zsh; do
  found="$(find "$TOOLS_INSTALL_DIR" -name "rg.${comp_file}" | head -n1)"
  if [[ -n "$found" ]]; then
    rel="${found#$TOOLS_INSTALL_DIR/}"
    mkdir -p "${TOOLS_SHARE}/completions"
    ln -sf "$found" "${TOOLS_SHARE}/completions/rg.${comp_file}"
  fi
done

echo "ripgrep installed: ${TOOLS_BIN}/rg"
