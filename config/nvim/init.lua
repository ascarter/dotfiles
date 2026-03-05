-- =============================================================================
-- Bootstrap lazy.nvim
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- Options
-- =============================================================================
local opt            = vim.opt

-- Leader (set before plugins)
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- Interface
opt.number           = true
opt.relativenumber   = true
opt.cursorline       = true
opt.scrolloff        = 10
opt.signcolumn       = "yes"
opt.breakindent      = true

-- Search
opt.ignorecase       = true
opt.smartcase        = true

-- Splits
opt.splitright       = true
opt.splitbelow       = true

-- Whitespace visibility
opt.list             = true
opt.listchars        = { tab = "» ", trail = "·", nbsp = "␣" }

-- Completion
opt.pumheight        = 10

-- Files
opt.undofile         = true
opt.swapfile         = false

-- Misc
opt.confirm          = true
vim.schedule(function() opt.clipboard = "unnamedplus" end)

-- =============================================================================
-- Statusline
-- =============================================================================
opt.showmode   = false
opt.ruler      = false

local mode_map = {
  n       = { hl = "ModeNormal", text = "NORMAL" },
  i       = { hl = "ModeInsert", text = "INSERT" },
  v       = { hl = "ModeVisual", text = "VISUAL" },
  V       = { hl = "ModeVisual", text = "V·LINE" },
  ["\22"] = { hl = "ModeVisual", text = "V·BLOCK" }, -- <C-v>
  s       = { hl = "ModeVisual", text = "SELECT" },
  S       = { hl = "ModeVisual", text = "S·LINE" },
  ["\19"] = { hl = "ModeVisual", text = "S·BLOCK" }, -- <C-s>
  R       = { hl = "ModeReplace", text = "REPLACE" },
  c       = { hl = "ModeCommand", text = "COMMAND" },
  r       = { hl = "ModeNormal", text = "PROMPT" },
  t       = { hl = "ModeTerminal", text = "TERMINAL" },
  ["!"]   = { hl = "ModeNormal", text = "SHELL" },
  no      = { hl = "ModeNormal", text = "OPERATOR" },
  nt      = { hl = "ModeTerminal", text = "N·TERM" },
}

function _G.statusline()
  local m     = mode_map[vim.fn.mode()] or { hl = "ModeNormal", text = vim.fn.mode() }
  local mode  = ("%%#%s# %s %%*"):format(m.hl, m.text)
  local left  = " %f %m%r"
  local right = "%l:%c  " .. mode .. "  " .. vim.bo.filetype .. " "
  return left .. "%=" .. right
end

opt.statusline = "%!v:lua.statusline()"

-- =============================================================================
-- Autocommands
-- =============================================================================
local augroup = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
  group    = augroup,
  callback = function() vim.wo.relativenumber = false end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group    = augroup,
  callback = function() vim.wo.relativenumber = true end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

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

-- =============================================================================
-- Colorscheme
-- =============================================================================
vim.cmd.colorscheme("ansi")

-- =============================================================================
-- Plugins (lazy.nvim)
-- =============================================================================
require("lazy").setup({
  spec             = { { import = "plugins" } },
  defaults         = { lazy = true },
  rocks            = { enabled = false },
  change_detection = { notify = false },
})
