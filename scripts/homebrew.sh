#!/bin/sh

# Homebrew install script for macOS and Linux

set -eu

case "$(uname -s)" in
Darwin)
  HOMEBREW_PREFIX="/opt/homebrew"
  ;;
Linux)
  HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  sudo dnf group install development-tools
  ;;
esac

# Homebrew install
if ! [ -d "${HOMEBREW_PREFIX}" ]; then
  echo "Install Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
fi

# Post-install
if command -v brew >/dev/null 2>&1; then
  brew bundle check --global || brew bundle install --global

  case "$(uname -s)" in
  Darwin)
    # Enable man page contextual menu item in Terminal.app
    if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
      echo "Installing homrebrew.man.conf"
      sudo mkdir -p /usr/local/etc/man.d
      echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf
    fi
    ;;
  esac
fi

# vim: set ft=sh ts=2 sw=2 et:
