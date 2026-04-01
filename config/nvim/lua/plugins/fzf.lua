require("fzf-lua").setup({
  "default-title",
  winopts = {
    border  = "rounded",
    preview = {
      border       = "rounded",
      layout       = "flex",
      flip_columns = 120,
    },
  },
  keymap = {
    fzf = {
      ["ctrl-q"] = "select-all+accept",
    },
  },
  files = {
    formatter = "path.filename_first",
    hidden    = true,
    follow    = true,
    git_icons = false,
  },
  grep = {
    hidden = true,
    follow = true,
  },
})

local fzf = require("fzf-lua")
local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

-- Find
map("<leader>ff", fzf.files,     "Find files")
map("<leader>fg", fzf.git_files, "Git files")
map("<leader>fr", fzf.oldfiles,  "Recent files")
map("<leader>fh", fzf.helptags,  "Help tags")
map("<leader>?",  fzf.keymaps,   "Keymaps")

-- Search / grep
map("<leader>/",  fzf.live_grep,  "Live grep")
map("<leader>sw", fzf.grep_cword, "Grep word")
map("<leader>sW", fzf.grep_cWORD, "Grep WORD")
map("<leader>sr", fzf.resume,     "Resume last picker")

-- Buffers
map("<leader>bb", fzf.buffers, "List buffers")

-- Code (LSP pickers)
map("<leader>cs", fzf.lsp_document_symbols,  "Document symbols")
map("<leader>cS", fzf.lsp_workspace_symbols, "Workspace symbols")
map("<leader>cd", fzf.diagnostics_document,  "Diagnostics")

-- Git
map("<leader>gc", fzf.git_commits, "Commits")
map("<leader>gs", fzf.git_status,  "Status")
