#!/usr/bin/env bash

# Fedora Atomic host update
#
# Ongoing maintenance: rpm-ostree upgrade, gh tool upgrade, and app scripts.
# Assumes init has been run and overlays are installed (post-reboot).

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Linux" ] || abort "Fedora Linux only"
[ -f /etc/os-release ] || abort "Unsupported Linux distribution"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || abort "Fedora Linux only"

log "update" "Updating Fedora Atomic host"

DOTFILES="${DOTFILES_HOME}/bin/dotfiles"

log "ostree" "Checking for system updates"
rpm-ostree upgrade

"$DOTFILES" script host/gh-tool upgrade

log "apps" "Running app scripts"
for script in "${DOTFILES_HOME}/scripts/apps/"*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "$script" .sh)"
  vlog "app" "$name"
  "$DOTFILES" script "apps/$name" || warn "app" "$name failed (continuing)"
done

log "update" "Fedora Atomic host update complete"
