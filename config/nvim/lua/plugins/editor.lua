return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({
      delay = 300,
      icons = { mappings = false },
      win = { border = "rounded" },
    })

    -- Label leader key groups
    wk.add({
      { "<leader>f", group = "find" },
      { "<leader>c", group = "code" },
      { "<leader>d", group = "debug" },
    })
  end,
}
