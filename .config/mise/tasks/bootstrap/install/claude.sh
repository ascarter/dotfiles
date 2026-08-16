#!/usr/bin/env sh
#MISE description="Install Claude Code from the official installer"

set -eu

if command -v claude >/dev/null 2>&1; then
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash

if ! command -v claude >/dev/null 2>&1; then
  printf 'claude install failed\n' >&2
  exit 1
fi
