#!/bin/sh

set -eu

install() {
  # Default to stable
  # To install preview:
  #   ZED_CHANNEL=preview zed.sh
  ZED_CHANNEL=${ZED_CHANNEL:-stable}
  
  if ! command -v zed >/dev/null 2>&1; then
    # Install Zed app bundle and add `zed` to ~/.local/bin
    curl -f https://zed.dev/install.sh | ZED_CHANNEL=$ZED_CHANNEL sh
  fi
}

uninstall() {
  if command -v zed >/dev/null 2>&1; then
    zed --uninstall
  fi
}

info() {
  if command -v zed >/dev/null 2>&1; then
    zed --version
  else
    echo "zed is not installed."
  fi
}

doctor() {
  info
}
