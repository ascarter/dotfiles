#!/usr/bin/env bash

# Install or upgrade Homebrew and run brew bundle (macOS only)
#
# Idempotent: installs Homebrew if missing, always runs brew bundle.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Darwin" ] || { log "homebrew" "macOS only — skipping"; exit 0; }

HOMEBREW_PREFIX="/opt/homebrew"

if ! [ -d "${HOMEBREW_PREFIX}" ]; then
  log "homebrew" "Installing to ${HOMEBREW_PREFIX}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "homebrew" "installed: ${HOMEBREW_PREFIX}"
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"

log "brew" "Upgrading packages"
brew upgrade

brew bundle --global check || brew bundle --global install

log "homebrew" "done"
