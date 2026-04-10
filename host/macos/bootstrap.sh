#!/usr/bin/env bash

# macOS host provisioning
#
# Installs Xcode CLT, applies defaults, installs Homebrew, runs brew bundle,
# and installs gh-tool.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Darwin" ] || abort "macOS only"

HOST_DIR="${DOTFILES_HOME}/host/macos"

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

# macOS defaults
log "defaults" "Applying macOS defaults"

# Terminal: focus follows mouse
defaults write com.apple.terminal FocusFollowsMouse -string true

# Reduce menu icons (macOS 26 Tahoe+)
defaults write -g NSMenuEnableActionImages -bool NO

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

# gh-tool — install CLI tools from GitHub releases
if command -v gh >/dev/null 2>&1; then
  if ! gh extension list 2>/dev/null | grep -q gh-tool; then
    log "gh-tool" "Installing gh-tool extension"
    gh extension install ascarter/gh-tool
  fi
  log "gh-tool" "Installing workstation tools"
  gh tool install
else
  warn "gh" "gh not found — install via brew"
fi

log "init" "macOS provisioning complete"
