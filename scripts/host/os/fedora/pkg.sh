#!/usr/bin/env bash

# Fedora package helper script.
#
# Intended to be called via:
#   dotfiles script host/os/fedora/pkg [install|remove|refresh] <package>

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  dotfiles script host/os/fedora/pkg install <package>
  dotfiles script host/os/fedora/pkg remove <package>
  dotfiles script host/os/fedora/pkg refresh
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || abort "Missing required command: $1"
}

[ "$(uname -s)" = "Linux" ] || abort "Unsupported OS: $(uname -s)"
[ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || abort "Unsupported Linux distribution: ${ID:-unknown}"

ACTION="${1:-}"
PACKAGE="${2:-}"

is_atomic=0
case "${VARIANT_ID:-}" in
  silverblue|cosmic-atomic) is_atomic=1 ;;
esac

case "$ACTION" in
  install)
    [ -n "$PACKAGE" ] || { usage; abort "install requires a package name"; }

    if [ "$is_atomic" -eq 1 ]; then
      require_cmd rpm-ostree
      echo "Installing package via rpm-ostree: $PACKAGE"
      rpm-ostree refresh-md
      rpm-ostree install --idempotent "$PACKAGE"
    else
      require_cmd sudo
      require_cmd dnf
      echo "Installing package via dnf: $PACKAGE"
      sudo dnf makecache --refresh
      sudo dnf install -y "$PACKAGE"
    fi
    ;;
  remove)
    [ -n "$PACKAGE" ] || { usage; abort "remove requires a package name"; }

    if [ "$is_atomic" -eq 1 ]; then
      require_cmd rpm-ostree
      echo "Removing package via rpm-ostree: $PACKAGE"
      rpm-ostree uninstall --idempotent "$PACKAGE"
    else
      require_cmd sudo
      require_cmd dnf
      echo "Removing package via dnf: $PACKAGE"
      sudo dnf remove -y "$PACKAGE"
    fi
    ;;
  refresh)
    if [ "$is_atomic" -eq 1 ]; then
      require_cmd rpm-ostree
      echo "Refreshing rpm-ostree metadata..."
      rpm-ostree refresh-md
    else
      require_cmd sudo
      require_cmd dnf
      echo "Refreshing dnf metadata..."
      sudo dnf makecache --refresh
    fi
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    abort "Unknown action: ${ACTION:-<none>}"
    ;;
esac
