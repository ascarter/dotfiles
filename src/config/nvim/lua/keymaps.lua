-- =============================================================================
-- Keymaps
-- =============================================================================
local map = function(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Exit terminal mode
map("t", "<Esc><Esc>", "<C-\\><C-n>")

-- Split navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprev<CR>")
map("n", "<S-l>", "<cmd>bnext<CR>")
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer" })

-- Clipboard: "On Yank" behavior (matches Zed setting)
-- y/Y use system clipboard; d/x/c/p/P stay in vim registers
map({ "n", "v" }, "y", '"+y')
map("n", "Y", '"+Y')

-- Completion: Tab accepts popup selection or ghost text, else inserts tab
-- Ctrl-Y does the same with fallback to built-in (insert char from line above)
-- Ctrl-N/P navigate popup items (built-in), Ctrl-E dismisses (built-in)
vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  end
  if not vim.lsp.inline_completion.get() then
    return "<Tab>"
  end
end, { expr = true, desc = "Accept completion or Tab" })

vim.keymap.set("i", "<C-y>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  end
  if not vim.lsp.inline_completion.get() then
    return "<C-y>"
  end
end, { expr = true, desc = "Accept completion" })

-- Esc dismisses popup without accepting, then exits insert mode
vim.keymap.set("i", "<Esc>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e><Esc>"
  end
  return "<Esc>"
end, { expr = true, desc = "Dismiss completion or exit insert" })
