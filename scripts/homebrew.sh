#!/bin/sh

set -eu

# Verify macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "macOS only" >&2
  exit 1
fi

# Homebrew install
if ! [ -d /opt/homebrew ]; then
  echo "Install Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v brew >/dev/null 2>&1; then
  if ! brew bundle check --global; then
    brew bundle install --global
  fi

  # Enable man page contextual menu item in Terminal.app
  if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
    echo "Installing homrebrew.man.conf"
    sudo mkdir -p /usr/local/etc/man.d
    echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf
  fi
fi
