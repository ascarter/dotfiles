#!/usr/bin/env bash

# Enable Tailscale and authenticate.
#
# Requires tailscale to already be installed:
#   macOS  — brew install --cask tailscale
#   Fedora — add tailscale repo to host rpm-repos manifest, then overlay/dnf install
#
# This script enables the tailscaled service and runs `tailscale up`.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

OS="$(uname -s)"

if ! command -v tailscale >/dev/null 2>&1; then
  abort "Tailscale is not installed"
fi

if tailscale status >/dev/null 2>&1; then
  log "tailscale" "already connected"
  exit 0
fi

case "$OS" in
  Darwin)
    log "tailscale" "macOS: login is handled by the Tailscale app/CLI auth flow"
    log "tailscale" "Run: tailscale up --accept-routes=true --ssh"
    ;;

  Linux)
    [ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
    . /etc/os-release

    case "${ID:-}" in
      fedora)
        sudo systemctl enable --now tailscaled
        sudo tailscale up --accept-routes=true --ssh
        ;;
      *)
        abort "Unsupported Linux distribution: ${ID:-unknown}"
        ;;
    esac
    ;;
  *)
    abort "Unsupported OS: $OS"
    ;;
esac
