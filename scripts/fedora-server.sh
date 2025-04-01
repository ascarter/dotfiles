#!/bin/sh

set -euo pipefail

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Server only" >&2
  exit 1
fi

# Verify Fedora Server
. /etc/os-release
if [ "$ID" != "fedora" ] || [ "$VARIANT_ID" != "server" ]; then
  echo "Fedora Server only" >&2
  exit 1
fi

sudo dnf install -y dnf-plugins-core @development-tools curl git zsh

# Change default shell to zsh
sudo usermod -s /usr/bin/zsh ${USER}
