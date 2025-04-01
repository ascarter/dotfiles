#!/bin/sh

set -euo pipefail

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Ubuntu only" >&2
  exit 1
fi

# Verify Ubuntu
. /etc/os-release
if [ "$ID" != "ubuntu" ]; then
  echo "Ubuntu only" >&2
  exit 1
fi
