#!/usr/bin/env bash

# Install RPM repositories from a manifest file (Linux only)
#
# Usage:
#   dotfiles script host/rpm-repos                    # uses default manifest
#   dotfiles script host/rpm-repos /path/to/manifest  # uses specified manifest
#
# Manifest format: one repo URL per line. Lines starting with # are comments.
# Idempotent: skips repos already in /etc/yum.repos.d/.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/rpm.sh"

[ "$(uname -s)" = "Linux" ] || { log "rpm-repos" "Linux only — skipping"; exit 0; }

# Determine manifest: argument, or auto-detect from host environment
manifest="${1:-}"
if [ -z "$manifest" ]; then
  if [ -f /run/.toolboxenv ]; then
    manifest="${DOTFILES_HOME}/host/toolbox/rpm-repos"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID:-}" in
      fedora) manifest="${DOTFILES_HOME}/host/fedora-atomic/rpm-repos" ;;
    esac
  fi
fi

[ -n "$manifest" ] && [ -f "$manifest" ] || { log "rpm-repos" "no manifest found"; exit 0; }

log "rpm-repos" "Processing $(basename "$(dirname "$manifest")")/$(basename "$manifest")"

while IFS= read -r repo || [ -n "$repo" ]; do
  [[ "$repo" =~ ^#.*$ || -z "$repo" ]] && continue
  add_repo "$repo"
done < "$manifest"

log "rpm-repos" "done"
