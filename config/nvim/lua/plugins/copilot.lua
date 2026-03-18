-- Fallback: use copilot.vim for ghost text on Neovim < 0.12 where
-- vim.lsp.inline_completion is not available. Once 0.12+ is installed,
-- the native LSP copilot server (via Mason) handles suggestions and
-- this plugin becomes a no-op.
local has_native = vim.lsp.inline_completion ~= nil

return {
  {
    "github/copilot.vim",
    cond = not has_native,
    lazy = false,
  },
}
