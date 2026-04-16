#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v copilot >/dev/null 2>&1; then
  log "copilot" "updating"
  copilot update || warn "copilot" "update failed"
  exit 0
fi

curl -fsSL https://gh.io/copilot-install | bash

log "copilot" "installed"
