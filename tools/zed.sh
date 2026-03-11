#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check zed

curl -f https://zed.dev/install.sh | sh

echo "Zed editor installed."
