return {
  -- Mason: portable language server installer
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {
      ui = { border = "rounded" },
    },
  },

  -- lspconfig: server configuration definitions
  {
    "neovim/nvim-lspconfig",
    lazy = false,
  },

  -- Bridge mason <-> nvim LSP (auto-enables installed servers)
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "bashls",
        "gopls",
        "lua_ls",
        "marksman",
        "rust_analyzer",
        "taplo",
      },
      automatic_enable = true,
    },
  },
}
