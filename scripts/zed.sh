#!/bin/sh

set -eu

# Handle command line option to enable preview channel
ZED_CHANNEL=${ZED_CHANNEL:-stable}

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -c  Channel (default: ${ZED_CHANNEL})"
  echo "  -h  Show usage"
}

while getopts ":hc:" opt; do
  case $opt in
  c)
    ZED_CHANNEL=$OPTARG
    ;;
  h)
    usage
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

case $(uname -s) in
Darwin)
  if command -v brew >/dev/null 2>&1; then
    CASK=zed
    if ! [ "$ZED_CHANNEL" = "stable" ]; then
      CASK="${CASK}@${ZED_CHANNEL}"
    fi
    brew install --cask "${CASK}"
  else
    echo "Homebrew is not installed. Please install Homebrew first."
  fi
  ;;
Linux)
  if ! command -v zed >/dev/null 2>&1; then
    # Install Zed app bundle and add `zed` to ~/.local/bin
    echo "Install zed ${ZED_CHANNEL}"
    curl -f https://zed.dev/install.sh | ZED_CHANNEL=$ZED_CHANNEL sh
  fi
  ;;
esac
