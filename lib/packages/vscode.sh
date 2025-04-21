#!/bin/sh

set -eu

install() {
  case $(uname -s) in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew install --cask visual-studio-code
    else
      echo "Homebrew is not installed. Please install Homebrew first."
    fi
    ;;
  Linux)
    if ! command -v code >/dev/null 2>&1; then
      echo "Not yet supported"
    fi
    ;;
  esac
}

uninstall() {
  case $(uname -s) in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew uninstall --cask visual-studio-code
    fi
    ;;
  Linux)
    echo "Not yet supported"
    ;;
  esac
}

info() {
  if command -v code >/dev/null 2>&1; then
    code --version
  else
    echo "code is not installed."
  fi
}

doctor() {
  info
}
