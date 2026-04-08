#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v claude >/dev/null 2>&1; then
  log "claude" "already installed: $(command -v claude)"
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash

log "claude" "installed"
