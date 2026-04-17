#!/usr/bin/env bash
#
# Update Neovim plugins, treesitter parsers, and Mason tools headlessly.
# Cleans up legacy lazy.nvim artifacts if present.
#
# Usage: dotfiles script nvim-update
#

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if ! command -v nvim >/dev/null 2>&1; then
  abort "nvim not found"
fi

# ── Clean up legacy lazy.nvim artifacts ────────────────────────────────────────
cleaned=0

if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy" ]; then
  log "nvim" "removing lazy.nvim plugin data"
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
  cleaned=1
fi

if [ -d "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy" ]; then
  log "nvim" "removing lazy.nvim state"
  rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy"
  cleaned=1
fi

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json" ]; then
  log "nvim" "removing lazy-lock.json"
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
  cleaned=1
fi

# Remove broken symlinks left by deleted config files
stale=$(find "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" -type l ! -exec test -e {} \; -print 2>/dev/null || true)
if [ -n "$stale" ]; then
  log "nvim" "removing stale symlinks"
  echo "$stale" | while read -r link; do rm -f "$link"; done
  cleaned=1
fi

if [ "$cleaned" -eq 1 ]; then
  log "nvim" "cleanup complete"
  log
fi

# ── Update ─────────────────────────────────────────────────────────────────────
log "nvim" "updating plugins..."
nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa
log

log "nvim" "updating treesitter parsers..."
nvim --headless +TSUpdate +qa
log

success "nvim" "update complete"
