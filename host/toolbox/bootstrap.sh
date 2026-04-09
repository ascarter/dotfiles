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
dnf_install() { sudo dnf install -y "$@" || warn "dnf" "failed: $*"; }

dnf_pkgs="${HOST_DIR}/dnf-rpms"
if [ -f "${dnf_pkgs}" ]; then
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    dnf_install "$pkg"
  done < "${dnf_pkgs}"
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

# gh-tool — install CLI tools from GitHub releases
if command -v gh >/dev/null 2>&1; then
  if ! gh extension list 2>/dev/null | grep -q gh-tool; then
    log "gh-tool" "Installing gh-tool extension"
    gh extension install ascarter/gh-tool
  fi
  log "gh-tool" "Installing workstation tools"
  gh tool install
else
  warn "gh" "gh not found — install gh first"
fi

log "init" "Toolbox provisioning complete"
