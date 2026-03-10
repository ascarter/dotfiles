#!/usr/bin/env bash

# macOS host provisioning script

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../../.." && pwd)}"
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

log "init" "macOS provisioning complete"
