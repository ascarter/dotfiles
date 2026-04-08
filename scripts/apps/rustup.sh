#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v rustup >/dev/null 2>&1; then
  log "rustup" "already installed: $(command -v rustup)"
  exit 0
fi

# Use the following to review rustup help and options:
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --help

# Install rustup with default toolchain and no path modification (handled in shell config)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

log "rustup" "installed"
