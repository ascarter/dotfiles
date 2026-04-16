#!/usr/bin/env bash

# Apply macOS defaults (macOS only)
#
# Idempotent: safe to re-run.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

[ "$(uname -s)" = "Darwin" ] || { log "macos-defaults" "macOS only — skipping"; exit 0; }

log "defaults" "Applying macOS defaults"

# Enable developer mode
spctl developer-mode enable-terminal 2>/dev/null || true

# Terminal: focus follows mouse
defaults write com.apple.terminal FocusFollowsMouse -string true

# Reduce menu icons (macOS 26 Tahoe+)
defaults write -g NSMenuEnableActionImages -bool NO

log "defaults" "done"
