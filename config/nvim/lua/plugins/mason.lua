local has_native_inline = vim.lsp.inline_completion ~= nil

local lsp_servers = {
  "bashls",
  "gopls",
  "lua_ls",
  "marksman",
  "rust_analyzer",
  "taplo",
}
-- Only use Copilot LSP server when Neovim supports inline completions
if has_native_inline then
  table.insert(lsp_servers, "copilot")
end

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

      -- Enable inline ghost-text completions for LSP servers that support it (Copilot)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          if vim.lsp.inline_completion
            and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, args.buf) then
            vim.lsp.inline_completion.enable(true, { bufnr = args.buf })
          end
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, args.buf) then
            vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", {
              buf = args.buf,
              desc = "LSP: trigger completion",
            })
          end
        end,
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
      ensure_installed = lsp_servers,
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
    },
  },
}
