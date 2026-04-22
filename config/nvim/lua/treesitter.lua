-- =============================================================================
-- Tree-sitter parser management (tree-sitter-manager.nvim)
-- =============================================================================
-- Replaces the archived nvim-treesitter. Manages parser install/update and
-- registers FileType autocmds to call vim.treesitter.start (Neovim 0.12+ has
-- treesitter in core). Use :TSManager for the TUI (i=install, u=update,
-- x=remove).

require("tree-sitter-manager").setup({
  ensure_installed = {
    "bash", "c", "css", "dockerfile", "go", "gomod", "gosum",
    "html", "javascript", "json", "lua", "make",
    "markdown", "markdown_inline", "python", "ruby",
    "rust", "sql", "swift", "toml", "typescript",
    "vim", "vimdoc", "yaml", "zig",
  },
  auto_install = true,
})

-- Skip treesitter highlighting on very large files (>500KB).
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 500 * 1024 then
      vim.schedule(function() pcall(vim.treesitter.stop, args.buf) end)
    end
  end,
})

-- =============================================================================
-- General-purpose text objects (mini.ai)
-- =============================================================================
-- Heuristic, language-agnostic: a"/i", a(/i(, ab/ib, a?/i?, etc.
-- Treesitter-aware text objects (af/if, ac/ic, aa/ia) are handled below by
-- nvim-treesitter-textobjects, which overrides mini.ai's heuristic versions
-- of those specific keys.
require("mini.ai").setup({ n_lines = 500 })

-- =============================================================================
-- Bracket motions (mini.bracketed)
-- =============================================================================
-- ]b/[b buffer, ]/ // [/ comment (Zed parity), ]d/[d diagnostic,
-- ]t/[t treesitter node, etc. See :h mini.bracketed.
--
-- Suffix overrides:
--   comment  → '/'  (frees ]c/[c for gitsigns hunk nav, matches Zed's ]/)
--   conflict → ''   (disabled; we reuse ]x/[x for treesitter expand/shrink)
require("mini.bracketed").setup({
  comment  = { suffix = "/" },
  conflict = { suffix = "" },
})

-- =============================================================================
-- Treesitter incremental selection (Zed-parity ]x / [x)
-- =============================================================================
-- ]x expands the visual selection to the parent treesitter node.
-- [x shrinks back to the previous (smaller) node in the expansion stack.
local ts_sel_stack = {}

local function ts_expand()
  local node
  if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
    -- Use current selection range to find the smallest enclosing node.
    local s = vim.fn.getpos("v")
    local e = vim.fn.getpos(".")
    local sr, sc = s[2] - 1, s[3] - 1
    local er, ec = e[2] - 1, e[3]
    if sr > er or (sr == er and sc > ec) then sr, sc, er, ec = er, ec - 1, sr, sc + 1 end
    node = vim.treesitter.get_node({ pos = { sr, sc } })
    if node then
      while node:parent() do
        local nr1, nc1, nr2, nc2 = node:range()
        if nr1 < sr or (nr1 == sr and nc1 < sc) or nr2 > er or (nr2 == er and nc2 > ec) then
          break
        end
        node = node:parent()
      end
    end
  else
    node = vim.treesitter.get_node()
    ts_sel_stack = {}
  end

  if not node then return end
  table.insert(ts_sel_stack, node)
  local sr, sc, er, ec = node:range()
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
end

local function ts_shrink()
  if #ts_sel_stack < 2 then return end
  table.remove(ts_sel_stack)
  local node = ts_sel_stack[#ts_sel_stack]
  local sr, sc, er, ec = node:range()
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
end

vim.keymap.set({ "n", "x" }, "]x", ts_expand, { silent = true, desc = "Expand syntax node" })
vim.keymap.set({ "n", "x" }, "[x", ts_shrink, { silent = true, desc = "Shrink syntax node" })

-- =============================================================================
-- Tree-sitter text objects & motions (Zed-style)
-- =============================================================================
-- nvim-treesitter-textobjects ships textobjects.scm queries for ~all
-- languages and a select/move API. It's standalone (no longer depends on the
-- archived nvim-treesitter) and actively maintained.

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
  },
  move = {
    set_jumps = true,
  },
})

local select = require("nvim-treesitter-textobjects.select").select_textobject
local move   = require("nvim-treesitter-textobjects.move")

-- Text objects: af/if (function), ac/ic (class), aa/ia (argument)
for _, map in ipairs({
  { "af", "@function.outer",  "Around function" },
  { "if", "@function.inner",  "Inside function" },
  { "ac", "@class.outer",     "Around class" },
  { "ic", "@class.inner",     "Inside class" },
  { "aa", "@parameter.outer", "Around argument" },
  { "ia", "@parameter.inner", "Inside argument" },
}) do
  vim.keymap.set({ "x", "o" }, map[1], function()
    select(map[2], "textobjects")
  end, { silent = true, desc = map[3] })
end

-- Method motions: ]m/[m (start), ]M/[M (end)
for _, map in ipairs({
  { "]m", move.goto_next_start,     "@function.outer", "Next method start" },
  { "[m", move.goto_previous_start, "@function.outer", "Previous method start" },
  { "]M", move.goto_next_end,       "@function.outer", "Next method end" },
  { "[M", move.goto_previous_end,   "@function.outer", "Previous method end" },
}) do
  vim.keymap.set({ "n", "x", "o" }, map[1], function()
    map[2](map[3], "textobjects")
  end, { silent = true, desc = map[4] })
end

-- Section motions: ]]/[[ and ][/[]
-- Zed parity: try @class.outer first; fall back to @function.outer when no
-- classes exist in the buffer (matches Zed's "section" semantics).
local function ts_section(direction, edge)
  local fn = ({
    ["next.start"]  = move.goto_next_start,
    ["prev.start"]  = move.goto_previous_start,
    ["next.end"]    = move.goto_next_end,
    ["prev.end"]    = move.goto_previous_end,
  })[direction .. "." .. edge]
  return function()
    local cur = vim.api.nvim_win_get_cursor(0)
    fn("@class.outer", "textobjects")
    -- If cursor didn't move, fall back to function.
    local new = vim.api.nvim_win_get_cursor(0)
    if cur[1] == new[1] and cur[2] == new[2] then
      fn("@function.outer", "textobjects")
    end
  end
end

for _, map in ipairs({
  { "]]", "next", "start", "Next section start" },
  { "[[", "prev", "start", "Previous section start" },
  { "][", "next", "end",   "Next section end" },
  { "[]", "prev", "end",   "Previous section end" },
}) do
  vim.keymap.set({ "n", "x", "o" }, map[1], ts_section(map[2], map[3]),
    { silent = true, desc = map[4] })
end
