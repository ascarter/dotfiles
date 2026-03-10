#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v fnm >/dev/null 2>&1; then
  echo "fnm already installed: $(command -v rustup)"
  exit 0
fi

curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

# Link fnm into XDG_LOCAL_BIN for easy access
mkdir -p "${XDG_BIN_HOME}"
ln -sf "${FNM_DIR}/fnm" "${XDG_BIN_HOME}/fnm"

echo "fnm installed."
