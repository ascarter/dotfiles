#!/bin/sh

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

case $(uname -s) in
Darwin)
  brew install --cask docker
  ;;
Linux)
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Docker not yet supported on ${ID}${VARIANT_ID:+-$VARIANT_ID}"
  else
    echo "linux-unknown"
  fi
  ;;
*) echo "unknown" ;;
esac
