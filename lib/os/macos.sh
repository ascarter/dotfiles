#!/bin/sh

# macOS install script

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
DOTFILES_SCRIPTS=${DOTFILES}/scripts

# Verify macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "macOS only" >&2
  exit 1
fi

# Xcode install
if ! [ -e /Library/Developer/CommandLineTools ]; then
  echo "Install xcode"
  xcode-select --install
  read -p "Press [Enter] to continue..." -n1 -s
  echo
  sudo xcodebuild -runFirstLaunch
fi

# Enable developer mode
spctl developer-mode enable-terminal

# Focus follow mouse
defaults write com.apple.terminal FocusFollowsMouse -string true
