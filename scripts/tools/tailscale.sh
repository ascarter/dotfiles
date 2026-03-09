#!/usr/bin/env bash

# Tailscale installation and enablement script
#
# Actions:
#   install (default): configure repo and install package
#   enable:            enable/start tailscaled and run tailscale up
#
# Linux (Fedora):
# - Uses shared Fedora host helper scripts for repo/package management.
#
# macOS:
# - Tailscale is expected to be managed by Homebrew cask.

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

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
    echo "Tailscale is already installed."
    return 0
  fi

  case "$OS" in
    Darwin)
      echo "Use Homebrew to install Tailscale on macOS:"
      echo "  brew install --cask tailscale-app"
      ;;

    Linux)
      [ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
      . /etc/os-release

      case "${ID:-}" in
        fedora)
          dotfiles script host/os/fedora/repo \
            "https://pkgs.tailscale.com/stable/fedora/tailscale.repo" \
            "/etc/yum.repos.d/tailscale.repo"

          dotfiles script host/os/fedora/pkg install tailscale
          echo "Tailscale package installed."
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
    echo "Tailscale is already connected."
    return 0
  fi

  case "$OS" in
    Darwin)
      echo "macOS enable/login is handled by the Tailscale app/CLI auth flow."
      echo "Run:"
      echo "  tailscale up --accept-routes=true --ssh"
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
