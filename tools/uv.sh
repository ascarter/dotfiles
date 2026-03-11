#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check uv

curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh

echo "uv installed."
