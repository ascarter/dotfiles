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
