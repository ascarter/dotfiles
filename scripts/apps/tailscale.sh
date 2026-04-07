#!/usr/bin/env bash

# Tailscale installation and enablement script
#
# Actions:
#   install (default): configure repo and install package
#   enable:            enable/start tailscaled and run tailscale up
#
# Linux (Fedora):
# - Uses shared Fedora lib helper scripts for repo/package management.
#
# macOS:
# - Tailscale is expected to be managed by Homebrew cask.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

usage() {
  cat <<'EOF'
Usage:
  tailscale.sh [install|enable]

Actions:
  install   Install Tailscale package (default)
  enable    Enable/start tailscaled and run tailscale up

Examples:
  tailscale.sh
  tailscale.sh install
  tailscale.sh enable
EOF
}

ACTION="${1:-install}"

case "$ACTION" in
  install|enable) ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    usage
    abort "Unknown action: $ACTION"
    ;;
esac

OS="$(uname -s)"

install() {
  if command -v tailscale >/dev/null 2>&1; then
    log "tailscale" "already installed: $(command -v tailscale)"
    return 0
  fi

  case "$OS" in
    Darwin)
      log "tailscale" "not found. Run: brew install --cask tailscale-app"
      exit 1
      ;;

    Linux)
      [ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
      . /etc/os-release

      case "${ID:-}" in
        fedora)
          bash "${DOTFILES_HOME}/lib/os/fedora/repo.sh" \
            "https://pkgs.tailscale.com/stable/fedora/tailscale.repo" \
            "/etc/yum.repos.d/tailscale.repo"

          bash "${DOTFILES_HOME}/lib/os/fedora/pkg.sh" install tailscale
          log "tailscale" "package installed"
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
}

enable() {
  if ! command -v tailscale >/dev/null 2>&1; then
    abort "Tailscale is not installed. Run: tailscale.sh install"
  fi

  if tailscale status >/dev/null 2>&1; then
    log "tailscale" "already connected"
    return 0
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
}

case "$ACTION" in
  install)
    install
    ;;
  enable)
    enable
    ;;
esac
