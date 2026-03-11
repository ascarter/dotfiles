#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check rv

curl -LsSf https://rv.dev/install | RV_NO_MODIFY_PATH=1 sh

echo "rv installed."
