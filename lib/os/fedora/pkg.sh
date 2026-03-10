#!/usr/bin/env bash

# Fedora package helper script.
#
# Intended to be called via:
#   bash "${DOTFILES_LIB_DIR}/os/fedora/pkg.sh" [install|remove|refresh] <package>

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

usage() {
  cat <<'EOF'
Usage:
  bash "${DOTFILES_LIB_DIR}/os/fedora/pkg.sh" install <package>
  bash "${DOTFILES_LIB_DIR}/os/fedora/pkg.sh" remove <package>
  bash "${DOTFILES_LIB_DIR}/os/fedora/pkg.sh" refresh
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
      log "pkg" "Installing via rpm-ostree: $PACKAGE"
      rpm-ostree refresh-md
      rpm-ostree install --idempotent "$PACKAGE"
    else
      require_cmd dnf
      log "pkg" "Installing via dnf: $PACKAGE"
      sudo dnf makecache --refresh
      sudo dnf install -y "$PACKAGE"
    fi
    ;;
  remove)
    [ -n "$PACKAGE" ] || { usage; abort "remove requires a package name"; }

    if [ "$is_atomic" -eq 1 ]; then
      require_cmd rpm-ostree
      log "pkg" "Removing via rpm-ostree: $PACKAGE"
      rpm-ostree uninstall --idempotent "$PACKAGE"
    else
      require_cmd dnf
      log "pkg" "Removing via dnf: $PACKAGE"
      sudo dnf remove -y "$PACKAGE"
    fi
    ;;
  refresh)
    if [ "$is_atomic" -eq 1 ]; then
      require_cmd rpm-ostree
      log "pkg" "Refreshing rpm-ostree metadata"
      rpm-ostree refresh-md
    else
      require_cmd dnf
      log "pkg" "Refreshing dnf metadata"
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
