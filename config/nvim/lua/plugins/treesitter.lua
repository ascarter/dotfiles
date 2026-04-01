require("nvim-treesitter").setup({})

require("nvim-treesitter").install({
  "bash", "c", "css", "dockerfile", "go", "gomod", "gosum",
  "html", "javascript", "json", "lua", "make",
  "markdown", "markdown_inline", "python", "ruby",
  "rust", "sql", "swift", "toml", "typescript",
  "vim", "vimdoc", "yaml", "zig",
})

-- Enable treesitter highlighting, skip large files (>500KB)
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 500 * 1024 then
      return
    end
    pcall(vim.treesitter.start)
  end,
})

-- =============================================================================
-- Tree-sitter text objects (Zed-style motions and selections)
-- =============================================================================

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
  { "af", "@function.outer", "Around function" },
  { "if", "@function.inner", "Inside function" },
  { "ac", "@class.outer",    "Around class" },
  { "ic", "@class.inner",    "Inside class" },
  { "aa", "@parameter.outer", "Around argument" },
  { "ia", "@parameter.inner", "Inside argument" },
}) do
  vim.keymap.set({ "x", "o" }, map[1], function()
    select(map[2], "textobjects")
  end, { silent = true, desc = map[3] })
end

-- Motions: ]m/[m (method), ]]/[[ (class), ]M/[M and ][/[] (ends)
for _, map in ipairs({
  { "]m", move.goto_next_start,     "@function.outer", "Next method start" },
  { "[m", move.goto_previous_start, "@function.outer", "Previous method start" },
  { "]]", move.goto_next_start,     "@class.outer",    "Next class start" },
  { "[[", move.goto_previous_start, "@class.outer",    "Previous class start" },
  { "]M", move.goto_next_end,       "@function.outer", "Next method end" },
  { "[M", move.goto_previous_end,   "@function.outer", "Previous method end" },
  { "][", move.goto_next_end,       "@class.outer",    "Next class end" },
  { "[]", move.goto_previous_end,   "@class.outer",    "Previous class end" },
}) do
  vim.keymap.set({ "n", "x", "o" }, map[1], function()
    map[2](map[3], "textobjects")
  end, { silent = true, desc = map[4] })
end
