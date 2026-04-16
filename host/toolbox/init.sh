#!/usr/bin/env bash

# Toolbox container initialisation
#
# First-time provisioning: RPM repos, baseline packages, login shell.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ -f /run/.toolboxenv ] || abort "Not running inside a toolbox container"

HOST_DIR="${DOTFILES_HOME}/host/toolbox"
DOTFILES="${DOTFILES_HOME}/bin/dotfiles"

log "init" "Provisioning toolbox container"

"$DOTFILES" script host/rpm-repos "${HOST_DIR}/rpm-repos"
"$DOTFILES" script host/dnf-packages "${HOST_DIR}/dnf-rpms"

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

"$DOTFILES" script host/gh-tool install

log "init" "Toolbox provisioning complete"
