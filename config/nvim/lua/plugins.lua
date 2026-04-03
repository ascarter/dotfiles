-- =============================================================================
-- Packages (vim.pack)
-- =============================================================================

-- Disable netrw (replaced by fzf-lua file picker)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

local gh = function(r) return "https://github.com/" .. r end

-- Build hook: recompile parsers after treesitter updates
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update" then
      vim.cmd("TSUpdate")
    end
  end,
})

-- Update plugins:  :lua vim.pack.update()
-- Update parsers:  :TSUpdate
-- Update Mason:    :Mason then press U
-- From CLI:        nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa
--                  nvim --headless +TSUpdate +qa
vim.pack.add({
  gh("ascarter/nvim-alpental-theme"),
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
  gh("mason-org/mason.nvim"),
  gh("ibhagwan/fzf-lua"),
  gh("mfussenegger/nvim-dap"),
  gh("rcarriga/nvim-dap-ui"),
  gh("nvim-neotest/nvim-nio"),
  gh("folke/which-key.nvim"),
  gh("echasnovski/mini.pairs"),
  gh("echasnovski/mini.surround"),
})
