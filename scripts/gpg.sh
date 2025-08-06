#!/bin/sh

# gpg configuration script

set -eu

# Set default values for environment variables if not already set
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${DOTFILES:=${XDG_DATA_HOME:-${HOME}/.local/share}/dotfiles}"

case $(uname -s) in
Darwin)
  if command -v pinentry-mac >/dev/null 2>&1; then
    # Configure pinentry-mac to use the macOS keychain
    defaults write org.gpgtools.pinentry-mac UseKeychain -bool YES
    defaults write org.gpgtools.pinentry-mac DisableKeychain -bool NO

    # Set pinentry-mac as the default pinentry program in ~/.gnupg/gpg-agent.conf
    gpg_agent_conf="$HOME/.gnupg/gpg-agent.conf"
    pinentry_path=$(which pinentry-mac)

    # Create .gnupg directory if it doesn't exist with correct permissions
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"

    # Check if pinentry-program is already set
    if [ ! -f "$gpg_agent_conf" ] || ! grep -q "^pinentry-program" "$gpg_agent_conf"; then
      echo "pinentry-program $pinentry_path" >>"$gpg_agent_conf"
    fi
  fi
  ;;
esac
