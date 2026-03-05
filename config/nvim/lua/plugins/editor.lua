return {
  -- Keymap discovery
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        delay = 300,
        icons = { mappings = false },
        notify = false,
        win = { border = "rounded" },
      })

      -- Label leader key groups
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
    end,
  },

  -- Auto-close brackets, quotes, etc.
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    config = function()
      require("mini.pairs").setup({})
    end,
  },

  -- Surround: add/change/delete surrounding chars
  -- Matches Zed/vim-surround keybindings: ys (add), cs (change), ds (delete)
  {
    "nvim-mini/mini.surround",
    event = "VeryLazy",
    config = function()
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
    end,
  },
}
