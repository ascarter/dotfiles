#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

tool_check claude

curl -fsSL https://claude.ai/install.sh | bash

echo "Claude Code installed."
