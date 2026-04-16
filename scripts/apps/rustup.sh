#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

# Rustup installs to CARGO_HOME/bin which may not be on PATH yet
: "${CARGO_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/cargo}"
export PATH="${CARGO_HOME}/bin:${PATH}"

if command -v rustup >/dev/null 2>&1; then
  log "rustup" "updating"
  rustup self update || warn "rustup" "self update failed"
  rustup update || warn "rustup" "toolchain update failed"
  exit 0
fi

# Use the following to review rustup help and options:
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --help

# Install rustup with default toolchain and no path modification (handled in shell config)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

log "rustup" "installed"
