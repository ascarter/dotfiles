#!/bin/sh

# Speedtest CLI installation script

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

case "$(uname -s)" in
  Darwin)
    echo "Use Homebrew to install Speedtest CLI on macOS"
    echo "brew tap "teamookla/speedtest"
    echo "brew install teamookla/speedtest/speedtest"
    exit 0
    ;;
  Linux)
    if command -v speedtest >/dev/null 2>&1; then
      echo "Speedtest CLI is already installed."
    else
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
   sudo yum install speedtest
   curl -fsSL https://install.speedtest.net/app/cli/install.rpm.sh | sudo bash
            sudo dnf install -y speedtest
            ;;
          *)
            abort "Unsupported Linux distribution: ${ID}"
            ;;
        esac
    fi
    ;;
  *)
    abort "Unsupported operating system: $(uname -s)"
    ;;
esac
