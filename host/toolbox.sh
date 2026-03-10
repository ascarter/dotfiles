#!/usr/bin/env bash

# Toolbox container provisioning script
#
# Run inside a toolbox container (detected via /run/.toolboxenv).
# Installs a minimal package baseline and configures the login shell.
#
# Usage:
#   dotfiles host init                 # auto-detected when inside a toolbox
#   bash host/os/toolbox.sh            # run directly

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

[ -f /run/.toolboxenv ] || abort "Not running inside a toolbox container"

log "init" "Provisioning toolbox container"

# Install baseline packages
if command -v dnf >/dev/null 2>&1; then
  log "pkg" "Installing baseline packages: git zsh curl"
  sudo dnf install -y git zsh curl
else
  warn "pkg" "dnf not found — skipping package baseline"
fi

# Set login shell to zsh
zsh_path="$(command -v zsh 2>/dev/null || true)"
if [ -n "$zsh_path" ]; then
  if ! getent passwd "$(whoami)" | grep -qE ":${zsh_path}$"; then
    log "shell" "Setting login shell to zsh"
    chsh --shell "$zsh_path"
  else
    log "shell" "login shell already zsh"
  fi
else
  warn "shell" "zsh not found — skipping login shell change"
fi

log "init" "Toolbox provisioning complete"
