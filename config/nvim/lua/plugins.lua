-- =============================================================================
-- Packages (vim.pack)
-- =============================================================================

-- Disable netrw (replaced by fzf-lua file picker)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

local gh = function(r) return "https://github.com/" .. r end

-- Update plugins:  :lua vim.pack.update()
-- Update parsers:  :TSUpdate
-- From CLI:        nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(event)
    local data = event.data
    if data.spec.name ~= "nvim-treesitter" or data.kind ~= "update" then
      return
    end

    if not data.active then
      vim.cmd.packadd("nvim-treesitter")
    end
    require("nvim-treesitter").update():wait(300000)
  end,
})

vim.pack.add({
  gh("ascarter/nvim-alpental-theme"),
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
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
