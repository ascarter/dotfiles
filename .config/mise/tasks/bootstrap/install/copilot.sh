#!/usr/bin/env sh
#MISE description="Install GitHub Copilot CLI from the official installer"

set -eu

if command -v copilot >/dev/null 2>&1; then
  exit 0
fi

curl -fsSL https://gh.io/copilot-install | bash

if ! command -v copilot >/dev/null 2>&1; then
  printf 'copilot install failed\n' >&2
  exit 1
fi
