-- =============================================================================
-- Mason (tool installer) + native LSP configuration
-- =============================================================================

-- Mason: install and manage LSP servers, DAP adapters, linters
require("mason").setup({ ui = { border = "rounded" } })

-- Auto-install required tools on startup
local tools = {
  "bash-language-server",
  "copilot-language-server",
  "gopls",
  "lua-language-server",
  "marksman",
  "rust-analyzer",
  "taplo",
  "codelldb",
  "delve",
}

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local registry = require("mason-registry")
    registry.refresh(function()
      for _, name in ipairs(tools) do
        local ok, pkg = pcall(registry.get_package, name)
        if ok and not pkg:is_installed() then
          pkg:install()
        end
      end
    end)
  end,
})

-- LSP server customizations (override nvim-lspconfig defaults)
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

-- Enable LSP servers (definitions provided by nvim-lspconfig)
vim.lsp.enable({
  "bashls",
  "copilot",
  "gopls",
  "lua_ls",
  "marksman",
  "rust_analyzer",
  "taplo",
})

-- LSP keymaps and features (activate when a language server attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    -- Enable built-in LSP completion
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", {
        buf = bufnr, desc = "LSP: trigger completion",
      })
    end

    -- Enable inline ghost-text completions (Copilot)
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion) then
      vim.lsp.inline_completion.enable(true, { bufnr = bufnr })
    end

    -- Use fzf-lua for references (nicer UI than default quickfix)
    local ok, fzf = pcall(require, "fzf-lua")
    if ok then
      vim.keymap.set("n", "grr", fzf.lsp_references, { buf = bufnr, silent = true, desc = "References" })
    end

    -- Format with leader key
    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, { buf = bufnr, silent = true, desc = "Format" })

    -- Inlay hints (<leader>ci to toggle)
    if client:supports_method("textDocument/inlayHint") then
      vim.keymap.set("n", "<leader>ci", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
      end, { buf = bufnr, silent = true, desc = "Toggle inlay hints" })
    end
  end,
})
