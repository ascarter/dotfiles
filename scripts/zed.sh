#!/bin/sh

set -eu

case $(uname -s) in
Darwin)
  if command -v brew >/dev/null 2>&1; then
    brew install --cask zed@preview
  else
    echo "Homebrew is not installed. Please install Homebrew first."
  fi
  ;;
Linux)
  # Default to stable
  # To install preview:
  #   ZED_CHANNEL=preview zed.sh
  ZED_CHANNEL=${ZED_CHANNEL:-stable}
  
  if ! command -v zed >/dev/null 2>&1; then
    # Install Zed app bundle and add `zed` to ~/.local/bin
    echo "Install zed ${ZED_CHANNEL}"
    curl -f https://zed.dev/install.sh | ZED_CHANNEL=$ZED_CHANNEL sh
  fi
  ;;
esac
