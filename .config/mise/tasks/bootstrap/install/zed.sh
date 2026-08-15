#!/usr/bin/env sh
#MISE description="Install Zed from the official installer"

set -eu

if command -v zed >/dev/null 2>&1; then
  exit 0
fi

curl -fsSL https://zed.dev/install.sh | sh

if ! command -v zed >/dev/null 2>&1; then
  printf 'bootstrap:install:zed: installation did not produce a working zed command\n' >&2
  exit 1
fi
