#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v codex >/dev/null 2>&1; then
  log "codex" "updating"
  codex update || warn "codex" "update failed"
  exit 0
fi

curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

log "codex" "installed"
