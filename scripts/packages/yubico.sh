#!/bin/sh

# Yubikey install script

set -eu

YUBICO_AUTHENTICATOR_ROOT="$XDG_DATA_HOME/yubico-authenticator"
YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT="$YUBICO_AUTHENTICATOR_ROOT/desktop_integration.sh"

install() {
  case $(uname -s) in
  Darwin)
    # Check if homebrew is installed. If it is, use homebrew to install 1Password
    if command -v brew >/dev/null 2>&1; then
      if ! [ -d "/Applications/Yubico Authenticator.app" ]; then
        brew install --cask yubico-authenticator
      fi
      brew install ykman
    else
      echo "Homebrew is not installed. Please install Homebrew first."
    fi
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
    fi

    YUBICO_AUTHENTICATOR_URL="https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz"
    curl -sSL "$YUBICO_AUTHENTICATOR_URL" | tar -xz -C "$YUBICO_AUTHENTICATOR_ROOT" --strip-components=1

    # case $ID in
    # fedora)
    #   ;;
    # debian | ubuntu)
    #   ;;
    # esac

    # Enable desktop integration
    if [ -f "$YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT" ]; then
      "$YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT" --install
    fi
    ;;
  esac

}

uninstall() {
  case $(uname -s) in
  Darwin)
    # Check if homebrew is installed
    if command -v brew >/dev/null 2>&1; then
      brew uninstall --cask yubico-authenticator
      brew uninstall ykman
    fi
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
    fi

    if [ -d "$YUBICO_AUTHENTICATOR_ROOT" ]; then
      # Disable desktop integration
      if [ -f "$YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT" ]; then
        "$YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT" --uninstall
      fi
      rm -rf "$YUBICO_AUTHENTICATOR_ROOT"
    fi
    ;;
  esac
}

info() {
  if command -v ykman >/dev/null 2>&1; then
    ykman --version
  else
    echo "ykman is not installed"
  fi
}

doctor() {
  if command -v ykman >/dev/null 2>&1; then
    ykman --diagnose
  else
    echo "ykman is not installed"
  fi
}
