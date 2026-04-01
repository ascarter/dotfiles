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
local opt                = vim.opt

-- Leader (set before plugins)
vim.g.mapleader          = " "
vim.g.maplocalleader     = " "

-- Disable netrw (replaced by fzf-lua file picker)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

-- Cursor
opt.guicursor            = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

-- Interface
opt.number               = true
opt.relativenumber       = true
opt.cursorline           = true
opt.scrolloff            = 10
opt.signcolumn           = "yes"
opt.breakindent          = true

-- Status column: bold line numbers for active line and visual selection
function _G.statuscolumn()
  local num = vim.v.relnum ~= 0 and vim.v.relnum or vim.v.lnum
  local bold = vim.v.relnum == 0
  if not bold then
    local mode = vim.fn.mode()
    if mode:find("[vV\22]") then
      local v_start, v_end = vim.fn.line("v"), vim.fn.line(".")
      if v_start > v_end then v_start, v_end = v_end, v_start end
      bold = vim.v.lnum >= v_start and vim.v.lnum <= v_end
    end
  end
  local hl = bold and "%#CursorLineNr#" or "%#LineNr#"
  return "%s%=" .. hl .. num .. "%* "
end

opt.statuscolumn = "%!v:lua.statuscolumn()"

-- Folding (treesitter-based)
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99

-- Search
opt.ignorecase   = true
opt.smartcase    = true

-- Splits
opt.splitright   = true
opt.splitbelow   = true

-- Whitespace visibility
opt.list         = true
opt.listchars    = { tab = "» ", trail = "·", nbsp = "␣" }

-- Completion
opt.pumheight    = 10

-- Files
opt.undofile     = true
opt.swapfile     = false

-- Suppress intro screen
opt.shortmess:append("I")

-- Misc
opt.confirm    = true

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
-- Diagnostics
-- =============================================================================
vim.diagnostic.config({
  virtual_text     = { prefix = "●" },
  signs            = true,
  underline        = true,
  update_in_insert = false,
  severity_sort    = true,
  float            = {
    border = "rounded",
    source = true,
  },
})

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

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

-- Open help in a vertical split
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("wincmd L")
  end,
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

-- Open file picker on startup (no args or directory arg)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if vim.fn.argc() == 0 or vim.fn.isdirectory(arg) == 1 then
      if vim.fn.isdirectory(arg) == 1 then
        vim.cmd.cd(arg)
      end
      vim.schedule(function() require("fzf-lua").files() end)
    end
  end,
})

-- Redirect :edit <directory> to fzf file picker
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if vim.fn.isdirectory(vim.api.nvim_buf_get_name(args.buf)) == 1 then
      vim.schedule(function()
        vim.cmd("bwipeout " .. args.buf)
        require("fzf-lua").files()
      end)
    end
  end,
})

-- LSP customizations (activate when a language server attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- Enable built-in LSP completion
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
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
    if client and client:supports_method("textDocument/inlayHint") then
      vim.keymap.set("n", "<leader>ci", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
      end, { buf = bufnr, silent = true, desc = "Toggle inlay hints" })
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
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer" })

-- Clipboard: "On Yank" behavior (matches Zed setting)
-- y/Y use system clipboard; d/x/c/p/P stay in vim registers
map({ "n", "v" }, "y", '"+y')
map("n", "Y", '"+Y')

-- =============================================================================
-- Plugins (lazy.nvim)
-- =============================================================================
require("lazy").setup({
  spec             = { { import = "plugins" } },
  defaults         = { lazy = true },
  rocks            = { enabled = false },
  change_detection = { notify = false },
})
