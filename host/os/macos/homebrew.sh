#!/usr/bin/env bash

# Homebrew package manager

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

case "$(uname -s)" in
  Darwin) HOMEBREW_PREFIX="/opt/homebrew" ;;
  Linux)  HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew" ;;
esac

if ! [ -d "${HOMEBREW_PREFIX}" ]; then
  log "homebrew" "Installing to ${HOMEBREW_PREFIX}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "homebrew" "installed: ${HOMEBREW_PREFIX}"
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
brew bundle --global check || brew bundle --global install

log "homebrew" "installation complete"
