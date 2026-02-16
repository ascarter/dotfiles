#!/bin/sh

# Zed editor

set -eu

if ! command -v zed >/dev/null 2>&1; then
  curl -f https://zed.dev/install.sh | sh
fi

echo "Zed editor installed."