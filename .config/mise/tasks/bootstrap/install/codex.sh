#!/usr/bin/env sh
#MISE description="Install Codex from the official installer"

set -eu

if command -v codex >/dev/null 2>&1; then
  exit 0
fi

curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

if ! command -v codex >/dev/null 2>&1; then
  printf 'codex install failed\n' >&2
  exit 1
fi
