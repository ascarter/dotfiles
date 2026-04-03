-- =============================================================================
-- Leader (set before any plugins reference it)
-- =============================================================================
vim.g.mapleader          = " "
vim.g.maplocalleader     = " "

-- =============================================================================
-- Configuration
-- =============================================================================
require("plugins")
require("options")
require("lsp")
require("treesitter")
require("fzf")
require("debugging")
require("editor")
require("keymaps")
require("autocmds")
