#!/usr/bin/env bash

# Install or upgrade gh-tool extension and managed tools
#
# Installs the gh-tool extension if missing, then runs install or upgrade.
# Requires gh CLI to be available.
#
# Usage:
#   dotfiles script host/gh-tool           # install tools
#   dotfiles script host/gh-tool upgrade   # upgrade tools

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if ! command -v gh >/dev/null 2>&1; then
  warn "gh-tool" "gh not found — skipping"
  exit 0
fi

# Ensure gh-tool extension is installed or upgraded
if ! gh extension list 2>/dev/null | grep -q gh-tool; then
  log "gh-tool" "Installing gh-tool extension"
  gh extension install ascarter/gh-tool
else
  gh extension upgrade tool 2>/dev/null || true
fi

action="${1:-install}"

case "$action" in
  install)
    log "gh-tool" "Installing workstation tools"
    gh tool install
    ;;
  upgrade)
    log "gh-tool" "Upgrading workstation tools"
    gh tool upgrade
    ;;
  *)
    abort "Unknown action: $action (use install or upgrade)"
    ;;
esac

log "gh-tool" "done"
