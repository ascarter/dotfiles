return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    -- Find
    { "<leader>ff", function() require("fzf-lua").files() end,          desc = "Find files" },
    { "<leader>fg", function() require("fzf-lua").git_files() end,      desc = "Git files" },
    { "<leader>fr", function() require("fzf-lua").oldfiles() end,       desc = "Recent files" },
    { "<leader>fh", function() require("fzf-lua").helptags() end,       desc = "Help tags" },
    { "<leader>?",  function() require("fzf-lua").keymaps() end,        desc = "Keymaps" },

    -- Search / grep
    { "<leader>/",  function() require("fzf-lua").live_grep() end,      desc = "Live grep" },
    { "<leader>sw", function() require("fzf-lua").grep_cword() end,     desc = "Grep word" },
    { "<leader>sW", function() require("fzf-lua").grep_cWORD() end,     desc = "Grep WORD" },
    { "<leader>sr", function() require("fzf-lua").resume() end,         desc = "Resume last picker" },

    -- Buffers
    { "<leader>bb", function() require("fzf-lua").buffers() end,        desc = "List buffers" },

    -- Code (LSP pickers)
    { "<leader>cs", function() require("fzf-lua").lsp_document_symbols() end,  desc = "Document symbols" },
    { "<leader>cS", function() require("fzf-lua").lsp_workspace_symbols() end, desc = "Workspace symbols" },
    { "<leader>cd", function() require("fzf-lua").diagnostics_document() end,  desc = "Diagnostics" },

    -- Git
    { "<leader>gc", function() require("fzf-lua").git_commits() end,    desc = "Commits" },
    { "<leader>gs", function() require("fzf-lua").git_status() end,     desc = "Status" },
  },
  config = function()
    require("fzf-lua").setup({
      "default-title",
      winopts = {
        border  = "rounded",
        preview = {
          border       = "rounded",
          layout       = "flex",
          flip_columns = 120,
        },
      },
      keymap = {
        fzf = {
          ["ctrl-q"] = "select-all+accept",
        },
      },
      files = {
        formatter = "path.filename_first",
        hidden    = true,
        follow    = true,
        git_icons = false,
      },
      grep = {
        hidden = true,
        follow = true,
      },
    })
  end,
}
