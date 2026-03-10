#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v uv >/dev/null 2>&1; then
  echo "uv already installed: $(command -v uv)"
  exit 0
fi

curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh

echo "uv installed."
