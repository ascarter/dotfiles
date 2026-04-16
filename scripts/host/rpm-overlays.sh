#!/usr/bin/env bash

# Install rpm-ostree overlay packages from a manifest file (Fedora Atomic only)
#
# Usage:
#   dotfiles script host/rpm-overlays                    # uses default manifest
#   dotfiles script host/rpm-overlays /path/to/manifest  # uses specified manifest
#
# Manifest format: one package per line. Lines starting with # are comments.
# Idempotent: uses rpm-ostree install --idempotent.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Linux" ] || { log "rpm-overlays" "Linux only — skipping"; exit 0; }
[ -f /run/.toolboxenv ] && { log "rpm-overlays" "not applicable in toolbox"; exit 0; }

# Determine manifest
manifest="${1:-}"
if [ -z "$manifest" ]; then
  manifest="${DOTFILES_HOME}/host/fedora-atomic/overlay-rpms"
fi

[ -f "$manifest" ] || { log "rpm-overlays" "no manifest found"; exit 0; }

log "rpm-overlays" "Processing $(basename "$manifest")"

while IFS= read -r pkg || [ -n "$pkg" ]; do
  [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
  rpm-ostree install --idempotent "$pkg" || warn "overlay" "failed: $pkg"
done < "$manifest"

# Desktop-specific overlays
case "${XDG_CURRENT_DESKTOP:-}" in
COSMIC)
  ;;
GNOME)
  rpm-ostree install --idempotent gnome-tweaks || warn "overlay" "failed: gnome-tweaks"
  gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
  ;;
esac

log "rpm-overlays" "done"
