#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check fnm

curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

# Link fnm into XDG_LOCAL_BIN for easy access
mkdir -p "${XDG_BIN_HOME}"
ln -sf "${FNM_DIR}/fnm" "${XDG_BIN_HOME}/fnm"

echo "fnm installed."
