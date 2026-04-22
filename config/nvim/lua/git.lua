-- =============================================================================
-- gitsigns.nvim — git decorations and hunk navigation (Zed parity)
-- =============================================================================
require("gitsigns").setup({
  signs = {
    add          = { text = "│" },
    change       = { text = "│" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
    untracked    = { text = "┆" },
  },
  signcolumn          = true,
  numhl               = false,
  linehl              = false,
  watch_gitdir        = { interval = 1000, follow_files = true },
  attach_to_untracked = true,
  current_line_blame  = false,
  on_attach           = function(bufnr)
    local gs = package.loaded.gitsigns
    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, silent = true, desc = desc })
    end

    -- Hunk navigation (Zed parity: ]c / [c)
    map("n", "]c", function()
      if vim.wo.diff then return "]c" end
      vim.schedule(function() gs.next_hunk() end)
      return "<Ignore>"
    end, "Next git hunk")
    map("n", "[c", function()
      if vim.wo.diff then return "[c" end
      vim.schedule(function() gs.prev_hunk() end)
      return "<Ignore>"
    end, "Previous git hunk")

    -- Hunk operations (Zed parity: do = expand diff hunk, dp = revert)
    map("n", "do", gs.preview_hunk,    "Preview/expand git hunk")
    map("n", "dp", gs.reset_hunk,      "Revert (reset) git hunk")
    map("n", "dO", gs.toggle_deleted,  "Toggle deleted lines view")
    map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>",   "Stage hunk")
    map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>",   "Reset hunk")
    map("n", "<leader>hS", gs.stage_buffer,                       "Stage buffer")
    map("n", "<leader>hu", gs.undo_stage_hunk,                    "Undo stage hunk")
    map("n", "<leader>hR", gs.reset_buffer,                       "Reset buffer")
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
    map("n", "<leader>hB", gs.toggle_current_line_blame,          "Toggle line blame")
    map("n", "<leader>hd", gs.diffthis,                           "Diff against index")
    map("n", "<leader>hD", function() gs.diffthis("~") end,       "Diff against last commit")

    -- Hunk text object
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>",     "Inside hunk")
  end,
})

-- =============================================================================
-- <leader>g* — repo-wide git pickers (fzf-lua) and buffer diff (gitsigns)
-- =============================================================================
local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>gs", "<cmd>FzfLua git_status<CR>",   "Git status")
map("<leader>gh", "<cmd>FzfLua git_hunks<CR>",    "Git hunks (repo)")
map("<leader>gl", "<cmd>FzfLua git_commits<CR>",  "Git log (repo)")
map("<leader>gL", "<cmd>FzfLua git_bcommits<CR>", "Git log (buffer)")
map("<leader>gb", "<cmd>FzfLua git_branches<CR>", "Git branches")
map("<leader>gd", function() require("gitsigns").diffthis() end,      "Diff against index")
map("<leader>gD", function() require("gitsigns").diffthis("~") end,   "Diff against last commit")
