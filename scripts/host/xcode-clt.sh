#!/usr/bin/env bash

# Install Xcode Command Line Tools (macOS only)
#
# Idempotent: skips if already installed.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Darwin" ] || { log "xcode-clt" "macOS only — skipping"; exit 0; }

if [ -e /Library/Developer/CommandLineTools ]; then
  log "xcode-clt" "already installed"
  exit 0
fi

log "xcode-clt" "Installing command line tools..."
xcode-select --install
read -p "Press [Enter] when installation completes..." -n1 -s
echo
sudo xcodebuild -runFirstLaunch

log "xcode-clt" "installed"
