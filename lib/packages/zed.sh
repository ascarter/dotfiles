#!/bin/sh

set -eu

install() {
  case $(uname -s) in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew install --cask zed zed@preview
    else
      echo "Homebrew is not installed. Please install Homebrew first."
    fi
    ;;
  Linux)
    if ! command -v zed >/dev/null 2>&1; then
      # Install Zed app bundle to ~/.local and add `zed` to ~/.local/bin
      curl -f https://zed.dev/install.sh | sh
    fi
    if ! command -v zed-preview >/dev/null 2>&1; then
      # Install Zed preview app bundle to ~/.local and add `zed-preview` to ~/.local/bin
      curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh
    fi
    ;;
  esac
}

uninstall() {
  case $(uname -s) in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew uninstall --cask zed zed@preview
    fi
    ;;
  Linux)
    if ! command -v zed >/dev/null 2>&1; then
      zed --uninstall
    fi

    if ! command -v zed-preview >/dev/null 2>&1; then
      zed-preview --uninstall
    fi
    ;;
  esac
}

info() {
  if command -v zed >/dev/null 2>&1; then
    zed --version
  else
    echo "zed is not installed."
  fi

  if command -v zed-preview >/dev/null 2>&1; then
    zed-preview --version
  else
    echo "zed-preview is not installed."
  fi
}

doctor() {
  info
}
