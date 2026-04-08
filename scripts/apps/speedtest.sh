#!/usr/bin/env bash

# Speedtest CLI installation script

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v speedtest >/dev/null 2>&1; then
  log "speedtest" "already installed: $(command -v speedtest)"
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    echo "speedtest not found. Run:"
    echo "  brew tap teamookla/speedtest"
    echo "  brew install teamookla/speedtest/speedtest"
    exit 1
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
        ubuntu | debian)
          echo "Installing Speedtest CLI on Debian/Ubuntu"
          curl -fsSL https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
          sudo apt-get install -y speedtest
          ;;
        fedora)
          echo "Installing Speedtest CLI on Fedora"
          curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
          sudo dnf install -y speedtest
          ;;
        *)
          abort "Unsupported Linux distribution: ${ID}"
          ;;
      esac
    else
      abort "Unsupported Linux distribution (missing /etc/os-release)"
    fi
    ;;
  *)
    abort "Unsupported operating system: $(uname -s)"
    ;;
esac
