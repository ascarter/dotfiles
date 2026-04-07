#!/usr/bin/env bash

# Toolbox container provisioning
#
# Installs baseline packages and configures login shell.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ -f /run/.toolboxenv ] || abort "Not running inside a toolbox container"

HOST_DIR="${DOTFILES_HOME}/host/toolbox"

log "init" "Provisioning toolbox container"

# Install baseline packages from manifest
if command -v dnf >/dev/null 2>&1 && [ -f "${HOST_DIR}/dnf-packages.txt" ]; then
  pkgs=()
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    pkgs+=("$pkg")
  done < "${HOST_DIR}/dnf-packages.txt"
  if [ ${#pkgs[@]} -gt 0 ]; then
    log "pkg" "Installing: ${pkgs[*]}"
    sudo dnf install -y "${pkgs[@]}"
  fi
else
  warn "pkg" "dnf not found or no package list — skipping"
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

# Aqua
AQUA_BIN="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin"
if ! command -v aqua >/dev/null 2>&1 && ! [ -x "${AQUA_BIN}/aqua" ]; then
  log "aqua" "Installing aqua"
  curl -sSfL https://raw.githubusercontent.com/aquaproj/aqua-installer/v4.0.2/aqua-installer | bash
fi
export PATH="${AQUA_BIN}:${PATH}"
if command -v aqua >/dev/null 2>&1; then
  log "aqua" "Installing workstation tools"
  aqua i -a
else
  warn "aqua" "aqua installation failed"
fi

log "init" "Toolbox provisioning complete"
