#!/usr/bin/env bash

# macOS host initialisation
#
# First-time provisioning: Xcode CLT, Homebrew, brew bundle, macOS defaults,
# and gh-tool.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Darwin" ] || abort "macOS only"

DOTFILES="${DOTFILES_HOME}/bin/dotfiles"

log "init" "Provisioning macOS host"

"$DOTFILES" script host/xcode-clt
"$DOTFILES" script host/macos-defaults
"$DOTFILES" script host/homebrew
"$DOTFILES" script host/gh-tool install

log "init" "macOS provisioning complete"
