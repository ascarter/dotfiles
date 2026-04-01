-- =============================================================================
-- Mason (tool installer) + native LSP configuration
-- =============================================================================

-- Mason: install and manage LSP servers, DAP adapters, linters
require("mason").setup()

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

    -- Enable built-in LSP completion (icon-only kind, no menu detail)
    if client:supports_method("textDocument/completion") then
      -- LSP CompletionItemKind icons (Material Design / Nerd Font)
      local kind_icons = {
        [1]  = "\u{f021a}",  -- Text: file-document
        [2]  = "\u{f0295}",  -- Method: function
        [3]  = "\u{f0295}",  -- Function: function
        [4]  = "\u{f0551}",  -- Constructor: wrench
        [5]  = "\u{f0374}",  -- Field: ray-start-arrow
        [6]  = "\u{f0034}",  -- Variable: alpha-v-circle
        [7]  = "\u{f01a7}",  -- Class: cube-scan
        [8]  = "\u{f01a5}",  -- Interface: cube-outline
        [9]  = "\u{f01a7}",  -- Module: cube-scan
        [10] = "\u{f0374}",  -- Property: ray-start-arrow
        [11] = "\u{f01a5}",  -- Unit: cube-outline
        [12] = "\u{f0317}",  -- Value: numeric
        [13] = "\u{f0279}",  -- Enum: format-list-numbered
        [14] = "\u{f0a76}",  -- Keyword: key-variant
        [15] = "\u{f0174}",  -- Snippet: code-tags
        [16] = "\u{f0266}",  -- Color: palette
        [17] = "\u{f0214}",  -- File: file
        [18] = "\u{f0320}",  -- Reference: link-variant
        [19] = "\u{f024b}",  -- Folder: folder
        [20] = "\u{f0279}",  -- EnumMember: format-list-numbered
        [21] = "\u{f0317}",  -- Constant: numeric
        [22] = "\u{f01a7}",  -- Struct: cube-scan
        [23] = "\u{f05ce}",  -- Event: lightning-bolt
        [24] = "\u{f0498}",  -- Operator: plus-minus-variant
        [25] = "\u{f01a7}",  -- TypeParameter: cube-scan
      }
      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,
        convert = function(item)
          local icon = kind_icons[item.kind] or ""
          return {
            abbr = icon ~= "" and (icon .. " " .. item.label) or item.label,
            kind = "",
            menu = "",
          }
        end,
      })
      vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", {
        buf = bufnr, desc = "LSP: trigger completion",
      })
    end

    -- Enable inline ghost-text completions (Copilot)
    -- Suggestions appear automatically; Tab or Ctrl-Y to accept
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
