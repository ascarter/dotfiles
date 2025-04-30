#!/bin/sh

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Ubuntu only" >&2
  exit 1
fi

# Verify Ubuntu
. /etc/os-release
case "${ID}" in
debian | ubuntu)
  sudo apt-get update && apt-get upgrade -y
  sudo apt-get install -y curl git gpg
  ;;
*)
  echo "Ubuntu/Debian only" >&2
  exit 1
  ;;
esac

# vim: set ft=sh ts=2 sw=2 et:
