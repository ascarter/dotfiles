#!/bin/sh
#
# Update Neovim plugins, treesitter parsers, and Mason tools headlessly.
#
# Usage: dotfiles script nvim-update
#

set -eu

if ! command -v nvim >/dev/null 2>&1; then
  echo "nvim not found" >&2
  exit 1
fi

echo "Updating plugins..."
nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa

echo "Updating treesitter parsers..."
nvim --headless +TSUpdate +qa

echo "Updating Mason tools..."
nvim --headless +'lua require("mason-registry").refresh(function() require("mason-registry").update(function() vim.cmd("qa") end) end)' 2>&1

echo "Neovim update complete."
