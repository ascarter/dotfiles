#!/bin/sh

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

if ! command -v zed >/dev/null 2>&1; then
  # Install Zed app bundle to ~/.local and add `zed` to ~/.local/bin
  curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh
fi

print "Zed setup complete"
