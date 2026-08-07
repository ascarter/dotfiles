-- Keymap discovery
local wk = require("which-key")
wk.setup({
  delay = 300,
  icons = { mappings = false },
  notify = false,
  win = { border = "rounded" },
})

wk.add({
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>d", group = "debug" },
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>s", group = "search" },
  { "g",         group = "goto" },
  { "]",         group = "next" },
  { "[",         group = "prev" },
})

-- Auto-close brackets, quotes, etc.
require("mini.pairs").setup({})

-- Surround: add/change/delete surrounding chars
-- Matches Zed/vim-surround keybindings: ys (add), cs (change), ds (delete)
require("mini.surround").setup({
  mappings = {
    add            = "ys",
    delete         = "ds",
    replace        = "cs",
    find           = "",
    find_left      = "",
    highlight      = "",
    update_n_lines = "",
  },
})
