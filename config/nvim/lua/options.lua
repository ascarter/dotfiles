-- =============================================================================
-- Options
-- =============================================================================
local opt                = vim.opt

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

opt.statuscolumn         = "%!v:lua.statuscolumn()"

-- Folding (treesitter-based)
opt.foldmethod           = "expr"
opt.foldexpr             = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel            = 99

-- Search
opt.ignorecase           = true
opt.smartcase            = true

-- Splits
opt.splitright           = true
opt.splitbelow           = true

-- Whitespace visibility
opt.list                 = true
opt.listchars            = { tab = "» ", trail = "·", nbsp = "␣" }

-- Completion
opt.pumheight            = 10
opt.pumwidth             = 15
opt.pummaxwidth          = 40
opt.pumborder            = "rounded"
opt.completeopt          = "menuone,noinsert,popup"

-- Floating windows (docs popup, hover, etc.)
opt.winborder            = "rounded"

-- Files
opt.undofile             = true
opt.swapfile             = false

-- Suppress intro screen
opt.shortmess:append("I")

-- Misc
opt.confirm              = true

-- =============================================================================
-- Colorscheme
-- =============================================================================
vim.cmd.colorscheme("alpental")

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

  -- Git: branch and +/~/- counts (provided by gitsigns via b:gitsigns_*)
  local git = ""
  local head = vim.b.gitsigns_head
  if head and head ~= "" then
    local s = vim.b.gitsigns_status_dict or {}
    local parts = { " " .. head }
    if (s.added or 0)   > 0 then table.insert(parts, "+" .. s.added)   end
    if (s.changed or 0) > 0 then table.insert(parts, "~" .. s.changed) end
    if (s.removed or 0) > 0 then table.insert(parts, "-" .. s.removed) end
    git = table.concat(parts, " ") .. "  "
  end

  local right = git .. "%l:%c  " .. mode .. "  " .. vim.bo.filetype .. " "
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
    source = true,
  },
})
