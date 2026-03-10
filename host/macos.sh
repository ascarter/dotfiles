#!/usr/bin/env bash

# macOS host provisioning script
#
# Installs Xcode command line tools, enables developer mode, applies terminal
# preferences, installs Homebrew, and runs brew bundle --global.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

[ "$(uname -s)" = "Darwin" ] || abort "macOS only"

log "init" "Provisioning macOS host"

# Xcode command line tools
if ! [ -e /Library/Developer/CommandLineTools ]; then
  log "xcode" "Installing command line tools..."
  xcode-select --install
  read -p "Press [Enter] when installation completes..." -n1 -s
  echo
  sudo xcodebuild -runFirstLaunch
else
  log "xcode" "command line tools OK"
fi

# Enable developer mode
log "spctl" "Enabling developer mode"
spctl developer-mode enable-terminal 2>/dev/null || true

# Terminal preferences
log "defaults" "Setting Terminal preferences"
defaults write com.apple.terminal FocusFollowsMouse -string true

# Homebrew
HOMEBREW_PREFIX="/opt/homebrew"
if ! [ -d "${HOMEBREW_PREFIX}" ]; then
  log "homebrew" "Installing to ${HOMEBREW_PREFIX}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "homebrew" "installed: ${HOMEBREW_PREFIX}"
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
brew bundle --global check || brew bundle --global install

log "init" "macOS provisioning complete"
