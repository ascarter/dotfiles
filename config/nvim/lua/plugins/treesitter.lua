return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({})

    -- Install parsers for common languages
    require("nvim-treesitter").install({
      "bash", "c", "css", "dockerfile", "go", "gomod", "html",
      "javascript", "json", "lua", "markdown", "python", "ruby",
      "rust", "toml", "typescript", "yaml",
    })

    -- Enable treesitter highlighting for all filetypes
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
