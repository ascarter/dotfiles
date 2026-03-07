return {
  -- Mason: portable tool installer (LSP servers, DAP adapters)
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {
      ui = { border = "rounded" },
      ensure_installed = {
        -- DAP adapters
        "codelldb",
        "delve",
      },
    },
  },

  -- Server configuration definitions required by mason-lspconfig
  {
    "neovim/nvim-lspconfig",
    lazy = false,
  },

  -- Bridge Mason <-> nvim LSP built-in client
  -- automatic_enable = true calls vim.lsp.enable() for every installed server
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
