#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v rv >/dev/null 2>&1; then
  echo "rv already installed: $(command -v rv)"
  exit 0
fi

curl -LsSf https://rv.dev/install | RV_NO_MODIFY_PATH=1 sh

echo "rv installed."
