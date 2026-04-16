#!/usr/bin/env bash

# Fedora Atomic host initialisation
#
# First-time provisioning: rpm-ostree upgrade, RPM repos, overlay packages.
# A reboot is required after overlays are installed before running host update.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Linux" ] || abort "Fedora Linux only"
[ -f /etc/os-release ] || abort "Unsupported Linux distribution"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || abort "Fedora Linux only"

HOST_DIR="${DOTFILES_HOME}/host/fedora-atomic"
DOTFILES="${DOTFILES_HOME}/bin/dotfiles"

log "init" "Provisioning Fedora Atomic host ($VARIANT_ID)"

rpm-ostree upgrade

"$DOTFILES" script host/rpm-repos "${HOST_DIR}/rpm-repos"
"$DOTFILES" script host/rpm-overlays "${HOST_DIR}/overlay-rpms"

log "init" "Fedora Atomic provisioning complete"
log "init" "Reboot required: run 'systemctl reboot' then 'dotfiles host update'"
