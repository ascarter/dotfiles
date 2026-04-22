-- =============================================================================
-- Packages (vim.pack)
-- =============================================================================

-- Disable netrw (replaced by fzf-lua file picker)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

local gh = function(r) return "https://github.com/" .. r end

-- Update plugins:  :lua vim.pack.update()
-- Update parsers:  :TSManager  (then 'u' on a parser, or 'i' to install)
-- Update Mason:    :Mason then press U
-- From CLI:        nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa
vim.pack.add({
  gh("ascarter/nvim-alpental-theme"),
  gh("romus204/tree-sitter-manager.nvim"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
  gh("mason-org/mason.nvim"),
  gh("ibhagwan/fzf-lua"),
  gh("mfussenegger/nvim-dap"),
  gh("rcarriga/nvim-dap-ui"),
  gh("nvim-neotest/nvim-nio"),
  gh("folke/which-key.nvim"),
  gh("nvim-mini/mini.ai"),
  gh("nvim-mini/mini.bracketed"),
  gh("nvim-mini/mini.pairs"),
  gh("nvim-mini/mini.surround"),
  gh("lewis6991/gitsigns.nvim"),
})
