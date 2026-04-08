#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"

if command -v copilot >/dev/null 2>&1; then
  echo "GitHub Copilot CLI already installed: $(command -v copilot)"
  exit 0
fi

curl -fsSL https://gh.io/copilot-install | bash

echo "GitHub Copilot CLI installed."
