return {
  -- Mason: portable tool installer (LSP servers, DAP adapters)
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {
      ui = { border = "rounded" },
    },
  },

  -- Server configuration definitions required by mason-lspconfig
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime   = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
            telemetry = { enable = false },
          },
        },
      })
    end,
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

  -- Bridge Mason <-> nvim-dap (auto-install and configure DAP adapters)
  {
    "jay-babu/mason-nvim-dap.nvim",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      ensure_installed = {
        "codelldb",
        "delve",
      },
      automatic_installation = true,
    },
  },
}
