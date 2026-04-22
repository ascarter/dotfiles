#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

# Juliaup installs to JULIAUP_HOME/bin which may not be on PATH yet
: "${JULIAUP_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/juliaup}"
export PATH="${JULIAUP_HOME}/bin:${PATH}"

if command -v juliaup >/dev/null 2>&1; then
  log "juliaup" "updating"
  juliaup self update || warn "juliaup" "self update failed"
  juliaup update || warn "juliaup" "channel update failed"
  exit 0
fi

# Use the following to review juliaup installer help and options:
# curl -fsSL https://install.julialang.org | sh -s -- --help

# Install juliaup with no prompt, custom path, and no PATH/self-update modifications
# --add-to-path=no prevents modifying .bashrc/.bash_profile (handled in shell config)
curl -fsSL https://install.julialang.org | sh -s -- -y \
  --path "${JULIAUP_HOME}" \
  --add-to-path=no \
  --background-selfupdate 0 \
  --startup-selfupdate 0

log "juliaup" "installed"
