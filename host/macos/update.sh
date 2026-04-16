#!/usr/bin/env bash

# macOS host update
#
# Ongoing maintenance: brew upgrade, brew bundle, gh tool upgrade,
# and app scripts.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Darwin" ] || abort "macOS only"

DOTFILES="${DOTFILES_HOME}/bin/dotfiles"

log "update" "Updating macOS host"

"$DOTFILES" script host/homebrew
"$DOTFILES" script host/gh-tool upgrade

log "apps" "Running app scripts"
for script in "${DOTFILES_HOME}/scripts/apps/"*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "$script" .sh)"
  vlog "app" "$name"
  "$DOTFILES" script "apps/$name" || warn "app" "$name failed (continuing)"
done

log "update" "macOS host update complete"
