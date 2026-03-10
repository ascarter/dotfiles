#!/usr/bin/env bash

# Initialize a toolbox container for dotfiles use.
#
# This script:
# 1) Ensures the target toolbox exists
# 2) Optionally installs a minimal container-local package baseline (git, zsh, curl)
# 3) Ensures ~/.zshenv bootstraps dotfiles environment
# 4) Runs `dotfiles shell` and `dotfiles sync` inside the container
#
# Usage:
#   dotfiles script host/config/toolbox-init <container-name> [--no-packages]
#
# Examples:
#   dotfiles script host/config/toolbox-init dev
#   dotfiles script host/config/toolbox-init rust --no-packages

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

usage() {
  cat <<'EOF'
Usage:
  toolbox-init <container-name> [--no-packages]

Options:
  --no-packages   Skip container-local package installation (git zsh curl)

Notes:
  - This script is intended to run on the host.
  - It does NOT run host provisioning scripts inside the container.
  - It runs only shell/bootstrap + sync logic for dotfiles.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || abort "Missing required command: $1"
}

run_in_toolbox() {
  container="$1"
  shift
  toolbox run --container "$container" -- "$@"
}

main() {
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage && exit 0
  [ $# -ge 1 ] || abort "Container name is required. Run with --help for usage."

  CONTAINER="$1"
  shift

  INSTALL_PACKAGES=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-packages) INSTALL_PACKAGES=0 ;;
      -h|--help) usage; exit 0 ;;
      *) abort "Unknown argument: $1" ;;
    esac
    shift
  done

  require_cmd toolbox
  require_cmd podman

  if ! podman container exists "$CONTAINER"; then
    abort "Toolbox container not found: $CONTAINER"
  fi

  log "toolbox" "Initializing container: $CONTAINER"

  if [ "$INSTALL_PACKAGES" -eq 1 ]; then
    log "toolbox" "Ensuring container-local packages: git zsh curl"
    run_in_toolbox "$CONTAINER" sh -lc '
      set -eu
      if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git zsh curl
      else
        echo "dnf not found; skipping package install baseline" >&2
      fi
    '
  fi

  run_in_toolbox "$CONTAINER" sh -lc '
    set -eu

    : "${XDG_DATA_HOME:=$HOME/.local/share}"
    : "${DOTFILES_HOME:=$XDG_DATA_HOME/dotfiles}"

    [ -x "$DOTFILES_HOME/bin/dotfiles" ] || {
      echo "dotfiles executable not found at: $DOTFILES_HOME/bin/dotfiles" >&2
      exit 1
    }

    "$DOTFILES_HOME/bin/dotfiles" shell || true
    "$DOTFILES_HOME/bin/dotfiles" sync

    echo "Toolbox dotfiles bootstrap complete."
    echo "Shell: $(getent passwd "$(whoami)" | cut -d: -f7 2>/dev/null || true)"
    echo "dotfiles: $(command -v dotfiles || true)"
    echo "zsh: $(command -v zsh || true)"
    echo "git: $(command -v git || true)"
  '

  log "toolbox" "Done: '$CONTAINER' is initialized"
}

main "$@"
