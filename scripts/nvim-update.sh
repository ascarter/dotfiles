#!/bin/sh
#
# Update Neovim plugins, treesitter parsers, and Mason tools headlessly.
# Cleans up legacy lazy.nvim artifacts if present.
#
# Usage: dotfiles script nvim-update
#

set -eu

if ! command -v nvim >/dev/null 2>&1; then
  echo "nvim not found" >&2
  exit 1
fi

# ── Clean up legacy lazy.nvim artifacts ────────────────────────────────────────
cleaned=0

if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy" ]; then
  echo "Removing lazy.nvim plugin data..."
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
  cleaned=1
fi

if [ -d "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy" ]; then
  echo "Removing lazy.nvim state..."
  rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy"
  cleaned=1
fi

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json" ]; then
  echo "Removing lazy-lock.json..."
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
  cleaned=1
fi

# Remove broken symlinks left by deleted config files
stale=$(find "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" -type l ! -exec test -e {} \; -print 2>/dev/null || true)
if [ -n "$stale" ]; then
  echo "Removing stale symlinks..."
  echo "$stale" | while read -r link; do rm -f "$link"; done
  cleaned=1
fi

if [ "$cleaned" -eq 1 ]; then
  echo "Cleanup complete."
  echo ""
fi

# ── Update ─────────────────────────────────────────────────────────────────────
echo "Updating plugins..."
nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa
echo ""

echo "Updating treesitter parsers..."
nvim --headless +TSUpdate +qa
echo ""

echo "Updating Mason registry..."
nvim --headless +'lua require("mason-registry").refresh(function() vim.cmd("qa") end)' 2>&1
echo ""

echo "Neovim update complete."
