#!/usr/bin/env bash

# Toolbox container update
#
# Ongoing maintenance: dnf upgrade and gh tool upgrade.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ -f /run/.toolboxenv ] || abort "Not running inside a toolbox container"

log "update" "Updating toolbox container"

DOTFILES="${DOTFILES_HOME}/bin/dotfiles"

log "dnf" "Upgrading packages"
sudo dnf upgrade -y

"$DOTFILES" script host/gh-tool upgrade

log "update" "Toolbox container update complete"
