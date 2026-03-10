#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v zed >/dev/null 2>&1; then
  echo "Zed editor already installed: $(command -v zed)"
  exit 0
fi

curl -f https://zed.dev/install.sh | sh

echo "Zed editor installed."
