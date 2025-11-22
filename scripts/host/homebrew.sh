#!/bin/sh

# Homebrew package manager

set -eu

case "$(uname -s)" in
  Darwin)
    HOMEBREW_PREFIX="/opt/homebrew"
    HOMEBREW_INTERACTIVE=""
    ;;
  Linux)
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    HOMEBREW_INTERACTIVE="NONINTERACTIVE=1"
    ;;
esac

if ! [ -d "${HOMEBREW_PREFIX}" ]; then
  echo "Installing homebrew to ${HOMEBREW_PREFIX}"
  env ${HOMEBREW_INTERACTIVE} /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew installed to ${HOMEBREW_PREFIX}"
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
brew bundle --global check || brew bundle --global install

# Post-install configuration
# case "$(uname -s)" in
#   Darwin)
#     # Enable man page contextual menu item in Terminal.app
#     if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
#       log info "homebrew" "configuring man pages"
#       sudo mkdir -p /usr/local/etc/man.d
#       echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf >/dev/null
#     fi
#     ;;
# esac

echo "homebrew installation complete"
