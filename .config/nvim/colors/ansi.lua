-- =====================================================================
-- ANSI 16-color theme for Neovim (Lua port)
-- =====================================================================
--
-- Palette:
-- ================================================
-- 0: Black        │   8: Bright Black (dark gray)
-- 1: Red          │   9: Bright Red
-- 2: Green        │  10: Bright Green
-- 3: Yellow       │  11: Bright Yellow
-- 4: Blue         │  12: Bright Blue
-- 5: Magenta      │  13: Bright Magenta
-- 6: Cyan         │  14: Bright Cyan
-- 7: White (gray) │  15: Bright White
-- ================================================

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "ansi"
vim.opt.termguicolors = false

local hi = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- UI elements -----------------------------------------------------------------
hi("CursorLine",   { ctermfg = "NONE", ctermbg = "NONE" })
hi("CursorColumn", { ctermfg = "NONE", ctermbg = "NONE" })
hi("CursorLineNr", { ctermbg = "NONE", bold = true })
hi("LineNr",       { ctermfg = 7 })

hi("StatusLine",   { bold = true })
hi("StatusLineNC", { ctermfg = 8 })

hi("ModeNormal",   {})
hi("ModeInsert",   { ctermbg = 11, bold = true })
hi("ModeVisual",   { ctermfg = 15, ctermbg = 12, bold = true })
hi("ModeReplace",  { ctermfg = 15, ctermbg = 9,  bold = true })
hi("ModeCommand",  { ctermfg = 15, ctermbg = 5,  bold = true })
hi("ModeTerminal", { ctermfg = 0,  ctermbg = 10, bold = true })

hi("Pmenu",        {})
hi("PmenuSel",     { ctermfg = 12, bold = true, reverse = true })
hi("PmenuSbar",    { ctermfg = 4,  ctermbg = 8 })
hi("PmenuThumb",   { ctermbg = 7 })

hi("Visual",       { ctermfg = 12, reverse = true })
hi("Search",       { ctermfg = 11, reverse = true })
hi("IncSearch",    { ctermfg = 11, reverse = true })
hi("MatchParen",   { ctermbg = 12, bold = true })

hi("SignColumn",   { ctermfg = 7, ctermbg = "NONE" })

hi("DebugBreakpoint", { ctermfg = 1, bold = true })
hi("DebugPC",         { ctermfg = 3, bold = true })

hi("WarningMsg", { ctermfg = 8,  ctermbg = 11 })
hi("ErrorMsg",   { ctermfg = 15, ctermbg = 1, bold = true, italic = true })

-- Syntax highlighting ---------------------------------------------------------
hi("Boolean",      {})
hi("Comment",      { ctermfg = 8, italic = true })
hi("Conditional",  {})
hi("Constant",     { italic = true })
hi("Number",       { italic = true })
hi("Exception",    {})
hi("Function",     {})
hi("Identifier",   {})
hi("Include",      { italic = true })
hi("Keyword",      {})
hi("Label",        { ctermfg = 4, bold = true })
hi("Macro",        { italic = true })
hi("Operator",     {})
hi("PreProc",      { italic = true })
hi("Repeat",       {})
hi("Special",      {})
hi("Statement",    {})
hi("StorageClass", {})
hi("String",       {})
hi("Structure",    { bold = true })
hi("Tag",          { ctermfg = 4, bold = true })
hi("Type",         {})
hi("Whitespace",   { ctermfg = 8 })

hi("Error", { ctermfg = 1, ctermbg = "NONE" })
hi("Todo",  { ctermfg = 2, ctermbg = "NONE", bold = true, italic = true })

-- Diff ------------------------------------------------------------------------
hi("DiffAdd",    { ctermfg = 0,  ctermbg = 10, bold = true })
hi("DiffChange", { ctermfg = 0,  ctermbg = 12, bold = true, italic = true })
hi("DiffDelete", { ctermfg = 15, ctermbg = 9,  bold = true })
hi("DiffText",   { ctermfg = 0,  ctermbg = 14, bold = true, italic = true })

hi("diffAdded",   { ctermfg = 4 })
hi("diffRemoved", { ctermfg = 1 })
hi("diffChanged", { ctermfg = 3 })

-- Diagnostics -----------------------------------------------------------------
hi("DiagnosticUnderlineError", { undercurl = true, ctermfg = 1 })
hi("DiagnosticUnderlineWarn",  { undercurl = true, ctermfg = 11 })
hi("DiagnosticUnderlineInfo",  { undercurl = true, ctermfg = 4 })
hi("DiagnosticUnderlineHint",  { undercurl = true, ctermfg = 8 })
