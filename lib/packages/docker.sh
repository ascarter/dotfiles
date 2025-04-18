#!/bin/sh

set -eu

install() {
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
}

uninstall() {
  case $(uname -s) in
  Darwin)
    brew uninstall --cask docker
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
}

info() {
  if command -v docker >/dev/null 2>&1; then
    docker --version
  fi
}

doctor() {
  if command -v docker >/dev/null 2>&1; then
    docker info
  fi
}
