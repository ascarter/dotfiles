#!/usr/bin/env bash

# Install dnf packages from a manifest file (toolbox/Fedora only)
#
# Usage:
#   dotfiles script host/dnf-packages                    # uses default manifest
#   dotfiles script host/dnf-packages /path/to/manifest  # uses specified manifest
#
# Manifest format: one package per line. Lines starting with # are comments.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Linux" ] || { log "dnf-packages" "Linux only — skipping"; exit 0; }

# Determine manifest: argument, or auto-detect from host environment
manifest="${1:-}"
if [ -z "$manifest" ]; then
  if [ -f /run/.toolboxenv ]; then
    manifest="${DOTFILES_HOME}/host/toolbox/dnf-rpms"
  fi
fi

[ -n "$manifest" ] && [ -f "$manifest" ] || { log "dnf-packages" "no manifest found"; exit 0; }

log "dnf-packages" "Processing $(basename "$manifest")"

while IFS= read -r pkg || [ -n "$pkg" ]; do
  [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
  sudo dnf install -y "$pkg" || warn "dnf" "failed: $pkg"
done < "$manifest"

log "dnf-packages" "done"
