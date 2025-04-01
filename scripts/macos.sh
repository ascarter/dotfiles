#!/bin/sh

# macOS install script

set -euo pipefail

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

# Homebrew install
if ! [ -d /opt/homebrew ]; then
  echo "Install Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Enable man page contextual menu item in Terminal.app
if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
  echo "Installing homrebrew.man.conf"
  sudo mkdir -p /usr/local/etc/man.d
  echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf
fi

if [ -x "$(command -v brew)" ]; then
  if ! brew bundle check --global; then
    brew bundle install --global
  fi
fi
