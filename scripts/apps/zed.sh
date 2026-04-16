#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v zed >/dev/null 2>&1; then
  log "zed" "already installed (self-updates)"
  exit 0
fi

curl -f https://zed.dev/install.sh | sh

log "zed" "installed"
